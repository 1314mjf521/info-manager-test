package services

import (
	"testing"
	"time"

	"info-management-system/internal/models"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// AuditServiceTestSuite 审计服务测试套件
type AuditServiceTestSuite struct {
	suite.Suite
	db           *gorm.DB
	auditService *AuditService
	testUser     *models.User
}

// SetupSuite 设置测试套件
func (suite *AuditServiceTestSuite) SetupSuite() {
	// 创建内存数据库
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	suite.Require().NoError(err)

	// 自动迁移
	err = db.AutoMigrate(&models.User{}, &models.AuditLog{})
	suite.Require().NoError(err)

	suite.db = db
	suite.auditService = NewAuditService(db)

	// 创建测试用户
	testUser := &models.User{
		Username:     "testuser",
		Email:        "test@example.com",
		PasswordHash: "hashedpassword",
	}
	err = db.Create(testUser).Error
	suite.Require().NoError(err)
	suite.testUser = testUser
}

// TearDownSuite 清理测试套件
func (suite *AuditServiceTestSuite) TearDownSuite() {
	sqlDB, _ := suite.db.DB()
	sqlDB.Close()
}

// TestCreateAuditLog 测试创建审计日志
func (suite *AuditServiceTestSuite) TestCreateAuditLog() {
	req := &AuditLogRequest{
		UserID:       suite.testUser.ID,
		Action:       "CREATE",
		ResourceType: "record",
		ResourceID:   1,
		NewValues: map[string]interface{}{
			"title":   "测试记录",
			"content": "测试内容",
		},
		IPAddress: "127.0.0.1",
		UserAgent: "test-agent",
	}

	err := suite.auditService.CreateAuditLog(req)

	assert.NoError(suite.T(), err)

	// 验证日志已创建
	var auditLog models.AuditLog
	err = suite.db.Where("user_id = ? AND action = ? AND resource_type = ?", 
		suite.testUser.ID, "CREATE", "record").First(&auditLog).Error
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), req.UserID, auditLog.UserID)
	assert.Equal(suite.T(), req.Action, auditLog.Action)
	assert.Equal(suite.T(), req.ResourceType, auditLog.ResourceType)
	assert.Equal(suite.T(), req.ResourceID, auditLog.ResourceID)
	assert.Equal(suite.T(), req.IPAddress, auditLog.IPAddress)
	assert.Equal(suite.T(), req.UserAgent, auditLog.UserAgent)
}

// TestGetAuditLogs 测试获取审计日志列表
func (suite *AuditServiceTestSuite) TestGetAuditLogs() {
	// 创建几条测试审计日志
	logs := []AuditLogRequest{
		{
			UserID:       suite.testUser.ID,
			Action:       "CREATE",
			ResourceType: "record",
			ResourceID:   1,
			IPAddress:    "127.0.0.1",
			UserAgent:    "test-agent",
		},
		{
			UserID:       suite.testUser.ID,
			Action:       "UPDATE",
			ResourceType: "record",
			ResourceID:   1,
			IPAddress:    "127.0.0.1",
			UserAgent:    "test-agent",
		},
		{
			UserID:       suite.testUser.ID,
			Action:       "DELETE",
			ResourceType: "record",
			ResourceID:   2,
			IPAddress:    "127.0.0.1",
			UserAgent:    "test-agent",
		},
	}

	for _, logReq := range logs {
		err := suite.auditService.CreateAuditLog(&logReq)
		suite.Require().NoError(err)
	}

	query := &AuditLogQuery{
		Page:     1,
		PageSize: 10,
	}

	result, err := suite.auditService.GetAuditLogs(query)

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.GreaterOrEqual(suite.T(), len(result.Logs), 3)
	assert.GreaterOrEqual(suite.T(), result.Total, int64(3))
	assert.Equal(suite.T(), 1, result.Page)
	assert.Equal(suite.T(), 10, result.PageSize)
}

