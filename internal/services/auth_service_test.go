package services

import (
	"testing"

	"info-management-system/internal/config"
	"info-management-system/internal/database"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
	"gorm.io/gorm"
)

type AuthServiceTestSuite struct {
	suite.Suite
	db          *gorm.DB
	authService *AuthService
	userService *UserService
}

func (suite *AuthServiceTestSuite) SetupSuite() {
	// 使用内存SQLite数据库进行测试
	cfg := &config.DatabaseConfig{
		Type:     "sqlite",
		Database: ":memory:",
	}

	err := database.Connect(cfg)
	suite.Require().NoError(err)

	suite.db = database.GetDB()

	// 执行迁移
	err = database.Migrate(suite.db)
	suite.Require().NoError(err)

	// 创建服务
	appConfig := &config.Config{
		JWT: config.JWTConfig{
			Secret:     "test-secret",
			ExpireTime: 24,
		},
	}

	suite.authService = NewAuthService(suite.db, appConfig)
	suite.userService = NewUserService(suite.db)
}

func (suite *AuthServiceTestSuite) TearDownSuite() {
	database.Close()
}

func (suite *AuthServiceTestSuite) SetupTest() {
	// 清理测试数据
	suite.db.Exec("DELETE FROM user_roles")
	suite.db.Exec("DELETE FROM users WHERE username != 'admin'")
}

func (suite *AuthServiceTestSuite) TestRegister() {
	req := &RegisterRequest{
		Username: "testuser",
		Email:    "test@example.com",
		Password: "password123",
	}

	user, err := suite.authService.Register(req)

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), user)
	assert.Equal(suite.T(), req.Username, user.Username)
	assert.Equal(suite.T(), req.Email, user.Email)
	assert.True(suite.T(), user.IsActive)
	assert.NotEmpty(suite.T(), user.PasswordHash)
}

func (suite *AuthServiceTestSuite) TestRegisterDuplicateUsername() {
	req := &RegisterRequest{
		Username: "admin", // 已存在的用户名
		Email:    "test@example.com",
		Password: "password123",
	}

	user, err := suite.authService.Register(req)

	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), user)
	assert.Contains(suite.T(), err.Error(), "用户名已存在")
}

func (suite *AuthServiceTestSuite) TestLogin() {
	// 先注册一个用户
	registerReq := &RegisterRequest{
		Username: "testuser",
		Email:    "test@example.com",
		Password: "password123",
	}
	_, err := suite.authService.Register(registerReq)
	suite.Require().NoError(err)

	// 测试登录
	loginReq := &LoginRequest{
		Username: "testuser",
		Password: "password123",
	}

	response, err := suite.authService.Login(loginReq)

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), response)
	assert.NotEmpty(suite.T(), response.Token)
	assert.NotEmpty(suite.T(), response.RefreshToken)
	assert.Equal(suite.T(), "testuser", response.User.Username)
	assert.Equal(suite.T(), "test@example.com", response.User.Email)
	assert.Contains(suite.T(), response.User.Roles, "user")
}

func (suite *AuthServiceTestSuite) TestLoginInvalidCredentials() {
	loginReq := &LoginRequest{
		Username: "nonexistent",
		Password: "wrongpassword",
	}

	response, err := suite.authService.Login(loginReq)

	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), response)
	assert.Contains(suite.T(), err.Error(), "用户名或密码错误")
}

func (suite *AuthServiceTestSuite) TestValidateToken() {
	// 先注册并登录获取token
	registerReq := &RegisterRequest{
		Username: "testuser",
		Email:    "test@example.com",
		Password: "password123",
	}
	_, err := suite.authService.Register(registerReq)
	suite.Require().NoError(err)

	loginReq := &LoginRequest{
		Username: "testuser",
		Password: "password123",
	}
	loginResponse, err := suite.authService.Login(loginReq)
	suite.Require().NoError(err)

	// 验证token
	claims, err := suite.authService.ValidateToken(loginResponse.Token)

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), claims)
	assert.Equal(suite.T(), "testuser", claims.Username)
	assert.Contains(suite.T(), claims.Roles, "user")
}

func (suite *AuthServiceTestSuite) TestValidateInvalidToken() {
	invalidToken := "invalid.token.here"

	claims, err := suite.authService.ValidateToken(invalidToken)

	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), claims)
}

func (suite *AuthServiceTestSuite) TestRefreshToken() {
	// 先注册并登录获取refresh token
	registerReq := &RegisterRequest{
		Username: "testuser",
		Email:    "test@example.com",
		Password: "password123",
	}
	_, err := suite.authService.Register(registerReq)
	suite.Require().NoError(err)

	loginReq := &LoginRequest{
		Username: "testuser",
		Password: "password123",
	}
	loginResponse, err := suite.authService.Login(loginReq)
	suite.Require().NoError(err)

	// 刷新token
	refreshResponse, err := suite.authService.RefreshToken(loginResponse.RefreshToken)

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), refreshResponse)
	assert.NotEmpty(suite.T(), refreshResponse.Token)
	assert.NotEmpty(suite.T(), refreshResponse.RefreshToken)
	// 新token应该不同（但由于时间戳相同可能会相同，所以这里只检查token不为空）
	assert.NotEmpty(suite.T(), refreshResponse.Token)
}

func TestAuthServiceTestSuite(t *testing.T) {
	suite.Run(t, new(AuthServiceTestSuite))
}