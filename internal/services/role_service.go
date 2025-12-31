package services

import (
	"fmt"

	"info-management-system/internal/models"

	"gorm.io/gorm"
)

// RoleService 角色服务
type RoleService struct {
	db *gorm.DB
}

// NewRoleService 创建角色服务
func NewRoleService(db *gorm.DB) *RoleService {
	return &RoleService{db: db}
}

// CreateRoleRequest 创建角色请求
type CreateRoleRequest struct {
	Name        string `json:"name" binding:"required,min=2,max=50"`
	DisplayName string `json:"displayName" binding:"required,max=200"`
	Description string `json:"description" binding:"max=500"`
	Status      string `json:"status" binding:"omitempty,oneof=active inactive"`
}

// UpdateRoleRequest 更新角色请求
type UpdateRoleRequest struct {
	Name        string `json:"name" binding:"omitempty,min=2,max=50"`
	DisplayName string `json:"displayName" binding:"omitempty,max=200"`
	Description string `json:"description" binding:"max=500"`
	Status      string `json:"status" binding:"omitempty,oneof=active inactive"`
}

// AssignPermissionsRequest 分配权限请求
type AssignPermissionsRequest struct {
	PermissionIDs []uint `json:"permissionIds" binding:"required"`
}

// RoleDetailResponse 角色详情响应
type RoleDetailResponse struct {
	ID          uint             `json:"id"`
	Name        string           `json:"name"`
	DisplayName string           `json:"displayName"`
	Description string           `json:"description"`
	Status      string           `json:"status"`
	IsSystem    bool             `json:"is_system"`
	Permissions []PermissionInfo `json:"permissions"`
	UserCount   int64            `json:"userCount"`
	CreatedAt   string           `json:"createdAt"`
	UpdatedAt   string           `json:"updatedAt"`
}

