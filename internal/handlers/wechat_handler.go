package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"info-management-system/internal/services"
)

type WechatHandler struct {
	wechatService *services.WechatService
}

func NewWechatHandler(wechatService *services.WechatService) *WechatHandler {
	return &WechatHandler{
		wechatService: wechatService,
	}
}

// ProcessZabbixWebhook 处理Zabbix Webhook请求（兼容Zabbix脚本格式）
func (h *WechatHandler) ProcessZabbixWebhook(c *gin.Context) {
	var params map[string]interface{}
	
	if err := c.ShouldBindJSON(&params); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数格式错误"})
		return
	}
	
	// 处理Zabbix格式的消息
	if err := h.wechatService.FormatZabbixWebhookMessage(params); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{"message": "OK"})
}

// SendTestMessage 发送测试消息
func (h *WechatHandler) SendTestMessage(c *gin.Context) {
	var req struct {
		WebhookURL string `json:"webhook_url" binding:"required"`
		Token      string `json:"token" binding:"required"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	
	if err := h.wechatService.TestWebhookConnection(req.WebhookURL, req.Token); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{"message": "测试消息发送成功"})
}

// GetWechatConfig 获取企业微信配置
func (h *WechatHandler) GetWechatConfig(c *gin.Context) {
	config, err := h.wechatService.GetWechatConfig()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, config)
}

// SaveWechatConfig 保存企业微信配置
func (h *WechatHandler) SaveWechatConfig(c *gin.Context) {
	var config services.WechatWebhookConfig
	
	if err := c.ShouldBindJSON(&config); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	
	if err := h.wechatService.SaveWechatConfig(&config); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{"message": "配置保存成功"})
}