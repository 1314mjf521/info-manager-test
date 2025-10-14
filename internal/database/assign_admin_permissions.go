package database

import (
	"info-management-system/internal/models"

	"gorm.io/gorm"
)

// AssignAdminPermissions 为管理员角色分配所有权限
func AssignAdminPermissions(db *gorm.DB) error {
	// 获取管理员角色
	var adminRole models.Role
	if err := db.Where("name = ?", "admin").First(&adminRole).Error; err != nil {
		return err
	}

	// 获取所有权限
	var permissions []models.Permission
	if err := db.Find(&permissions).Error; err != nil {
		return err
	}

	// 删除现有的管理员角色权限关联
	if err := db.Where("role_id = ?", adminRole.ID).Delete(&models.RolePermission{}).Error; err != nil {
		return err
	}

	// 为管理员角色分配所有权限
	for _, permission := range permissions {
		rolePermission := models.RolePermission{
			RoleID:       adminRole.ID,
			PermissionID: permission.ID,
		}
		if err := db.Create(&rolePermission).Error; err != nil {
			return err
		}
	}

	return nil
}