// GetAllRoles 获取所有角色
func (s *RoleService) GetAllRoles() ([]RoleDetailResponse, error) {
	var roles []models.Role
	if err := s.db.Preload("Permissions").Find(&roles).Error; err != nil {
		return nil, fmt.Errorf("获取角色列表失败: %w", err)
	}

	result := make([]RoleDetailResponse, len(roles))
	for i, role := range roles {
		// 获取用户数量
		var userCount int64
		s.db.Model(&models.UserRole{}).Where("role_id = ?", role.ID).Count(&userCount)

		// 转换权限信息
		permissions := make([]PermissionInfo, len(role.Permissions))
		for j, permission := range role.Permissions {
			permissions[j] = PermissionInfo{
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

		result[i] = RoleDetailResponse{
			ID:          role.ID,
			Name:        role.Name,
			DisplayName: role.DisplayName,
			Description: role.Description,
			Status:      role.Status,
			IsSystem:    role.IsSystem,
			Permissions: permissions,
			UserCount:   userCount,
			CreatedAt:   role.CreatedAt.Format("2006-01-02 15:04:05"),
			UpdatedAt:   role.UpdatedAt.Format("2006-01-02 15:04:05"),
		}
	}

	return result, nil
}

// GetRoleByID 根据ID获取角色
func (s *RoleService) GetRoleByID(roleID uint) (*RoleDetailResponse, error) {
	var role models.Role
	if err := s.db.Preload("Permissions").First(&role, roleID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("角色不存在")
		}
		return nil, fmt.Errorf("获取角色失败: %w", err)
	}

	// 获取用户数量
	var userCount int64
	s.db.Model(&models.UserRole{}).Where("role_id = ?", role.ID).Count(&userCount)

	// 转换权限信息
	permissions := make([]PermissionInfo, len(role.Permissions))
	for i, permission := range role.Permissions {
		permissions[i] = PermissionInfo{
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

	return &RoleDetailResponse{
		ID:          role.ID,
		Name:        role.Name,
		DisplayName: role.DisplayName,
		Description: role.Description,
		Status:      role.Status,
		IsSystem:    role.IsSystem,
		Permissions: permissions,
		UserCount:   userCount,
		CreatedAt:   role.CreatedAt.Format("2006-01-02 15:04:05"),
		UpdatedAt:   role.UpdatedAt.Format("2006-01-02 15:04:05"),
	}, nil
}

// CreateRole 创建角色
func (s *RoleService) CreateRole(req *CreateRoleRequest) (*RoleDetailResponse, error) {
	// 检查角色名是否已存在
	var count int64
	if err := s.db.Model(&models.Role{}).Where("name = ?", req.Name).Count(&count).Error; err != nil {
		return nil, fmt.Errorf("检查角色名失败: %v", err)
	}
	if count > 0 {
		return nil, fmt.Errorf("角色名已存在")
	}

	status := req.Status
	if status == "" {
		status = "active"
	}

	role := models.Role{
		Name:        req.Name,
		DisplayName: req.DisplayName,
		Description: req.Description,
		Status:      status,
		IsSystem:    false, // 用户创建的角色不是系统角色
	}

	if err := s.db.Create(&role).Error; err != nil {
		return nil, fmt.Errorf("创建角色失败: %w", err)
	}

	return &RoleDetailResponse{
		ID:          role.ID,
		Name:        role.Name,
		DisplayName: role.DisplayName,
		Description: role.Description,
		Status:      role.Status,
		IsSystem:    role.IsSystem,
		Permissions: []PermissionInfo{},
		UserCount:   0,
		CreatedAt:   role.CreatedAt.Format("2006-01-02 15:04:05"),
		UpdatedAt:   role.UpdatedAt.Format("2006-01-02 15:04:05"),
	}, nil
}

// UpdateRole 更新角色
func (s *RoleService) UpdateRole(roleID uint, req *UpdateRoleRequest) (*RoleDetailResponse, error) {
	var role models.Role
	if err := s.db.First(&role, roleID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("角色不存在")
		}
		return nil, fmt.Errorf("获取角色失败: %w", err)
	}

	// 检查是否为系统角色
	if role.IsSystem {
		return nil, fmt.Errorf("系统角色不能修改")
	}

	// 检查角色名是否已被其他角色使用
	if req.Name != "" && req.Name != role.Name {
		var count int64
		if err := s.db.Model(&models.Role{}).Where("name = ? AND id != ?", req.Name, roleID).Count(&count).Error; err != nil {
			return nil, fmt.Errorf("检查角色名失败: %v", err)
		}
		if count > 0 {
			return nil, fmt.Errorf("角色名已被使用")
		}
		role.Name = req.Name
	}

	if req.DisplayName != "" {
		role.DisplayName = req.DisplayName
	}

	if req.Description != "" {
		role.Description = req.Description
	}

	if req.Status != "" {
		role.Status = req.Status
	}

	if err := s.db.Save(&role).Error; err != nil {
		return nil, fmt.Errorf("更新角色失败: %w", err)
	}

	// 重新获取角色详情
	return s.GetRoleByID(roleID)
}

// DeleteRole 删除角色
func (s *RoleService) DeleteRole(roleID uint) error {
	var role models.Role
	if err := s.db.First(&role, roleID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("角色不存在")
		}
		return fmt.Errorf("获取角色失败: %w", err)
	}

	// 检查是否为系统角色
	if role.IsSystem {
		return fmt.Errorf("系统角色不能删除")
	}

	// 检查是否有用户使用该角色
	var userCount int64
	s.db.Model(&models.UserRole{}).Where("role_id = ?", roleID).Count(&userCount)
	if userCount > 0 {
		return fmt.Errorf("该角色正在被 %d 个用户使用，无法删除", userCount)
	}

	// 开始事务
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 删除角色权限关联
	if err := tx.Where("role_id = ?", roleID).Delete(&models.RolePermission{}).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("删除角色权限关联失败: %w", err)
	}

	// 删除角色
	if err := tx.Delete(&role).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("删除角色失败: %w", err)
	}

	return tx.Commit().Error
}

