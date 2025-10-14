package database

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"info-management-system/internal/config"

	"github.com/glebarez/sqlite"
	"gorm.io/driver/mysql"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// DB 数据库实例
var DB *gorm.DB

// Connect 连接数据库
func Connect(cfg *config.DatabaseConfig) error {
	var dialector gorm.Dialector
	dsn := cfg.GetDSN()

	driver := cfg.GetDriver()
	fmt.Printf("🔗 Connecting to %s database...\n", strings.ToUpper(driver))
	fmt.Printf("📍 Database DSN: %s\n", dsn)

	switch driver {
	case "postgres":
		dialector = postgres.Open(dsn)
	case "mysql":
		dialector = mysql.Open(dsn)
	case "sqlite":
		// 确保SQLite数据库文件的目录存在
		if err := ensureDir(dsn); err != nil {
			return fmt.Errorf("failed to create database directory: %w", err)
		}

		// 构建优化的SQLite DSN，使用配置参数
		sqliteConfig := cfg.SQLite
		optimizedDSN := buildSQLiteDSN(dsn, sqliteConfig)
		dialector = sqlite.Open(optimizedDSN)
	default:
		return fmt.Errorf("unsupported database type: %s (supported: postgres, mysql, sqlite)", driver)
	}

	// GORM配置
	gormConfig := &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	}

	var err error
	DB, err = gorm.Open(dialector, gormConfig)
	if err != nil {
		return fmt.Errorf("failed to connect to database: %w", err)
	}

	// 配置连接池
	sqlDB, err := DB.DB()
	if err != nil {
		return fmt.Errorf("failed to get database instance: %w", err)
	}

	// 根据数据库类型设置连接池参数
	if driver == "sqlite" {
		// SQLite推荐单连接，避免并发写入冲突
		maxOpenConns := 1
		maxIdleConns := 1
		connMaxLifetime := time.Hour
		connMaxIdleTime := 30 * time.Minute

		// 使用配置值覆盖默认值
		if cfg.SQLite.MaxOpenConns > 0 {
			maxOpenConns = cfg.SQLite.MaxOpenConns
		}
		if cfg.SQLite.MaxIdleConns > 0 {
			maxIdleConns = cfg.SQLite.MaxIdleConns
		}
		if cfg.SQLite.ConnMaxLifetime != "" {
			if duration, err := time.ParseDuration(cfg.SQLite.ConnMaxLifetime); err == nil {
				connMaxLifetime = duration
			}
		}
		if cfg.SQLite.ConnMaxIdleTime != "" {
			if duration, err := time.ParseDuration(cfg.SQLite.ConnMaxIdleTime); err == nil {
				connMaxIdleTime = duration
			}
		}

		sqlDB.SetMaxIdleConns(maxIdleConns)
		sqlDB.SetMaxOpenConns(maxOpenConns)
		sqlDB.SetConnMaxLifetime(connMaxLifetime)
		sqlDB.SetConnMaxIdleTime(connMaxIdleTime)
	} else {
		// 其他数据库使用标准连接池配置
		sqlDB.SetMaxIdleConns(10)
		sqlDB.SetMaxOpenConns(100)
		sqlDB.SetConnMaxLifetime(time.Hour)
	}

	fmt.Printf("✅ Successfully connected to %s database\n", strings.ToUpper(driver))
	return nil
}

// Close 关闭数据库连接
func Close() error {
	if DB != nil {
		sqlDB, err := DB.DB()
		if err != nil {
			return err
		}
		return sqlDB.Close()
	}
	return nil
}

// GetDB 获取数据库实例
func GetDB() *gorm.DB {
	return DB
}

// HealthCheck 数据库健康检查
func HealthCheck() error {
	if DB == nil {
		return fmt.Errorf("database connection is nil")
	}

	sqlDB, err := DB.DB()
	if err != nil {
		return fmt.Errorf("failed to get database instance: %w", err)
	}

	if err := sqlDB.Ping(); err != nil {
		return fmt.Errorf("database ping failed: %w", err)
	}

	return nil
}

// ensureDir 确保目录存在
func ensureDir(filePath string) error {
	dir := filepath.Dir(filePath)
	if dir == "." {
		return nil
	}

	if _, err := os.Stat(dir); os.IsNotExist(err) {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("failed to create directory %s: %w", dir, err)
		}
	}
	return nil
}

// buildSQLiteDSN 构建优化的SQLite DSN
func buildSQLiteDSN(path string, cfg config.SQLiteConfig) string {
	// 设置默认值
	journalMode := "WAL"
	busyTimeout := 30000
	cacheSize := -64000
	synchronous := "NORMAL"
	tempStore := "MEMORY"

	// 使用配置值覆盖默认值
	if cfg.JournalMode != "" {
		journalMode = cfg.JournalMode
	}
	if cfg.BusyTimeout > 0 {
		busyTimeout = cfg.BusyTimeout
	}
	if cfg.CacheSize != 0 {
		cacheSize = cfg.CacheSize
	}
	if cfg.Synchronous != "" {
		synchronous = cfg.Synchronous
	}
	if cfg.TempStore != "" {
		tempStore = cfg.TempStore
	}

	// 构建DSN
	dsn := fmt.Sprintf("%s?_journal_mode=%s&_busy_timeout=%d&_cache_size=%d&_synchronous=%s&_temp_store=%s",
		path, journalMode, busyTimeout, cacheSize, synchronous, tempStore)

	return dsn
}
