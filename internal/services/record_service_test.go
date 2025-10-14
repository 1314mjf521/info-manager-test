package services

import (
	"testing"

	"info-management-system/internal/models"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// RecordServiceTestSuite 记录服务测试套件
type RecordServiceTestSuite struct {
	suite.Suite
	db                *gorm.DB
	recordService     *RecordService
	recordTypeService *RecordTypeService
	auditService      *AuditService
	testUser          *models.User
	testRecordType    *models.RecordType
}

// SetupSuite 设置测试套件
func (suite *RecordServiceTestSuite) SetupSuite() {
	// 创建内存数据库
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	suite.Require().NoError(err)

	// 自动迁移
	err = db.AutoMigrate(
		&models.User{},
		&models.Role{},
		&models.Permission{},
		&models.RecordType{},
		&models.Record{},
		&models.AuditLog{},
	)
	suite.Require().NoError(err)

	suite.db = db

	// 创建服务实例
	suite.auditService = NewAuditService(db)
	suite.recordTypeService = NewRecordTypeService(db)
	suite.recordService = NewRecordService(db, suite.recordTypeService, suite.auditService)

	// 创建测试用户
	testUser := &models.User{
		Username:     "testuser",
		Email:        "test@example.com",
		PasswordHash: "hashedpassword",
	}
	err = db.Create(testUser).Error
	suite.Require().NoError(err)
	suite.testUser = testUser

	// 创建测试记录类型
	testRecordType := &models.RecordType{
		Name:        "test_type",
		DisplayName: "测试类型",
		Schema: models.JSONB{
			"fields": []interface{}{
				map[string]interface{}{
					"name": "description",
					"type": "string",
				},
			},
		},
		TableName: "records_test_type",
		IsActive:  true,
	}
	err = db.Create(testRecordType).Error
	suite.Require().NoError(err)
	suite.testRecordType = testRecordType
}

// TearDownSuite 清理测试套件
func (suite *RecordServiceTestSuite) TearDownSuite() {
	sqlDB, _ := suite.db.DB()
	sqlDB.Close()
}

// TestCreateRecord 测试创建记录
func (suite *RecordServiceTestSuite) TestCreateRecord() {
	req := &CreateRecordRequest{
		Type:  "test_type",
		Title: "测试记录",
		Content: map[string]interface{}{
			"description": "这是一个测试记录",
		},
		Tags: []string{"test", "demo"},
	}

	record, err := suite.recordService.CreateRecord(req, suite.testUser.ID, "127.0.0.1", "test-agent")

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), record)
	assert.Equal(suite.T(), req.Type, record.Type)
	assert.Equal(suite.T(), req.Title, record.Title)
	assert.Equal(suite.T(), suite.testUser.ID, record.CreatedBy)
	assert.Equal(suite.T(), 1, record.Version)

	// 验证审计日志
	var auditLog models.AuditLog
	err = suite.db.Where("resource_type = ? AND resource_id = ? AND action = ?", "record", record.ID, "CREATE").First(&auditLog).Error
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), suite.testUser.ID, auditLog.UserID)
}

// TestGetRecords 测试获取记录列表
func (suite *RecordServiceTestSuite) TestGetRecords() {
	// 创建测试记录
	testRecord := &models.Record{
		Type:      "test_type",
		Title:     "测试记录",
		Content:   models.JSONB{"description": "测试内容"},
		Tags:      []string{"test"},
		CreatedBy: suite.testUser.ID,
		Version:   1,
	}
	err := suite.db.Create(testRecord).Error
	suite.Require().NoError(err)

	query := &RecordListQuery{
		Page:     1,
		PageSize: 20,
	}

	result, err := suite.recordService.GetRecords(query, suite.testUser.ID, true)

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Greater(suite.T(), len(result.Records), 0)
	assert.Greater(suite.T(), result.Total, int64(0))
}

// TestGetRecordByID 测试根据ID获取记录
func (suite *RecordServiceTestSuite) TestGetRecordByID() {
	// 创建测试记录
	testRecord := &models.Record{
		Type:      "test_type",
		Title:     "测试记录",
		Content:   models.JSONB{"description": "测试内容"},
		Tags:      []string{"test"},
		CreatedBy: suite.testUser.ID,
		Version:   1,
	}
	err := suite.db.Create(testRecord).Error
	suite.Require().NoError(err)

	record, err := suite.recordService.GetRecordByID(testRecord.ID, suite.testUser.ID, true)

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), record)
	assert.Equal(suite.T(), testRecord.ID, record.ID)
	assert.Equal(suite.T(), testRecord.Title, record.Title)
}

