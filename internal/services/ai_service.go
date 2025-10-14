package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"info-management-system/internal/models"

	"gorm.io/gorm"
)

// AIService AI服务
type AIService struct {
	db         *gorm.DB
	httpClient *http.Client
}

// NewAIService 创建AI服务
func NewAIService(db *gorm.DB) *AIService {
	return &AIService{
		db: db,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// AI配置相关请求结构
type AIConfigRequest struct {
	Provider    string  `json:"provider" binding:"required,oneof=openai azure anthropic"`
	Name        string  `json:"name" binding:"required"`
	APIKey      string  `json:"api_key" binding:"required"`
	APIEndpoint string  `json:"api_endpoint"`
	Model       string  `json:"model" binding:"required"`
	Config      string  `json:"config"`
	IsActive    bool    `json:"is_active"`
	IsDefault   bool    `json:"is_default"`
	MaxTokens   int     `json:"max_tokens"`
	Temperature float32 `json:"temperature"`
}

// 记录优化请求结构
type RecordOptimizeRequest struct {
	ConfigID *uint                  `json:"config_id"`
	Content  map[string]interface{} `json:"content" binding:"required"`
	Options  map[string]interface{} `json:"options"`
}

// 语音识别请求结构
type SpeechToTextRequest struct {
	ConfigID *uint  `json:"config_id"`
	AudioURL string `json:"audio_url" binding:"required"`
	Language string `json:"language"`
	Options  map[string]interface{} `json:"options"`
}

// AI聊天请求结构
type AIChatRequest struct {
	ConfigID  *uint  `json:"config_id"`
	SessionID *uint  `json:"session_id"`
	Message   string `json:"message" binding:"required"`
	Stream    bool   `json:"stream"`
	Options   map[string]interface{} `json:"options"`
}

// 响应结构
type AIConfigListResponse struct {
	Configs  []models.AIConfig `json:"configs"`
	Total    int64             `json:"total"`
	Page     int               `json:"page"`
	PageSize int               `json:"page_size"`
}

type AITaskListResponse struct {
	Tasks    []models.AITask `json:"tasks"`
	Total    int64           `json:"total"`
	Page     int             `json:"page"`
	PageSize int             `json:"page_size"`
}

type AIChatSessionListResponse struct {
	Sessions []models.AIChatSession `json:"sessions"`
	Total    int64                  `json:"total"`
	Page     int                    `json:"page"`
	PageSize int                    `json:"page_size"`
}

type AIUsageStatsResponse struct {
	Stats []models.AIUsageStats `json:"stats"`
	Total int64                 `json:"total"`
}

// OpenAI API相关结构
type OpenAIRequest struct {
	Model       string                   `json:"model"`
	Messages    []OpenAIMessage          `json:"messages,omitempty"`
	Prompt      string                   `json:"prompt,omitempty"`
	MaxTokens   int                      `json:"max_tokens,omitempty"`
	Temperature float32                  `json:"temperature,omitempty"`
	Stream      bool                     `json:"stream,omitempty"`
	Audio       *OpenAIAudioRequest      `json:"audio,omitempty"`
}

type OpenAIMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type OpenAIAudioRequest struct {
	Input    string `json:"input"`
	Voice    string `json:"voice,omitempty"`
	Language string `json:"language,omitempty"`
}

type OpenAIResponse struct {
	ID      string                 `json:"id"`
	Object  string                 `json:"object"`
	Created int64                  `json:"created"`
	Model   string                 `json:"model"`
	Choices []OpenAIChoice         `json:"choices"`
	Usage   OpenAIUsage            `json:"usage"`
	Error   *OpenAIError           `json:"error,omitempty"`
}

type OpenAIChoice struct {
	Index        int           `json:"index"`
	Message      OpenAIMessage `json:"message,omitempty"`
	Text         string        `json:"text,omitempty"`
	FinishReason string        `json:"finish_reason"`
}

type OpenAIUsage struct {
	PromptTokens     int `json:"prompt_tokens"`
	CompletionTokens int `json:"completion_tokens"`
	TotalTokens      int `json:"total_tokens"`
}

type OpenAIError struct {
	Message string `json:"message"`
	Type    string `json:"type"`
	Code    string `json:"code"`
}

// CreateConfig 创建AI配置
func (s *AIService) CreateConfig(req *AIConfigRequest, userID uint) (*models.AIConfig, error) {
	// 如果设置为默认配置，取消其他同提供商的默认设置
	if req.IsDefault {
		if err := s.db.Model(&models.AIConfig{}).
			Where("provider = ? AND is_default = ?", req.Provider, true).
			Update("is_default", false).Error; err != nil {
			return nil, fmt.Errorf("更新默认配置设置失败: %v", err)
		}
	}

	config := &models.AIConfig{
		Provider:    req.Provider,
		Name:        req.Name,
		APIKey:      s.encryptAPIKey(req.APIKey), // 加密存储
		APIEndpoint: req.APIEndpoint,
		Model:       req.Model,
		Config:      req.Config,
		IsActive:    req.IsActive,
		IsDefault:   req.IsDefault,
		MaxTokens:   req.MaxTokens,
		Temperature: req.Temperature,
		CreatedBy:   userID,
	}

	// 设置默认值
	if config.MaxTokens == 0 {
		config.MaxTokens = 4000
	}
	if config.Temperature == 0 {
		config.Temperature = 0.7
	}

	if err := s.db.Create(config).Error; err != nil {
		return nil, fmt.Errorf("创建AI配置失败: %v", err)
	}

	// 预加载关联数据
	if err := s.db.Preload("Creator").First(config, config.ID).Error; err != nil {
		return nil, fmt.Errorf("获取AI配置失败: %v", err)
	}

	// 解密API密钥用于返回（仅显示部分）
	config.APIKey = s.maskAPIKey(req.APIKey)

	return config, nil
}

// GetConfigs 获取AI配置列表
func (s *AIService) GetConfigs(page, pageSize int, provider string, userID uint, hasAllPermission bool) (*AIConfigListResponse, error) {
	var configs []models.AIConfig
	var total int64

	query := s.db.Model(&models.AIConfig{})

	// 提供商过滤
	if provider != "" {
		query = query.Where("provider = ?", provider)
	}

	// 权限控制
	if !hasAllPermission {
		query = query.Where("created_by = ?", userID)
	}

	// 计算总数
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取配置总数失败: %v", err)
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Preload("Creator").
		Offset(offset).
		Limit(pageSize).
		Order("created_at DESC").
		Find(&configs).Error; err != nil {
		return nil, fmt.Errorf("获取配置列表失败: %v", err)
	}

	// 掩码API密钥
	for i := range configs {
		configs[i].APIKey = s.maskAPIKey(configs[i].APIKey)
	}

	return &AIConfigListResponse{
		Configs:  configs,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// GetConfigByID 根据ID获取AI配置
func (s *AIService) GetConfigByID(id, userID uint, hasAllPermission bool) (*models.AIConfig, error) {
	var config models.AIConfig

	query := s.db.Preload("Creator")

	// 权限控制
	if !hasAllPermission {
		query = query.Where("created_by = ?", userID)
	}

	if err := query.First(&config, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("配置不存在或无权访问")
		}
		return nil, fmt.Errorf("获取配置失败: %v", err)
	}

	// 掩码API密钥
	config.APIKey = s.maskAPIKey(config.APIKey)

	return &config, nil
}

// UpdateConfig 更新AI配置
func (s *AIService) UpdateConfig(id uint, req *AIConfigRequest, userID uint, hasAllPermission bool) (*models.AIConfig, error) {
	var config models.AIConfig

	query := s.db.Model(&config)

	// 权限控制
	if !hasAllPermission {
		query = query.Where("created_by = ?", userID)
	}

	if err := query.First(&config, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("配置不存在或无权修改")
		}
		return nil, fmt.Errorf("获取配置失败: %v", err)
	}

	// 如果设置为默认配置，取消其他同提供商的默认设置
	if req.IsDefault && !config.IsDefault {
		if err := s.db.Model(&models.AIConfig{}).
			Where("provider = ? AND is_default = ? AND id != ?", req.Provider, true, id).
			Update("is_default", false).Error; err != nil {
			return nil, fmt.Errorf("更新默认配置设置失败: %v", err)
		}
	}

	// 更新字段
	updates := map[string]interface{}{
		"provider":     req.Provider,
		"name":         req.Name,
		"api_endpoint": req.APIEndpoint,
		"model":        req.Model,
		"config":       req.Config,
		"is_active":    req.IsActive,
		"is_default":   req.IsDefault,
		"max_tokens":   req.MaxTokens,
		"temperature":  req.Temperature,
	}

	// 如果提供了新的API密钥，则更新
	if req.APIKey != "" && req.APIKey != s.maskAPIKey(config.APIKey) {
		updates["api_key"] = s.encryptAPIKey(req.APIKey)
	}

	if err := s.db.Model(&config).Updates(updates).Error; err != nil {
		return nil, fmt.Errorf("更新配置失败: %v", err)
	}

	// 重新加载数据
	if err := s.db.Preload("Creator").First(&config, id).Error; err != nil {
		return nil, fmt.Errorf("获取更新后的配置失败: %v", err)
	}

	// 掩码API密钥
	config.APIKey = s.maskAPIKey(config.APIKey)

	return &config, nil
}

// DeleteConfig 删除AI配置
func (s *AIService) DeleteConfig(id, userID uint, hasAllPermission bool) error {
	var config models.AIConfig

	query := s.db.Model(&config)

	// 权限控制
	if !hasAllPermission {
		query = query.Where("created_by = ?", userID)
	}

	if err := query.First(&config, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("配置不存在或无权删除")
		}
		return fmt.Errorf("获取配置失败: %v", err)
	}

	if err := s.db.Delete(&config).Error; err != nil {
		return fmt.Errorf("删除配置失败: %v", err)
	}

	return nil
}

// OptimizeRecord 优化记录
func (s *AIService) OptimizeRecord(req *RecordOptimizeRequest, userID uint) (*models.AITask, error) {
	// 获取AI配置
	config, err := s.getActiveConfig(req.ConfigID, "openai", userID)
	if err != nil {
		return nil, err
	}

	// 创建AI任务
	task := &models.AITask{
		Type:     "optimize",
		ConfigID: config.ID,
		UserID:   userID,
		Status:   "pending",
	}

	// 序列化输入
	if inputJSON, err := json.Marshal(req.Content); err != nil {
		return nil, fmt.Errorf("序列化输入失败: %v", err)
	} else {
		task.Input = string(inputJSON)
	}

	// 序列化元数据
	if len(req.Options) > 0 {
		if metadataJSON, err := json.Marshal(req.Options); err != nil {
			return nil, fmt.Errorf("序列化元数据失败: %v", err)
		} else {
			task.Metadata = string(metadataJSON)
		}
	}

	if err := s.db.Create(task).Error; err != nil {
		return nil, fmt.Errorf("创建AI任务失败: %v", err)
	}

	// 异步处理任务
	go s.processOptimizeTask(task.ID)

	// 预加载关联数据
	if err := s.db.Preload("Config").Preload("User").First(task, task.ID).Error; err != nil {
		return nil, fmt.Errorf("获取AI任务失败: %v", err)
	}

	return task, nil
}

// SpeechToText 语音识别
func (s *AIService) SpeechToText(req *SpeechToTextRequest, userID uint) (*models.AITask, error) {
	// 获取AI配置
	config, err := s.getActiveConfig(req.ConfigID, "openai", userID)
	if err != nil {
		return nil, err
	}

	// 创建AI任务
	task := &models.AITask{
		Type:     "speech-to-text",
		ConfigID: config.ID,
		UserID:   userID,
		Status:   "pending",
		Input:    req.AudioURL,
	}

	// 序列化元数据
	metadata := map[string]interface{}{
		"language": req.Language,
	}
	if len(req.Options) > 0 {
		for k, v := range req.Options {
			metadata[k] = v
		}
	}

	if metadataJSON, err := json.Marshal(metadata); err != nil {
		return nil, fmt.Errorf("序列化元数据失败: %v", err)
	} else {
		task.Metadata = string(metadataJSON)
	}

	if err := s.db.Create(task).Error; err != nil {
		return nil, fmt.Errorf("创建AI任务失败: %v", err)
	}

	// 异步处理任务
	go s.processSpeechToTextTask(task.ID)

	// 预加载关联数据
	if err := s.db.Preload("Config").Preload("User").First(task, task.ID).Error; err != nil {
		return nil, fmt.Errorf("获取AI任务失败: %v", err)
	}

	return task, nil
}

// Chat AI聊天
func (s *AIService) Chat(req *AIChatRequest, userID uint) (*models.AIChatSession, error) {
	// 获取AI配置
	config, err := s.getActiveConfig(req.ConfigID, "openai", userID)
	if err != nil {
		return nil, err
	}

	var session *models.AIChatSession

	// 获取或创建会话
	if req.SessionID != nil {
		if err := s.db.Preload("Messages").First(&session, *req.SessionID).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				return nil, fmt.Errorf("会话不存在")
			}
			return nil, fmt.Errorf("获取会话失败: %v", err)
		}

		// 检查权限
		if session.UserID != userID {
			return nil, fmt.Errorf("无权访问此会话")
		}
	} else {
		// 创建新会话
		session = &models.AIChatSession{
			UserID:   userID,
			Title:    s.generateChatTitle(req.Message),
			ConfigID: config.ID,
			Status:   "active",
		}

		if err := s.db.Create(session).Error; err != nil {
			return nil, fmt.Errorf("创建会话失败: %v", err)
		}
	}

	// 添加用户消息
	userMessage := &models.AIChatMessage{
		SessionID: session.ID,
		Role:      "user",
		Content:   req.Message,
	}

	if err := s.db.Create(userMessage).Error; err != nil {
		return nil, fmt.Errorf("保存用户消息失败: %v", err)
	}

	// 异步处理AI回复
	go s.processChatMessage(session.ID, userMessage.ID, req.Stream)

	// 更新会话信息
	now := time.Now()
	session.LastUsedAt = &now
	session.MessageCount++
	s.db.Save(session)

	// 重新加载会话数据
	if err := s.db.Preload("Config").Preload("User").Preload("Messages").First(session, session.ID).Error; err != nil {
		return nil, fmt.Errorf("获取会话失败: %v", err)
	}

	return session, nil
}

