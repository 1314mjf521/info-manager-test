package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"gorm.io/gorm"
)

// WechatService 企业微信服务
type WechatService struct {
	db *gorm.DB
}

// NewWechatService 创建企业微信服务
func NewWechatService(db *gorm.DB) *WechatService {
	return &WechatService{
		db: db,
	}
}

// WechatWebhookConfig 企业微信Webhook配置
type WechatWebhookConfig struct {
	WebhookURL string `json:"webhook_url"`
	Token      string `json:"token"`
}

// WechatMessage 企业微信消息结构
type WechatMessage struct {
	MsgType  string                 `json:"msgtype"`
	Markdown *WechatMarkdownMessage `json:"markdown,omitempty"`
	Text     *WechatTextMessage     `json:"text,omitempty"`
}

// WechatMarkdownMessage Markdown消息
type WechatMarkdownMessage struct {
	Content string `json:"content"`
}

// WechatTextMessage 文本消息
type WechatTextMessage struct {
	Content             string   `json:"content"`
	MentionedList       []string `json:"mentioned_list,omitempty"`
	MentionedMobileList []string `json:"mentioned_mobile_list,omitempty"`
}

// WechatResponse 企业微信API响应
type WechatResponse struct {
	ErrCode int    `json:"errcode"`
	ErrMsg  string `json:"errmsg"`
}

// SendWebhookMessage 发送企业微信Webhook消息
func (w *WechatService) SendWebhookMessage(webhookURL, content string, msgType string) error {
	if webhookURL == "" {
		return fmt.Errorf("企业微信Webhook URL不能为空")
	}

	var message WechatMessage

	switch msgType {
	case "markdown":
		message = WechatMessage{
			MsgType: "markdown",
			Markdown: &WechatMarkdownMessage{
				Content: content,
			},
		}
	case "text":
		message = WechatMessage{
			MsgType: "text",
			Text: &WechatTextMessage{
				Content: content,
			},
		}
	default:
		// 默认使用markdown格式
		message = WechatMessage{
			MsgType: "markdown",
			Markdown: &WechatMarkdownMessage{
				Content: content,
			},
		}
	}

	// 序列化消息
	messageJSON, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("序列化消息失败: %v", err)
	}

	// 发送HTTP请求
	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	req, err := http.NewRequest("POST", webhookURL, bytes.NewBuffer(messageJSON))
	if err != nil {
		return fmt.Errorf("创建请求失败: %v", err)
	}

	req.Header.Set("Content-Type", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("发送请求失败: %v", err)
	}
	defer resp.Body.Close()

	// 读取响应
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("读取响应失败: %v", err)
	}

	// 解析响应
	var wechatResp WechatResponse
	if err := json.Unmarshal(body, &wechatResp); err != nil {
		return fmt.Errorf("解析响应失败: %v", err)
	}

	// 检查响应状态
	if wechatResp.ErrCode != 0 {
		return fmt.Errorf("企业微信API错误: %s (错误码: %d)", wechatResp.ErrMsg, wechatResp.ErrCode)
	}

	return nil
}

// SendZabbixAlert 发送Zabbix告警到企业微信
func (w *WechatService) SendZabbixAlert(webhookURL, token, subject, message string) error {
	// 构建企业微信消息内容
	content := w.buildZabbixAlertContent(subject, message)
	
	// 构建完整的Webhook URL
	fullURL := fmt.Sprintf("%s?key=%s", webhookURL, token)
	
	return w.SendWebhookMessage(fullURL, content, "markdown")
}

// buildZabbixAlertContent 构建Zabbix告警内容
func (w *WechatService) buildZabbixAlertContent(subject, message string) string {
	// 获取当前时间
	now := time.Now().Format("2006-01-02 15:04:05")
	
	// 构建Markdown格式的消息
	content := fmt.Sprintf(`## 🚨 Zabbix告警通知

**告警标题:** %s

**告警内容:**
%s

**告警时间:** %s

---
*来自信息管理系统*`, subject, message, now)

	return content
}

// SendTicketNotification 发送工单通知到企业微信
func (w *WechatService) SendTicketNotification(webhookURL, token string, ticketID uint, title, action, description string) error {
	content := w.buildTicketNotificationContent(ticketID, title, action, description)
	
	// 构建完整的Webhook URL
	fullURL := fmt.Sprintf("%s?key=%s", webhookURL, token)
	
	return w.SendWebhookMessage(fullURL, content, "markdown")
}

