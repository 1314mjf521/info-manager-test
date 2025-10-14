package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"strings"
	"time"
)

// OCRService OCR识别服务
type OCRService struct {
	apiKey    string
	apiURL    string
	timeout   time.Duration
	languages []string
}

// NewOCRService 创建OCR服务
func NewOCRService(apiKey, apiURL string) *OCRService {
	return &OCRService{
		apiKey:  apiKey,
		apiURL:  apiURL,
		timeout: 30 * time.Second,
		languages: []string{
			"zh-cn", // 中文简体
			"zh-tw", // 中文繁体
			"en",    // 英文
			"ja",    // 日文
			"ko",    // 韩文
		},
	}
}

// OCRRequest OCR识别请求
type OCRRequest struct {
	File     *multipart.FileHeader `form:"file" binding:"required"`
	Language string                `form:"language,default=auto"`
}

// OCRResponse OCR识别响应
type OCRResponse struct {
	Text       string             `json:"text"`
	Language   string             `json:"language"`
	Confidence float64            `json:"confidence"`
	Regions    []OCRRegion        `json:"regions"`
	ProcessTime int64             `json:"process_time"`
	Status     string             `json:"status"`
}

// OCRRegion OCR识别区域
type OCRRegion struct {
	Text       string      `json:"text"`
	Confidence float64     `json:"confidence"`
	BoundingBox BoundingBox `json:"bounding_box"`
}

// BoundingBox 边界框
type BoundingBox struct {
	X      int `json:"x"`
	Y      int `json:"y"`
	Width  int `json:"width"`
	Height int `json:"height"`
}

// RecognizeText 识别图片中的文字
func (s *OCRService) RecognizeText(req *OCRRequest, userID uint) (*OCRResponse, error) {
	startTime := time.Now()

	// 验证文件类型
	if !s.isImageFile(req.File.Header.Get("Content-Type")) {
		return nil, fmt.Errorf("不支持的图片格式: %s", req.File.Header.Get("Content-Type"))
	}

	// 验证文件大小 (限制5MB)
	if req.File.Size > 5*1024*1024 {
		return nil, fmt.Errorf("图片文件过大，最大支持5MB")
	}

	// 验证语言参数
	if req.Language != "auto" && !s.isSupportedLanguage(req.Language) {
		return nil, fmt.Errorf("不支持的语言: %s", req.Language)
	}

	// 如果没有配置OCR API，返回模拟结果
	if s.apiKey == "" || s.apiURL == "" {
		return s.mockOCRResponse(req.File.Filename, req.Language, startTime), nil
	}

	// 调用真实的OCR API
	return s.callOCRAPI(req, startTime)
}

// callOCRAPI 调用OCR API
func (s *OCRService) callOCRAPI(req *OCRRequest, startTime time.Time) (*OCRResponse, error) {
	// 打开上传的文件
	file, err := req.File.Open()
	if err != nil {
		return nil, fmt.Errorf("打开文件失败: %w", err)
	}
	defer file.Close()

	// 创建multipart请求
	var requestBody bytes.Buffer
	writer := multipart.NewWriter(&requestBody)

	// 添加文件
	part, err := writer.CreateFormFile("file", req.File.Filename)
	if err != nil {
		return nil, fmt.Errorf("创建文件字段失败: %w", err)
	}

	if _, err := io.Copy(part, file); err != nil {
		return nil, fmt.Errorf("复制文件内容失败: %w", err)
	}

	// 添加语言参数
	if err := writer.WriteField("language", req.Language); err != nil {
		return nil, fmt.Errorf("添加语言参数失败: %w", err)
	}

	writer.Close()

	// 创建HTTP请求
	httpReq, err := http.NewRequest("POST", s.apiURL, &requestBody)
	if err != nil {
		return nil, fmt.Errorf("创建HTTP请求失败: %w", err)
	}

	// 设置请求头
	httpReq.Header.Set("Content-Type", writer.FormDataContentType())
	httpReq.Header.Set("Authorization", "Bearer "+s.apiKey)

	// 发送请求
	client := &http.Client{Timeout: s.timeout}
	resp, err := client.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("OCR API请求失败: %w", err)
	}
	defer resp.Body.Close()

	// 读取响应
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("读取OCR响应失败: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("OCR API返回错误: %s", string(respBody))
	}

	// 解析响应
	var ocrResp OCRResponse
	if err := json.Unmarshal(respBody, &ocrResp); err != nil {
		return nil, fmt.Errorf("解析OCR响应失败: %w", err)
	}

	// 设置处理时间
	ocrResp.ProcessTime = time.Since(startTime).Milliseconds()
	ocrResp.Status = "success"

	return &ocrResp, nil
}

