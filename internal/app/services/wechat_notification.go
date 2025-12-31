package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"gorm.io/gorm"

	"info-management-system/internal/models"
)

// WechatNotificationService 企业微信通知服务
type WechatNotificationService struct {
	db *gorm.DB
}

// NewWechatNotificationService 创建企业微信通知服务
func NewWechatNotificationService(db *gorm.DB) *WechatNotificationService {
	return &WechatNotificationService{db: db}
}

// WechatMessage 企业微信消息结构
type WechatMessage struct {
	MsgType  string           `json:"msgtype"`
	Markdown WechatMarkdown   `json:"markdown"`
}

// WechatMarkdown 企业微信Markdown消息
type WechatMarkdown struct {
	Content string `json:"content"`
}

// WechatResponse 企业微信响应
type WechatResponse struct {
	ErrCode int    `json:"errcode"`
	ErrMsg  string `json:"errmsg"`
}

// SendTicketNotification 发送工单通知
func (s *WechatNotificationService) SendTicketNotification(ticket *models.Ticket, action string, webhookURL string) error {
	content := s.buildTicketMessage(ticket, action)
	return s.sendMessage(content, webhookURL)
}

// SendZabbixAlert 发送Zabbix告警（兼容原有脚本）
func (s *WechatNotificationService) SendZabbixAlert(subject, message, webhookURL string) error {
	content := fmt.Sprintf("# %s\n\n%s", subject, message)
	return s.sendMessage(content, webhookURL)
}

// SendCustomNotification 发送自定义通知
func (s *WechatNotificationService) SendCustomNotification(title, content, webhookURL string) error {
	message := fmt.Sprintf("# %s\n\n%s", title, content)
	return s.sendMessage(message, webhookURL)
}

// buildTicketMessage 构建工单消息内容
func (s *WechatNotificationService) buildTicketMessage(ticket *models.Ticket, action string) string {
	var title string
	var color string
	
	switch action {
	case "created":
		title = "🎫 新工单创建"
		color = "info"
	case "assigned":
		title = "👤 工单已分配"
		color = "warning"
	case "status_changed":
		title = "🔄 工单状态变更"
		color = s.getStatusColor(ticket.Status)
	case "commented":
		title = "💬 工单新评论"
		color = "info"
	case "resolved":
		title = "✅ 工单已解决"
		color = "success"
	case "closed":
		title = "🔒 工单已关闭"
		color = "success"
	default:
		title = "📋 工单更新"
		color = "info"
	}

	priorityEmoji := s.getPriorityEmoji(ticket.Priority)
	statusEmoji := s.getStatusEmoji(ticket.Status)
	
	content := fmt.Sprintf(`%s

**工单信息：**
- 🆔 **工单ID：** #%d
- 📝 **标题：** %s
- 🏷️ **类型：** %s
- %s **优先级：** %s
- %s **状态：** %s
- 👤 **创建人：** %s`,
		title,
		ticket.ID,
		ticket.Title,
		s.getTypeDisplayName(ticket.Type),
		priorityEmoji,
		s.getPriorityDisplayName(ticket.Priority),
		statusEmoji,
		s.getStatusDisplayName(ticket.Status),
		ticket.Creator.DisplayName,
	)

	// 添加分配人信息
	if ticket.Assignee != nil {
		content += fmt.Sprintf("\n- 🎯 **分配给：** %s", ticket.Assignee.DisplayName)
	}

	// 添加分类信息
	if ticket.Category != "" {
		content += fmt.Sprintf("\n- 📂 **分类：** %s", ticket.Category)
	}

	// 添加截止时间
	if ticket.DueDate != nil {
		dueDate := ticket.DueDate.Format("2006-01-02 15:04")
		if ticket.IsOverdue() {
			content += fmt.Sprintf("\n- ⏰ **截止时间：** <font color=\"warning\">%s (已过期)</font>", dueDate)
		} else {
			content += fmt.Sprintf("\n- ⏰ **截止时间：** %s", dueDate)
		}
	}

	// 添加描述（截取前100字符）
	if ticket.Description != "" {
		description := ticket.Description
		if len(description) > 100 {
			description = description[:100] + "..."
		}
		content += fmt.Sprintf("\n\n**描述：**\n%s", description)
	}

	// 添加时间信息
	content += fmt.Sprintf("\n\n**时间：** %s", ticket.CreatedAt.Format("2006-01-02 15:04:05"))

	return content
}