// TestGetAuditLogsWithFilters 测试带过滤条件的审计日志查询
func (suite *AuditServiceTestSuite) TestGetAuditLogsWithFilters() {
	// 创建测试审计日志
	req := &AuditLogRequest{
		UserID:       suite.testUser.ID,
		Action:       "CREATE",
		ResourceType: "record",
		ResourceID:   100,
		IPAddress:    "127.0.0.1",
		UserAgent:    "test-agent",
	}
	err := suite.auditService.CreateAuditLog(req)
	suite.Require().NoError(err)

	// 按用户ID过滤
	query := &AuditLogQuery{
		UserID:   suite.testUser.ID,
		Page:     1,
		PageSize: 10,
	}

	result, err := suite.auditService.GetAuditLogs(query)
	assert.NoError(suite.T(), err)
	assert.Greater(suite.T(), len(result.Logs), 0)
	for _, log := range result.Logs {
		assert.Equal(suite.T(), suite.testUser.ID, log.UserID)
	}

	// 按操作类型过滤
	query.Action = "CREATE"
	result, err = suite.auditService.GetAuditLogs(query)
	assert.NoError(suite.T(), err)
	assert.Greater(suite.T(), len(result.Logs), 0)
	for _, log := range result.Logs {
		assert.Equal(suite.T(), "CREATE", log.Action)
	}

	// 按资源类型过滤
	query.ResourceType = "record"
	result, err = suite.auditService.GetAuditLogs(query)
	assert.NoError(suite.T(), err)
	assert.Greater(suite.T(), len(result.Logs), 0)
	for _, log := range result.Logs {
		assert.Equal(suite.T(), "record", log.ResourceType)
	}

	// 按资源ID过滤
	query.ResourceID = 100
	result, err = suite.auditService.GetAuditLogs(query)
	assert.NoError(suite.T(), err)
	assert.Greater(suite.T(), len(result.Logs), 0)
	for _, log := range result.Logs {
		assert.Equal(suite.T(), uint(100), log.ResourceID)
	}
}

// TestGetAuditLogsWithDateRange 测试日期范围过滤
func (suite *AuditServiceTestSuite) TestGetAuditLogsWithDateRange() {
	// 创建测试审计日志
	req := &AuditLogRequest{
		UserID:       suite.testUser.ID,
		Action:       "CREATE",
		ResourceType: "record",
		ResourceID:   200,
		IPAddress:    "127.0.0.1",
		UserAgent:    "test-agent",
	}
	err := suite.auditService.CreateAuditLog(req)
	suite.Require().NoError(err)

	today := time.Now().Format("2006-01-02")
	query := &AuditLogQuery{
		StartDate: today,
		EndDate:   today,
		Page:      1,
		PageSize:  10,
	}

	result, err := suite.auditService.GetAuditLogs(query)
	assert.NoError(suite.T(), err)
	assert.Greater(suite.T(), len(result.Logs), 0)
}

// TestGetResourceAuditLogs 测试获取特定资源的审计日志
func (suite *AuditServiceTestSuite) TestGetResourceAuditLogs() {
	resourceID := uint(300)

	// 创建针对特定资源的审计日志
	actions := []string{"CREATE", "UPDATE", "DELETE"}
	for _, action := range actions {
		req := &AuditLogRequest{
			UserID:       suite.testUser.ID,
			Action:       action,
			ResourceType: "record",
			ResourceID:   resourceID,
			IPAddress:    "127.0.0.1",
			UserAgent:    "test-agent",
		}
		err := suite.auditService.CreateAuditLog(req)
		suite.Require().NoError(err)
	}

	logs, err := suite.auditService.GetResourceAuditLogs("record", resourceID)

	assert.NoError(suite.T(), err)
	assert.Len(suite.T(), logs, 3)
	for _, log := range logs {
		assert.Equal(suite.T(), "record", log.ResourceType)
		assert.Equal(suite.T(), resourceID, log.ResourceID)
	}
}

// TestGetUserAuditLogs 测试获取用户的审计日志
func (suite *AuditServiceTestSuite) TestGetUserAuditLogs() {
	// 创建用户的审计日志
	for i := 0; i < 5; i++ {
		req := &AuditLogRequest{
			UserID:       suite.testUser.ID,
			Action:       "CREATE",
			ResourceType: "record",
			ResourceID:   uint(400 + i),
			IPAddress:    "127.0.0.1",
			UserAgent:    "test-agent",
		}
		err := suite.auditService.CreateAuditLog(req)
		suite.Require().NoError(err)
	}

	// 获取用户的审计日志（限制3条）
	logs, err := suite.auditService.GetUserAuditLogs(suite.testUser.ID, 3)

	assert.NoError(suite.T(), err)
	assert.LessOrEqual(suite.T(), len(logs), 3)
	for _, log := range logs {
		assert.Equal(suite.T(), suite.testUser.ID, log.UserID)
	}

	// 获取用户的所有审计日志
	allLogs, err := suite.auditService.GetUserAuditLogs(suite.testUser.ID, 0)
	assert.NoError(suite.T(), err)
	assert.GreaterOrEqual(suite.T(), len(allLogs), 5)
}

