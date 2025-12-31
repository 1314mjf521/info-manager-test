package services

import (
	"fmt"
	"gorm.io/gorm"
)

// PermissionInitService 权限初始化服务
type PermissionInitService struct {
	db *gorm.DB
}

// NewPermissionInitService 创建权限初始化服务
func NewPermissionInitService(db *gorm.DB) *PermissionInitService {
	return &PermissionInitService{db: db}
}

// InitializePermissions 初始化精细化权限数据
func (s *PermissionInitService) InitializePermissions() error {
	permissions := GetAllDetailedPermissions()
	
	// 开始事务
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 清空现有权限数据以确保ID一致性
	if err := tx.Exec("DELETE FROM role_permissions").Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("清空角色权限关联失败: %v", err)
	}
	if err := tx.Exec("DELETE FROM permissions").Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("清空权限数据失败: %v", err)
	}

	// 批量插入权限，使用预设ID
	for _, perm := range permissions {
		if err := tx.Create(&perm).Error; err != nil {
			tx.Rollback()
			return fmt.Errorf("创建权限失败 (ID: %d, Name: %s): %v", perm.ID, perm.Name, err)
		}
	}

	// 提交事务
	if err := tx.Commit().Error; err != nil {
		return fmt.Errorf("提交事务失败: %v", err)
	}

	return nil
}