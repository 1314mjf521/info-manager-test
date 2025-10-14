package database

import (
	"testing"

	"info-management-system/internal/config"

	"github.com/stretchr/testify/assert"
)

func TestConnect(t *testing.T) {
	// 跳过需要CGO的SQLite测试
	t.Skip("Skipping SQLite test - requires CGO which is not available in this environment")
}

func TestConnect_UnsupportedDatabase(t *testing.T) {
	cfg := &config.DatabaseConfig{
		Type: "unsupported",
	}

	err := Connect(cfg)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "unsupported database type")
}

func TestHealthCheck_NilDB(t *testing.T) {
	// 保存原始DB
	originalDB := DB
	defer func() {
		DB = originalDB
	}()

	// 设置DB为nil
	DB = nil

	err := HealthCheck()
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "database connection is nil")
}
