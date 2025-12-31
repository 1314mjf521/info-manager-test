package main

import (
	"fmt"
	"log"

	"github.com/glebarez/sqlite"
	"gorm.io/gorm"
)

type Permission struct {
	ID          uint   `gorm:"primaryKey"`
	Name        string `gorm:"uniqueIndex;not null"`
	DisplayName string `gorm:"not null"`
	Resource    string `gorm:"index;not null"`
	Action      string `gorm:"not null"`
}

func main() {
	// 连接数据库
	db, err := gorm.Open(sqlite.Open("build/info_system.db"), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// 查询admin用户的所有权限
	var permissions []Permission
	result := db.Find(&permissions)
	if result.Error != nil {
		log.Fatal("Failed to query permissions:", result.Error)
	}

	fmt.Printf("Total permissions in database: %d\n", len(permissions))

	// 查询admin角色的权限
	type RolePermission struct {
		RoleID       uint `gorm:"primaryKey"`
		PermissionID uint `gorm:"primaryKey"`
	}

	var rolePerms []RolePermission
	result = db.Where("role_id = ?", 1).Find(&rolePerms)
	if result.Error != nil {
		log.Fatal("Failed to query role permissions:", result.Error)
	}

	fmt.Printf("\nAdmin role has %d permissions\n", len(rolePerms))
	
	// 检查admin用户的具体权限
	fmt.Printf("\nAdmin user permissions:\n")
	adminPermCount := 0
	systemPermCount := 0
	recordsPermCount := 0
	
	for _, rp := range rolePerms {
		for _, perm := range permissions {
			if rp.PermissionID == perm.ID {
				adminPermCount++
				if perm.Resource == "system" {
					systemPermCount++
					fmt.Printf("System permission: %s (ID: %d, Action: %s)\n", perm.Name, perm.ID, perm.Action)
				}
				if perm.Resource == "records" {
					recordsPermCount++
					if recordsPermCount <= 5 { // 只显示前5个记录权限
						fmt.Printf("Records permission: %s (ID: %d, Action: %s)\n", perm.Name, perm.ID, perm.Action)
					}
				}
			}
		}
	}
	
	fmt.Printf("\nSummary:\n")
	fmt.Printf("Admin has %d total permissions\n", adminPermCount)
	fmt.Printf("Admin has %d system permissions\n", systemPermCount)
	fmt.Printf("Admin has %d records permissions\n", recordsPermCount)
}