// TestUpdateRecord 测试更新记录
func (suite *RecordServiceTestSuite) TestUpdateRecord() {
	// 创建测试记录
	testRecord := &models.Record{
		Type:      "test_type",
		Title:     "原始标题",
		Content:   models.JSONB{"description": "原始内容"},
		Tags:      []string{"original"},
		CreatedBy: suite.testUser.ID,
		Version:   1,
	}
	err := suite.db.Create(testRecord).Error
	suite.Require().NoError(err)

	req := &UpdateRecordRequest{
		Title: "更新后的标题",
		Content: map[string]interface{}{
			"description": "更新后的内容",
		},
		Tags: []string{"updated"},
	}

	record, err := suite.recordService.UpdateRecord(testRecord.ID, req, suite.testUser.ID, true, "127.0.0.1", "test-agent")

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), record)
	assert.Equal(suite.T(), req.Title, record.Title)
	assert.Equal(suite.T(), 2, record.Version) // 版本应该增加

	// 验证审计日志
	var auditLog models.AuditLog
	err = suite.db.Where("resource_type = ? AND resource_id = ? AND action = ?", "record", record.ID, "UPDATE").First(&auditLog).Error
	assert.NoError(suite.T(), err)
}

// TestDeleteRecord 测试删除记录
func (suite *RecordServiceTestSuite) TestDeleteRecord() {
	// 创建测试记录
	testRecord := &models.Record{
		Type:      "test_type",
		Title:     "待删除记录",
		Content:   models.JSONB{"description": "待删除内容"},
		Tags:      []string{"delete"},
		CreatedBy: suite.testUser.ID,
		Version:   1,
	}
	err := suite.db.Create(testRecord).Error
	suite.Require().NoError(err)

	err = suite.recordService.DeleteRecord(testRecord.ID, suite.testUser.ID, true, "127.0.0.1", "test-agent")

	assert.NoError(suite.T(), err)

	// 验证记录已被软删除
	var deletedRecord models.Record
	err = suite.db.Unscoped().First(&deletedRecord, testRecord.ID).Error
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), deletedRecord.DeletedAt)

	// 验证审计日志
	var auditLog models.AuditLog
	err = suite.db.Where("resource_type = ? AND resource_id = ? AND action = ?", "record", testRecord.ID, "DELETE").First(&auditLog).Error
	assert.NoError(suite.T(), err)
}

// TestBatchCreateRecords 测试批量创建记录
func (suite *RecordServiceTestSuite) TestBatchCreateRecords() {
	req := &BatchCreateRequest{
		Records: []CreateRecordRequest{
			{
				Type:  "test_type",
				Title: "批量记录1",
				Content: map[string]interface{}{
					"description": "批量内容1",
				},
				Tags: []string{"batch", "test1"},
			},
			{
				Type:  "test_type",
				Title: "批量记录2",
				Content: map[string]interface{}{
					"description": "批量内容2",
				},
				Tags: []string{"batch", "test2"},
			},
		},
	}

	records, err := suite.recordService.BatchCreateRecords(req, suite.testUser.ID, "127.0.0.1", "test-agent")

	assert.NoError(suite.T(), err)
	assert.Len(suite.T(), records, 2)
	assert.Equal(suite.T(), "批量记录1", records[0].Title)
	assert.Equal(suite.T(), "批量记录2", records[1].Title)

	// 验证审计日志
	var auditCount int64
	suite.db.Model(&models.AuditLog{}).Where("action = ?", "BATCH_CREATE").Count(&auditCount)
	assert.Equal(suite.T(), int64(2), auditCount)
}

// TestImportRecords 测试导入记录
func (suite *RecordServiceTestSuite) TestImportRecords() {
	req := &ImportRecordsRequest{
		Type: "test_type",
		Records: []map[string]interface{}{
			{
				"title":       "导入记录1",
				"description": "导入内容1",
				"tags":        []interface{}{"import", "test1"},
			},
			{
				"title":       "导入记录2",
				"description": "导入内容2",
				"tags":        []interface{}{"import", "test2"},
			},
		},
	}

	records, err := suite.recordService.ImportRecords(req, suite.testUser.ID, "127.0.0.1", "test-agent")

	assert.NoError(suite.T(), err)
	assert.Len(suite.T(), records, 2)
	assert.Equal(suite.T(), "导入记录1", records[0].Title)
	assert.Equal(suite.T(), "导入记录2", records[1].Title)

	// 验证审计日志
	var auditCount int64
	suite.db.Model(&models.AuditLog{}).Where("action = ?", "IMPORT").Count(&auditCount)
	assert.Equal(suite.T(), int64(2), auditCount)
}

