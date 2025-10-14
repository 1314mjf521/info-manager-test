package services

import (
	"testing"

	"info-management-system/internal/models"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// RecordTypeServiceTestSuite 记录类型服务测试套件
type RecordTypeServiceTestSuite struct {
	suite.Suite
	db                *gorm.DB
	recordTypeService *RecordTypeService
}

// SetupSuite 设置测试套件
func (suite *RecordTypeServiceTestSuite) SetupSuite() {
	// 创建内存数据库
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	suite.Require().NoError(err)

	// 自动迁移
	err = db.AutoMigrate(&models.RecordType{}, &models.Record{})
	suite.Require().NoError(err)

	suite.db = db
	suite.recordTypeService = NewRecordTypeService(db)
}

// TearDownSuite 清理测试套件
func (suite *RecordTypeServiceTestSuite) TearDownSuite() {
	sqlDB, _ := suite.db.DB()
	sqlDB.Close()
}

// TestCreateRecordType 测试创建记录类型
func (suite *RecordTypeServiceTestSuite) TestCreateRecordType() {
	req := &CreateRecordTypeRequest{
		Name:        "daily_report",
		DisplayName: "日报",
		Schema: map[string]interface{}{
			"fields": []interface{}{
				map[string]interface{}{
					"name":     "summary",
					"type":     "string",
					"required": true,
				},
				map[string]interface{}{
					"name":     "tasks",
					"type":     "array",
					"required": false,
				},
			},
		},
	}

	recordType, err := suite.recordTypeService.CreateRecordType(req)

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), recordType)
	assert.Equal(suite.T(), req.Name, recordType.Name)
	assert.Equal(suite.T(), req.DisplayName, recordType.DisplayName)
	assert.Equal(suite.T(), "records_daily_report", recordType.TableName)
	assert.True(suite.T(), recordType.IsActive)
	assert.Equal(suite.T(), int64(0), recordType.RecordCount)
}

// TestCreateDuplicateRecordType 测试创建重复的记录类型
func (suite *RecordTypeServiceTestSuite) TestCreateDuplicateRecordType() {
	// 先创建一个记录类型
	req1 := &CreateRecordTypeRequest{
		Name:        "test_type",
		DisplayName: "测试类型",
		Schema: map[string]interface{}{
			"fields": []interface{}{},
		},
	}

	_, err := suite.recordTypeService.CreateRecordType(req1)
	assert.NoError(suite.T(), err)

	// 尝试创建同名的记录类型
	req2 := &CreateRecordTypeRequest{
		Name:        "test_type",
		DisplayName: "重复测试类型",
		Schema: map[string]interface{}{
			"fields": []interface{}{},
		},
	}

	_, err = suite.recordTypeService.CreateRecordType(req2)
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "记录类型名称已存在")
}

// TestGetAllRecordTypes 测试获取所有记录类型
func (suite *RecordTypeServiceTestSuite) TestGetAllRecordTypes() {
	// 创建几个测试记录类型
	types := []CreateRecordTypeRequest{
		{
			Name:        "type1",
			DisplayName: "类型1",
			Schema:      map[string]interface{}{"fields": []interface{}{}},
		},
		{
			Name:        "type2",
			DisplayName: "类型2",
			Schema:      map[string]interface{}{"fields": []interface{}{}},
		},
	}

	for _, typeReq := range types {
		_, err := suite.recordTypeService.CreateRecordType(&typeReq)
		suite.Require().NoError(err)
	}

	recordTypes, err := suite.recordTypeService.GetAllRecordTypes()

	assert.NoError(suite.T(), err)
	assert.GreaterOrEqual(suite.T(), len(recordTypes), 2)

	// 验证返回的记录类型包含我们创建的
	typeNames := make(map[string]bool)
	for _, rt := range recordTypes {
		typeNames[rt.Name] = true
	}
	assert.True(suite.T(), typeNames["type1"])
	assert.True(suite.T(), typeNames["type2"])
}

