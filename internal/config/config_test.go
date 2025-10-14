package config

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestLoad(t *testing.T) {
	// 测试默认配置加载
	cfg, err := Load()
	assert.NoError(t, err)
	assert.NotNil(t, cfg)

	// 验证默认值
	assert.Equal(t, "8080", cfg.Server.Port)
	assert.Equal(t, "debug", cfg.Server.Mode)
	assert.Equal(t, "sqlite", cfg.Database.Type)
	assert.Equal(t, "info", cfg.Log.Level)
}

func TestLoadWithEnv(t *testing.T) {
	// 设置环境变量
	os.Setenv("IMS_SERVER_PORT", "9090")
	os.Setenv("IMS_DATABASE_TYPE", "postgres")
	defer func() {
		os.Unsetenv("IMS_SERVER_PORT")
		os.Unsetenv("IMS_DATABASE_TYPE")
	}()

	cfg, err := Load()
	assert.NoError(t, err)
	assert.NotNil(t, cfg)

	// 验证环境变量覆盖
	assert.Equal(t, "9090", cfg.Server.Port)
	assert.Equal(t, "postgres", cfg.Database.Type)
}

func TestDatabaseConfig_GetDSN(t *testing.T) {
	tests := []struct {
		name     string
		config   DatabaseConfig
		expected string
	}{
		{
			name: "PostgreSQL DSN",
			config: DatabaseConfig{
				Type:     "postgres",
				Host:     "localhost",
				Port:     "5432",
				Username: "user",
				Password: "pass",
				Database: "testdb",
				SSLMode:  "disable",
			},
			expected: "host=localhost port=5432 user=user password=pass dbname=testdb sslmode=disable",
		},
		{
			name: "MySQL DSN",
			config: DatabaseConfig{
				Type:     "mysql",
				Host:     "localhost",
				Port:     "3306",
				Username: "user",
				Password: "pass",
				Database: "testdb",
			},
			expected: "user:pass@tcp(localhost:3306)/testdb?charset=utf8mb4&parseTime=True&loc=Local",
		},
		{
			name: "SQLite DSN",
			config: DatabaseConfig{
				Type:     "sqlite",
				Database: "test.db",
			},
			expected: "test.db",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			dsn := tt.config.GetDSN()
			assert.Equal(t, tt.expected, dsn)
		})
	}
}