// 辅助方法

// encryptAPIKey 加密API密钥（简化实现）
func (s *AIService) encryptAPIKey(apiKey string) string {
	// 这里应该使用真正的加密算法
	// 为了演示，我们只是简单地存储
	return apiKey
}

// maskAPIKey 掩码API密钥
func (s *AIService) maskAPIKey(apiKey string) string {
	if len(apiKey) <= 8 {
		return strings.Repeat("*", len(apiKey))
	}
	return apiKey[:4] + strings.Repeat("*", len(apiKey)-8) + apiKey[len(apiKey)-4:]
}

// getActiveConfig 获取活跃的AI配置
func (s *AIService) getActiveConfig(configID *uint, provider string, userID uint) (*models.AIConfig, error) {
	var config models.AIConfig

	if configID != nil {
		// 使用指定的配置
		if err := s.db.Where("id = ? AND is_active = ?", *configID, true).First(&config).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				return nil, fmt.Errorf("指定的AI配置不存在或已禁用")
			}
			return nil, fmt.Errorf("获取AI配置失败: %v", err)
		}
	} else {
		// 使用默认配置
		if err := s.db.Where("provider = ? AND is_default = ? AND is_active = ?", provider, true, true).First(&config).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				return nil, fmt.Errorf("未找到默认的%s配置", provider)
			}
			return nil, fmt.Errorf("获取默认AI配置失败: %v", err)
		}
	}

	return &config, nil
}