// TestGetRecordTypeByID 测试根据ID获取记录类型
func (suite *RecordTypeServiceTestSuite) TestGetRecordTypeByID() {
	// 创建测试记录类型
	req := &CreateRecordTypeRequest{
		Name:        "get_by_id_test",
		DisplayName: "根据ID获取测试",
		Schema:      map[string]interface{}{"fields": []interface{}{}},
	}

	createdType, err := suite.recordTypeService.CreateRecordType(req)
	suite.Require().NoError(err)

	// 根据ID获取
	recordType, err := suite.recordTypeService.GetRecordTypeByID(createdType.ID)

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), recordType)
	assert.Equal(suite.T(), createdType.ID, recordType.ID)
	assert.Equal(suite.T(), createdType.Name, recordType.Name)
	assert.Equal(suite.T(), createdType.DisplayName, recordType.DisplayName)
}

// TestGetRecordTypeByIDNotFound 测试获取不存在的记录类型
func (suite *RecordTypeServiceTestSuite) TestGetRecordTypeByIDNotFound() {
	_, err := suite.recordTypeService.GetRecordTypeByID(99999)

	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "记录类型不存在")
}

// TestGetRecordTypeByName 测试根据名称获取记录类型
func (suite *RecordTypeServiceTestSuite) TestGetRecordTypeByName() {
	// 创建测试记录类型
	req := &CreateRecordTypeRequest{
		Name:        "get_by_name_test",
		DisplayName: "根据名称获取测试",
		Schema:      map[string]interface{}{"fields": []interface{}{}},
	}

	_, err := suite.recordTypeService.CreateRecordType(req)
	suite.Require().NoError(err)

	// 根据名称获取
	recordType, err := suite.recordTypeService.GetRecordTypeByName("get_by_name_test")

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), recordType)
	assert.Equal(suite.T(), "get_by_name_test", recordType.Name)
	assert.Equal(suite.T(), "根据名称获取测试", recordType.DisplayName)
}

// TestUpdateRecordType 测试更新记录类型
func (suite *RecordTypeServiceTestSuite) TestUpdateRecordType() {
	// 创建测试记录类型
	req := &CreateRecordTypeRequest{
		Name:        "update_test",
		DisplayName: "更新测试",
		Schema:      map[string]interface{}{"fields": []interface{}{}},
	}

	createdType, err := suite.recordTypeService.CreateRecordType(req)
	suite.Require().NoError(err)

	// 更新记录类型
	isActive := false
	updateReq := &UpdateRecordTypeRequest{
		DisplayName: "更新后的显示名称",
		Schema: map[string]interface{}{
			"fields": []interface{}{
				map[string]interface{}{
					"name": "new_field",
					"type": "string",
				},
			},
		},
		IsActive: &isActive,
	}

	updatedType, err := suite.recordTypeService.UpdateRecordType(createdType.ID, updateReq)

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), updatedType)
	assert.Equal(suite.T(), "更新后的显示名称", updatedType.DisplayName)
	assert.False(suite.T(), updatedType.IsActive)
	assert.Contains(suite.T(), updatedType.Schema, "fields")
}

// TestDeleteRecordType 测试删除记录类型
func (suite *RecordTypeServiceTestSuite) TestDeleteRecordType() {
	// 创建测试记录类型
	req := &CreateRecordTypeRequest{
		Name:        "delete_test",
		DisplayName: "删除测试",
		Schema:      map[string]interface{}{"fields": []interface{}{}},
	}

	createdType, err := suite.recordTypeService.CreateRecordType(req)
	suite.Require().NoError(err)

	// 删除记录类型
	err = suite.recordTypeService.DeleteRecordType(createdType.ID)

	assert.NoError(suite.T(), err)

	// 验证记录类型已被删除
	_, err = suite.recordTypeService.GetRecordTypeByID(createdType.ID)
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "记录类型不存在")
}

