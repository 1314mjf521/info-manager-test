package config

import (
	"fmt"
	"strings"

	"github.com/spf13/viper"
)

// Config 应用配置结构
type Config struct {
	Server   ServerConfig   `mapstructure:"server"`
	Database DatabaseConfig `mapstructure:"database"`
	Redis    RedisConfig    `mapstructure:"redis"`
	JWT      JWTConfig      `mapstructure:"jwt"`
	Log      LogConfig      `mapstructure:"log"`
}

// ServerConfig 服务器配置
type ServerConfig struct {
	Port string `mapstructure:"port"`
	Mode string `mapstructure:"mode"` // debug, release
}

// DatabaseConfig 数据库配置
type DatabaseConfig struct {
	Driver string       `mapstructure:"driver"` // postgres, mysql, sqlite
	SQLite SQLiteConfig `mapstructure:"sqlite"`
	MySQL  MySQLConfig  `mapstructure:"mysql"`

	// 兼容旧配置
	Type     string `mapstructure:"type"` // postgres, mysql, sqlite
	Host     string `mapstructure:"host"`
	Port     string `mapstructure:"port"`
	Username string `mapstructure:"username"`
	Password string `mapstructure:"password"`
	Database string `mapstructure:"database"`
	SSLMode  string `mapstructure:"ssl_mode"`
}

// SQLiteConfig SQLite配置
type SQLiteConfig struct {
	Path            string `mapstructure:"path"`
	JournalMode     string `mapstructure:"journal_mode"`
	BusyTimeout     int    `mapstructure:"busy_timeout"`
	CacheSize       int    `mapstructure:"cache_size"`
	PageSize        int    `mapstructure:"page_size"`
	Synchronous     string `mapstructure:"synchronous"`
	TempStore       string `mapstructure:"temp_store"`
	MaxOpenConns    int    `mapstructure:"max_open_conns"`
	MaxIdleConns    int    `mapstructure:"max_idle_conns"`
	ConnMaxLifetime string `mapstructure:"conn_max_lifetime"`
	ConnMaxIdleTime string `mapstructure:"conn_max_idle_time"`
}

// MySQLConfig MySQL配置
type MySQLConfig struct {
	Host     string `mapstructure:"host"`
	Port     string `mapstructure:"port"`
	Username string `mapstructure:"username"`
	Password string `mapstructure:"password"`
	Database string `mapstructure:"database"`
	Charset  string `mapstructure:"charset"`
}

// RedisConfig Redis配置
type RedisConfig struct {
	Host     string `mapstructure:"host"`
	Port     string `mapstructure:"port"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
}

// JWTConfig JWT配置
type JWTConfig struct {
	Secret     string `mapstructure:"secret"`
	ExpireTime int    `mapstructure:"expire_time"` // 小时
}

// LogConfig 日志配置
type LogConfig struct {
	Level  string `mapstructure:"level"`  // debug, info, warn, error
	Format string `mapstructure:"format"` // json, text
}

// Load 加载配置
func Load() (*Config, error) {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./configs")
	viper.AddConfigPath(".")

	// 设置环境变量前缀
	viper.SetEnvPrefix("IMS")
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	// 设置默认值
	setDefaults()

	// 读取配置文件
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("failed to read config file: %w", err)
		}
	}

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	return &config, nil
}

// setDefaults 设置默认配置值
func setDefaults() {
	// 服务器默认配置
	viper.SetDefault("server.port", "8080")
	viper.SetDefault("server.mode", "debug")

	// 数据库默认配置
	viper.SetDefault("database.type", "sqlite")
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", "5432")
	viper.SetDefault("database.database", "info_system.db")
	viper.SetDefault("database.ssl_mode", "disable")

	// Redis默认配置
	viper.SetDefault("redis.host", "localhost")
	viper.SetDefault("redis.port", "6379")
	viper.SetDefault("redis.db", 0)

	// JWT默认配置
	viper.SetDefault("jwt.secret", "your-secret-key-change-in-production")
	viper.SetDefault("jwt.expire_time", 24)

	// 日志默认配置
	viper.SetDefault("log.level", "info")
	viper.SetDefault("log.format", "json")
}

// GetDSN 获取数据库连接字符串
func (c *DatabaseConfig) GetDSN() string {
	// 优先使用新的配置格式
	driver := c.Driver
	if driver == "" {
		driver = c.Type // 兼容旧配置
	}

	switch driver {
	case "postgres":
		return fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
			c.Host, c.Port, c.Username, c.Password, c.Database, c.SSLMode)
	case "mysql":
		if c.MySQL.Host != "" {
			// 使用新配置格式
			charset := c.MySQL.Charset
			if charset == "" {
				charset = "utf8mb4"
			}
			return fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=%s&parseTime=True&loc=Local",
				c.MySQL.Username, c.MySQL.Password, c.MySQL.Host, c.MySQL.Port, c.MySQL.Database, charset)
		}
		// 兼容旧配置格式
		return fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
			c.Username, c.Password, c.Host, c.Port, c.Database)
	case "sqlite":
		if c.SQLite.Path != "" {
			// 使用新配置格式
			return c.SQLite.Path
		}
		// 兼容旧配置格式
		return c.Database
	default:
		return ""
	}
}

// GetDriver 获取数据库驱动名称
func (c *DatabaseConfig) GetDriver() string {
	driver := c.Driver
	if driver == "" {
		driver = c.Type // 兼容旧配置
	}
	return driver
}
