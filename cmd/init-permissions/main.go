package main

import (
	"fmt"
	"log"
	"os"

	"info-management-system/internal/config"
	"info-management-system/internal/database"
	"info-management-system/internal/services"
)

func main() {
	// 加载配置
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// 连接数据库
	if err := database.Connect(&cfg.Database); err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// 执行数据库迁移
	if err := database.Migrate(database.GetDB()); err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	// 初始化权限服务
	permissionService := services.NewPermissionService(database.GetDB())

	// 初始化精细化权限数据
	fmt.Println("开始初始化精细化权限数据...")
	if err := permissionService.InitializeDetailedPermissions(); err != nil {
		log.Fatalf("Failed to initialize permissions: %v", err)
	}

	fmt.Println("权限数据初始化完成！")
	
	// 验证权限数据
	permissions, err := permissionService.GetAllPermissions()
	if err != nil {
		log.Fatalf("Failed to get permissions: %v", err)
	}

	fmt.Printf("总共初始化了 %d 个权限\n", len(permissions))
	
	// 按模块统计权限
	moduleCount := make(map[string]int)
	for _, perm := range permissions {
		moduleCount[perm.Resource]++
	}

	fmt.Println("\n各模块权限统计:")
	for module, count := range moduleCount {
		fmt.Printf("- %s: %d 个权限\n", module, count)
	}

	os.Exit(0)
}