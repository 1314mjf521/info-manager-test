package services

import (
	"fmt"
	"sync"
	"time"

	"info-management-system/internal/models"

	"gorm.io/gorm"
)

// CacheItem 缓存项
type CacheItem struct {
	Value     interface{}
	ExpiresAt time.Time
}

// SimpleCache 简单的内存缓存
type SimpleCache struct {
	items map[string]*CacheItem
	mutex sync.RWMutex
}

// NewSimpleCache 创建简单缓存
func NewSimpleCache() *SimpleCache {
	return &SimpleCache{
		items: make(map[string]*CacheItem),
	}
}

// Get 获取缓存项
func (c *SimpleCache) Get(key string) (interface{}, bool) {
	c.mutex.RLock()
	defer c.mutex.RUnlock()
	
	item, exists := c.items[key]
	if !exists || time.Now().After(item.ExpiresAt) {
		return nil, false
	}
	return item.Value, true
}

// Set 设置缓存项
func (c *SimpleCache) Set(key string, value interface{}, duration time.Duration) {
	c.mutex.Lock()
	defer c.mutex.Unlock()
	
	c.items[key] = &CacheItem{
		Value:     value,
		ExpiresAt: time.Now().Add(duration),
	}
}

// PermissionService 权限服务
type PermissionService struct {
	db    *gorm.DB
	cache *SimpleCache
}

// NewPermissionService 创建权限服务
func NewPermissionService(db *gorm.DB) *PermissionService {
	return &PermissionService{
		db:    db,
		cache: NewSimpleCache(),
	}
}

// PermissionCheckRequest 权限检查请求
type PermissionCheckRequest struct {
	UserID   uint   `json:"user_id" binding:"required"`
	Resource string `json:"resource" binding:"required"`
	Action   string `json:"action" binding:"required"`
	Scope    string `json:"scope,omitempty"`
}

// PermissionCheckResponse 权限检查响应
type PermissionCheckResponse struct {
	HasPermission bool   `json:"has_permission"`
	Message       string `json:"message,omitempty"`
}

// UserPermissionsResponse 用户权限响应
type UserPermissionsResponse struct {
	UserID        uint                `json:"user_id"`
	Username      string              `json:"username"`
	Roles         []RoleInfo          `json:"roles"`
	Permissions   []PermissionInfo    `json:"permissions"`
	PermissionMap map[string][]string `json:"permission_map"` // resource -> actions
}

