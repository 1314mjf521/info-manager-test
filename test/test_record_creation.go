package main

import (
	"fmt"
	"log"

	"info-management-system/internal/config"
	"info-management-system/internal/database"
	"info-management-system/internal/models"
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
	defer database.Close()

	db := database.GetDB()

	fmt.Println("Connected to MySQL successfully!")

	// 测试查询现有记录类型
	var recordTypes []models.RecordType
	if err := db.Find(&recordTypes).Error; err != nil {
		log.Fatalf("Failed to query record types: %v", err)
	}

	fmt.Printf("Found %d record types:\n", len(recordTypes))
	for _, rt := range recordTypes {
		fmt.Printf("- %s: %s (Active: %v)\n", rt.Name, rt.DisplayName, rt.IsActive)
	}

	if len(recordTypes) == 0 {
		fmt.Println("No record types found, cannot test record creation")
		return
	}

	// 使用第一个记录类型创建测试记录
	recordType := recordTypes[0]
	
	// 创建测试记录
	testRecord := models.Record{
		Type:      recordType.Name,
		Title:     "MySQL Test Record",
		Content:   models.JSONB{"description": "Testing MySQL database integration", "test": true},
		Tags:      models.StringSlice{"mysql", "test"},
		CreatedBy: 1, // 假设admin用户ID为1
		Version:   1,
	}

	fmt.Printf("Creating test record with type: %s\n", recordType.Name)
	
	if err := db.Create(&testRecord).Error; err != nil {
		log.Fatalf("Failed to create test record: %v", err)
	}

	fmt.Printf("✓ Test record created successfully with ID: %d\n", testRecord.ID)

	// 查询刚创建的记录
	var createdRecord models.Record
	if err := db.Preload("Creator").First(&createdRecord, testRecord.ID).Error; err != nil {
		log.Printf("Warning: Failed to query created record: %v", err)
	} else {
		fmt.Printf("✓ Record retrieved: %s (ID: %d)\n", createdRecord.Title, createdRecord.ID)
	}

	fmt.Println("MySQL record creation test completed successfully!")
}