// generateChatTitle 生成聊天标题
func (s *AIService) generateChatTitle(message string) string {
	if len(message) > 50 {
		return message[:50] + "..."
	}
	return message
}

// processOptimizeTask 处理记录优化任务
func (s *AIService) processOptimizeTask(taskID uint) {
	// 更新任务状态
	now := time.Now()
	s.db.Model(&models.AITask{}).Where("id = ?", taskID).Updates(map[string]interface{}{
		"status":     "processing",
		"started_at": &now,
	})

	// 获取任务详情
	var task models.AITask
	if err := s.db.Preload("Config").First(&task, taskID).Error; err != nil {
		s.updateTaskError(taskID, fmt.Sprintf("获取任务失败: %v", err))
		return
	}

	// 解析输入内容
	var content map[string]interface{}
	if err := json.Unmarshal([]byte(task.Input), &content); err != nil {
		s.updateTaskError(taskID, fmt.Sprintf("解析输入内容失败: %v", err))
		return
	}

	// 构建优化提示
	prompt := s.buildOptimizePrompt(content)

	// 调用OpenAI API
	response, err := s.callOpenAI(&task.Config, prompt, false)
	if err != nil {
		s.updateTaskError(taskID, fmt.Sprintf("调用AI服务失败: %v", err))
		return
	}

	// 更新任务完成状态
	completedAt := time.Now()
	duration := int(completedAt.Sub(now).Milliseconds())
	
	updates := map[string]interface{}{
		"status":       "completed",
		"progress":     100,
		"output":       response.Choices[0].Message.Content,
		"tokens_used":  response.Usage.TotalTokens,
		"duration":     duration,
		"completed_at": &completedAt,
	}

	s.db.Model(&models.AITask{}).Where("id = ?", taskID).Updates(updates)

	// 更新使用统计
	s.updateUsageStats(task.UserID, task.ConfigID, "optimize", 1, response.Usage.TotalTokens, duration, true)
}