// mockOCRResponse 模拟OCR响应（用于演示和测试）
func (s *OCRService) mockOCRResponse(filename, language string, startTime time.Time) *OCRResponse {
	// 根据文件名生成模拟文本
	mockText := s.generateMockText(filename, language)
	
	return &OCRResponse{
		Text:       mockText,
		Language:   s.detectLanguage(language),
		Confidence: 0.95,
		Regions: []OCRRegion{
			{
				Text:       mockText,
				Confidence: 0.95,
				BoundingBox: BoundingBox{
					X:      10,
					Y:      10,
					Width:  200,
					Height: 50,
				},
			},
		},
		ProcessTime: time.Since(startTime).Milliseconds(),
		Status:      "success",
	}
}

// generateMockText 生成模拟文本
func (s *OCRService) generateMockText(filename, language string) string {
	switch language {
	case "zh-cn", "zh", "auto":
		return "这是一个OCR识别的示例文本。\n文件名: " + filename + "\n识别时间: " + time.Now().Format("2006-01-02 15:04:05")
	case "zh-tw":
		return "這是一個OCR識別的示例文本。\n文件名: " + filename + "\n識別時間: " + time.Now().Format("2006-01-02 15:04:05")
	case "en":
		return "This is a sample OCR recognition text.\nFilename: " + filename + "\nRecognition time: " + time.Now().Format("2006-01-02 15:04:05")
	case "ja":
		return "これはOCR認識のサンプルテキストです。\nファイル名: " + filename + "\n認識時間: " + time.Now().Format("2006-01-02 15:04:05")
	case "ko":
		return "이것은 OCR 인식 샘플 텍스트입니다.\n파일명: " + filename + "\n인식 시간: " + time.Now().Format("2006-01-02 15:04:05")
	default:
		return "OCR recognition sample text.\nFilename: " + filename + "\nRecognition time: " + time.Now().Format("2006-01-02 15:04:05")
	}
}

// detectLanguage 检测语言
func (s *OCRService) detectLanguage(language string) string {
	if language == "auto" {
		return "zh-cn" // 默认返回中文
	}
	return language
}

// isImageFile 检查是否为图片文件
func (s *OCRService) isImageFile(mimeType string) bool {
	imageTypes := []string{
		"image/jpeg",
		"image/jpg",
		"image/png",
		"image/gif",
		"image/bmp",
		"image/webp",
		"image/tiff",
	}

	for _, imageType := range imageTypes {
		if imageType == mimeType {
			return true
		}
	}
	return false
}

// isSupportedLanguage 检查是否为支持的语言
func (s *OCRService) isSupportedLanguage(language string) bool {
	for _, lang := range s.languages {
		if lang == language {
			return true
		}
	}
	return false
}

// GetSupportedLanguages 获取支持的语言列表
func (s *OCRService) GetSupportedLanguages() []string {
	return s.languages
}

// ValidateImage 验证图片文件
func (s *OCRService) ValidateImage(file *multipart.FileHeader) error {
	// 检查文件类型
	if !s.isImageFile(file.Header.Get("Content-Type")) {
		return fmt.Errorf("不支持的图片格式: %s", file.Header.Get("Content-Type"))
	}

	// 检查文件大小
	if file.Size > 5*1024*1024 {
		return fmt.Errorf("图片文件过大，最大支持5MB")
	}

	// 检查文件扩展名
	filename := strings.ToLower(file.Filename)
	validExtensions := []string{".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".tiff"}
	
	hasValidExtension := false
	for _, ext := range validExtensions {
		if strings.HasSuffix(filename, ext) {
			hasValidExtension = true
			break
		}
	}

	if !hasValidExtension {
		return fmt.Errorf("不支持的图片文件扩展名")
	}

	return nil
}