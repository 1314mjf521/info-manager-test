package main

import (
	"log"
	"os"

	"info-management-system/internal/app"
	"info-management-system/internal/config"
)

func main() {
	// 加载配置
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// 创建应用实例
	application, err := app.New(cfg)
	if err != nil {
		log.Fatalf("Failed to create application: %v", err)
	}

	// 启动服务器
	port := os.Getenv("PORT")
	if port == "" {
		port = cfg.Server.Port
	}

	log.Printf("Starting server on port %s", port)
	if err := application.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