// processSpeechToTextTask 处理语音识别任务
func (s *AIService) processSpeechToTextTask(taskID uint) {
	// 更新任务状态
	now := time.Now()
	s.db.Model(&models.AITask{}).Where("id = ?", taskID).Updates(map[string]interface{}{
		"status":     "processing",
		"started_at": &now,
	})

	// 获取任务详情
	var task models.AITask
	if err := s.db.Preload("Config").First(&task, taskID).Error; err != nil {
		s.updateTaskError(taskID, fmt.Sprintf("获取任务失败: %v", err))
		return
	}

	// 模拟语音识别处理
	// 在实际实现中，这里应该调用真正的语音识别API
	time.Sleep(2 * time.Second) // 模拟处理时间

	// 模拟识别结果
	result := map[string]interface{}{
		"text":       "这是模拟的语音识别结果",
		"language":   "zh-CN",
		"confidence": 0.95,
		"duration":   "00:00:30",
	}

	resultJSON, _ := json.Marshal(result)

	// 更新任务完成状态
	completedAt := time.Now()
	duration := int(completedAt.Sub(now).Milliseconds())
	
	updates := map[string]interface{}{
		"status":       "completed",
		"progress":     100,
		"output":       string(resultJSON),
		"tokens_used":  0, // 语音识别通常不计算tokens
		"duration":     duration,
		"completed_at": &completedAt,
	}

	s.db.Model(&models.AITask{}).Where("id = ?", taskID).Updates(updates)

	// 更新使用统计
	s.updateUsageStats(task.UserID, task.ConfigID, "speech-to-text", 1, 0, duration, true)
}

