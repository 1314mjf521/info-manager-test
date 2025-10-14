package middleware

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// AuditMiddleware 审计中间件
func AuditMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取客户端IP
		clientIP := c.ClientIP()
		
		// 获取User-Agent
		userAgent := c.GetHeader("User-Agent")
		
		// 将IP和User-Agent存储到上下文中，供服务层使用
		c.Set("client_ip", clientIP)
		c.Set("user_agent", userAgent)
		
		// 对于需要记录请求体的操作，读取并保存请求体
		if shouldLogRequestBody(c.Request.Method, c.Request.URL.Path) {
			body, err := io.ReadAll(c.Request.Body)
			if err == nil {
				// 恢复请求体供后续处理使用
				c.Request.Body = io.NopCloser(bytes.NewBuffer(body))
				
				// 将请求体存储到上下文中
				c.Set("request_body", string(body))
			}
		}
		
		c.Next()
	}
}

// shouldLogRequestBody 判断是否需要记录请求体
func shouldLogRequestBody(method, path string) bool {
	// 只对POST、PUT、PATCH请求记录请求体
	if method != http.MethodPost && method != http.MethodPut && method != http.MethodPatch {
		return false
	}
	
	// 排除敏感路径
	sensitivePatterns := []string{
		"/auth/login",
		"/auth/register",
		"/users/password",
	}
	
	for _, pattern := range sensitivePatterns {
		if strings.Contains(path, pattern) {
			return false
		}
	}
	
	return true
}

// GetAuditInfo 从上下文中获取审计信息
func GetAuditInfo(c *gin.Context) (string, string) {
	clientIP, _ := c.Get("client_ip")
	userAgent, _ := c.Get("user_agent")
	
	ip, _ := clientIP.(string)
	ua, _ := userAgent.(string)
	
	return ip, ua
}

// GetRequestBody 从上下文中获取请求体
func GetRequestBody(c *gin.Context) string {
	body, exists := c.Get("request_body")
	if !exists {
		return ""
	}
	
	bodyStr, _ := body.(string)
	return bodyStr
}

// LogOperationResult 记录操作结果的辅助函数
func LogOperationResult(c *gin.Context, operation string, resourceType string, resourceID uint, success bool, errorMsg string) {
	// 这里可以添加操作结果的日志记录逻辑
	// 例如记录到数据库或日志文件
	
	userID := c.GetUint("user_id")
	clientIP, userAgent := GetAuditInfo(c)
	
	logData := map[string]interface{}{
		"user_id":       userID,
		"operation":     operation,
		"resource_type": resourceType,
		"resource_id":   resourceID,
		"success":       success,
		"client_ip":     clientIP,
		"user_agent":    userAgent,
	}
	
	if !success && errorMsg != "" {
		logData["error"] = errorMsg
	}
	
	// 将日志数据序列化为JSON并记录
	if logJSON, err := json.Marshal(logData); err == nil {
		// 这里可以使用日志库记录到文件或发送到日志服务
		// 例如: log.Info(string(logJSON))
		_ = logJSON // 暂时忽略，避免编译警告
	}
}