// AssignPermissions 为角色分配权限
func (s *RoleService) AssignPermissions(roleID uint, req *AssignPermissionsRequest) (*RoleDetailResponse, error) {
	var role models.Role
	if err := s.db.First(&role, roleID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("角色不存在")
		}
		return nil, fmt.Errorf("获取角色失败: %w", err)
	}

	// 验证权限ID是否存在
	var permissions []models.Permission
	if err := s.db.Where("id IN ?", req.PermissionIDs).Find(&permissions).Error; err != nil {
		return nil, fmt.Errorf("获取权限失败: %w", err)
	}

	if len(permissions) != len(req.PermissionIDs) {
		// 找出缺失的权限ID
		foundIDs := make(map[uint]bool)
		for _, perm := range permissions {
			foundIDs[perm.ID] = true
		}
		
		var missingIDs []uint
		for _, id := range req.PermissionIDs {
			if !foundIDs[id] {
				missingIDs = append(missingIDs, id)
			}
		}
		
		return nil, fmt.Errorf("权限ID不存在: %v (请求: %v, 找到: %d个)", missingIDs, req.PermissionIDs, len(permissions))
	}

	// 开始事务
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 删除现有的角色权限关联
	if err := tx.Where("role_id = ?", roleID).Delete(&models.RolePermission{}).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("删除现有权限关联失败: %w", err)
	}

	// 创建新的角色权限关联
	for _, permissionID := range req.PermissionIDs {
		rolePermission := models.RolePermission{
			RoleID:       roleID,
			PermissionID: permissionID,
		}
		if err := tx.Create(&rolePermission).Error; err != nil {
			tx.Rollback()
			return nil, fmt.Errorf("创建权限关联失败: %w", err)
		}
	}

	if err := tx.Commit().Error; err != nil {
		return nil, fmt.Errorf("提交事务失败: %w", err)
	}

	// 重新获取角色详情
	return s.GetRoleByID(roleID)
}