// processChatMessage 处理聊天消息
func (s *AIService) processChatMessage(sessionID, messageID uint, stream bool) {
	// 获取会话和配置
	var session models.AIChatSession
	if err := s.db.Preload("Config").Preload("Messages").First(&session, sessionID).Error; err != nil {
		return
	}

	// 构建消息历史
	messages := make([]OpenAIMessage, 0)
	
	// 添加系统消息
	messages = append(messages, OpenAIMessage{
		Role:    "system",
		Content: "你是一个有用的AI助手，请用中文回答用户的问题。",
	})

	// 添加历史消息（最近10条）
	recentMessages := session.Messages
	if len(recentMessages) > 10 {
		recentMessages = recentMessages[len(recentMessages)-10:]
	}

	for _, msg := range recentMessages {
		messages = append(messages, OpenAIMessage{
			Role:    msg.Role,
			Content: msg.Content,
		})
	}

	// 调用OpenAI API
	response, err := s.callOpenAIChatCompletion(&session.Config, messages, stream)
	if err != nil {
		// 创建错误消息
		errorMessage := &models.AIChatMessage{
			SessionID: sessionID,
			Role:      "assistant",
			Content:   fmt.Sprintf("抱歉，处理您的请求时出现错误: %v", err),
		}
		s.db.Create(errorMessage)
		return
	}

	// 保存AI回复
	assistantMessage := &models.AIChatMessage{
		SessionID: sessionID,
		Role:      "assistant",
		Content:   response.Choices[0].Message.Content,
		Tokens:    response.Usage.TotalTokens,
	}

	s.db.Create(assistantMessage)

	// 更新会话统计
	session.MessageCount++
	session.TokensUsed += response.Usage.TotalTokens
	s.db.Save(&session)

	// 更新使用统计
	s.updateUsageStats(session.UserID, session.ConfigID, "chat", 1, response.Usage.TotalTokens, 0, true)
}

