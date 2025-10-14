# 后端日志删除API实现建议

## 问题分析

从后端日志可以看出：
```
{"method":"DELETE","path":"/api/v1/logs/10522","status_code":404}
```

前端正在调用 `DELETE /api/v1/logs/{id}` 和 `POST /api/v1/logs/batch-delete` API，但后端返回404，说明这些API还没有实现。

## 需要实现的API

### 1. 单条日志删除 API

**路径**: `DELETE /api/v1/logs/{id}`

**Go实现建议** (在 `internal/handlers/system_handler.go` 或类似文件中):

```go
// DeleteLog 删除单条日志
func (h *SystemHandler) DeleteLog(c *gin.Context) {
    logID := c.Param("id")
    
    // 验证ID格式
    id, err := strconv.ParseUint(logID, 10, 32)
    if err != nil {
        c.JSON(400, gin.H{
            "success": false,
            "message": "无效的日志ID",
        })
        return
    }
    
    // 删除日志
    err = h.systemService.DeleteLog(uint(id))
    if err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            c.JSON(404, gin.H{
                "success": false,
                "message": "日志不存在",
            })
            return
        }
        
        c.JSON(500, gin.H{
            "success": false,
            "message": "删除日志失败",
        })
        return
    }
    
    c.JSON(200, gin.H{
        "success": true,
        "message": "日志删除成功",
    })
}
```

### 2. 批量日志删除 API

**路径**: `POST /api/v1/logs/batch-delete`

**请求体**:
```json
{
    "ids": [1, 2, 3, 4, 5]
}
```

**Go实现建议**:

```go
// BatchDeleteLogs 批量删除日志
func (h *SystemHandler) BatchDeleteLogs(c *gin.Context) {
    var req struct {
        IDs []uint `json:"ids" binding:"required"`
    }
    
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{
            "success": false,
            "message": "请求参数错误",
        })
        return
    }
    
    if len(req.IDs) == 0 {
        c.JSON(400, gin.H{
            "success": false,
            "message": "请提供要删除的日志ID列表",
        })
        return
    }
    
    // 限制批量删除数量
    if len(req.IDs) > 1000 {
        c.JSON(400, gin.H{
            "success": false,
            "message": "单次最多删除1000条日志",
        })
        return
    }
    
    // 批量删除日志
    deletedCount, err := h.systemService.BatchDeleteLogs(req.IDs)
    if err != nil {
        c.JSON(500, gin.H{
            "success": false,
            "message": "批量删除日志失败",
        })
        return
    }
    
    c.JSON(200, gin.H{
        "success": true,
        "data": gin.H{
            "deleted_count": deletedCount,
        },
        "message": "批量删除完成",
    })
}
```

### 3. Service层实现建议

**在 `internal/services/system_service.go` 中添加**:

```go
// DeleteLog 删除单条日志
func (s *SystemService) DeleteLog(id uint) error {
    result := s.db.Delete(&models.SystemLog{}, id)
    if result.Error != nil {
        return result.Error
    }
    
    if result.RowsAffected == 0 {
        return gorm.ErrRecordNotFound
    }
    
    return nil
}

// BatchDeleteLogs 批量删除日志
func (s *SystemService) BatchDeleteLogs(ids []uint) (int64, error) {
    result := s.db.Delete(&models.SystemLog{}, ids)
    if result.Error != nil {
        return 0, result.Error
    }
    
    return result.RowsAffected, nil
}
```

### 4. 路由注册

**在路由文件中添加** (通常在 `internal/app/routes.go` 或类似文件):

```go
// 日志管理路由
logRoutes := v1.Group("/logs")
{
    logRoutes.GET("", systemHandler.GetLogs)           // 现有的获取日志列表
    logRoutes.POST("/cleanup", systemHandler.CleanupLogs) // 现有的清理日志
    logRoutes.DELETE("/:id", systemHandler.DeleteLog)     // 新增：删除单条日志
    logRoutes.POST("/batch-delete", systemHandler.BatchDeleteLogs) // 新增：批量删除
}
```

## 安全考虑

### 1. 权限验证
```go
// 在handler中添加权限检查
func (h *SystemHandler) DeleteLog(c *gin.Context) {
    // 检查用户是否有删除日志的权限
    if !h.permissionService.HasPermission(c, "logs", "delete") {
        c.JSON(403, gin.H{
            "success": false,
            "message": "没有删除日志的权限",
        })
        return
    }
    
    // ... 其余删除逻辑
}
```

### 2. 操作审计
```go
// 记录删除操作
func (s *SystemService) DeleteLog(id uint) error {
    // 先获取要删除的日志信息（用于审计）
    var log models.SystemLog
    if err := s.db.First(&log, id).Error; err != nil {
        return err
    }
    
    // 执行删除
    result := s.db.Delete(&models.SystemLog{}, id)
    if result.Error != nil {
        return result.Error
    }
    
    // 记录删除操作到审计日志
    s.LogOperation("delete_log", map[string]interface{}{
        "deleted_log_id": id,
        "deleted_log_level": log.Level,
        "deleted_log_category": log.Category,
    })
    
    return nil
}
```

### 3. 软删除选项
如果需要支持软删除（推荐用于重要日志）：

```go
// 在模型中添加软删除字段
type SystemLog struct {
    ID        uint           `gorm:"primarykey"`
    // ... 其他字段
    DeletedAt gorm.DeletedAt `gorm:"index"`
}

// 软删除实现
func (s *SystemService) SoftDeleteLog(id uint) error {
    result := s.db.Delete(&models.SystemLog{}, id) // GORM会自动使用软删除
    return result.Error
}

// 硬删除实现（如果需要）
func (s *SystemService) HardDeleteLog(id uint) error {
    result := s.db.Unscoped().Delete(&models.SystemLog{}, id)
    return result.Error
}
```

## 测试建议

### 1. 单元测试
```go
func TestDeleteLog(t *testing.T) {
    // 创建测试日志
    log := &models.SystemLog{
        Level:    "info",
        Category: "test",
        Message:  "test message",
    }
    db.Create(log)
    
    // 测试删除
    err := systemService.DeleteLog(log.ID)
    assert.NoError(t, err)
    
    // 验证删除结果
    var count int64
    db.Model(&models.SystemLog{}).Where("id = ?", log.ID).Count(&count)
    assert.Equal(t, int64(0), count)
}
```

### 2. API测试
```bash
# 测试单条删除
curl -X DELETE "http://localhost:8080/api/v1/logs/123" \
  -H "Authorization: Bearer $TOKEN"

# 测试批量删除
curl -X POST "http://localhost:8080/api/v1/logs/batch-delete" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"ids": [1, 2, 3]}'
```

## 实现优先级

1. **高优先级**: 单条日志删除 API (`DELETE /api/v1/logs/{id}`)
2. **中优先级**: 批量删除 API (`POST /api/v1/logs/batch-delete`)
3. **低优先级**: 权限验证和操作审计

## 前端兼容性

当前前端代码已经实现了：
- ✅ API不存在时的友好错误提示
- ✅ 自动降级到逐个删除（批量删除API不可用时）
- ✅ 加载状态和错误处理
- ✅ 用户确认对话框

一旦后端API实现完成，前端功能将立即可用，无需额外修改。