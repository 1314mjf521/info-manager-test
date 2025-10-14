package middleware

import (
	"net/http"
	"strconv"
	"strings"

	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// RecordPermissionMiddleware 记录权限中间件
func RecordPermissionMiddleware(permissionService *services.PermissionService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetUint("user_id")
		if userID == 0 {
			c.JSON(http.StatusUnauthorized, APIResponse{
				Success: false,
				Error: &APIError{
					Code:    "UNAUTHORIZED",
					Message: "用户未认证",
				},
			})
			c.Abort()
			return
		}

		// 检查用户是否有查看所有记录的权限
		hasAllRecordsPermission := false
		if permissionsResp, err := permissionService.GetUserPermissions(userID); err == nil {
			for _, perm := range permissionsResp.Permissions {
				if perm.Resource == "records" && perm.Action == "read" && perm.Scope == "all" {
					hasAllRecordsPermission = true
					break
				}
			}
		}

		// 检查用户是否有修改所有记录的权限
		hasModifyAllRecordsPermission := false
		if permissionsResp, err := permissionService.GetUserPermissions(userID); err == nil {
			for _, perm := range permissionsResp.Permissions {
				if perm.Resource == "records" && 
				   (perm.Action == "write" || perm.Action == "delete") && 
				   perm.Scope == "all" {
					hasModifyAllRecordsPermission = true
					break
				}
			}
		}

		// 将权限信息存储到上下文中
		c.Set("has_all_records_permission", hasAllRecordsPermission)
		c.Set("has_modify_all_records_permission", hasModifyAllRecordsPermission)

		// 对于特定的操作，进行额外的权限检查
		method := c.Request.Method
		path := c.Request.URL.Path

		// 检查创建记录权限
		if method == "POST" && (strings.HasSuffix(path, "/records") || 
			strings.Contains(path, "/records/batch") || 
			strings.Contains(path, "/records/import")) {
			
			if !hasCreateRecordPermission(permissionService, userID) {
				c.JSON(http.StatusForbidden, APIResponse{
					Success: false,
					Error: &APIError{
						Code:    "PERMISSION_DENIED",
						Message: "没有创建记录的权限",
					},
				})
				c.Abort()
				return
			}
		}

		// 检查修改/删除记录权限
		if (method == "PUT" || method == "DELETE") && strings.Contains(path, "/records/") {
			recordIDStr := extractRecordID(path)
			if recordIDStr != "" {
				recordID, err := strconv.ParseUint(recordIDStr, 10, 32)
				if err == nil {
					if !hasModifyRecordPermission(permissionService, userID, uint(recordID), hasModifyAllRecordsPermission) {
						c.JSON(http.StatusForbidden, APIResponse{
							Success: false,
							Error: &APIError{
								Code:    "PERMISSION_DENIED",
								Message: "没有修改此记录的权限",
							},
						})
						c.Abort()
						return
					}
				}
			}
		}

		c.Next()
	}
}

// hasCreateRecordPermission 检查用户是否有创建记录的权限
func hasCreateRecordPermission(permissionService *services.PermissionService, userID uint) bool {
	permissionsResp, err := permissionService.GetUserPermissions(userID)
	if err != nil {
		return false
	}

	for _, perm := range permissionsResp.Permissions {
		if perm.Resource == "records" && perm.Action == "write" {
			return true
		}
	}

	return false
}

// hasModifyRecordPermission 检查用户是否有修改特定记录的权限
func hasModifyRecordPermission(permissionService *services.PermissionService, userID, recordID uint, hasAllPermission bool) bool {
	// 如果有修改所有记录的权限，直接返回true
	if hasAllPermission {
		return true
	}

	// 检查是否有修改自己记录的权限
	permissionsResp, err := permissionService.GetUserPermissions(userID)
	if err != nil {
		return false
	}

	hasOwnPermission := false
	for _, perm := range permissionsResp.Permissions {
		if perm.Resource == "records" && 
		   (perm.Action == "write" || perm.Action == "delete") && 
		   perm.Scope == "own" {
			hasOwnPermission = true
			break
		}
	}

	if !hasOwnPermission {
		return false
	}

	// TODO: 这里需要检查记录是否属于当前用户
	// 由于需要查询数据库，这个检查应该在服务层进行
	// 这里暂时返回true，让服务层进行具体的权限检查
	return true
}

// extractRecordID 从路径中提取记录ID
func extractRecordID(path string) string {
	parts := strings.Split(path, "/")
	for i, part := range parts {
		if part == "records" && i+1 < len(parts) {
			return parts[i+1]
		}
	}
	return ""
}

// RecordOwnershipMiddleware 记录所有权中间件
func RecordOwnershipMiddleware(recordService *services.RecordService) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 只对PUT和DELETE请求进行所有权检查
		method := c.Request.Method
		if method != "PUT" && method != "DELETE" {
			c.Next()
			return
		}

		// 检查是否有修改所有记录的权限
		hasAllPermission := c.GetBool("has_modify_all_records_permission")
		if hasAllPermission {
			c.Next()
			return
		}

		// 提取记录ID
		recordIDStr := c.Param("id")
		if recordIDStr == "" {
			c.Next()
			return
		}

		recordID, err := strconv.ParseUint(recordIDStr, 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, APIResponse{
				Success: false,
				Error: &APIError{
					Code:    "INVALID_RECORD_ID",
					Message: "无效的记录ID",
				},
			})
			c.Abort()
			return
		}

		// 检查记录所有权
		userID := c.GetUint("user_id")
		ownerID, err := recordService.GetRecordOwner(uint(recordID))
		if err != nil {
			c.JSON(http.StatusNotFound, APIResponse{
				Success: false,
				Error: &APIError{
					Code:    "RECORD_NOT_FOUND",
					Message: "记录不存在",
				},
			})
			c.Abort()
			return
		}

		if ownerID != userID {
			c.JSON(http.StatusForbidden, APIResponse{
				Success: false,
				Error: &APIError{
					Code:    "PERMISSION_DENIED",
					Message: "没有修改此记录的权限",
				},
			})
			c.Abort()
			return
		}

		c.Next()
	}
}