// sendMessage 发送消息到企业微信
func (s *WechatNotificationService) sendMessage(content, webhookURL string) error {
	message := WechatMessage{
		MsgType: "markdown",
		Markdown: WechatMarkdown{
			Content: content,
		},
	}

	jsonData, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("序列化消息失败: %v", err)
	}

	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	resp, err := client.Post(webhookURL, "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("发送请求失败: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("读取响应失败: %v", err)
	}

	var wechatResp WechatResponse
	if err := json.Unmarshal(body, &wechatResp); err != nil {
		return fmt.Errorf("解析响应失败: %v", err)
	}

	if wechatResp.ErrCode != 0 {
		return fmt.Errorf("企业微信返回错误: %s (code: %d)", wechatResp.ErrMsg, wechatResp.ErrCode)
	}

	// 记录通知历史
	s.recordNotificationHistory(content, webhookURL, "success", "")

	return nil
}

// recordNotificationHistory 记录通知历史
func (s *WechatNotificationService) recordNotificationHistory(content, webhook, status, errorMsg string) {
	notification := models.NotificationHistory{
		Channel:   "wechat",
		Recipient: webhook,
		Content:   content,
		Status:    status,
		Error:     errorMsg,
		SentAt:    time.Now(),
	}
	s.db.Create(&notification)
}

// 辅助方法：获取状态颜色
func (s *WechatNotificationService) getStatusColor(status models.TicketStatus) string {
	switch status {
	case models.TicketStatusSubmitted:
		return "info"
	case models.TicketStatusAssigned:
		return "warning"
	case models.TicketStatusApproved:
		return "success"
	case models.TicketStatusInProgress:
		return "warning"
	case models.TicketStatusPending:
		return "warning"
	case models.TicketStatusResolved:
		return "success"
	case models.TicketStatusClosed:
		return "success"
	case models.TicketStatusRejected:
		return "danger"
	default:
		return "info"
	}
}

// 辅助方法：获取优先级表情
func (s *WechatNotificationService) getPriorityEmoji(priority models.TicketPriority) string {
	switch priority {
	case models.TicketPriorityLow:
		return "🟢"
	case models.TicketPriorityNormal:
		return "🟡"
	case models.TicketPriorityHigh:
		return "🟠"
	case models.TicketPriorityCritical:
		return "🔴"
	default:
		return "⚪"
	}
}

// 辅助方法：获取状态表情
func (s *WechatNotificationService) getStatusEmoji(status models.TicketStatus) string {
	switch status {
	case models.TicketStatusSubmitted:
		return "📝"
	case models.TicketStatusAssigned:
		return "👤"
	case models.TicketStatusApproved:
		return "✅"
	case models.TicketStatusInProgress:
		return "⚡"
	case models.TicketStatusPending:
		return "⏳"
	case models.TicketStatusResolved:
		return "✅"
	case models.TicketStatusClosed:
		return "🔒"
	case models.TicketStatusRejected:
		return "❌"
	default:
		return "📋"
	}
}

// 辅助方法：获取类型显示名称
func (s *WechatNotificationService) getTypeDisplayName(ticketType models.TicketType) string {
	switch ticketType {
	case models.TicketTypeBug:
		return "故障报告"
	case models.TicketTypeFeature:
		return "功能请求"
	case models.TicketTypeSupport:
		return "技术支持"
	case models.TicketTypeChange:
		return "变更请求"
	default:
		return string(ticketType)
	}
}

// 辅助方法：获取优先级显示名称
func (s *WechatNotificationService) getPriorityDisplayName(priority models.TicketPriority) string {
	switch priority {
	case models.TicketPriorityLow:
		return "低"
	case models.TicketPriorityNormal:
		return "普通"
	case models.TicketPriorityHigh:
		return "高"
	case models.TicketPriorityCritical:
		return "紧急"
	default:
		return string(priority)
	}
}

// 辅助方法：获取状态显示名称
func (s *WechatNotificationService) getStatusDisplayName(status models.TicketStatus) string {
	switch status {
	case models.TicketStatusSubmitted:
		return "已提交"
	case models.TicketStatusAssigned:
		return "已分派"
	case models.TicketStatusApproved:
		return "已审批"
	case models.TicketStatusInProgress:
		return "处理中"
	case models.TicketStatusPending:
		return "等待反馈"
	case models.TicketStatusResolved:
		return "已解决"
	case models.TicketStatusClosed:
		return "已关闭"
	case models.TicketStatusRejected:
		return "已拒绝"
	default:
		return string(status)
	}
}