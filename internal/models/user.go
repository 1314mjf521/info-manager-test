package models

import (
	"time"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// User 用户模型
type User struct {
	ID           uint           `json:"id" gorm:"primaryKey"`
	Username     string         `json:"username" gorm:"uniqueIndex;not null;size:100"`
	Email        string         `json:"email" gorm:"uniqueIndex;not null;size:255"`
	DisplayName  string         `json:"displayName" gorm:"size:200"`
	PasswordHash string         `json:"-" gorm:"not null;size:255"`
	Status       string         `json:"status" gorm:"default:active;size:20"`
	IsActive     bool           `json:"is_active" gorm:"default:true"`
	LastLogin    *time.Time     `json:"lastLoginAt"`
	LastLoginIP  string         `json:"lastLoginIP" gorm:"size:45"` // 支持IPv6
	CreatedAt    time.Time      `json:"createdAt"`
	UpdatedAt    time.Time      `json:"updatedAt"`
	DeletedAt    gorm.DeletedAt `json:"-" gorm:"index"`

	// 关联关系
	Roles       []Role       `json:"roles" gorm:"many2many:user_roles;"`
	Permissions []Permission `json:"permissions" gorm:"many2many:user_permissions;"`
}

// Role 角色模型
type Role struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	Name        string    `json:"name" gorm:"uniqueIndex;not null;size:100"`
	DisplayName string    `json:"displayName" gorm:"size:200"`
	Description string    `json:"description" gorm:"size:500"`
	Status      string    `json:"status" gorm:"default:active;size:20"`
	IsSystem    bool      `json:"is_system" gorm:"default:false"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

	// 关联关系
	Users       []User       `json:"users" gorm:"many2many:user_roles;"`
	Permissions []Permission `json:"permissions" gorm:"many2many:role_permissions;"`
}

// Permission 权限模型
type Permission struct {
	ID          uint   `json:"id" gorm:"primaryKey"`
	Name        string `json:"name" gorm:"uniqueIndex;size:100"`
	DisplayName string `json:"displayName" gorm:"size:200"`
	Description string `json:"description" gorm:"size:500"`
	Resource    string `json:"resource" gorm:"not null;size:100"`
	Action      string `json:"action" gorm:"not null;size:50"`
	Scope       string `json:"scope" gorm:"not null;size:50"`
	ParentID    *uint  `json:"parentId" gorm:"index"`

	// 关联关系
	Roles    []Role       `json:"roles" gorm:"many2many:role_permissions;"`
	Parent   *Permission  `json:"parent" gorm:"foreignKey:ParentID"`
	Children []Permission `json:"children" gorm:"foreignKey:ParentID"`
}

// UserRole 用户角色关联表
type UserRole struct {
	UserID uint `json:"user_id" gorm:"primaryKey"`
	RoleID uint `json:"role_id" gorm:"primaryKey"`
	User   User `json:"user" gorm:"foreignKey:UserID"`
	Role   Role `json:"role" gorm:"foreignKey:RoleID"`
}

// RolePermission 角色权限关联表
type RolePermission struct {
	RoleID       uint       `json:"role_id" gorm:"primaryKey"`
	PermissionID uint       `json:"permission_id" gorm:"primaryKey"`
	Role         Role       `json:"role" gorm:"foreignKey:RoleID"`
	Permission   Permission `json:"permission" gorm:"foreignKey:PermissionID"`
}

// UserPermission 用户权限关联表（直接权限分配）
type UserPermission struct {
	UserID       uint       `json:"user_id" gorm:"primaryKey"`
	PermissionID uint       `json:"permission_id" gorm:"primaryKey"`
	User         User       `json:"user" gorm:"foreignKey:UserID"`
	Permission   Permission `json:"permission" gorm:"foreignKey:PermissionID"`
}

// HashPassword 加密密码
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

// CheckPassword 验证密码
func (u *User) CheckPassword(password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password))
	return err == nil
}

// SetPassword 设置密码
func (u *User) SetPassword(password string) error {
	hash, err := HashPassword(password)
	if err != nil {
		return err
	}
	u.PasswordHash = hash
	return nil
}

// HasPermission 检查用户是否有指定权限
func (u *User) HasPermission(resource, action, scope string) bool {
	// 检查直接分配的权限
	for _, permission := range u.Permissions {
		if permission.Resource == resource &&
			permission.Action == action &&
			(permission.Scope == scope || permission.Scope == "all") {
			return true
		}
	}
	
	// 检查通过角色获得的权限
	for _, role := range u.Roles {
		for _, permission := range role.Permissions {
			if permission.Resource == resource &&
				permission.Action == action &&
				(permission.Scope == scope || permission.Scope == "all") {
				return true
			}
		}
	}
	return false
}

// GetPermissions 获取用户所有权限
func (u *User) GetPermissions() []Permission {
	var permissions []Permission
	permissionMap := make(map[string]bool)

	// 添加直接分配的权限
	for _, permission := range u.Permissions {
		key := permission.Resource + ":" + permission.Action + ":" + permission.Scope
		if !permissionMap[key] {
			permissions = append(permissions, permission)
			permissionMap[key] = true
		}
	}

	// 添加通过角色获得的权限
	for _, role := range u.Roles {
		for _, permission := range role.Permissions {
			key := permission.Resource + ":" + permission.Action + ":" + permission.Scope
			if !permissionMap[key] {
				permissions = append(permissions, permission)
				permissionMap[key] = true
			}
		}
	}

	return permissions
}