// RoleInfo 角色信息
type RoleInfo struct {
	ID          uint   `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	IsSystem    bool   `json:"is_system"`
}

// PermissionInfo 权限信息
type PermissionInfo struct {
	ID          uint             `json:"id"`
	Name        string           `json:"name"`
	DisplayName string           `json:"displayName"`
	Description string           `json:"description"`
	Resource    string           `json:"resource"`
	Action      string           `json:"action"`
	Scope       string           `json:"scope"`
	ParentID    *uint            `json:"parentId"`
	Children    []PermissionInfo `json:"children,omitempty"`
}

// UpdatePermissionRequest 更新权限请求
type UpdatePermissionRequest struct {
	DisplayName string `json:"displayName"`
	Description string `json:"description"`
	Resource    string `json:"resource"`
	Action      string `json:"action"`
	Scope       string `json:"scope"`
	ParentID    *uint  `json:"parentId"`
}

// CheckPermission 检查用户权限
func (s *PermissionService) CheckPermission(req *PermissionCheckRequest) (*PermissionCheckResponse, error) {
	// 获取用户及其角色和权限
	var user models.User
	if err := s.db.Preload("Roles.Permissions").First(&user, req.UserID).Error; err != nil {
		return &PermissionCheckResponse{
			HasPermission: false,
			Message:       "用户不存在",
		}, nil
	}

	// 检查用户是否激活
	if !user.IsActive {
		return &PermissionCheckResponse{
			HasPermission: false,
			Message:       "用户账户已被禁用",
		}, nil
	}

	// 检查权限
	hasPermission := s.userHasPermission(&user, req.Resource, req.Action, req.Scope)

	response := &PermissionCheckResponse{
		HasPermission: hasPermission,
	}

	if !hasPermission {
		response.Message = "权限不足"
	}

	return response, nil
}

// GetUserPermissions 获取用户所有权限（优化版本，添加缓存）
func (s *PermissionService) GetUserPermissions(userID uint) (*UserPermissionsResponse, error) {
	// 尝试从缓存获取
	cacheKey := fmt.Sprintf("user_permissions:%d", userID)
	if cached, exists := s.cache.Get(cacheKey); exists {
		if response, ok := cached.(*UserPermissionsResponse); ok {
			return response, nil
		}
	}

	// 优化查询：使用Join而不是Preload，减少查询次数
	var user models.User
	if err := s.db.Select("id, username, email, display_name, status").First(&user, userID).Error; err != nil {
		return nil, fmt.Errorf("用户不存在")
	}

	// 单独查询用户角色和权限，使用更高效的查询
	var userRoles []models.UserRole
	if err := s.db.Where("user_id = ?", userID).Find(&userRoles).Error; err != nil {
		return nil, fmt.Errorf("查询用户角色失败: %w", err)
	}

	if len(userRoles) == 0 {
		// 用户没有角色，返回空权限
		response := &UserPermissionsResponse{
			UserID:        user.ID,
			Username:      user.Username,
			Roles:         []RoleInfo{},
			Permissions:   []PermissionInfo{},
			PermissionMap: make(map[string][]string),
		}
		// 缓存结果
		s.cache.Set(cacheKey, response, 5*time.Minute)
		return response, nil
	}

	// 获取角色ID列表
	roleIDs := make([]uint, len(userRoles))
	for i, ur := range userRoles {
		roleIDs[i] = ur.RoleID
	}

	// 批量查询角色信息
	var roles []models.Role
	if err := s.db.Where("id IN ?", roleIDs).Find(&roles).Error; err != nil {
		return nil, fmt.Errorf("查询角色信息失败: %w", err)
	}

	// 批量查询角色权限
	var rolePermissions []models.RolePermission
	if err := s.db.Where("role_id IN ?", roleIDs).Find(&rolePermissions).Error; err != nil {
		return nil, fmt.Errorf("查询角色权限失败: %w", err)
	}

	// 获取权限ID列表
	permissionIDs := make([]uint, len(rolePermissions))
	for i, rp := range rolePermissions {
		permissionIDs[i] = rp.PermissionID
	}

	// 批量查询权限信息
	var permissions []models.Permission
	if len(permissionIDs) > 0 {
		if err := s.db.Where("id IN ?", permissionIDs).Find(&permissions).Error; err != nil {
			return nil, fmt.Errorf("查询权限信息失败: %w", err)
		}
	}

	// 构建角色信息
	roleInfos := make([]RoleInfo, len(roles))
	for i, role := range roles {
		roleInfos[i] = RoleInfo{
			ID:          role.ID,
			Name:        role.Name,
			Description: role.Description,
			IsSystem:    role.IsSystem,
		}
	}

	// 收集所有权限（去重）
	permissionMap := make(map[string]models.Permission)
	resourceActionMap := make(map[string][]string)

	for _, permission := range permissions {
		key := fmt.Sprintf("%s:%s:%s", permission.Resource, permission.Action, permission.Scope)
		permissionMap[key] = permission

		// 构建资源-动作映射
		if actions, exists := resourceActionMap[permission.Resource]; exists {
			// 检查动作是否已存在
			found := false
			for _, action := range actions {
				if action == permission.Action {
					found = true
					break
				}
			}
			if !found {
				resourceActionMap[permission.Resource] = append(actions, permission.Action)
			}
		} else {
			resourceActionMap[permission.Resource] = []string{permission.Action}
		}
	}

	// 转换为权限信息列表
	permissionInfos := make([]PermissionInfo, 0, len(permissionMap))
	for _, permission := range permissionMap {
		permissionInfos = append(permissionInfos, PermissionInfo{
			ID:          permission.ID,
			Name:        permission.Name,
			DisplayName: permission.DisplayName,
			Description: permission.Description,
			Resource:    permission.Resource,
			Action:      permission.Action,
			Scope:       permission.Scope,
			ParentID:    permission.ParentID,
		})
	}

	response := &UserPermissionsResponse{
		UserID:        user.ID,
		Username:      user.Username,
		Roles:         roleInfos,
		Permissions:   permissionInfos,
		PermissionMap: resourceActionMap,
	}

	// 缓存结果
	s.cache.Set(cacheKey, response, 5*time.Minute)
	return response, nil
}

// userHasPermission 检查用户是否有指定权限
func (s *PermissionService) userHasPermission(user *models.User, resource, action, scope string) bool {
	for _, role := range user.Roles {
		for _, permission := range role.Permissions {
			if permission.Resource == resource && permission.Action == action {
				// 如果没有指定scope，或者权限scope为"all"，或者scope匹配
				if scope == "" || permission.Scope == "all" || permission.Scope == scope {
					return true
				}
			}
		}
	}
	return false
}

// GetAllPermissions 获取系统所有权限
func (s *PermissionService) GetAllPermissions() ([]PermissionInfo, error) {
	var permissions []models.Permission
	if err := s.db.Find(&permissions).Error; err != nil {
		return nil, fmt.Errorf("获取权限列表失败: %w", err)
	}

	result := make([]PermissionInfo, len(permissions))
	for i, permission := range permissions {
		result[i] = PermissionInfo{
			ID:          permission.ID,
			Name:        permission.Name,
			DisplayName: permission.DisplayName,
			Description: permission.Description,
			Resource:    permission.Resource,
			Action:      permission.Action,
			Scope:       permission.Scope,
			ParentID:    permission.ParentID,
		}
	}

	return result, nil
}

// GetPermissionTree 获取权限树结构
func (s *PermissionService) GetPermissionTree() ([]PermissionInfo, error) {
	var permissions []models.Permission
	// 获取所有权限数据
	if err := s.db.Order("id ASC").Find(&permissions).Error; err != nil {
		return nil, fmt.Errorf("获取权限列表失败: %w", err)
	}

	// 构建权限映射
	permissionMap := make(map[uint]models.Permission)
	for _, permission := range permissions {
		permissionMap[permission.ID] = permission
	}

	// 递归构建权限树
	var buildTree func(parentID *uint) []PermissionInfo
	buildTree = func(parentID *uint) []PermissionInfo {
		var result []PermissionInfo
		
		for _, permission := range permissions {
			// 检查是否为当前层级的子权限
			if (parentID == nil && permission.ParentID == nil) || 
			   (parentID != nil && permission.ParentID != nil && *permission.ParentID == *parentID) {
				
				permInfo := PermissionInfo{
					ID:          permission.ID,
					Name:        permission.Name,
					DisplayName: permission.DisplayName,
					Description: permission.Description,
					Resource:    permission.Resource,
					Action:      permission.Action,
					Scope:       permission.Scope,
					ParentID:    permission.ParentID,
					Children:    buildTree(&permission.ID), // 递归构建子权限
				}
				result = append(result, permInfo)
			}
		}
		
		return result
	}

	// 构建根权限树
	rootPermissions := buildTree(nil)
	return rootPermissions, nil
}

// CreatePermission 创建权限
func (s *PermissionService) CreatePermission(resource, action, scope string) (*PermissionInfo, error) {
	// 检查权限是否已存在
	var count int64
	if err := s.db.Model(&models.Permission{}).Where("resource = ? AND action = ? AND scope = ?", resource, action, scope).Count(&count).Error; err != nil {
		return nil, fmt.Errorf("检查权限失败: %v", err)
	}
	if count > 0 {
		return nil, fmt.Errorf("权限已存在")
	}

	permission := models.Permission{
		Resource: resource,
		Action:   action,
		Scope:    scope,
	}

	if err := s.db.Create(&permission).Error; err != nil {
		return nil, fmt.Errorf("创建权限失败: %w", err)
	}

	return &PermissionInfo{
		ID:          permission.ID,
		Name:        permission.Name,
		DisplayName: permission.DisplayName,
		Description: permission.Description,
		Resource:    permission.Resource,
		Action:      permission.Action,
		Scope:       permission.Scope,
		ParentID:    permission.ParentID,
	}, nil
}

// CreatePermissionWithDetails 创建带详细信息的权限
func (s *PermissionService) CreatePermissionWithDetails(name, displayName, description, resource, action, scope string, parentID *uint) (*PermissionInfo, error) {
	// 检查权限是否已存在
	var count int64
	if err := s.db.Model(&models.Permission{}).Where("name = ?", name).Count(&count).Error; err != nil {
		return nil, fmt.Errorf("检查权限失败: %v", err)
	}
	if count > 0 {
		return nil, fmt.Errorf("权限已存在")
	}

	permission := models.Permission{
		Name:        name,
		DisplayName: displayName,
		Description: description,
		Resource:    resource,
		Action:      action,
		Scope:       scope,
		ParentID:    parentID,
	}

	if err := s.db.Create(&permission).Error; err != nil {
		return nil, fmt.Errorf("创建权限失败: %w", err)
	}

	return &PermissionInfo{
		ID:          permission.ID,
		Name:        permission.Name,
		DisplayName: permission.DisplayName,
		Description: permission.Description,
		Resource:    permission.Resource,
		Action:      permission.Action,
		Scope:       permission.Scope,
		ParentID:    permission.ParentID,
	}, nil
}

// UpdatePermission 更新权限
func (s *PermissionService) UpdatePermission(id uint, req *UpdatePermissionRequest) (*PermissionInfo, error) {
	var permission models.Permission
	if err := s.db.First(&permission, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("权限不存在")
		}
		return nil, fmt.Errorf("查询权限失败: %w", err)
	}

	// 更新字段
	if req.DisplayName != "" {
		permission.DisplayName = req.DisplayName
	}
	if req.Description != "" {
		permission.Description = req.Description
	}
	if req.Resource != "" {
		permission.Resource = req.Resource
	}
	if req.Action != "" {
		permission.Action = req.Action
	}
	if req.Scope != "" {
		permission.Scope = req.Scope
	}
	permission.ParentID = req.ParentID

	if err := s.db.Save(&permission).Error; err != nil {
		return nil, fmt.Errorf("更新权限失败: %w", err)
	}

	// 清除缓存
	s.cache = NewSimpleCache()

	return &PermissionInfo{
		ID:          permission.ID,
		Name:        permission.Name,
		DisplayName: permission.DisplayName,
		Description: permission.Description,
		Resource:    permission.Resource,
		Action:      permission.Action,
		Scope:       permission.Scope,
		ParentID:    permission.ParentID,
	}, nil
}

// DeletePermission 删除权限
func (s *PermissionService) DeletePermission(id uint) error {
	// 检查是否有子权限
	var childCount int64
	if err := s.db.Model(&models.Permission{}).Where("parent_id = ?", id).Count(&childCount).Error; err != nil {
		return fmt.Errorf("检查子权限失败: %w", err)
	}
	if childCount > 0 {
		return fmt.Errorf("无法删除权限：存在子权限")
	}

	// 检查是否有角色使用此权限
	var rolePermCount int64
	if err := s.db.Model(&models.RolePermission{}).Where("permission_id = ?", id).Count(&rolePermCount).Error; err != nil {
		return fmt.Errorf("检查权限使用情况失败: %w", err)
	}
	if rolePermCount > 0 {
		return fmt.Errorf("无法删除权限：有角色正在使用此权限")
	}

	if err := s.db.Delete(&models.Permission{}, id).Error; err != nil {
		return fmt.Errorf("删除权限失败: %w", err)
	}

	return nil
}

// InitializeDetailedPermissions 初始化精细化权限数据
func (s *PermissionService) InitializeDetailedPermissions() error {
	permissions := GetAllDetailedPermissions()
	
	// 开始事务
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 清空现有权限数据以确保ID一致性
	if err := tx.Exec("DELETE FROM role_permissions").Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("清空角色权限关联失败: %v", err)
	}
	if err := tx.Exec("DELETE FROM permissions").Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("清空权限数据失败: %v", err)
	}

	// 批量插入权限，使用预设ID
	for _, perm := range permissions {
		if err := tx.Create(&perm).Error; err != nil {
			tx.Rollback()
			return fmt.Errorf("创建权限失败 (ID: %d, Name: %s): %v", perm.ID, perm.Name, err)
		}
	}

	// 提交事务
	if err := tx.Commit().Error; err != nil {
		return fmt.Errorf("提交事务失败: %v", err)
	}

	// 重新分配admin角色的所有权限
	if err := s.assignAllPermissionsToAdmin(); err != nil {
		return fmt.Errorf("分配admin权限失败: %v", err)
	}

	// 清除缓存
	s.cache = NewSimpleCache()

	return nil
}

// InitializeSimplifiedPermissions 初始化简化权限数据
func (s *PermissionService) InitializeSimplifiedPermissions() error {
	permissions := GetSimplifiedPermissions()
	
	// 开始事务
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 清空现有权限数据以确保ID一致性
	if err := tx.Exec("DELETE FROM role_permissions").Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("清空角色权限关联失败: %v", err)
	}
	if err := tx.Exec("DELETE FROM permissions").Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("清空权限数据失败: %v", err)
	}

	// 批量插入权限，使用预设ID
	for _, perm := range permissions {
		if err := tx.Create(&perm).Error; err != nil {
			tx.Rollback()
			return fmt.Errorf("创建权限失败 (ID: %d, Name: %s): %v", perm.ID, perm.Name, err)
		}
	}

	// 提交事务
	if err := tx.Commit().Error; err != nil {
		return fmt.Errorf("提交事务失败: %v", err)
	}

	// 重新分配admin角色的所有权限
	if err := s.assignAllPermissionsToAdmin(); err != nil {
		return fmt.Errorf("分配admin权限失败: %v", err)
	}

	// 清除缓存
	s.cache = NewSimpleCache()

	return nil
}

// assignAllPermissionsToAdmin 给admin角色分配所有权限
func (s *PermissionService) assignAllPermissionsToAdmin() error {
	// 查找admin角色
	var adminRole models.Role
	if err := s.db.Where("name = ?", "admin").First(&adminRole).Error; err != nil {
		return fmt.Errorf("找不到admin角色: %v", err)
	}

	// 获取所有权限
	var allPermissions []models.Permission
	if err := s.db.Find(&allPermissions).Error; err != nil {
		return fmt.Errorf("获取权限列表失败: %v", err)
	}

	// 清空admin角色的现有权限
	if err := s.db.Exec("DELETE FROM role_permissions WHERE role_id = ?", adminRole.ID).Error; err != nil {
		return fmt.Errorf("清空admin角色权限失败: %v", err)
	}

	// 为admin角色分配所有权限
	for _, permission := range allPermissions {
		rolePermission := struct {
			RoleID       uint `gorm:"primaryKey"`
			PermissionID uint `gorm:"primaryKey"`
		}{
			RoleID:       adminRole.ID,
			PermissionID: permission.ID,
		}
		
		if err := s.db.Table("role_permissions").Create(&rolePermission).Error; err != nil {
			return fmt.Errorf("分配权限失败 (权限ID: %d): %v", permission.ID, err)
		}
	}

	return nil
}
