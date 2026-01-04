package middleware

import (
	"bytes"
	"io"
	"time"

	"info-management-system/internal/logger"

	"github.com/gin-gonic/gin"
)

// RequestLoggingMiddleware 请求日志中间件
func RequestLoggingMiddleware(logger *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		// 获取用户ID（如果已认证）
		var userID uint
		if uid, exists := c.Get("user_id"); exists {
			if id, ok := uid.(uint); ok {
				userID = id
			}
		}

		// 记录请求体（仅对POST/PUT/PATCH请求）
		var requestBody string
		if c.Request.Method == "POST" || c.Request.Method == "PUT" || c.Request.Method == "PATCH" {
			if c.Request.Body != nil {
				bodyBytes, _ := io.ReadAll(c.Request.Body)
				c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
				
				// 只记录前1000个字符，避免日志过大
				if len(bodyBytes) > 1000 {
					requestBody = string(bodyBytes[:1000]) + "...[truncated]"
				} else {
					requestBody = string(bodyBytes)
				}
			}
		}

		// 处理请求
		c.Next()

		// 计算处理时间
		duration := time.Since(start)

		// 记录请求日志
		logger.LogRequest(
			c.Request.Method,
			c.Request.URL.Path,
			c.Request.UserAgent(),
			c.ClientIP(),
			userID,
			c.Writer.Status(),
			duration,
		)

		// 如果有错误，记录详细信息
		if len(c.Errors) > 0 {
			for _, err := range c.Errors {
				logger.LogError(err.Err, map[string]interface{}{
					"method":       c.Request.Method,
					"path":         c.Request.URL.Path,
					"user_id":      userID,
					"client_ip":    c.ClientIP(),
					"status_code":  c.Writer.Status(),
					"request_body": requestBody,
				})
			}
		}

		// 记录慢请求
		if duration > 2*time.Second {
			logger.LogPerformance("slow_request", duration, map[string]interface{}{
				"method":    c.Request.Method,
				"path":      c.Request.URL.Path,
				"user_id":   userID,
				"client_ip": c.ClientIP(),
			})
		}
	}
}

// AuthLoggingMiddleware 认证日志中间件
func AuthLoggingMiddleware(logger *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 只对认证相关的路径记录日志
		if c.Request.URL.Path == "/api/v1/auth/login" ||
			c.Request.URL.Path == "/api/v1/auth/logout" ||
			c.Request.URL.Path == "/api/v1/auth/refresh" {

			c.Next()

			// 获取用户信息
			var userID uint
			var username string
			if uid, exists := c.Get("user_id"); exists {
				if id, ok := uid.(uint); ok {
					userID = id
				}
			}
			if uname, exists := c.Get("username"); exists {
				if name, ok := uname.(string); ok {
					username = name
				}
			}

			// 记录认证日志
			success := c.Writer.Status() < 400
			reason := ""
			if !success && len(c.Errors) > 0 {
				reason = c.Errors[0].Error()
			}

			logger.LogAuth(
				c.Request.URL.Path,
				userID,
				username,
				c.ClientIP(),
				success,
				reason,
			)
		} else {
			c.Next()
		}
	}
}

// SecurityLoggingMiddleware 安全日志中间件
func SecurityLoggingMiddleware(logger *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 检查可疑活动
		userAgent := c.Request.UserAgent()
		clientIP := c.ClientIP()

		// 检查是否为可疑的User-Agent
		suspiciousUserAgents := []string{
			"sqlmap", "nikto", "nmap", "masscan", "zap", "burp",
		}
		
		for _, suspicious := range suspiciousUserAgents {
			if len(userAgent) > 0 && contains(userAgent, suspicious) {
				logger.LogSecurity("suspicious_user_agent", 0, clientIP, map[string]interface{}{
					"user_agent": userAgent,
					"path":       c.Request.URL.Path,
					"method":     c.Request.Method,
				})
				break
			}
		}

		// 检查是否为可疑的请求路径
		suspiciousPaths := []string{
			"/.env", "/admin", "/phpmyadmin", "/wp-admin", "/.git",
		}
		
		for _, suspicious := range suspiciousPaths {
			if contains(c.Request.URL.Path, suspicious) {
				logger.LogSecurity("suspicious_path_access", 0, clientIP, map[string]interface{}{
					"path":       c.Request.URL.Path,
					"method":     c.Request.Method,
					"user_agent": userAgent,
				})
				break
			}
		}

		c.Next()

		// 记录权限拒绝
		if c.Writer.Status() == 403 {
			var userID uint
			if uid, exists := c.Get("user_id"); exists {
				if id, ok := uid.(uint); ok {
					userID = id
				}
			}

			logger.LogSecurity("access_denied", userID, clientIP, map[string]interface{}{
				"path":        c.Request.URL.Path,
				"method":      c.Request.Method,
				"status_code": c.Writer.Status(),
			})
		}
	}
}

// contains 检查字符串是否包含子字符串（不区分大小写）
func contains(s, substr string) bool {
	return len(s) >= len(substr) && 
		   (s == substr || 
		    (len(s) > len(substr) && 
		     (s[:len(substr)] == substr || 
		      s[len(s)-len(substr):] == substr ||
		      indexOf(s, substr) >= 0)))
}

// indexOf 查找子字符串位置
func indexOf(s, substr string) int {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return i
		}
	}
	return -1
}