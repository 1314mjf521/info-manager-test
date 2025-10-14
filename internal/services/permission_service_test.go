package services

import (
	"testing"

	"info-management-system/internal/config"
	"info-management-system/internal/database"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
	"gorm.io/gorm"
)

type PermissionServiceTestSuite struct {
	suite.Suite
	db                *gorm.DB
	permissionService *PermissionService
	roleService       *RoleService
	authService       *AuthService
}

func (suite *PermissionServiceTestSuite) SetupSuite() {
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

	suite.permissionService = NewPermissionService(suite.db)
	suite.roleService = NewRoleService(suite.db)
	suite.authService = NewAuthService(suite.db, appConfig)
}

func (suite *PermissionServiceTestSuite) TearDownSuite() {
	database.Close()
}

func (suite *PermissionServiceTestSuite) SetupTest() {
	// 清理测试数据（保留系统数据）
	suite.db.Exec("DELETE FROM role_permissions WHERE role_id > 3")
	suite.db.Exec("DELETE FROM user_roles WHERE user_id > 1")
	suite.db.Exec("DELETE FROM users WHERE id > 1")
	suite.db.Exec("DELETE FROM roles WHERE id > 3")
}

func (suite *PermissionServiceTestSuite) TestCheckPermission() {
	// 测试管理员权限
	req := &PermissionCheckRequest{
		UserID:   1, // admin用户
		Resource: "system",
		Action:   "admin",
		Scope:    "all",
	}

	response, err := suite.permissionService.CheckPermission(req)

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), response)
	assert.True(suite.T(), response.HasPermission)
	assert.Empty(suite.T(), response.Message)
}

func (suite *PermissionServiceTestSuite) TestCheckPermissionDenied() {
	// 创建一个普通用户
	registerReq := &RegisterRequest{
		Username: "testuser",
		Email:    "test@example.com",
		Password: "password123",
	}
	user, err := suite.authService.Register(registerReq)
	suite.Require().NoError(err)

	// 测试普通用户没有管理员权限
	req := &PermissionCheckRequest{
		UserID:   user.ID,
		Resource: "system",
		Action:   "admin",
		Scope:    "all",
	}

	response, err := suite.permissionService.CheckPermission(req)

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), response)
	assert.False(suite.T(), response.HasPermission)
	assert.Equal(suite.T(), "权限不足", response.Message)
}

func (suite *PermissionServiceTestSuite) TestGetUserPermissions() {
	// 获取管理员用户权限
	response, err := suite.permissionService.GetUserPermissions(1)

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), response)
	assert.Equal(suite.T(), uint(1), response.UserID)
	assert.Equal(suite.T(), "admin", response.Username)
	assert.Len(suite.T(), response.Roles, 1)
	assert.Equal(suite.T(), "admin", response.Roles[0].Name)
	assert.Greater(suite.T(), len(response.Permissions), 0)
	assert.Contains(suite.T(), response.PermissionMap, "system")
	assert.Contains(suite.T(), response.PermissionMap["system"], "admin")
}

func (suite *PermissionServiceTestSuite) TestGetAllPermissions() {
	permissions, err := suite.permissionService.GetAllPermissions()

	assert.NoError(suite.T(), err)
	assert.Greater(suite.T(), len(permissions), 0)

	// 检查是否包含系统管理员权限
	found := false
	for _, permission := range permissions {
		if permission.Resource == "system" && permission.Action == "admin" && permission.Scope == "all" {
			found = true
			break
		}
	}
	assert.True(suite.T(), found, "应该包含系统管理员权限")
}

func (suite *PermissionServiceTestSuite) TestCreatePermission() {
	permission, err := suite.permissionService.CreatePermission("test", "action", "scope")

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), permission)
	assert.Equal(suite.T(), "test", permission.Resource)
	assert.Equal(suite.T(), "action", permission.Action)
	assert.Equal(suite.T(), "scope", permission.Scope)
}

func (suite *PermissionServiceTestSuite) TestCreateDuplicatePermission() {
	// 尝试创建已存在的权限
	_, err := suite.permissionService.CreatePermission("system", "admin", "all")

	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "权限已存在")
}

func TestPermissionServiceTestSuite(t *testing.T) {
	suite.Run(t, new(PermissionServiceTestSuite))
}