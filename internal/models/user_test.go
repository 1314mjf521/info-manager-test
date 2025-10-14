package models

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestHashPassword(t *testing.T) {
	password := "testpassword123"

	hash, err := HashPassword(password)
	assert.NoError(t, err)
	assert.NotEmpty(t, hash)
	assert.NotEqual(t, password, hash)
}

func TestUser_CheckPassword(t *testing.T) {
	user := &User{}
	password := "testpassword123"

	// 设置密码
	err := user.SetPassword(password)
	assert.NoError(t, err)

	// 验证正确密码
	assert.True(t, user.CheckPassword(password))

	// 验证错误密码
	assert.False(t, user.CheckPassword("wrongpassword"))
}

func TestUser_SetPassword(t *testing.T) {
	user := &User{}
	password := "testpassword123"

	err := user.SetPassword(password)
	assert.NoError(t, err)
	assert.NotEmpty(t, user.PasswordHash)
	assert.NotEqual(t, password, user.PasswordHash)
}

func TestUser_HasPermission(t *testing.T) {
	// 创建测试用户和权限
	user := &User{
		Roles: []Role{
			{
				Permissions: []Permission{
					{Resource: "users", Action: "read", Scope: "all"},
					{Resource: "records", Action: "write", Scope: "own"},
				},
			},
		},
	}

	// 测试有权限的情况
	assert.True(t, user.HasPermission("users", "read", "all"))
	assert.True(t, user.HasPermission("records", "write", "own"))

	// 测试无权限的情况
	assert.False(t, user.HasPermission("users", "delete", "all"))
	assert.False(t, user.HasPermission("records", "read", "all"))
}

func TestUser_GetPermissions(t *testing.T) {
	// 创建测试用户和权限
	user := &User{
		Roles: []Role{
			{
				Permissions: []Permission{
					{Resource: "users", Action: "read", Scope: "all"},
					{Resource: "records", Action: "write", Scope: "own"},
				},
			},
			{
				Permissions: []Permission{
					{Resource: "users", Action: "read", Scope: "all"}, // 重复权限
					{Resource: "files", Action: "read", Scope: "own"},
				},
			},
		},
	}

	permissions := user.GetPermissions()

	// 验证权限数量（去重后）
	assert.Len(t, permissions, 3)

	// 验证权限内容
	expectedPermissions := map[string]bool{
		"users:read:all":    true,
		"records:write:own": true,
		"files:read:own":    true,
	}

	for _, perm := range permissions {
		key := perm.Resource + ":" + perm.Action + ":" + perm.Scope
		assert.True(t, expectedPermissions[key], "Unexpected permission: %s", key)
	}
}