// buildTicketNotificationContent 构建工单通知内容
func (w *WechatService) buildTicketNotificationContent(ticketID uint, title, action, description string) string {
	now := time.Now().Format("2006-01-02 15:04:05")
	
	var emoji string
	var actionText string
	
	switch action {
	case "created":
		emoji = "📝"
		actionText = "新工单创建"
	case "assigned":
		emoji = "👤"
		actionText = "工单已分配"
	case "status_changed":
		emoji = "🔄"
		actionText = "工单状态变更"
	case "updated":
		emoji = "✏️"
		actionText = "工单已更新"
	case "commented":
		emoji = "💬"
		actionText = "工单新评论"
	default:
		emoji = "📋"
		actionText = "工单通知"
	}
	
	content := fmt.Sprintf(`## %s %s

**工单ID:** #%d
**工单标题:** %s

**变更说明:**
%s

**通知时间:** %s

---
*来自信息管理系统*`, emoji, actionText, ticketID, title, description, now)

	return content
}

// SendSystemNotification 发送系统通知到企业微信
func (w *WechatService) SendSystemNotification(webhookURL, token, title, content string, notificationType string) error {
	messageContent := w.buildSystemNotificationContent(title, content, notificationType)
	
	// 构建完整的Webhook URL
	fullURL := fmt.Sprintf("%s?key=%s", webhookURL, token)
	
	return w.SendWebhookMessage(fullURL, messageContent, "markdown")
}

// buildSystemNotificationContent 构建系统通知内容
func (w *WechatService) buildSystemNotificationContent(title, content, notificationType string) string {
	now := time.Now().Format("2006-01-02 15:04:05")
	
	var emoji string
	switch notificationType {
	case "info":
		emoji = "ℹ️"
	case "warning":
		emoji = "⚠️"
	case "error":
		emoji = "❌"
	case "success":
		emoji = "✅"
	default:
		emoji = "📢"
	}
	
	messageContent := fmt.Sprintf(`## %s %s

%s

**通知时间:** %s

---
*来自信息管理系统*`, emoji, title, content, now)

	return messageContent
}

// TestWebhookConnection 测试企业微信Webhook连接
func (w *WechatService) TestWebhookConnection(webhookURL, token string) error {
	content := w.buildTestMessage()
	
	// 构建完整的Webhook URL
	fullURL := fmt.Sprintf("%s?key=%s", webhookURL, token)
	
	return w.SendWebhookMessage(fullURL, content, "markdown")
}

// buildTestMessage 构建测试消息
func (w *WechatService) buildTestMessage() string {
	now := time.Now().Format("2006-01-02 15:04:05")
	
	content := fmt.Sprintf(`## 🧪 企业微信连接测试

**测试状态:** 连接成功 ✅

**测试时间:** %s

---
*来自信息管理系统 - 这是一条测试消息*`, now)

	return content
}

// FormatZabbixWebhookMessage 格式化Zabbix Webhook消息（兼容Zabbix脚本格式）
func (w *WechatService) FormatZabbixWebhookMessage(params map[string]interface{}) error {
	// 解析参数
	token, ok := params["Token"].(string)
	if !ok || token == "" {
		return fmt.Errorf("Token参数缺失或无效")
	}
	
	to, ok := params["To"].(string)
	if !ok || to == "" {
		return fmt.Errorf("To参数缺失或无效")
	}
	
	subject, ok := params["Subject"].(string)
	if !ok {
		subject = "Zabbix告警"
	}
	
	message, ok := params["Message"].(string)
	if !ok {
		message = "无告警内容"
	}
	
	// 构建Webhook URL
	webhookURL := "https://qyapi.weixin.qq.com/cgi-bin/webhook/send"
	
	// 发送告警
	return w.SendZabbixAlert(webhookURL, token, subject, message)
}

// GetWechatConfig 获取企业微信配置
func (w *WechatService) GetWechatConfig() (*WechatWebhookConfig, error) {
	// 这里应该从数据库或配置文件中读取企业微信配置
	// 为了简化，返回默认配置结构
	config := &WechatWebhookConfig{
		WebhookURL: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send",
		Token:      "", // 需要从配置中读取
	}
	
	return config, nil
}

// SaveWechatConfig 保存企业微信配置
func (w *WechatService) SaveWechatConfig(config *WechatWebhookConfig) error {
	// 这里应该将配置保存到数据库或配置文件
	// 为了简化，这里只做验证
	if config.WebhookURL == "" {
		return fmt.Errorf("Webhook URL不能为空")
	}
	
	if config.Token == "" {
		return fmt.Errorf("Token不能为空")
	}
	
	// 测试连接
	if err := w.TestWebhookConnection(config.WebhookURL, config.Token); err != nil {
		return fmt.Errorf("企业微信连接测试失败: %v", err)
	}
	
	return nil
}