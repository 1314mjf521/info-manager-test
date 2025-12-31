package services

import (
	"errors"
	"fmt"
	"time"

	"info-management-system/internal/config"
	"info-management-system/internal/models"

	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"
)

// AuthService 认证服务
type AuthService struct {
	db     *gorm.DB
	config *config.Config
}

// NewAuthService 创建认证服务
func NewAuthService(db *gorm.DB, config *config.Config) *AuthService {
	return &AuthService{
		db:     db,
		config: config,
	}
}

// LoginRequest 登录请求
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// RegisterRequest 注册请求
type RegisterRequest struct {
	Username string `json:"username" binding:"required,min=3,max=50"`
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
}

// LoginResponse 登录响应
type LoginResponse struct {
	Token        string    `json:"token"`
	RefreshToken string    `json:"refresh_token"`
	ExpiresAt    time.Time `json:"expires_at"`
	User         UserInfo  `json:"user"`
}

// UserInfo 用户信息
type UserInfo struct {
	ID          uint                 `json:"id"`
	Username    string               `json:"username"`
	Email       string               `json:"email"`
	IsActive    bool                 `json:"is_active"`
	Roles       []AuthRoleInfo       `json:"roles"`
	Permissions []AuthPermissionInfo `json:"permissions"`
}

// AuthRoleInfo 认证角色信息
type AuthRoleInfo struct {
	ID          uint   `json:"id"`
	Name        string `json:"name"`
	DisplayName string `json:"display_name"`
	Description string `json:"description"`
}

// AuthPermissionInfo 认证权限信息
type AuthPermissionInfo struct {
	ID          uint   `json:"id"`
	Name        string `json:"name"`
	DisplayName string `json:"display_name"`
	Description string `json:"description"`
	Resource    string `json:"resource"`
	Action      string `json:"action"`
	Scope       string `json:"scope"`
}

// JWTClaims JWT声明
type JWTClaims struct {
	UserID   uint     `json:"user_id"`
	Username string   `json:"username"`
	Roles    []string `json:"roles"`
	jwt.RegisteredClaims
}

// Login 用户登录
func (s *AuthService) Login(req *LoginRequest) (*LoginResponse, error) {
	return s.LoginWithIP(req, "")
}

// LoginWithIP 用户登录（带IP记录）
func (s *AuthService) LoginWithIP(req *LoginRequest, clientIP string) (*LoginResponse, error) {
	// 查找用户并预加载角色和权限
	var user models.User
	if err := s.db.Preload("Roles.Permissions").Where("username = ? OR email = ?", req.Username, req.Username).First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("用户名或密码错误")
		}
		return nil, fmt.Errorf("查询用户失败: %w", err)
	}

	// 检查用户是否激活
	if !user.IsActive {
		return nil, fmt.Errorf("用户账户已被禁用")
	}

	// 验证密码
	if !user.CheckPassword(req.Password) {
		return nil, fmt.Errorf("用户名或密码错误")
	}

	// 更新最后登录时间和IP
	now := time.Now()
	user.LastLogin = &now
	if clientIP != "" {
		user.LastLoginIP = clientIP
	}
	s.db.Save(&user)

	// 生成JWT token
	token, expiresAt, err := s.generateToken(&user)
	if err != nil {
		return nil, fmt.Errorf("生成token失败: %w", err)
	}

	// 生成刷新token
	refreshToken, _, err := s.generateRefreshToken(&user)
	if err != nil {
		return nil, fmt.Errorf("生成刷新token失败: %w", err)
	}

	return s.buildLoginResponse(token, refreshToken, expiresAt, &user)
}

// Register 用户注册
func (s *AuthService) Register(req *RegisterRequest) (*models.User, error) {
	// 检查用户名是否已存在
	var existingUser models.User
	if err := s.db.Where("username = ?", req.Username).First(&existingUser).Error; err == nil {
		return nil, fmt.Errorf("用户名已存在")
	}

	// 检查邮箱是否已存在
	if err := s.db.Where("email = ?", req.Email).First(&existingUser).Error; err == nil {
		return nil, fmt.Errorf("邮箱已存在")
	}

	// 创建新用户
	user := models.User{
		Username: req.Username,
		Email:    req.Email,
		IsActive: true,
	}

	// 设置密码
	if err := user.SetPassword(req.Password); err != nil {
		return nil, fmt.Errorf("密码加密失败: %w", err)
	}

	// 保存用户
	if err := s.db.Create(&user).Error; err != nil {
		return nil, fmt.Errorf("创建用户失败: %w", err)
	}

	// 分配默认角色
	var defaultRole models.Role
	if err := s.db.Where("name = ?", "user").First(&defaultRole).Error; err == nil {
		userRole := models.UserRole{
			UserID: user.ID,
			RoleID: defaultRole.ID,
		}
		s.db.Create(&userRole)
	}

	return &user, nil
}

