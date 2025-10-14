package utils

import (
	"fmt"
	"strings"

	"gorm.io/gorm"
)

// DatabaseType 数据库类型
type DatabaseType string

const (
	MySQL      DatabaseType = "mysql"
	PostgreSQL DatabaseType = "postgres"
	SQLite     DatabaseType = "sqlite"
)

// GetDatabaseType 获取数据库类型
func GetDatabaseType(db *gorm.DB) DatabaseType {
	dialectName := db.Dialector.Name()
	switch dialectName {
	case "mysql":
		return MySQL
	case "postgres":
		return PostgreSQL
	case "sqlite":
		return SQLite
	default:
		return SQLite // 默认使用SQLite
	}
}

// JSONContainsQuery 根据数据库类型生成JSON包含查询
func JSONContainsQuery(db *gorm.DB, column string, value interface{}) (string, interface{}) {
	dbType := GetDatabaseType(db)

	switch dbType {
	case MySQL:
		// MySQL使用JSON_CONTAINS函数
		return fmt.Sprintf("JSON_CONTAINS(%s, ?)", column), fmt.Sprintf(`"%v"`, value)
	case PostgreSQL:
		// PostgreSQL使用@>操作符
		return fmt.Sprintf("%s @> ?", column), fmt.Sprintf(`["%v"]`, value)
	case SQLite:
		// SQLite使用LIKE模糊匹配（因为SQLite的JSON支持有限）
		return fmt.Sprintf("%s LIKE ?", column), fmt.Sprintf(`%%"%v"%%`, value)
	default:
		// 默认使用LIKE
		return fmt.Sprintf("%s LIKE ?", column), fmt.Sprintf(`%%"%v"%%`, value)
	}
}

// JSONArrayContainsQuery 生成JSON数组包含查询的完整WHERE条件
func JSONArrayContainsQuery(db *gorm.DB, column string, value interface{}) (string, interface{}) {
	dbType := GetDatabaseType(db)

	switch dbType {
	case MySQL:
		// MySQL: column = '' OR column IS NULL OR JSON_CONTAINS(column, '"value"')
		query := fmt.Sprintf("%s = '' OR %s IS NULL OR JSON_CONTAINS(%s, ?)", column, column, column)
		return query, fmt.Sprintf(`"%v"`, value)
	case PostgreSQL:
		// PostgreSQL: column = '' OR column IS NULL OR column @> '["value"]'
		query := fmt.Sprintf("%s = '' OR %s IS NULL OR %s @> ?", column, column, column)
		return query, fmt.Sprintf(`["%v"]`, value)
	case SQLite:
		// SQLite: column = '' OR column IS NULL OR column LIKE '%"value"%'
		query := fmt.Sprintf("%s = '' OR %s IS NULL OR %s LIKE ?", column, column, column)
		return query, fmt.Sprintf(`%%"%v"%%`, value)
	default:
		// 默认使用LIKE
		query := fmt.Sprintf("%s = '' OR %s IS NULL OR %s LIKE ?", column, column, column)
		return query, fmt.Sprintf(`%%"%v"%%`, value)
	}
}

// BuildJSONQuery 构建JSON查询的辅助函数
func BuildJSONQuery(db *gorm.DB, baseQuery *gorm.DB, column string, value interface{}) *gorm.DB {
	query, param := JSONArrayContainsQuery(db, column, value)
	return baseQuery.Where(query, param)
}

// GetDatabaseInfo 获取数据库信息
func GetDatabaseInfo(db *gorm.DB) map[string]interface{} {
	dbType := GetDatabaseType(db)
	dialectName := db.Dialector.Name()

	info := map[string]interface{}{
		"type":    string(dbType),
		"dialect": dialectName,
	}

	// 获取数据库版本信息
	var version string
	switch dbType {
	case MySQL:
		db.Raw("SELECT VERSION()").Scan(&version)
	case PostgreSQL:
		db.Raw("SELECT version()").Scan(&version)
	case SQLite:
		db.Raw("SELECT sqlite_version()").Scan(&version)
	}

	if version != "" {
		info["version"] = version
	}

	return info
}

// IsJSONSupported 检查数据库是否支持原生JSON操作
func IsJSONSupported(db *gorm.DB) bool {
	dbType := GetDatabaseType(db)

	switch dbType {
	case MySQL:
		// MySQL 5.7+ 支持JSON
		var version string
		db.Raw("SELECT VERSION()").Scan(&version)
		// 简单检查，实际应该解析版本号
		return strings.Contains(version, "5.7") || strings.Contains(version, "8.0") ||
			!strings.Contains(version, "5.6") && !strings.Contains(version, "5.5")
	case PostgreSQL:
		// PostgreSQL 9.2+ 支持JSON
		return true
	case SQLite:
		// SQLite 3.38+ 有JSON支持，但功能有限
		var version string
		db.Raw("SELECT sqlite_version()").Scan(&version)
		// 对于兼容性，我们假设SQLite不完全支持复杂JSON操作
		return false
	default:
		return false
	}
}
