package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/go-sql-driver/mysql"
)

func main() {
	// 连接到MySQL服务器（不指定数据库）
	dsn := "manger_info:yFZaM4fkBCKfYM2w@tcp(192.168.100.16:3308)/"
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		log.Fatalf("Failed to connect to MySQL: %v", err)
	}
	defer db.Close()

	// 测试连接
	if err := db.Ping(); err != nil {
		log.Fatalf("Failed to ping MySQL: %v", err)
	}

	fmt.Println("Connected to MySQL server successfully!")

	// 查看所有数据库
	rows, err := db.Query("SHOW DATABASES")
	if err != nil {
		log.Fatalf("Failed to show databases: %v", err)
	}
	defer rows.Close()

	fmt.Println("Available databases:")
	for rows.Next() {
		var dbName string
		if err := rows.Scan(&dbName); err != nil {
			log.Printf("Error scanning database name: %v", err)
			continue
		}
		fmt.Printf("- %s\n", dbName)
	}

	// 尝试创建数据库
	fmt.Println("\nTrying to create database 'info_system'...")
	_, err = db.Exec("CREATE DATABASE IF NOT EXISTS info_system")
	if err != nil {
		log.Printf("Failed to create database: %v", err)
	} else {
		fmt.Println("Database 'info_system' created or already exists!")
	}
}