// RefreshToken 刷新token
func (s *AuthService) RefreshToken(tokenString string) (*LoginResponse, error) {
	// 解析token
	claims, err := s.parseToken(tokenString)
	if err != nil {
		return nil, fmt.Errorf("无效的刷新token: %w", err)
	}

	// 查找用户并预加载角色和权限
	var user models.User
	if err := s.db.Preload("Roles.Permissions").First(&user, claims.UserID).Error; err != nil {
		return nil, fmt.Errorf("用户不存在")
	}

	// 检查用户是否激活
	if !user.IsActive {
		return nil, fmt.Errorf("用户账户已被禁用")
	}

	// 生成新的token
	token, expiresAt, err := s.generateToken(&user)
	if err != nil {
		return nil, fmt.Errorf("生成token失败: %w", err)
	}

	// 生成新的刷新token
	refreshToken, _, err := s.generateRefreshToken(&user)
	if err != nil {
		return nil, fmt.Errorf("生成刷新token失败: %w", err)
	}

	return s.buildLoginResponse(token, refreshToken, expiresAt, &user)
}

// buildLoginResponse 构建登录响应
func (s *AuthService) buildLoginResponse(token, refreshToken string, expiresAt time.Time, user *models.User) (*LoginResponse, error) {
	// 构建角色信息
	roles := make([]AuthRoleInfo, len(user.Roles))
	for i, role := range user.Roles {
		roles[i] = AuthRoleInfo{
			ID:          role.ID,
			Name:        role.Name,
			DisplayName: role.DisplayName,
			Description: role.Description,
		}
	}

	// 收集所有权限（去重）
	permissionMap := make(map[uint]models.Permission)
	for _, role := range user.Roles {
		for _, permission := range role.Permissions {
			permissionMap[permission.ID] = permission
		}
	}

	// 构建权限信息
	permissions := make([]AuthPermissionInfo, 0, len(permissionMap))
	for _, permission := range permissionMap {
		permissions = append(permissions, AuthPermissionInfo{
			ID:          permission.ID,
			Name:        permission.Name,
			DisplayName: permission.DisplayName,
			Description: permission.Description,
			Resource:    permission.Resource,
			Action:      permission.Action,
			Scope:       permission.Scope,
		})
	}

	return &LoginResponse{
		Token:        token,
		RefreshToken: refreshToken,
		ExpiresAt:    expiresAt,
		User: UserInfo{
			ID:          user.ID,
			Username:    user.Username,
			Email:       user.Email,
			IsActive:    user.IsActive,
			Roles:       roles,
			Permissions: permissions,
		},
	}, nil
}

// ValidateToken 验证token
func (s *AuthService) ValidateToken(tokenString string) (*JWTClaims, error) {
	return s.parseToken(tokenString)
}

// generateToken 生成JWT token
func (s *AuthService) generateToken(user *models.User) (string, time.Time, error) {
	expiresAt := time.Now().Add(time.Duration(s.config.JWT.ExpireTime) * time.Hour)

	roles := make([]string, len(user.Roles))
	for i, role := range user.Roles {
		roles[i] = role.Name
	}

	claims := JWTClaims{
		UserID:   user.ID,
		Username: user.Username,
		Roles:    roles,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expiresAt),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "info-management-system",
			Subject:   fmt.Sprintf("%d", user.ID),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(s.config.JWT.Secret))
	if err != nil {
		return "", time.Time{}, err
	}

	return tokenString, expiresAt, nil
}

// generateRefreshToken 生成刷新token
func (s *AuthService) generateRefreshToken(user *models.User) (string, time.Time, error) {
	expiresAt := time.Now().Add(7 * 24 * time.Hour) // 7天

	claims := JWTClaims{
		UserID:   user.ID,
		Username: user.Username,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expiresAt),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "info-management-system-refresh",
			Subject:   fmt.Sprintf("%d", user.ID),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(s.config.JWT.Secret))
	if err != nil {
		return "", time.Time{}, err
	}

	return tokenString, expiresAt, nil
}

// parseToken 解析token
func (s *AuthService) parseToken(tokenString string) (*JWTClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(s.config.JWT.Secret), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*JWTClaims); ok && token.Valid {
		return claims, nil
	}

	return nil, fmt.Errorf("invalid token")
}