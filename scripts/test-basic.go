package main

import (
	"fmt"
	"log"

	"info-management-system/internal/config"
	"info-management-system/internal/models"
)

func main() {
	fmt.Println("🚀 测试项目基础设施...")

	// 1. 测试配置加载
	fmt.Println("📋 测试配置加载...")
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("❌ 配置加载失败: %v", err)
	}
	fmt.Printf("✅ 配置加载成功 - 服务器端口: %s, 数据库类型: %s\n", cfg.Server.Port, cfg.Database.Type)

	// 2. 测试用户模型功能
	fmt.Println("👤 测试用户模型功能...")
	testUser := &models.User{
		Username: "testuser",
		Email:    "test@example.com",
	}

	err = testUser.SetPassword("testpassword123")
	if err != nil {
		log.Fatalf("❌ 密码设置失败: %v", err)
	}

	if !testUser.CheckPassword("testpassword123") {
		log.Fatalf("❌ 密码验证失败")
	}
	fmt.Println("✅ 用户模型功能正常")

	// 3. 测试权限模型
	fmt.Println("🔐 测试权限模型...")
	role := &models.Role{
		Name:        "test_role",
		Description: "测试角色",
	}

	permission := &models.Permission{
		Resource: "test_resource",
		Action:   "read",
		Scope:    "own",
	}

	role.Permissions = []models.Permission{*permission}
	testUser.Roles = []models.Role{*role}

	if !testUser.HasPermission("test_resource", "read", "own") {
		log.Fatalf("❌ 权限检查失败")
	}
	fmt.Println("✅ 权限模型功能正常")

	fmt.Println("\n🎉 基础设施测试通过！")
	fmt.Println("\n📝 下一步:")
	fmt.Println("   1. 配置PostgreSQL或MySQL数据库")
	fmt.Println("   2. 运行 './build/server' 启动服务器")
	fmt.Println("   3. 访问 http://localhost:8080/health 检查服务状态")
}
