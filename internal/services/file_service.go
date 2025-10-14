package services

import (
	"crypto/md5"
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"time"

	"info-management-system/internal/models"

	"gorm.io/gorm"
)

// FileService 文件服务
type FileService struct {
	db           *gorm.DB
	auditService *AuditService
	uploadPath   string
	maxFileSize  int64
	allowedTypes []string
}

// NewFileService 创建文件服务
func NewFileService(db *gorm.DB, auditService *AuditService) *FileService {
	return &FileService{
		db:           db,
		auditService: auditService,
		uploadPath:   "./uploads",
		maxFileSize:  10 * 1024 * 1024, // 10MB
		allowedTypes: []string{
			"image/jpeg", "image/png", "image/gif", "image/webp",
			"application/pdf", "text/plain", "text/csv",
			"application/vnd.ms-excel",
			"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
			"application/msword",
			"application/vnd.openxmlformats-officedocument.wordprocessingml.document",
		},
	}
}

// UploadRequest 文件上传请求
type UploadRequest struct {
	File        *multipart.FileHeader `form:"file" binding:"required"`
	Description string                `form:"description"`
	Category    string                `form:"category"`
}

// FileResponse 文件响应
type FileResponse struct {
	ID           uint   `json:"id"`
	Filename     string `json:"filename"`
	OriginalName string `json:"original_name"`
	MimeType     string `json:"mime_type"`
	Size         int64  `json:"size"`
	Hash         string `json:"hash"`
	UploadedBy   uint   `json:"uploaded_by"`
	Uploader     string `json:"uploader"`
	CreatedAt    string `json:"created_at"`
	UpdatedAt    string `json:"updated_at"`
	DownloadURL  string `json:"download_url"`
}

// FileListQuery 文件列表查询参数
type FileListQuery struct {
	Search   string `form:"search"`
	Category string `form:"category"`
	MimeType string `form:"mime_type"`
	Page     int    `form:"page,default=1"`
	PageSize int    `form:"page_size,default=20"`
	SortBy   string `form:"sort_by,default=created_at"`
	SortOrder string `form:"sort_order,default=desc"`
}

// FileListResponse 文件列表响应
type FileListResponse struct {
	Files      []FileResponse `json:"files"`
	Total      int64          `json:"total"`
	Page       int            `json:"page"`
	PageSize   int            `json:"page_size"`
	TotalPages int            `json:"total_pages"`
}

// UploadFile 上传文件
func (s *FileService) UploadFile(req *UploadRequest, userID uint, ipAddress, userAgent string) (*FileResponse, error) {
	// 验证文件大小
	if req.File.Size > s.maxFileSize {
		return nil, fmt.Errorf("文件大小超过限制 (%d MB)", s.maxFileSize/(1024*1024))
	}

	// 验证文件类型
	if !s.isAllowedType(req.File.Header.Get("Content-Type")) {
		return nil, fmt.Errorf("不支持的文件类型: %s", req.File.Header.Get("Content-Type"))
	}

	// 打开上传的文件
	src, err := req.File.Open()
	if err != nil {
		return nil, fmt.Errorf("打开文件失败: %w", err)
	}
	defer src.Close()

	// 计算文件哈希
	hash, err := s.calculateHash(src)
	if err != nil {
		return nil, fmt.Errorf("计算文件哈希失败: %w", err)
	}

	// 重置文件指针
	src.Seek(0, 0)

	// 检查文件是否已存在
	var existingFile models.File
	if err := s.db.Where("hash = ?", hash).First(&existingFile).Error; err == nil {
		// 文件已存在，返回现有文件信息
		return s.GetFileByID(existingFile.ID, userID, true)
	}

	// 确保上传目录存在
	if err := s.ensureUploadDir(); err != nil {
		return nil, fmt.Errorf("创建上传目录失败: %w", err)
	}

	// 生成唯一文件名
	filename := s.generateFilename(req.File.Filename)
	filePath := filepath.Join(s.uploadPath, filename)

	// 保存文件到磁盘
	dst, err := os.Create(filePath)
	if err != nil {
		return nil, fmt.Errorf("创建文件失败: %w", err)
	}
	defer dst.Close()

	if _, err := io.Copy(dst, src); err != nil {
		os.Remove(filePath) // 清理失败的文件
		return nil, fmt.Errorf("保存文件失败: %w", err)
	}

	// 保存文件信息到数据库
	file := models.File{
		Filename:     filename,
		OriginalName: req.File.Filename,
		MimeType:     req.File.Header.Get("Content-Type"),
		Size:         req.File.Size,
		Path:         filePath,
		Hash:         hash,
		UploadedBy:   userID,
	}

	if err := s.db.Create(&file).Error; err != nil {
		os.Remove(filePath) // 清理失败的文件
		return nil, fmt.Errorf("保存文件信息失败: %w", err)
	}

	// 记录审计日志
	if s.auditService != nil {
		s.auditService.LogFileOperation(userID, "UPLOAD", file.ID, nil, &file, ipAddress, userAgent)
	}

	// 返回文件信息
	return s.GetFileByID(file.ID, userID, true)
}

// GetFileByID 根据ID获取文件信息
func (s *FileService) GetFileByID(id uint, userID uint, hasAllPermission bool) (*FileResponse, error) {
	var file models.File
	query := s.db.Preload("Uploader")

	// 权限过滤：如果没有查看所有文件的权限，只能查看自己上传的文件
	if !hasAllPermission {
		query = query.Where("uploaded_by = ?", userID)
	}

	if err := query.First(&file, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("文件不存在或无权访问")
		}
		return nil, fmt.Errorf("获取文件失败: %w", err)
	}

	return &FileResponse{
		ID:           file.ID,
		Filename:     file.Filename,
		OriginalName: file.OriginalName,
		MimeType:     file.MimeType,
		Size:         file.Size,
		Hash:         file.Hash,
		UploadedBy:   file.UploadedBy,
		Uploader:     file.Uploader.Username,
		CreatedAt:    file.CreatedAt.Format("2006-01-02 15:04:05"),
		UpdatedAt:    file.UpdatedAt.Format("2006-01-02 15:04:05"),
		DownloadURL:  fmt.Sprintf("/api/v1/files/%d", file.ID),
	}, nil
}

