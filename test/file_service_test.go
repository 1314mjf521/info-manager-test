package test

import (
	"bytes"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"testing"

	"info-management-system/internal/config"
	"info-management-system/internal/database"
	"info-management-system/internal/models"
	"info-management-system/internal/services"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// FileServiceTestSuite 文件服务测试套件
type FileServiceTestSuite struct {
	suite.Suite
	fileService  *services.FileService
	auditService *services.AuditService
	testUser     *models.User
	testFile     *multipart.FileHeader
}

// SetupSuite 设置测试套件
func (suite *FileServiceTestSuite) SetupSuite() {
	// 加载配置
	cfg, err := config.Load()
	suite.Require().NoError(err)

	// 连接数据库
	err = database.Connect(&cfg.Database)
	suite.Require().NoError(err)

	// 执行迁移
	err = database.Migrate(database.GetDB())
	suite.Require().NoError(err)

	// 初始化服务
	db := database.GetDB()
	suite.auditService = services.NewAuditService(db)
	suite.fileService = services.NewFileService(db, suite.auditService)

	// 创建测试用户
	suite.testUser = &models.User{
		Username: "filetest",
		Email:    "filetest@example.com",
		Password: "password123",
	}
	err = db.Create(suite.testUser).Error
	suite.Require().NoError(err)

	// 创建测试文件
	suite.createTestFile()
}

// TearDownSuite 清理测试套件
func (suite *FileServiceTestSuite) TearDownSuite() {
	db := database.GetDB()
	
	// 清理测试数据
	db.Where("uploaded_by = ?", suite.testUser.ID).Delete(&models.File{})
	db.Delete(suite.testUser)
	
	// 清理测试文件
	os.RemoveAll("./uploads")
	os.Remove("test_image.png")
}

// createTestFile 创建测试文件
func (suite *FileServiceTestSuite) createTestFile() {
	// 创建一个简单的测试图片文件
	testContent := []byte("fake image content for testing")
	
	// 创建临时文件
	tmpFile, err := os.CreateTemp("", "test_image_*.png")
	suite.Require().NoError(err)
	defer tmpFile.Close()

	_, err = tmpFile.Write(testContent)
	suite.Require().NoError(err)

	// 创建multipart.FileHeader
	var buf bytes.Buffer
	writer := multipart.NewWriter(&buf)
	
	part, err := writer.CreateFormFile("file", "test_image.png")
	suite.Require().NoError(err)
	
	_, err = part.Write(testContent)
	suite.Require().NoError(err)
	
	writer.Close()

	// 解析multipart数据
	reader := multipart.NewReader(&buf, writer.Boundary())
	form, err := reader.ReadForm(32 << 20) // 32MB
	suite.Require().NoError(err)

	files := form.File["file"]
	suite.Require().Len(files, 1)
	
	suite.testFile = files[0]
	suite.testFile.Header.Set("Content-Type", "image/png")
}

// TestUploadFile 测试文件上传
func (suite *FileServiceTestSuite) TestUploadFile() {
	req := &services.UploadRequest{
		File:        suite.testFile,
		Description: "Test file upload",
		Category:    "test",
	}

	result, err := suite.fileService.UploadFile(req, suite.testUser.ID, "127.0.0.1", "test-agent")
	
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Equal(suite.T(), "test_image.png", result.OriginalName)
	assert.Equal(suite.T(), "image/png", result.MimeType)
	assert.Equal(suite.T(), suite.testUser.ID, result.UploadedBy)
	assert.NotEmpty(suite.T(), result.Hash)
	assert.NotEmpty(suite.T(), result.DownloadURL)
}

// TestGetFiles 测试获取文件列表
func (suite *FileServiceTestSuite) TestGetFiles() {
	// 先上传一个文件
	req := &services.UploadRequest{
		File:        suite.testFile,
		Description: "Test file for listing",
		Category:    "test",
	}

	uploadedFile, err := suite.fileService.UploadFile(req, suite.testUser.ID, "127.0.0.1", "test-agent")
	suite.Require().NoError(err)

	// 测试获取文件列表
	query := &services.FileListQuery{
		Page:     1,
		PageSize: 10,
	}

	result, err := suite.fileService.GetFiles(query, suite.testUser.ID, false)
	
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.GreaterOrEqual(suite.T(), result.Total, int64(1))
	assert.GreaterOrEqual(suite.T(), len(result.Files), 1)
	
	// 验证文件信息
	found := false
	for _, file := range result.Files {
		if file.ID == uploadedFile.ID {
			found = true
			assert.Equal(suite.T(), uploadedFile.OriginalName, file.OriginalName)
			assert.Equal(suite.T(), uploadedFile.MimeType, file.MimeType)
			break
		}
	}
	assert.True(suite.T(), found, "上传的文件应该在列表中")
}

// TestGetFileByID 测试根据ID获取文件
func (suite *FileServiceTestSuite) TestGetFileByID() {
	// 先上传一个文件
	req := &services.UploadRequest{
		File:        suite.testFile,
		Description: "Test file for get by ID",
		Category:    "test",
	}

	uploadedFile, err := suite.fileService.UploadFile(req, suite.testUser.ID, "127.0.0.1", "test-agent")
	suite.Require().NoError(err)

	// 测试获取文件信息
	result, err := suite.fileService.GetFileByID(uploadedFile.ID, suite.testUser.ID, false)
	
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Equal(suite.T(), uploadedFile.ID, result.ID)
	assert.Equal(suite.T(), uploadedFile.OriginalName, result.OriginalName)
	assert.Equal(suite.T(), uploadedFile.MimeType, result.MimeType)
}

// TestDeleteFile 测试删除文件
func (suite *FileServiceTestSuite) TestDeleteFile() {
	// 先上传一个文件
	req := &services.UploadRequest{
		File:        suite.testFile,
		Description: "Test file for deletion",
		Category:    "test",
	}

	uploadedFile, err := suite.fileService.UploadFile(req, suite.testUser.ID, "127.0.0.1", "test-agent")
	suite.Require().NoError(err)

	// 测试删除文件
	err = suite.fileService.DeleteFile(uploadedFile.ID, suite.testUser.ID, false, "127.0.0.1", "test-agent")
	assert.NoError(suite.T(), err)

	// 验证文件已被删除
	_, err = suite.fileService.GetFileByID(uploadedFile.ID, suite.testUser.ID, false)
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "文件不存在或无权访问")
}