// TestGetRecordsByType 测试根据类型获取记录
func (suite *RecordServiceTestSuite) TestGetRecordsByType() {
	// 创建不同类型的测试记录
	testRecord1 := &models.Record{
		Type:      "test_type",
		Title:     "类型测试记录1",
		Content:   models.JSONB{"description": "内容1"},
		CreatedBy: suite.testUser.ID,
		Version:   1,
	}
	testRecord2 := &models.Record{
		Type:      "other_type",
		Title:     "类型测试记录2",
		Content:   models.JSONB{"description": "内容2"},
		CreatedBy: suite.testUser.ID,
		Version:   1,
	}

	err := suite.db.Create(testRecord1).Error
	suite.Require().NoError(err)
	err = suite.db.Create(testRecord2).Error
	suite.Require().NoError(err)

	records, err := suite.recordService.GetRecordsByType("test_type", suite.testUser.ID, true)

	assert.NoError(suite.T(), err)
	assert.Greater(suite.T(), len(records), 0)
	
	// 验证所有返回的记录都是指定类型
	for _, record := range records {
		assert.Equal(suite.T(), "test_type", record.Type)
	}
}

// TestPermissionFiltering 测试权限过滤
func (suite *RecordServiceTestSuite) TestPermissionFiltering() {
	// 创建另一个用户
	otherUser := &models.User{
		Username:     "otheruser",
		Email:        "other@example.com",
		PasswordHash: "hashedpassword",
	}
	err := suite.db.Create(otherUser).Error
	suite.Require().NoError(err)

	// 创建属于其他用户的记录
	otherRecord := &models.Record{
		Type:      "test_type",
		Title:     "其他用户的记录",
		Content:   models.JSONB{"description": "其他用户的内容"},
		CreatedBy: otherUser.ID,
		Version:   1,
	}
	err = suite.db.Create(otherRecord).Error
	suite.Require().NoError(err)

	// 测试无权限用户无法访问其他用户的记录
	_, err = suite.recordService.GetRecordByID(otherRecord.ID, suite.testUser.ID, false)
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "记录不存在或无权访问")

	// 测试有全部权限的用户可以访问
	record, err := suite.recordService.GetRecordByID(otherRecord.ID, suite.testUser.ID, true)
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), record)
}

// TestRecordValidation 测试记录验证
func (suite *RecordServiceTestSuite) TestRecordValidation() {
	// 测试无效的记录类型
	req := &CreateRecordRequest{
		Type:  "invalid_type",
		Title: "无效类型记录",
		Content: map[string]interface{}{
			"description": "测试内容",
		},
	}

	_, err := suite.recordService.CreateRecord(req, suite.testUser.ID, "127.0.0.1", "test-agent")
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "记录类型不存在")
}

// TestRecordVersioning 测试记录版本控制
func (suite *RecordServiceTestSuite) TestRecordVersioning() {
	// 创建记录
	req := &CreateRecordRequest{
		Type:  "test_type",
		Title: "版本测试记录",
		Content: map[string]interface{}{
			"description": "初始版本",
		},
	}

	record, err := suite.recordService.CreateRecord(req, suite.testUser.ID, "127.0.0.1", "test-agent")
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), 1, record.Version)

	// 更新记录
	updateReq := &UpdateRecordRequest{
		Title: "更新版本测试记录",
		Content: map[string]interface{}{
			"description": "更新版本",
		},
	}

	updatedRecord, err := suite.recordService.UpdateRecord(record.ID, updateReq, suite.testUser.ID, true, "127.0.0.1", "test-agent")
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), 2, updatedRecord.Version)

	// 再次更新
	updateReq2 := &UpdateRecordRequest{
		Title: "再次更新版本测试记录",
	}

	updatedRecord2, err := suite.recordService.UpdateRecord(record.ID, updateReq2, suite.testUser.ID, true, "127.0.0.1", "test-agent")
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), 3, updatedRecord2.Version)
}

// 运行测试套件
func TestRecordServiceSuite(t *testing.T) {
	suite.Run(t, new(RecordServiceTestSuite))
}