// TestLogRecordOperation 测试记录操作的审计日志
func (suite *AuditServiceTestSuite) TestLogRecordOperation() {
	oldRecord := &models.Record{
		ID:      1,
		Type:    "test_type",
		Title:   "旧标题",
		Content: models.JSONB{"old": "content"},
		Tags:    []string{"old"},
		Version: 1,
	}

	newRecord := &models.Record{
		ID:      1,
		Type:    "test_type",
		Title:   "新标题",
		Content: models.JSONB{"new": "content"},
		Tags:    []string{"new"},
		Version: 2,
	}

	err := suite.auditService.LogRecordOperation(
		suite.testUser.ID, "UPDATE", 1, oldRecord, newRecord, "127.0.0.1", "test-agent")

	assert.NoError(suite.T(), err)

	// 验证审计日志
	var auditLog models.AuditLog
	err = suite.db.Where("user_id = ? AND action = ? AND resource_id = ?", 
		suite.testUser.ID, "UPDATE", 1).First(&auditLog).Error
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), "record", auditLog.ResourceType)
	assert.Contains(suite.T(), auditLog.OldValues, "title")
	assert.Contains(suite.T(), auditLog.NewValues, "title")
}

// TestGetAuditStatistics 测试获取审计统计信息
func (suite *AuditServiceTestSuite) TestGetAuditStatistics() {
	// 创建不同类型的审计日志
	actions := []string{"CREATE", "UPDATE", "DELETE", "CREATE", "UPDATE"}
	resourceTypes := []string{"record", "record", "record", "user", "user"}

	for i, action := range actions {
		req := &AuditLogRequest{
			UserID:       suite.testUser.ID,
			Action:       action,
			ResourceType: resourceTypes[i],
			ResourceID:   uint(500 + i),
			IPAddress:    "127.0.0.1",
			UserAgent:    "test-agent",
		}
		err := suite.auditService.CreateAuditLog(req)
		suite.Require().NoError(err)
	}

	statistics, err := suite.auditService.GetAuditStatistics(30)

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), statistics)
	assert.Contains(suite.T(), statistics, "total_operations")
	assert.Contains(suite.T(), statistics, "action_stats")
	assert.Contains(suite.T(), statistics, "resource_stats")
	assert.Contains(suite.T(), statistics, "user_stats")
	assert.Contains(suite.T(), statistics, "period_days")

	totalOps := statistics["total_operations"].(int64)
	assert.GreaterOrEqual(suite.T(), totalOps, int64(5))
}

// TestCleanupOldAuditLogs 测试清理旧的审计日志
func (suite *AuditServiceTestSuite) TestCleanupOldAuditLogs() {
	// 创建一些审计日志
	for i := 0; i < 3; i++ {
		req := &AuditLogRequest{
			UserID:       suite.testUser.ID,
			Action:       "CREATE",
			ResourceType: "record",
			ResourceID:   uint(600 + i),
			IPAddress:    "127.0.0.1",
			UserAgent:    "test-agent",
		}
		err := suite.auditService.CreateAuditLog(req)
		suite.Require().NoError(err)
	}

	// 获取清理前的日志数量
	var countBefore int64
	suite.db.Model(&models.AuditLog{}).Count(&countBefore)

	// 清理1天前的日志（应该不会删除任何日志，因为都是刚创建的）
	deletedCount, err := suite.auditService.CleanupOldAuditLogs(1)

	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), int64(0), deletedCount)

	// 验证日志数量没有变化
	var countAfter int64
	suite.db.Model(&models.AuditLog{}).Count(&countAfter)
	assert.Equal(suite.T(), countBefore, countAfter)
}

// TestAuditLogPagination 测试审计日志分页
func (suite *AuditServiceTestSuite) TestAuditLogPagination() {
	// 创建多条审计日志
	for i := 0; i < 25; i++ {
		req := &AuditLogRequest{
			UserID:       suite.testUser.ID,
			Action:       "CREATE",
			ResourceType: "record",
			ResourceID:   uint(700 + i),
			IPAddress:    "127.0.0.1",
			UserAgent:    "test-agent",
		}
		err := suite.auditService.CreateAuditLog(req)
		suite.Require().NoError(err)
	}

	// 测试第一页
	query := &AuditLogQuery{
		Page:     1,
		PageSize: 10,
	}

	result, err := suite.auditService.GetAuditLogs(query)
	assert.NoError(suite.T(), err)
	assert.LessOrEqual(suite.T(), len(result.Logs), 10)
	assert.Equal(suite.T(), 1, result.Page)
	assert.Equal(suite.T(), 10, result.PageSize)
	assert.Greater(suite.T(), result.TotalPages, 1)

	// 测试第二页
	query.Page = 2
	result, err = suite.auditService.GetAuditLogs(query)
	assert.NoError(suite.T(), err)
	assert.LessOrEqual(suite.T(), len(result.Logs), 10)
	assert.Equal(suite.T(), 2, result.Page)
}

// 运行测试套件
func TestAuditServiceSuite(t *testing.T) {
	suite.Run(t, new(AuditServiceTestSuite))
}