// TestFilePermissions 测试文件权限
func (suite *FileServiceTestSuite) TestFilePermissions() {
	// 创建另一个用户
	otherUser := &models.User{
		Username: "otheruser",
		Email:    "other@example.com",
		Password: "password123",
	}
	db := database.GetDB()
	err := db.Create(otherUser).Error
	suite.Require().NoError(err)
	defer db.Delete(otherUser)

	// 用第一个用户上传文件
	req := &services.UploadRequest{
		File:        suite.testFile,
		Description: "Test file for permissions",
		Category:    "test",
	}

	uploadedFile, err := suite.fileService.UploadFile(req, suite.testUser.ID, "127.0.0.1", "test-agent")
	suite.Require().NoError(err)

	// 第二个用户尝试访问文件（无权限）
	_, err = suite.fileService.GetFileByID(uploadedFile.ID, otherUser.ID, false)
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "文件不存在或无权访问")

	// 第二个用户尝试删除文件（无权限）
	err = suite.fileService.DeleteFile(uploadedFile.ID, otherUser.ID, false, "127.0.0.1", "test-agent")
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "文件不存在或无权删除")

	// 管理员权限可以访问所有文件
	result, err := suite.fileService.GetFileByID(uploadedFile.ID, otherUser.ID, true)
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Equal(suite.T(), uploadedFile.ID, result.ID)
}

// TestFileValidation 测试文件验证
func (suite *FileServiceTestSuite) TestFileValidation() {
	// 测试不支持的文件类型
	invalidFile := suite.testFile
	invalidFile.Header.Set("Content-Type", "application/x-executable")

	req := &services.UploadRequest{
		File:        invalidFile,
		Description: "Invalid file type",
		Category:    "test",
	}

	_, err := suite.fileService.UploadFile(req, suite.testUser.ID, "127.0.0.1", "test-agent")
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "不支持的文件类型")
}

// TestFileSearch 测试文件搜索
func (suite *FileServiceTestSuite) TestFileSearch() {
	// 上传一个带特定名称的文件
	testFile := suite.testFile
	testFile.Filename = "searchable_test_file.png"

	req := &services.UploadRequest{
		File:        testFile,
		Description: "Searchable test file",
		Category:    "test",
	}

	uploadedFile, err := suite.fileService.UploadFile(req, suite.testUser.ID, "127.0.0.1", "test-agent")
	suite.Require().NoError(err)

	// 测试搜索
	query := &services.FileListQuery{
		Search:   "searchable",
		Page:     1,
		PageSize: 10,
	}

	result, err := suite.fileService.GetFiles(query, suite.testUser.ID, false)
	
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.GreaterOrEqual(suite.T(), result.Total, int64(1))
	
	// 验证搜索结果包含上传的文件
	found := false
	for _, file := range result.Files {
		if file.ID == uploadedFile.ID {
			found = true
			break
		}
	}
	assert.True(suite.T(), found, "搜索结果应该包含匹配的文件")
}

// 运行文件服务测试套件
func TestFileServiceTestSuite(t *testing.T) {
	suite.Run(t, new(FileServiceTestSuite))
}