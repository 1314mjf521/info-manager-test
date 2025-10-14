package main

import (
	"fmt"
	"log"

	"info-management-system/internal/config"
	"info-management-system/internal/database"
)

func main() {
	// 加载配置
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	fmt.Printf("Database config: Type=%s, Host=%s, Port=%s, Database=%s\n", 
		cfg.Database.Type, cfg.Database.Host, cfg.Database.Port, cfg.Database.Database)
	
	// 连接数据库
	if err := database.Connect(&cfg.Database); err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer database.Close()

	// 测试连接
	if err := database.HealthCheck(); err != nil {
		log.Fatalf("Database health check failed: %v", err)
	}

	fmt.Println("MySQL connection successful!")
}