// buildOptimizePrompt 构建优化提示
func (s *AIService) buildOptimizePrompt(content map[string]interface{}) string {
	contentJSON, _ := json.Marshal(content)
	
	prompt := fmt.Sprintf(`请帮我优化以下记录内容，使其更加清晰、准确和完整：

原始内容：
%s

请按照以下要求进行优化：
1. 保持原始信息的准确性
2. 改善语言表达，使其更加清晰
3. 补充必要的细节信息
4. 确保格式规范统一
5. 返回JSON格式的优化结果

请直接返回优化后的JSON内容，不需要额外的解释。`, string(contentJSON))

	return prompt
}

// callOpenAI 调用OpenAI API
func (s *AIService) callOpenAI(config *models.AIConfig, prompt string, stream bool) (*OpenAIResponse, error) {
	// 构建请求
	request := OpenAIRequest{
		Model:       config.Model,
		Prompt:      prompt,
		MaxTokens:   config.MaxTokens,
		Temperature: config.Temperature,
		Stream:      stream,
	}

	return s.makeOpenAIRequest(config, "completions", request)
}

// callOpenAIChatCompletion 调用OpenAI聊天完成API
func (s *AIService) callOpenAIChatCompletion(config *models.AIConfig, messages []OpenAIMessage, stream bool) (*OpenAIResponse, error) {
	// 构建请求
	request := OpenAIRequest{
		Model:       config.Model,
		Messages:    messages,
		MaxTokens:   config.MaxTokens,
		Temperature: config.Temperature,
		Stream:      stream,
	}

	return s.makeOpenAIRequest(config, "chat/completions", request)
}

// makeOpenAIRequest 发起OpenAI API请求
func (s *AIService) makeOpenAIRequest(config *models.AIConfig, endpoint string, request OpenAIRequest) (*OpenAIResponse, error) {
	// 序列化请求
	requestBody, err := json.Marshal(request)
	if err != nil {
		return nil, fmt.Errorf("序列化请求失败: %v", err)
	}

	// 构建API URL
	apiURL := config.APIEndpoint
	if apiURL == "" {
		apiURL = "https://api.openai.com/v1"
	}
	apiURL = fmt.Sprintf("%s/%s", strings.TrimRight(apiURL, "/"), endpoint)

	// 创建HTTP请求
	req, err := http.NewRequest("POST", apiURL, bytes.NewBuffer(requestBody))
	if err != nil {
		return nil, fmt.Errorf("创建请求失败: %v", err)
	}

	// 设置请求头
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", config.APIKey))

	// 发送请求
	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("发送请求失败: %v", err)
	}
	defer resp.Body.Close()

	// 读取响应
	responseBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("读取响应失败: %v", err)
	}

	// 解析响应
	var response OpenAIResponse
	if err := json.Unmarshal(responseBody, &response); err != nil {
		return nil, fmt.Errorf("解析响应失败: %v", err)
	}

	// 检查API错误
	if response.Error != nil {
		return nil, fmt.Errorf("OpenAI API错误: %s", response.Error.Message)
	}

	// 检查HTTP状态码
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API请求失败，状态码: %d", resp.StatusCode)
	}

	return &response, nil
}

// updateTaskError 更新任务错误状态
func (s *AIService) updateTaskError(taskID uint, errorMsg string) {
	s.db.Model(&models.AITask{}).Where("id = ?", taskID).Updates(map[string]interface{}{
		"status":    "failed",
		"error_msg": errorMsg,
	})
}

// updateUsageStats 更新使用统计
func (s *AIService) updateUsageStats(userID, configID uint, taskType string, requestCount, tokensUsed, duration int, success bool) {
	today := time.Now().Truncate(24 * time.Hour)

	var stats models.AIUsageStats
	err := s.db.Where("user_id = ? AND config_id = ? AND date = ? AND task_type = ?", 
		userID, configID, today, taskType).First(&stats).Error

	if err == gorm.ErrRecordNotFound {
		// 创建新的统计记录
		stats = models.AIUsageStats{
			UserID:       userID,
			ConfigID:     configID,
			Date:         today,
			TaskType:     taskType,
			RequestCount: requestCount,
			TokensUsed:   tokensUsed,
			Duration:     duration,
		}

		if success {
			stats.SuccessCount = 1
		} else {
			stats.FailureCount = 1
		}

		s.db.Create(&stats)
	} else if err == nil {
		// 更新现有统计记录
		updates := map[string]interface{}{
			"request_count": gorm.Expr("request_count + ?", requestCount),
			"tokens_used":   gorm.Expr("tokens_used + ?", tokensUsed),
			"duration":      gorm.Expr("duration + ?", duration),
		}

		if success {
			updates["success_count"] = gorm.Expr("success_count + 1")
		} else {
			updates["failure_count"] = gorm.Expr("failure_count + 1")
		}

		s.db.Model(&stats).Updates(updates)
	}
}

