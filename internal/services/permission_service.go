package services

import (
	"fmt"

	"info-management-system/internal/models"

	"gorm.io/gorm"
)

// PermissionService 权限服务
type PermissionService struct {
	db *gorm.DB
}

// NewPermissionService 创建权限服务
func NewPermissionService(db *gorm.DB) *PermissionService {
	return &PermissionService{db: db}
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

// GetUserPermissions 获取用户所有权限
func (s *PermissionService) GetUserPermissions(userID uint) (*UserPermissionsResponse, error) {
	// 获取用户及其角色和权限
	var user models.User
	if err := s.db.Preload("Roles.Permissions").First(&user, userID).Error; err != nil {
		return nil, fmt.Errorf("用户不存在")
	}

	// 构建角色信息
	roles := make([]RoleInfo, len(user.Roles))
	for i, role := range user.Roles {
		roles[i] = RoleInfo{
			ID:          role.ID,
			Name:        role.Name,
			Description: role.Description,
			IsSystem:    role.IsSystem,
		}
	}

	// 收集所有权限（去重）
	permissionMap := make(map[string]models.Permission)
	resourceActionMap := make(map[string][]string)

	for _, role := range user.Roles {
		for _, permission := range role.Permissions {
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
	}

	// 转换为权限信息列表
	permissions := make([]PermissionInfo, 0, len(permissionMap))
	for _, permission := range permissionMap {
		permissions = append(permissions, PermissionInfo{
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

	return &UserPermissionsResponse{
		UserID:        user.ID,
		Username:      user.Username,
		Roles:         roles,
		Permissions:   permissions,
		PermissionMap: resourceActionMap,
	}, nil
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
	if err := s.db.Preload("Children").Find(&permissions).Error; err != nil {
		return nil, fmt.Errorf("获取权限列表失败: %w", err)
	}

	// 构建权限映射
	permissionMap := make(map[uint]*PermissionInfo)
	var rootPermissions []PermissionInfo

	// 第一遍：创建所有权限节点
	for _, permission := range permissions {
		permInfo := &PermissionInfo{
			ID:          permission.ID,
			Name:        permission.Name,
			DisplayName: permission.DisplayName,
			Description: permission.Description,
			Resource:    permission.Resource,
			Action:      permission.Action,
			Scope:       permission.Scope,
			ParentID:    permission.ParentID,
			Children:    []PermissionInfo{},
		}
		permissionMap[permission.ID] = permInfo
	}

	// 第二遍：构建树结构
	for _, permission := range permissions {
		permInfo := permissionMap[permission.ID]
		if permission.ParentID == nil {
			// 根节点
			rootPermissions = append(rootPermissions, *permInfo)
		} else {
			// 子节点，添加到父节点的children中
			if parent, exists := permissionMap[*permission.ParentID]; exists {
				parent.Children = append(parent.Children, *permInfo)
			}
		}
	}

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
