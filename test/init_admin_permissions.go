package main

import (
	"fmt"
	"log"

	"info-management-system/internal/config"
	"info-management-system/internal/database"
	"info-management-system/internal/models"

	"gorm.io/gorm"
)

func main() {
	// 加载配置
	cfg, err := config.Load()
	if err != nil {
		log.Fatal("Failed to load config:", err)
	}

	// 初始化数据库连接
	err = database.Connect(&cfg.Database)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer database.Close()

	db := database.GetDB()

	// 确保admin用户存在并有正确的权限
	if err := setupAdminPermissions(db); err != nil {
		log.Fatal("Failed to setup admin permissions:", err)
	}

	fmt.Println("Admin permissions setup completed successfully!")
}

func setupAdminPermissions(db *gorm.DB) error {
	// 1. 确保admin用户存在
	var adminUser models.User
	result := db.Where("username = ?", "admin").First(&adminUser)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			fmt.Println("Admin user not found, please run the main application first to create admin user")
			return result.Error
		}
		return result.Error
	}

	fmt.Printf("Found admin user: ID=%d, Username=%s\n", adminUser.ID, adminUser.Username)

	// 2. 创建或获取admin角色
	var adminRole models.Role
	result = db.Where("name = ?", "admin").First(&adminRole)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			// 创建admin角色
			adminRole = models.Role{
				Name:        "admin",
				Description: "系统管理员",
			}
			if err := db.Create(&adminRole).Error; err != nil {
				return fmt.Errorf("failed to create admin role: %v", err)
			}
			fmt.Printf("Created admin role: ID=%d\n", adminRole.ID)
		} else {
			return result.Error
		}
	} else {
		fmt.Printf("Found admin role: ID=%d, Name=%s\n", adminRole.ID, adminRole.Name)
	}

	// 3. 创建必要的权限
	permissions := []models.Permission{
		// 系统权限
		{Resource: "system", Action: "admin", Scope: "all"},
		// 文件权限
		{Resource: "files", Action: "read", Scope: "all"},
		{Resource: "files", Action: "write", Scope: "all"},
		{Resource: "files", Action: "delete", Scope: "all"},
		// 记录权限
		{Resource: "records", Action: "read", Scope: "all"},
		{Resource: "records", Action: "write", Scope: "all"},
		{Resource: "records", Action: "delete", Scope: "all"},
		// 用户权限
		{Resource: "users", Action: "read", Scope: "all"},
		{Resource: "users", Action: "write", Scope: "all"},
		// 角色权限
		{Resource: "roles", Action: "read", Scope: "all"},
		{Resource: "roles", Action: "write", Scope: "all"},
		// 权限管理权限
		{Resource: "permissions", Action: "read", Scope: "all"},
		{Resource: "permissions", Action: "write", Scope: "all"},
		// 导出权限
		{Resource: "export", Action: "read", Scope: "all"},
		{Resource: "export", Action: "write", Scope: "all"},
		{Resource: "export", Action: "delete", Scope: "all"},
	}

	for i := range permissions {
		var existingPerm models.Permission
		result := db.Where("resource = ? AND action = ? AND scope = ?", permissions[i].Resource, permissions[i].Action, permissions[i].Scope).First(&existingPerm)
		if result.Error != nil {
			if result.Error == gorm.ErrRecordNotFound {
				if err := db.Create(&permissions[i]).Error; err != nil {
					return fmt.Errorf("failed to create permission %s:%s:%s: %v", permissions[i].Resource, permissions[i].Action, permissions[i].Scope, err)
				}
				fmt.Printf("Created permission: %s:%s:%s (ID=%d)\n", permissions[i].Resource, permissions[i].Action, permissions[i].Scope, permissions[i].ID)
			} else {
				return result.Error
			}
		} else {
			permissions[i].ID = existingPerm.ID
			fmt.Printf("Found existing permission: %s:%s:%s (ID=%d)\n", permissions[i].Resource, permissions[i].Action, permissions[i].Scope, permissions[i].ID)
		}
	}

	// 4. 将权限分配给admin角色
	for _, perm := range permissions {
		var rolePermission models.RolePermission
		result := db.Where("role_id = ? AND permission_id = ?", adminRole.ID, perm.ID).First(&rolePermission)
		if result.Error != nil {
			if result.Error == gorm.ErrRecordNotFound {
				rolePermission = models.RolePermission{
					RoleID:       adminRole.ID,
					PermissionID: perm.ID,
				}
				if err := db.Create(&rolePermission).Error; err != nil {
					return fmt.Errorf("failed to assign permission %d to role %d: %v", perm.ID, adminRole.ID, err)
				}
				fmt.Printf("Assigned permission %s:%s:%s to admin role\n", perm.Resource, perm.Action, perm.Scope)
			} else {
				return result.Error
			}
		}
	}

	// 5. 将admin角色分配给admin用户
	var userRole models.UserRole
	result = db.Where("user_id = ? AND role_id = ?", adminUser.ID, adminRole.ID).First(&userRole)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			userRole = models.UserRole{
				UserID: adminUser.ID,
				RoleID: adminRole.ID,
			}
			if err := db.Create(&userRole).Error; err != nil {
				return fmt.Errorf("failed to assign admin role to admin user: %v", err)
			}
			fmt.Printf("Assigned admin role to admin user\n")
		} else {
			return result.Error
		}
	} else {
		fmt.Printf("Admin user already has admin role\n")
	}

	return nil
}