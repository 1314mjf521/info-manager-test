package logger

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	"github.com/sirupsen/logrus"
	"gopkg.in/natefinch/lumberjack.v2"
)

// LogConfig 日志配置
type LogConfig struct {
	Level      string `json:"level" yaml:"level"`           // 日志级别
	Format     string `json:"format" yaml:"format"`         // 日志格式 (json/text)
	Output     string `json:"output" yaml:"output"`         // 输出方式 (stdout/file/both)
	FilePath   string `json:"file_path" yaml:"file_path"`   // 日志文件路径
	MaxSize    int    `json:"max_size" yaml:"max_size"`     // 单个日志文件最大大小(MB)
	MaxBackups int    `json:"max_backups" yaml:"max_backups"` // 保留的旧日志文件数量
	MaxAge     int    `json:"max_age" yaml:"max_age"`       // 日志文件保留天数
	Compress   bool   `json:"compress" yaml:"compress"`     // 是否压缩旧日志文件
}

// Logger 日志管理器
type Logger struct {
	*logrus.Logger
	config *LogConfig
}

// NewLogger 创建新的日志管理器
func NewLogger(config *LogConfig) (*Logger, error) {
	logger := logrus.New()

	// 设置日志级别
	level, err := logrus.ParseLevel(config.Level)
	if err != nil {
		return nil, fmt.Errorf("invalid log level %s: %w", config.Level, err)
	}
	logger.SetLevel(level)

	// 设置日志格式
	if config.Format == "json" {
		logger.SetFormatter(&logrus.JSONFormatter{
			TimestampFormat: time.RFC3339,
			FieldMap: logrus.FieldMap{
				logrus.FieldKeyTime:  "timestamp",
				logrus.FieldKeyLevel: "level",
				logrus.FieldKeyMsg:   "message",
				logrus.FieldKeyFunc:  "function",
				logrus.FieldKeyFile:  "file",
			},
		})
	} else {
		logger.SetFormatter(&logrus.TextFormatter{
			FullTimestamp:   true,
			TimestampFormat: "2006-01-02 15:04:05",
			ForceColors:     true,
		})
	}

	// 设置输出
	if err := setupOutput(logger, config); err != nil {
		return nil, fmt.Errorf("failed to setup logger output: %w", err)
	}

	return &Logger{
		Logger: logger,
		config: config,
	}, nil
}

// setupOutput 设置日志输出
func setupOutput(logger *logrus.Logger, config *LogConfig) error {
	switch config.Output {
	case "stdout":
		logger.SetOutput(os.Stdout)
	case "file":
		fileWriter, err := createFileWriter(config)
		if err != nil {
			return err
		}
		logger.SetOutput(fileWriter)
	case "both":
		fileWriter, err := createFileWriter(config)
		if err != nil {
			return err
		}
		multiWriter := io.MultiWriter(os.Stdout, fileWriter)
		logger.SetOutput(multiWriter)
	default:
		logger.SetOutput(os.Stdout)
	}
	return nil
}

// createFileWriter 创建文件写入器
func createFileWriter(config *LogConfig) (io.Writer, error) {
	// 确保日志目录存在
	logDir := filepath.Dir(config.FilePath)
	if err := os.MkdirAll(logDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create log directory %s: %w", logDir, err)
	}

	// 创建日志轮转写入器
	return &lumberjack.Logger{
		Filename:   config.FilePath,
		MaxSize:    config.MaxSize,    // MB
		MaxBackups: config.MaxBackups, // 保留文件数
		MaxAge:     config.MaxAge,     // 天数
		Compress:   config.Compress,   // 压缩
		LocalTime:  true,              // 使用本地时间
	}, nil
}

// WithFields 添加字段
func (l *Logger) WithFields(fields logrus.Fields) *logrus.Entry {
	return l.Logger.WithFields(fields)
}

// WithField 添加单个字段
func (l *Logger) WithField(key string, value interface{}) *logrus.Entry {
	return l.Logger.WithField(key, value)
}

// WithError 添加错误字段
func (l *Logger) WithError(err error) *logrus.Entry {
	return l.Logger.WithError(err)
}

// WithContext 添加上下文信息
func (l *Logger) WithContext(userID uint, action string, resource string) *logrus.Entry {
	return l.Logger.WithFields(logrus.Fields{
		"user_id":  userID,
		"action":   action,
		"resource": resource,
	})
}

// LogRequest 记录请求日志
func (l *Logger) LogRequest(method, path, userAgent, clientIP string, userID uint, statusCode int, duration time.Duration) {
	l.Logger.WithFields(logrus.Fields{
		"type":        "request",
		"method":      method,
		"path":        path,
		"user_agent":  userAgent,
		"client_ip":   clientIP,
		"user_id":     userID,
		"status_code": statusCode,
		"duration_ms": duration.Milliseconds(),
	}).Info("HTTP Request")
}

// LogAuth 记录认证日志
func (l *Logger) LogAuth(action string, userID uint, username string, clientIP string, success bool, reason string) {
	entry := l.Logger.WithFields(logrus.Fields{
		"type":      "auth",
		"action":    action,
		"user_id":   userID,
		"username":  username,
		"client_ip": clientIP,
		"success":   success,
	})

	if reason != "" {
		entry = entry.WithField("reason", reason)
	}

	if success {
		entry.Info("Authentication Success")
	} else {
		entry.Warn("Authentication Failed")
	}
}

// LogOperation 记录操作日志
func (l *Logger) LogOperation(userID uint, action string, resource string, resourceID interface{}, details map[string]interface{}) {
	fields := logrus.Fields{
		"type":        "operation",
		"user_id":     userID,
		"action":      action,
		"resource":    resource,
		"resource_id": resourceID,
	}

	// 添加详细信息
	for k, v := range details {
		fields[k] = v
	}

	l.Logger.WithFields(fields).Info("User Operation")
}

// LogError 记录错误日志
func (l *Logger) LogError(err error, context map[string]interface{}) {
	entry := l.Logger.WithError(err).WithFields(logrus.Fields{
		"type": "error",
	})

	// 添加上下文信息
	for k, v := range context {
		entry = entry.WithField(k, v)
	}

	entry.Error("System Error")
}

// LogSecurity 记录安全日志
func (l *Logger) LogSecurity(event string, userID uint, clientIP string, details map[string]interface{}) {
	fields := logrus.Fields{
		"type":      "security",
		"event":     event,
		"user_id":   userID,
		"client_ip": clientIP,
	}

	// 添加详细信息
	for k, v := range details {
		fields[k] = v
	}

	l.Logger.WithFields(fields).Warn("Security Event")
}

// LogPerformance 记录性能日志
func (l *Logger) LogPerformance(operation string, duration time.Duration, details map[string]interface{}) {
	fields := logrus.Fields{
		"type":        "performance",
		"operation":   operation,
		"duration_ms": duration.Milliseconds(),
	}

	// 添加详细信息
	for k, v := range details {
		fields[k] = v
	}

	level := logrus.InfoLevel
	if duration > 5*time.Second {
		level = logrus.WarnLevel
	} else if duration > 10*time.Second {
		level = logrus.ErrorLevel
	}

	l.Logger.WithFields(fields).Log(level, "Performance Metric")
}

// GetConfig 获取日志配置
func (l *Logger) GetConfig() *LogConfig {
	return l.config
}

// SetLevel 动态设置日志级别
func (l *Logger) SetLevel(level string) error {
	logLevel, err := logrus.ParseLevel(level)
	if err != nil {
		return fmt.Errorf("invalid log level %s: %w", level, err)
	}
	l.Logger.SetLevel(logLevel)
	l.config.Level = level
	return nil
}