// TestDeleteRecordTypeWithRecords 测试删除有记录的记录类型
func (suite *RecordTypeServiceTestSuite) TestDeleteRecordTypeWithRecords() {
	// 创建测试记录类型
	req := &CreateRecordTypeRequest{
		Name:        "delete_with_records_test",
		DisplayName: "有记录的删除测试",
		Schema:      map[string]interface{}{"fields": []interface{}{}},
	}

	createdType, err := suite.recordTypeService.CreateRecordType(req)
	suite.Require().NoError(err)

	// 创建使用该类型的记录
	testRecord := &models.Record{
		Type:      createdType.Name,
		Title:     "测试记录",
		Content:   models.JSONB{"test": "data"},
		CreatedBy: 1,
		Version:   1,
	}
	err = suite.db.Create(testRecord).Error
	suite.Require().NoError(err)

	// 尝试删除记录类型
	err = suite.recordTypeService.DeleteRecordType(createdType.ID)

	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "该记录类型正在被")
	assert.Contains(suite.T(), err.Error(), "条记录使用，无法删除")
}

// TestValidateRecordData 测试记录数据验证
func (suite *RecordTypeServiceTestSuite) TestValidateRecordData() {
	// 创建测试记录类型
	req := &CreateRecordTypeRequest{
		Name:        "validation_test",
		DisplayName: "验证测试",
		Schema:      map[string]interface{}{"fields": []interface{}{}},
	}

	_, err := suite.recordTypeService.CreateRecordType(req)
	suite.Require().NoError(err)

	// 测试有效数据
	validData := map[string]interface{}{
		"field1": "value1",
		"field2": "value2",
	}

	err = suite.recordTypeService.ValidateRecordData("validation_test", validData)
	assert.NoError(suite.T(), err)

	// 测试空数据
	emptyData := map[string]interface{}{}
	err = suite.recordTypeService.ValidateRecordData("validation_test", emptyData)
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "记录内容不能为空")

	// 测试不存在的记录类型
	err = suite.recordTypeService.ValidateRecordData("nonexistent_type", validData)
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "记录类型不存在")
}

// TestValidateInactiveRecordType 测试验证已禁用的记录类型
func (suite *RecordTypeServiceTestSuite) TestValidateInactiveRecordType() {
	// 创建测试记录类型
	req := &CreateRecordTypeRequest{
		Name:        "inactive_test",
		DisplayName: "禁用测试",
		Schema:      map[string]interface{}{"fields": []interface{}{}},
	}

	createdType, err := suite.recordTypeService.CreateRecordType(req)
	suite.Require().NoError(err)

	// 禁用记录类型
	isActive := false
	updateReq := &UpdateRecordTypeRequest{
		IsActive: &isActive,
	}

	_, err = suite.recordTypeService.UpdateRecordType(createdType.ID, updateReq)
	suite.Require().NoError(err)

	// 测试验证禁用的记录类型
	testData := map[string]interface{}{
		"field1": "value1",
	}

	err = suite.recordTypeService.ValidateRecordData("inactive_test", testData)
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "记录类型已禁用")
}

// TestRecordTypeWithRecordCount 测试记录类型的记录数量统计
func (suite *RecordTypeServiceTestSuite) TestRecordTypeWithRecordCount() {
	// 创建测试记录类型
	req := &CreateRecordTypeRequest{
		Name:        "count_test",
		DisplayName: "计数测试",
		Schema:      map[string]interface{}{"fields": []interface{}{}},
	}

	createdType, err := suite.recordTypeService.CreateRecordType(req)
	suite.Require().NoError(err)

	// 初始记录数应为0
	recordType, err := suite.recordTypeService.GetRecordTypeByID(createdType.ID)
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), int64(0), recordType.RecordCount)

	// 创建几条记录
	for i := 0; i < 3; i++ {
		testRecord := &models.Record{
			Type:      createdType.Name,
			Title:     "测试记录",
			Content:   models.JSONB{"test": "data"},
			CreatedBy: 1,
			Version:   1,
		}
		err = suite.db.Create(testRecord).Error
		suite.Require().NoError(err)
	}

	// 重新获取记录类型，验证记录数量
	recordType, err = suite.recordTypeService.GetRecordTypeByID(createdType.ID)
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), int64(3), recordType.RecordCount)
}

// 运行测试套件
func TestRecordTypeServiceSuite(t *testing.T) {
	suite.Run(t, new(RecordTypeServiceTestSuite))
}