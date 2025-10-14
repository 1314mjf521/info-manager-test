package main

import (
	"fmt"
	"log"

	"info-management-system/internal/config"
	"info-management-system/internal/database"
	"info-management-system/internal/models"
)

func main() {
	fmt.Println("🚀 验证项目基础设施...")

	// 1. 验证配置加载
	fmt.Println("📋 验证配置加载...")
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("❌ 配置加载失败: %v", err)
	}
	fmt.Printf("✅ 配置加载成功 - 服务器端口: %s, 数据库类型: %s\n", cfg.Server.Port, cfg.Database.Type)

	// 2. 验证数据库连接
	fmt.Println("🗄️ 验证数据库连接...")
	err = database.Connect(&cfg.Database)
	if err != nil {
		log.Fatalf("❌ 数据库连接失败: %v", err)
	}
	fmt.Println("✅ 数据库连接成功")

	// 3. 验证数据库健康检查
	fmt.Println("🏥 验证数据库健康检查...")
	err = database.HealthCheck()
	if err != nil {
		log.Fatalf("❌ 数据库健康检查失败: %v", err)
	}
	fmt.Println("✅ 数据库健康检查通过")

	// 4. 验证数据库迁移
	fmt.Println("🔄 验证数据库迁移...")
	err = database.Migrate(database.GetDB())
	if err != nil {
		log.Fatalf("❌ 数据库迁移失败: %v", err)
	}
	fmt.Println("✅ 数据库迁移成功")

	// 5. 验证用户模型功能
	fmt.Println("👤 验证用户模型功能...")
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

	// 6. 验证数据库操作
	fmt.Println("💾 验证数据库操作...")
	db := database.GetDB()

	// 创建测试用户
	result := db.Create(testUser)
	if result.Error != nil {
		log.Fatalf("❌ 用户创建失败: %v", result.Error)
	}

	// 查询测试用户
	var foundUser models.User
	result = db.Where("username = ?", "testuser").First(&foundUser)
	if result.Error != nil {
		log.Fatalf("❌ 用户查询失败: %v", result.Error)
	}

	if foundUser.Username != "testuser" {
		log.Fatalf("❌ 用户数据不匹配")
	}

	// 清理测试数据
	db.Delete(&foundUser)
	fmt.Println("✅ 数据库操作正常")

	// 7. 关闭数据库连接
	fmt.Println("🔒 关闭数据库连接...")
	err = database.Close()
	if err != nil {
		log.Printf("⚠️ 数据库关闭警告: %v", err)
	} else {
		fmt.Println("✅ 数据库连接已关闭")
	}

	fmt.Println("\n🎉 所有验证通过！项目基础设施搭建成功！")
	fmt.Println("\n📝 下一步:")
	fmt.Println("   1. 运行 'make dev' 启动开发服务器")
	fmt.Println("   2. 访问 http://localhost:8080/health 检查服务状态")
	fmt.Println("   3. 开始实现具体的API接口")
}
