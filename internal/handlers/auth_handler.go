package handlers

import (
	"info-management-system/internal/middleware"
	"info-management-system/internal/services"
	"net"
	"strings"

	"github.com/gin-gonic/gin"
)

// AuthHandler 认证处理器
type AuthHandler struct {
	authService *services.AuthService
	userService *services.UserService
}

// NewAuthHandler 创建认证处理器
func NewAuthHandler(authService *services.AuthService, userService *services.UserService) *AuthHandler {
	return &AuthHandler{
		authService: authService,
		userService: userService,
	}
}

// Login 用户登录
func (h *AuthHandler) Login(c *gin.Context) {
	var req services.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	// 获取客户端真实IP
	clientIP := h.getRealClientIP(c)

	response, err := h.authService.LoginWithIP(&req, clientIP)
	if err != nil {
		middleware.ValidationErrorResponse(c, "登录失败", err.Error())
		return
	}

	middleware.Success(c, response)
}

// Register 用户注册
func (h *AuthHandler) Register(c *gin.Context) {
	var req services.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	user, err := h.authService.Register(&req)
	if err != nil {
		middleware.ValidationErrorResponse(c, "注册失败", err.Error())
		return
	}

	// 返回用户信息（不包含密码）
	userInfo := services.UserInfo{
		ID:          user.ID,
		Username:    user.Username,
		Email:       user.Email,
		IsActive:    user.IsActive,
		Roles:       []services.AuthRoleInfo{}, // 空角色列表
		Permissions: []services.AuthPermissionInfo{}, // 空权限列表
	}

	middleware.Created(c, userInfo)
}

// RefreshToken 刷新token
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	response, err := h.authService.RefreshToken(req.RefreshToken)
	if err != nil {
		middleware.AuthorizationErrorResponse(c, err.Error())
		return
	}

	middleware.Success(c, response)
}

// Logout 用户注销
func (h *AuthHandler) Logout(c *gin.Context) {
	// 在实际应用中，这里可以将token加入黑名单
	// 目前只是返回成功响应
	middleware.Success(c, gin.H{
		"message": "注销成功",
	})
}

// GetProfile 获取用户信息
func (h *AuthHandler) GetProfile(c *gin.Context) {
	userID, exists := middleware.GetCurrentUserID(c)
	if !exists {
		middleware.AuthorizationErrorResponse(c, "未登录")
		return
	}

	profile, err := h.userService.GetProfile(userID)
	if err != nil {
		middleware.InternalErrorResponse(c, err)
		return
	}

	middleware.Success(c, profile)
}

// UpdateProfile 更新用户信息
func (h *AuthHandler) UpdateProfile(c *gin.Context) {
	userID, exists := middleware.GetCurrentUserID(c)
	if !exists {
		middleware.AuthorizationErrorResponse(c, "未登录")
		return
	}

	var req services.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	profile, err := h.userService.UpdateProfile(userID, &req)
	if err != nil {
		middleware.ValidationErrorResponse(c, "更新失败", err.Error())
		return
	}

	middleware.Success(c, profile)
}

// ChangePassword 修改密码
func (h *AuthHandler) ChangePassword(c *gin.Context) {
	userID, exists := middleware.GetCurrentUserID(c)
	if !exists {
		middleware.AuthorizationErrorResponse(c, "未登录")
		return
	}

	var req services.ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		middleware.ValidationErrorResponse(c, "请求参数错误", err.Error())
		return
	}

	if err := h.userService.ChangePassword(userID, &req); err != nil {
		middleware.ValidationErrorResponse(c, "修改密码失败", err.Error())
		return
	}

	middleware.Success(c, gin.H{
		"message": "密码修改成功",
	})
}

// getRealClientIP 获取客户端真实IP地址
func (h *AuthHandler) getRealClientIP(c *gin.Context) string {
	// 优先级顺序：X-Real-IP > X-Forwarded-For > RemoteAddr

	// 1. 检查 X-Real-IP 头（通常由 Nginx 等反向代理设置）
	if realIP := c.GetHeader("X-Real-IP"); realIP != "" {
		if ip := net.ParseIP(realIP); ip != nil {
			return realIP
		}
	}

	// 2. 检查 X-Forwarded-For 头（可能包含多个IP，取第一个）
	if forwardedFor := c.GetHeader("X-Forwarded-For"); forwardedFor != "" {
		// X-Forwarded-For 格式: client, proxy1, proxy2
		ips := strings.Split(forwardedFor, ",")
		if len(ips) > 0 {
			clientIP := strings.TrimSpace(ips[0])
			if ip := net.ParseIP(clientIP); ip != nil {
				return clientIP
			}
		}
	}

	// 3. 检查其他常见的代理头
	proxyHeaders := []string{
		"X-Forwarded",
		"Forwarded-For",
		"Forwarded",
		"X-Client-IP",
		"Client-IP",
	}

	for _, header := range proxyHeaders {
		if headerValue := c.GetHeader(header); headerValue != "" {
			// 处理可能的多IP情况
			ips := strings.Split(headerValue, ",")
			for _, ipStr := range ips {
				ipStr = strings.TrimSpace(ipStr)
				// 移除端口号（如果存在）
				if colonIndex := strings.LastIndex(ipStr, ":"); colonIndex != -1 {
					if ip := net.ParseIP(ipStr[:colonIndex]); ip != nil {
						ipStr = ipStr[:colonIndex]
					}
				}
				if ip := net.ParseIP(ipStr); ip != nil && !ip.IsLoopback() {
					return ipStr
				}
			}
		}
	}

	// 4. 最后使用 Gin 的 ClientIP 方法（会处理基本的代理情况）
	clientIP := c.ClientIP()

	// 5. 如果是本地回环地址，尝试获取本机的实际IP
	if clientIP == "127.0.0.1" || clientIP == "::1" {
		if localIP := h.getLocalIP(); localIP != "" {
			return localIP + " (local)"
		}
	}

	return clientIP
}

// getLocalIP 获取本机的实际IP地址
func (h *AuthHandler) getLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return ""
	}

	for _, addr := range addrs {
		if ipNet, ok := addr.(*net.IPNet); ok && !ipNet.IP.IsLoopback() {
			if ipNet.IP.To4() != nil {
				return ipNet.IP.String()
			}
		}
	}

	return ""
}
