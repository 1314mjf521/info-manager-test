package test

import (
	"bytes"
	"mime/multipart"
	"testing"

	"info-management-system/internal/services"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// OCRServiceTestSuite OCR服务测试套件
type OCRServiceTestSuite struct {
	suite.Suite
	ocrService *services.OCRService
	testImage  *multipart.FileHeader
}

// SetupSuite 设置测试套件
func (suite *OCRServiceTestSuite) SetupSuite() {
	// 初始化OCR服务（使用模拟模式）
	suite.ocrService = services.NewOCRService("", "")

	// 创建测试图片文件
	suite.createTestImage()
}

// createTestImage 创建测试图片
func (suite *OCRServiceTestSuite) createTestImage() {
	// 创建一个模拟的图片内容
	imageContent := []byte("fake image content for OCR testing")
	
	// 创建multipart.FileHeader
	var buf bytes.Buffer
	writer := multipart.NewWriter(&buf)
	
	part, err := writer.CreateFormFile("file", "test_ocr_image.png")
	suite.Require().NoError(err)
	
	_, err = part.Write(imageContent)
	suite.Require().NoError(err)
	
	writer.Close()

	// 解析multipart数据
	reader := multipart.NewReader(&buf, writer.Boundary())
	form, err := reader.ReadForm(32 << 20) // 32MB
	suite.Require().NoError(err)

	files := form.File["file"]
	suite.Require().Len(files, 1)
	
	suite.testImage = files[0]
	suite.testImage.Header.Set("Content-Type", "image/png")
}

// TestRecognizeTextChinese 测试中文OCR识别
func (suite *OCRServiceTestSuite) TestRecognizeTextChinese() {
	req := &services.OCRRequest{
		File:     suite.testImage,
		Language: "zh-cn",
	}

	result, err := suite.ocrService.RecognizeText(req, 1)
	
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Equal(suite.T(), "success", result.Status)
	assert.Equal(suite.T(), "zh-cn", result.Language)
	assert.NotEmpty(suite.T(), result.Text)
	assert.Greater(suite.T(), result.Confidence, 0.0)
	assert.Greater(suite.T(), result.ProcessTime, int64(0))
	assert.Len(suite.T(), result.Regions, 1)
	
	// 验证识别的文本包含中文
	assert.Contains(suite.T(), result.Text, "OCR识别")
	assert.Contains(suite.T(), result.Text, suite.testImage.Filename)
}

// TestRecognizeTextEnglish 测试英文OCR识别
func (suite *OCRServiceTestSuite) TestRecognizeTextEnglish() {
	req := &services.OCRRequest{
		File:     suite.testImage,
		Language: "en",
	}

	result, err := suite.ocrService.RecognizeText(req, 1)
	
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Equal(suite.T(), "success", result.Status)
	assert.Equal(suite.T(), "en", result.Language)
	assert.NotEmpty(suite.T(), result.Text)
	assert.Greater(suite.T(), result.Confidence, 0.0)
	
	// 验证识别的文本包含英文
	assert.Contains(suite.T(), result.Text, "OCR recognition")
	assert.Contains(suite.T(), result.Text, suite.testImage.Filename)
}

// TestRecognizeTextAuto 测试自动语言检测
func (suite *OCRServiceTestSuite) TestRecognizeTextAuto() {
	req := &services.OCRRequest{
		File:     suite.testImage,
		Language: "auto",
	}

	result, err := suite.ocrService.RecognizeText(req, 1)
	
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Equal(suite.T(), "success", result.Status)
	assert.Equal(suite.T(), "zh-cn", result.Language) // 默认检测为中文
	assert.NotEmpty(suite.T(), result.Text)
}

// TestRecognizeTextJapanese 测试日文OCR识别
func (suite *OCRServiceTestSuite) TestRecognizeTextJapanese() {
	req := &services.OCRRequest{
		File:     suite.testImage,
		Language: "ja",
	}

	result, err := suite.ocrService.RecognizeText(req, 1)
	
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Equal(suite.T(), "success", result.Status)
	assert.Equal(suite.T(), "ja", result.Language)
	assert.NotEmpty(suite.T(), result.Text)
	
	// 验证识别的文本包含日文
	assert.Contains(suite.T(), result.Text, "OCR認識")
}

// TestRecognizeTextKorean 测试韩文OCR识别
func (suite *OCRServiceTestSuite) TestRecognizeTextKorean() {
	req := &services.OCRRequest{
		File:     suite.testImage,
		Language: "ko",
	}

	result, err := suite.ocrService.RecognizeText(req, 1)
	
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Equal(suite.T(), "success", result.Status)
	assert.Equal(suite.T(), "ko", result.Language)
	assert.NotEmpty(suite.T(), result.Text)
	
	// 验证识别的文本包含韩文
	assert.Contains(suite.T(), result.Text, "OCR 인식")
}

// TestInvalidFileType 测试无效文件类型
func (suite *OCRServiceTestSuite) TestInvalidFileType() {
	invalidFile := suite.testImage
	invalidFile.Header.Set("Content-Type", "text/plain")

	req := &services.OCRRequest{
		File:     invalidFile,
		Language: "zh-cn",
	}

	_, err := suite.ocrService.RecognizeText(req, 1)
	
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "不支持的图片格式")
}

