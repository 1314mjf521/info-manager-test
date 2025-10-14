package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// APIResponse 统一API响应格式
type APIResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   *APIError   `json:"error,omitempty"`
	Meta    *Meta       `json:"meta,omitempty"`
}

// APIError API错误信息
type APIError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

// Meta 元数据信息
type Meta struct {
	Page       int `json:"page,omitempty"`
	PageSize   int `json:"page_size,omitempty"`
	Total      int `json:"total,omitempty"`
	TotalPages int `json:"total_pages,omitempty"`
}

// 自定义错误类型
type ValidationError struct {
	Message string
	Details string
}

func (e *ValidationError) Error() string {
	return e.Message
}

type AuthorizationError struct {
	Message string
}

func (e *AuthorizationError) Error() string {
	return e.Message
}

type NotFoundError struct {
	Message string
}

func (e *NotFoundError) Error() string {
	return e.Message
}

// ErrorHandler 错误处理中间件
func ErrorHandler(logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		if len(c.Errors) > 0 {
			err := c.Errors.Last()

			// 记录错误日志
			logger.WithFields(logrus.Fields{
				"error":      err.Error(),
				"path":       c.Request.URL.Path,
				"method":     c.Request.Method,
				"request_id": c.GetString("request_id"),
			}).Error("Request error")

			var apiErr *APIError
			var statusCode int

			switch e := err.Err.(type) {
			case *ValidationError:
				apiErr = &APIError{
					Code:    "VALIDATION_ERROR",
					Message: e.Message,
					Details: e.Details,
				}
				statusCode = http.StatusBadRequest
			case *AuthorizationError:
				apiErr = &APIError{
					Code:    "AUTHORIZATION_ERROR",
					Message: "Access denied",
				}
				statusCode = http.StatusForbidden
			case *NotFoundError:
				apiErr = &APIError{
					Code:    "NOT_FOUND",
					Message: e.Message,
				}
				statusCode = http.StatusNotFound
			default:
				apiErr = &APIError{
					Code:    "INTERNAL_ERROR",
					Message: "Internal server error",
				}
				statusCode = http.StatusInternalServerError
			}

			c.JSON(statusCode, APIResponse{
				Success: false,
				Error:   apiErr,
			})
		}
	}
}

// Success 成功响应
func Success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, APIResponse{
		Success: true,
		Data:    data,
	})
}

// SuccessWithMeta 带元数据的成功响应
func SuccessWithMeta(c *gin.Context, data interface{}, meta *Meta) {
	c.JSON(http.StatusOK, APIResponse{
		Success: true,
		Data:    data,
		Meta:    meta,
	})
}

// Created 创建成功响应
func Created(c *gin.Context, data interface{}) {
	c.JSON(http.StatusCreated, APIResponse{
		Success: true,
		Data:    data,
	})
}

// ValidationErrorResponse 验证错误响应
func ValidationErrorResponse(c *gin.Context, message, details string) {
	c.Error(&ValidationError{Message: message, Details: details})
}

// AuthorizationErrorResponse 授权错误响应
func AuthorizationErrorResponse(c *gin.Context, message string) {
	c.Error(&AuthorizationError{Message: message})
}

// NotFoundErrorResponse 未找到错误响应
func NotFoundErrorResponse(c *gin.Context, message string) {
	c.Error(&NotFoundError{Message: message})
}

// InternalErrorResponse 内部错误响应
func InternalErrorResponse(c *gin.Context, err error) {
	c.Error(err)
}