// GetRolePermissions 获取角色权限
func (s *RoleService) GetRolePermissions(roleID uint) ([]PermissionInfo, error) {
	var role models.Role
	if err := s.db.Preload("Permissions").First(&role, roleID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("角色不存在")
		}
		return nil, fmt.Errorf("获取角色失败: %w", err)
	}

	permissions := make([]PermissionInfo, len(role.Permissions))
	for i, permission := range role.Permissions {
		permissions[i] = PermissionInfo{
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

	return permissions, nil
}

// ImportRoleData 导入角色数据结构
type ImportRoleData struct {
	Name        string `json:"name" binding:"required"`
	DisplayName string `json:"displayName" binding:"required"`
	Description string `json:"description"`
	Status      string `json:"status"`
	Permissions string `json:"permissions"` // 权限名称，用逗号分隔
}

// ImportRolesRequest 导入角色请求
type ImportRolesRequest struct {
	Roles []ImportRoleData `json:"roles" binding:"required"`
}

// ImportRoleResult 导入角色结果
type ImportRoleResult struct {
	Name        string `json:"name"`
	DisplayName string `json:"displayName"`
	Success     bool   `json:"success"`
	Error       string `json:"error,omitempty"`
	RoleID      uint   `json:"role_id,omitempty"`
}

// BatchUpdateRoleStatusRequest 批量更新角色状态请求
type BatchUpdateRoleStatusRequest struct {
	RoleIDs []uint `json:"role_ids" binding:"required"`
	Status  string `json:"status" binding:"required,oneof=active inactive"`
}

// BatchDeleteRolesRequest 批量删除角色请求
type BatchDeleteRolesRequest struct {
	RoleIDs []uint `json:"role_ids" binding:"required"`
}

// ImportRoles 导入角色
func (s *RoleService) ImportRoles(req *ImportRolesRequest) ([]ImportRoleResult, error) {
	results := make([]ImportRoleResult, 0, len(req.Roles))

	for _, data := range req.Roles {
		result := ImportRoleResult{
			Name:        data.Name,
			DisplayName: data.DisplayName,
			Success:     false,
		}

		// 检查角色名是否已存在
		var existingRole models.Role
		if err := s.db.Where("name = ?", data.Name).First(&existingRole).Error; err == nil {
			result.Error = "角色名已存在"
			results = append(results, result)
			continue
		}

		// 设置默认状态
		status := data.Status
		if status == "" {
			status = "active"
		}

		// 创建角色
		role := models.Role{
			Name:        data.Name,
			DisplayName: data.DisplayName,
			Description: data.Description,
			Status:      status,
			IsSystem:    false,
		}

		if err := s.db.Create(&role).Error; err != nil {
			result.Error = "创建角色失败"
			results = append(results, result)
			continue
		}

		// 处理权限分配
		if data.Permissions != "" {
			permissionNames := make([]string, 0)
			for _, name := range splitAndTrim(data.Permissions, ",") {
				if name != "" {
					permissionNames = append(permissionNames, name)
				}
			}

			if len(permissionNames) > 0 {
				var permissions []models.Permission
				if err := s.db.Where("name IN ?", permissionNames).Find(&permissions).Error; err == nil {
					// 创建角色权限关联
					for _, permission := range permissions {
						rolePermission := models.RolePermission{
							RoleID:       role.ID,
							PermissionID: permission.ID,
						}
						s.db.Create(&rolePermission)
					}
				}
			}
		}

		result.Success = true
		result.RoleID = role.ID
		results = append(results, result)
	}

	return results, nil
}

// BatchUpdateRoleStatus 批量更新角色状态
func (s *RoleService) BatchUpdateRoleStatus(req *BatchUpdateRoleStatusRequest) error {
	// 检查是否包含系统角色
	var systemRoleCount int64
	if err := s.db.Model(&models.Role{}).Where("id IN ? AND is_system = ?", req.RoleIDs, true).Count(&systemRoleCount).Error; err != nil {
		return fmt.Errorf("检查系统角色失败: %w", err)
	}

	if systemRoleCount > 0 {
		return fmt.Errorf("不能修改系统角色状态")
	}

	return s.db.Model(&models.Role{}).Where("id IN ?", req.RoleIDs).Update("status", req.Status).Error
}

// BatchDeleteRoles 批量删除角色
func (s *RoleService) BatchDeleteRoles(req *BatchDeleteRolesRequest) error {
	// 检查是否包含系统角色
	var systemRoleCount int64
	if err := s.db.Model(&models.Role{}).Where("id IN ? AND is_system = ?", req.RoleIDs, true).Count(&systemRoleCount).Error; err != nil {
		return fmt.Errorf("检查系统角色失败: %w", err)
	}

	if systemRoleCount > 0 {
		return fmt.Errorf("不能删除系统角色")
	}

	// 检查是否有用户使用这些角色
	var userRoleCount int64
	if err := s.db.Model(&models.UserRole{}).Where("role_id IN ?", req.RoleIDs).Count(&userRoleCount).Error; err != nil {
		return fmt.Errorf("检查用户角色关联失败: %w", err)
	}

	if userRoleCount > 0 {
		return fmt.Errorf("部分角色正在被用户使用，无法删除")
	}

	return s.db.Transaction(func(tx *gorm.DB) error {
		// 先删除角色权限关联
		if err := tx.Where("role_id IN ?", req.RoleIDs).Delete(&models.RolePermission{}).Error; err != nil {
			return err
		}

		// 再删除角色
		return tx.Where("id IN ?", req.RoleIDs).Delete(&models.Role{}).Error
	})
}

// splitAndTrim 分割字符串并去除空白
func splitAndTrim(s, sep string) []string {
	if s == "" {
		return []string{}
	}

	parts := make([]string, 0)
	for _, part := range splitString(s, sep) {
		trimmed := trimString(part)
		if trimmed != "" {
			parts = append(parts, trimmed)
		}
	}
	return parts
}

// splitString 分割字符串
func splitString(s, sep string) []string {
	if s == "" {
		return []string{}
	}

	result := make([]string, 0)
	start := 0

	for i := 0; i < len(s); {
		if i+len(sep) <= len(s) && s[i:i+len(sep)] == sep {
			result = append(result, s[start:i])
			start = i + len(sep)
			i = start
		} else {
			i++
		}
	}

	result = append(result, s[start:])
	return result
}

// trimString 去除字符串两端空白
func trimString(s string) string {
	start := 0
	end := len(s)

	// 去除开头空白
	for start < end && (s[start] == ' ' || s[start] == '\t' || s[start] == '\n' || s[start] == '\r') {
		start++
	}

	// 去除结尾空白
	for end > start && (s[end-1] == ' ' || s[end-1] == '\t' || s[end-1] == '\n' || s[end-1] == '\r') {
		end--
	}

	return s[start:end]
}