// TestInvalidLanguage 测试无效语言
func (suite *OCRServiceTestSuite) TestInvalidLanguage() {
	req := &services.OCRRequest{
		File:     suite.testImage,
		Language: "invalid-lang",
	}

	_, err := suite.ocrService.RecognizeText(req, 1)
	
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "不支持的语言")
}

// TestFileSizeLimit 测试文件大小限制
func (suite *OCRServiceTestSuite) TestFileSizeLimit() {
	// 创建一个超大的文件
	largeFile := suite.testImage
	largeFile.Size = 6 * 1024 * 1024 // 6MB，超过5MB限制

	req := &services.OCRRequest{
		File:     largeFile,
		Language: "zh-cn",
	}

	_, err := suite.ocrService.RecognizeText(req, 1)
	
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "图片文件过大")
}

// TestGetSupportedLanguages 测试获取支持的语言列表
func (suite *OCRServiceTestSuite) TestGetSupportedLanguages() {
	languages := suite.ocrService.GetSupportedLanguages()
	
	assert.NotEmpty(suite.T(), languages)
	assert.Contains(suite.T(), languages, "zh-cn")
	assert.Contains(suite.T(), languages, "zh-tw")
	assert.Contains(suite.T(), languages, "en")
	assert.Contains(suite.T(), languages, "ja")
	assert.Contains(suite.T(), languages, "ko")
}

// TestValidateImage 测试图片验证
func (suite *OCRServiceTestSuite) TestValidateImage() {
	// 测试有效图片
	err := suite.ocrService.ValidateImage(suite.testImage)
	assert.NoError(suite.T(), err)

	// 测试无效文件类型
	invalidFile := suite.testImage
	invalidFile.Header.Set("Content-Type", "text/plain")
	err = suite.ocrService.ValidateImage(invalidFile)
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "不支持的图片格式")

	// 测试文件过大
	largeFile := suite.testImage
	largeFile.Size = 6 * 1024 * 1024 // 6MB
	largeFile.Header.Set("Content-Type", "image/png") // 重置为有效类型
	err = suite.ocrService.ValidateImage(largeFile)
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "图片文件过大")

	// 测试无效扩展名
	invalidExtFile := suite.testImage
	invalidExtFile.Filename = "test.txt"
	invalidExtFile.Header.Set("Content-Type", "image/png")
	invalidExtFile.Size = 1024 // 重置为有效大小
	err = suite.ocrService.ValidateImage(invalidExtFile)
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "不支持的图片文件扩展名")
}

// TestOCRRegions 测试OCR区域信息
func (suite *OCRServiceTestSuite) TestOCRRegions() {
	req := &services.OCRRequest{
		File:     suite.testImage,
		Language: "zh-cn",
	}

	result, err := suite.ocrService.RecognizeText(req, 1)
	
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	assert.Len(suite.T(), result.Regions, 1)
	
	region := result.Regions[0]
	assert.NotEmpty(suite.T(), region.Text)
	assert.Greater(suite.T(), region.Confidence, 0.0)
	assert.Greater(suite.T(), region.BoundingBox.Width, 0)
	assert.Greater(suite.T(), region.BoundingBox.Height, 0)
}

// 运行OCR服务测试套件
func TestOCRServiceTestSuite(t *testing.T) {
	suite.Run(t, new(OCRServiceTestSuite))
}