package handlers

import (
	"net/http"
	"strconv"

	"info-management-system/internal/middleware"
	"info-management-system/internal/services"

	"github.com/gin-gonic/gin"
)

// FileHandler 文件处理器
type FileHandler struct {
	fileService *services.FileService
}

// NewFileHandler 创建文件处理器
func NewFileHandler(fileService *services.FileService) *FileHandler {
	return &FileHandler{
		fileService: fileService,
	}
}

// UploadFile 上传文件
func (h *FileHandler) UploadFile(c *gin.Context) {
	var req services.UploadRequest
	if err := c.ShouldBind(&req); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	userID := c.GetUint("user_id")
	clientIP := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	file, err := h.fileService.UploadFile(&req, userID, clientIP, userAgent)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    file,
	})
}

// GetFiles 获取文件列表
func (h *FileHandler) GetFiles(c *gin.Context) {
	var query services.FileListQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		middleware.ValidationErrorResponse(c, "参数验证失败", err.Error())
		return
	}

	// 获取用户信息和权限
	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_files_permission")

	files, err := h.fileService.GetFiles(&query, userID, hasAllPermission)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, files)
}

// GetFileByID 根据ID获取文件信息
func (h *FileHandler) GetFileByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的文件ID", "")
		return
	}

	// 获取用户信息和权限
	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_files_permission")

	file, err := h.fileService.GetFileByID(uint(id), userID, hasAllPermission)
	if err != nil {
		if err.Error() == "文件不存在或无权访问" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "FILE_NOT_FOUND",
					"message": "文件不存在或无权访问",
				},
			})
			return
		}

		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, file)
}

// DownloadFile 下载文件
func (h *FileHandler) DownloadFile(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的文件ID", "")
		return
	}

	// 获取用户信息和权限
	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_files_permission")

	// 获取文件信息
	file, err := h.fileService.GetFileByID(uint(id), userID, hasAllPermission)
	if err != nil {
		if err.Error() == "文件不存在或无权访问" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "FILE_NOT_FOUND",
					"message": "文件不存在或无权访问",
				},
			})
			return
		}

		middleware.InternalErrorResponse(c, err)
		return
	}

	// 获取文件物理路径
	filePath, err := h.fileService.GetFilePath(uint(id), userID, hasAllPermission)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	// 设置响应头
	c.Header("Content-Description", "File Transfer")
	c.Header("Content-Transfer-Encoding", "binary")
	c.Header("Content-Disposition", "attachment; filename="+file.OriginalName)
	c.Header("Content-Type", file.MimeType)

	// 发送文件
	c.File(filePath)
}

// DeleteFile 删除文件
func (h *FileHandler) DeleteFile(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		middleware.ValidationErrorResponse(c, "无效的文件ID", "")
		return
	}

	// 获取用户信息和权限
	userID := c.GetUint("user_id")
	hasAllPermission := c.GetBool("has_all_files_permission")
	clientIP := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	err = h.fileService.DeleteFile(uint(id), userID, hasAllPermission, clientIP, userAgent)
	if err != nil {
		if err.Error() == "文件不存在或无权删除" {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error": gin.H{
					"code":    "FILE_NOT_FOUND",
					"message": "文件不存在或无权删除",
				},
			})
			return
		}

		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, gin.H{"message": "文件删除成功"})
}