// HealthCheck 健康检查
func (s *AIService) HealthCheck(configID uint) (*models.AIHealthCheck, error) {
	// 获取配置
	var config models.AIConfig
	if err := s.db.First(&config, configID).Error; err != nil {
		return nil, fmt.Errorf("获取配置失败: %v", err)
	}

	startTime := time.Now()
	
	// 发送简单的测试请求
	testRequest := OpenAIRequest{
		Model:       config.Model,
		Messages:    []OpenAIMessage{{Role: "user", Content: "Hello"}},
		MaxTokens:   10,
		Temperature: 0.1,
	}

	var status string
	var errorMsg string
	
	_, err := s.makeOpenAIRequest(&config, "chat/completions", testRequest)
	if err != nil {
		status = "unhealthy"
		errorMsg = err.Error()
	} else {
		status = "healthy"
	}

	responseTime := int(time.Since(startTime).Milliseconds())

	// 保存健康检查记录
	healthCheck := &models.AIHealthCheck{
		ConfigID:     configID,
		Status:       status,
		ResponseTime: responseTime,
		ErrorMsg:     errorMsg,
		CheckedAt:    time.Now(),
	}

	s.db.Create(healthCheck)

	return healthCheck, nil
}

// GetTasks 获取AI任务列表
func (s *AIService) GetTasks(page, pageSize int, taskType, status string, userID uint, hasAllPermission bool) (*AITaskListResponse, error) {
	var tasks []models.AITask
	var total int64

	query := s.db.Model(&models.AITask{})

	// 任务类型过滤
	if taskType != "" {
		query = query.Where("type = ?", taskType)
	}

	// 状态过滤
	if status != "" {
		query = query.Where("status = ?", status)
	}

	// 权限控制
	if !hasAllPermission {
		query = query.Where("user_id = ?", userID)
	}

	// 计算总数
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取任务总数失败: %v", err)
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Preload("Config").Preload("User").
		Offset(offset).
		Limit(pageSize).
		Order("created_at DESC").
		Find(&tasks).Error; err != nil {
		return nil, fmt.Errorf("获取任务列表失败: %v", err)
	}

	return &AITaskListResponse{
		Tasks:    tasks,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// GetChatSessions 获取聊天会话列表
func (s *AIService) GetChatSessions(page, pageSize int, userID uint) (*AIChatSessionListResponse, error) {
	var sessions []models.AIChatSession
	var total int64

	query := s.db.Model(&models.AIChatSession{}).Where("user_id = ?", userID)

	// 计算总数
	if err := query.Count(&total).Error; err != nil {
		return nil, fmt.Errorf("获取会话总数失败: %v", err)
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := query.Preload("Config").
		Offset(offset).
		Limit(pageSize).
		Order("last_used_at DESC").
		Find(&sessions).Error; err != nil {
		return nil, fmt.Errorf("获取会话列表失败: %v", err)
	}

	return &AIChatSessionListResponse{
		Sessions: sessions,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// GetUsageStats 获取使用统计
func (s *AIService) GetUsageStats(userID uint, startDate, endDate time.Time, taskType string) (*AIUsageStatsResponse, error) {
	var stats []models.AIUsageStats

	query := s.db.Model(&models.AIUsageStats{}).Where("user_id = ?", userID)

	// 日期范围过滤
	if !startDate.IsZero() {
		query = query.Where("date >= ?", startDate)
	}
	if !endDate.IsZero() {
		query = query.Where("date <= ?", endDate)
	}

	// 任务类型过滤
	if taskType != "" {
		query = query.Where("task_type = ?", taskType)
	}

	if err := query.Preload("Config").Order("date DESC").Find(&stats).Error; err != nil {
		return nil, fmt.Errorf("获取使用统计失败: %v", err)
	}

	return &AIUsageStatsResponse{
		Stats: stats,
		Total: int64(len(stats)),
	}, nil
}