// GetFiles 获取文件列表
func (s *FileService) GetFiles(query *FileListQuery, userID uint, hasAllPermission bool) (*FileListResponse, error) {
	db := s.db.Model(&models.File{}).Preload("Uploader")

	// 权限过滤：如果没有查看所有文件的权限，只能查看自己上传的文件
	if !hasAllPermission {
		db = db.Where("uploaded_by = ?", userID)
	}

	// 搜索过滤
	if query.Search != "" {
		searchTerm := "%" + query.Search + "%"
		db = db.Where("original_name LIKE ? OR filename LIKE ?", searchTerm, searchTerm)
	}

	// 类别过滤
	if query.Category != "" {
		db = db.Where("mime_type LIKE ?", query.Category+"%")
	}

	// MIME类型过滤
	if query.MimeType != "" {
		db = db.Where("mime_type = ?", query.MimeType)
	}

	// 计算总数
	var total int64
	if err := db.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取文件总数失败: %w", err)
	}

	// 排序
	orderBy := query.SortBy + " " + strings.ToUpper(query.SortOrder)
	db = db.Order(orderBy)

	// 分页
	offset := (query.Page - 1) * query.PageSize
	db = db.Offset(offset).Limit(query.PageSize)

	// 查询文件
	var files []models.File
	if err := db.Find(&files).Error; err != nil {
		return nil, fmt.Errorf("获取文件列表失败: %w", err)
	}

	// 转换响应
	fileResponses := make([]FileResponse, len(files))
	for i, file := range files {
		fileResponses[i] = FileResponse{
			ID:           file.ID,
			Filename:     file.Filename,
			OriginalName: file.OriginalName,
			MimeType:     file.MimeType,
			Size:         file.Size,
			Hash:         file.Hash,
			UploadedBy:   file.UploadedBy,
			Uploader:     file.Uploader.Username,
			CreatedAt:    file.CreatedAt.Format("2006-01-02 15:04:05"),
			UpdatedAt:    file.UpdatedAt.Format("2006-01-02 15:04:05"),
			DownloadURL:  fmt.Sprintf("/api/v1/files/%d", file.ID),
		}
	}

	// 计算总页数
	totalPages := int((total + int64(query.PageSize) - 1) / int64(query.PageSize))

	return &FileListResponse{
		Files:      fileResponses,
		Total:      total,
		Page:       query.Page,
		PageSize:   query.PageSize,
		TotalPages: totalPages,
	}, nil
}

// DeleteFile 删除文件
func (s *FileService) DeleteFile(id uint, userID uint, hasAllPermission bool, ipAddress, userAgent string) error {
	var file models.File
	query := s.db

	// 权限过滤
	if !hasAllPermission {
		query = query.Where("uploaded_by = ?", userID)
	}

	if err := query.First(&file, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("文件不存在或无权删除")
		}
		return fmt.Errorf("获取文件失败: %w", err)
	}

	// 删除数据库记录
	if err := s.db.Delete(&file).Error; err != nil {
		return fmt.Errorf("删除文件记录失败: %w", err)
	}

	// 删除物理文件
	if err := os.Remove(file.Path); err != nil && !os.IsNotExist(err) {
		// 记录警告但不返回错误，因为数据库记录已删除
		fmt.Printf("Warning: failed to delete physical file %s: %v\n", file.Path, err)
	}

	// 记录审计日志
	if s.auditService != nil {
		s.auditService.LogFileOperation(userID, "DELETE", file.ID, &file, nil, ipAddress, userAgent)
	}

	return nil
}

// GetFilePath 获取文件物理路径
func (s *FileService) GetFilePath(id uint, userID uint, hasAllPermission bool) (string, error) {
	var file models.File
	query := s.db

	// 权限过滤
	if !hasAllPermission {
		query = query.Where("uploaded_by = ?", userID)
	}

	if err := query.First(&file, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return "", fmt.Errorf("文件不存在或无权访问")
		}
		return "", fmt.Errorf("获取文件失败: %w", err)
	}

	return file.Path, nil
}

// isAllowedType 检查文件类型是否允许
func (s *FileService) isAllowedType(mimeType string) bool {
	for _, allowedType := range s.allowedTypes {
		if allowedType == mimeType {
			return true
		}
	}
	return false
}

// calculateHash 计算文件哈希
func (s *FileService) calculateHash(file io.Reader) (string, error) {
	hash := md5.New()
	if _, err := io.Copy(hash, file); err != nil {
		return "", err
	}
	return fmt.Sprintf("%x", hash.Sum(nil)), nil
}

// ensureUploadDir 确保上传目录存在
func (s *FileService) ensureUploadDir() error {
	if _, err := os.Stat(s.uploadPath); os.IsNotExist(err) {
		return os.MkdirAll(s.uploadPath, 0755)
	}
	return nil
}

// generateFilename 生成唯一文件名
func (s *FileService) generateFilename(originalName string) string {
	ext := filepath.Ext(originalName)
	timestamp := time.Now().Unix()
	return fmt.Sprintf("%d_%s%s", timestamp, generateRandomString(8), ext)
}

// generateRandomString 生成随机字符串
func generateRandomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[time.Now().UnixNano()%int64(len(charset))]
	}
	return string(b)
}