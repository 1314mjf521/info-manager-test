package services

import (
	"fmt"
	"time"

	"info-management-system/internal/models"

	"gorm.io/gorm"
)

// UserService 用户服务
type UserService struct {
	db *gorm.DB
}

// NewUserService 创建用户服务
func NewUserService(db *gorm.DB) *UserService {
	return &UserService{db: db}
}

// UpdateProfileRequest 更新用户信息请求
type UpdateProfileRequest struct {
	Email string `json:"email" binding:"omitempty,email"`
}

// ChangePasswordRequest 修改密码请求
type ChangePasswordRequest struct {
	OldPassword string `json:"old_password" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=6"`
}

// GetProfile 获取用户信息
func (s *UserService) GetProfile(userID uint) (*UserInfo, error) {
	var user models.User
	if err := s.db.Preload("Roles").First(&user, userID).Error; err != nil {
		return nil, fmt.Errorf("用户不存在")
	}

	// 构建角色信息
	authRoles := make([]AuthRoleInfo, len(user.Roles))
	for i, role := range user.Roles {
		authRoles[i] = AuthRoleInfo{
			ID:          role.ID,
			Name:        role.Name,
			DisplayName: role.DisplayName,
			Description: role.Description,
		}
	}

	return &UserInfo{
		ID:          user.ID,
		Username:    user.Username,
		Email:       user.Email,
		IsActive:    user.IsActive,
		Roles:       authRoles,
		Permissions: []AuthPermissionInfo{}, // 空权限列表，如需要可以后续加载
	}, nil
}

// UpdateProfile 更新用户信息
func (s *UserService) UpdateProfile(userID uint, req *UpdateProfileRequest) (*UserInfo, error) {
	var user models.User
	if err := s.db.First(&user, userID).Error; err != nil {
		return nil, fmt.Errorf("用户不存在")
	}

	// 检查邮箱是否已被其他用户使用
	if req.Email != "" && req.Email != user.Email {
		var count int64
		if err := s.db.Model(&models.User{}).Where("email = ? AND id != ?", req.Email, userID).Count(&count).Error; err != nil {
			return nil, fmt.Errorf("检查邮箱失败: %v", err)
		}
		if count > 0 {
			return nil, fmt.Errorf("邮箱已被使用")
		}
		user.Email = req.Email
	}

	// 保存更新
	if err := s.db.Save(&user).Error; err != nil {
		return nil, fmt.Errorf("更新用户信息失败: %w", err)
	}

	// 重新加载用户信息
	return s.GetProfile(userID)
}

// ChangePassword 修改密码
func (s *UserService) ChangePassword(userID uint, req *ChangePasswordRequest) error {
	var user models.User
	if err := s.db.First(&user, userID).Error; err != nil {
		return fmt.Errorf("用户不存在")
	}

	// 验证旧密码
	if !user.CheckPassword(req.OldPassword) {
		return fmt.Errorf("原密码错误")
	}

	// 设置新密码
	if err := user.SetPassword(req.NewPassword); err != nil {
		return fmt.Errorf("密码加密失败: %w", err)
	}

	// 保存更新
	if err := s.db.Save(&user).Error; err != nil {
		return fmt.Errorf("修改密码失败: %w", err)
	}

	return nil
}

// GetUserByID 根据ID获取用户
func (s *UserService) GetUserByID(userID uint) (*models.User, error) {
	var user models.User
	if err := s.db.Preload("Roles.Permissions").First(&user, userID).Error; err != nil {
		return nil, fmt.Errorf("用户不存在")
	}
	return &user, nil
}

// CreateUserRequest 创建用户请求
type CreateUserRequest struct {
	Username    string `json:"username" binding:"required,min=3,max=20"`
	Email       string `json:"email" binding:"required,email"`
	DisplayName string `json:"displayName" binding:"required,max=200"`
	Password    string `json:"password" binding:"required,min=6"`
	Status      string `json:"status" binding:"omitempty,oneof=active inactive"`
	Description string `json:"description" binding:"max=500"`
}

// UpdateUserRequest 更新用户请求
type UpdateUserRequest struct {
	Username    string `json:"username" binding:"omitempty,min=3,max=20"`
	Email       string `json:"email" binding:"omitempty,email"`
	DisplayName string `json:"displayName" binding:"omitempty,max=200"`
	Status      string `json:"status" binding:"omitempty,oneof=active inactive"`
	Description string `json:"description" binding:"max=500"`
}

// AssignRolesRequest 分配角色请求
type AssignRolesRequest struct {
	RoleIDs []uint `json:"roleIds" binding:"required"`
}

// UserDetailResponse 用户详情响应
type UserDetailResponse struct {
	ID          uint           `json:"id"`
	Username    string         `json:"username"`
	Email       string         `json:"email"`
	DisplayName string         `json:"displayName"`
	Status      string         `json:"status"`
	IsActive    bool           `json:"isActive"`
	LastLogin   string         `json:"lastLoginAt"`
	LastLoginIP string         `json:"lastLoginIP"`
	Roles       []UserRoleInfo `json:"roles"`
	CreatedAt   string         `json:"createdAt"`
	UpdatedAt   string         `json:"updatedAt"`
}

// UserRoleInfo 用户角色信息
type UserRoleInfo struct {
	ID          uint   `json:"id"`
	Name        string `json:"name"`
	DisplayName string `json:"displayName"`
	Description string `json:"description"`
}

// GetAllUsers 获取所有用户
func (s *UserService) GetAllUsers(page, size int, username, email, status string) ([]UserDetailResponse, int64, error) {
	var users []models.User
	var total int64

	query := s.db.Model(&models.User{}).Preload("Roles")

	// 添加搜索条件
	if username != "" {
		query = query.Where("username LIKE ?", "%"+username+"%")
	}
	if email != "" {
		query = query.Where("email LIKE ?", "%"+email+"%")
	}
	if status != "" {
		query = query.Where("status = ?", status)
	}

	// 获取总数
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, fmt.Errorf("获取用户总数失败: %w", err)
	}

	// 分页查询
	offset := (page - 1) * size
	if err := query.Offset(offset).Limit(size).Find(&users).Error; err != nil {
		return nil, 0, fmt.Errorf("获取用户列表失败: %w", err)
	}

	// 转换为响应格式
	result := make([]UserDetailResponse, len(users))
	for i, user := range users {
		roles := make([]UserRoleInfo, len(user.Roles))
		for j, role := range user.Roles {
			roles[j] = UserRoleInfo{
				ID:          role.ID,
				Name:        role.Name,
				DisplayName: role.DisplayName,
				Description: role.Description,
			}
		}

		lastLogin := ""
		if user.LastLogin != nil {
			lastLogin = user.LastLogin.Format("2006-01-02 15:04:05")
		}

		result[i] = UserDetailResponse{
			ID:          user.ID,
			Username:    user.Username,
			Email:       user.Email,
			DisplayName: user.DisplayName,
			Status:      user.Status,
			IsActive:    user.IsActive,
			LastLogin:   lastLogin,
			LastLoginIP: user.LastLoginIP,
			Roles:       roles,
			CreatedAt:   user.CreatedAt.Format("2006-01-02 15:04:05"),
			UpdatedAt:   user.UpdatedAt.Format("2006-01-02 15:04:05"),
		}
	}

	return result, total, nil
}

// CreateUser 创建用户
func (s *UserService) CreateUser(req *CreateUserRequest) (*UserDetailResponse, error) {
	// 检查用户名是否已存在
	var count int64
	if err := s.db.Model(&models.User{}).Where("username = ?", req.Username).Count(&count).Error; err != nil {
		return nil, fmt.Errorf("检查用户名失败: %v", err)
	}
	if count > 0 {
		return nil, fmt.Errorf("用户名已存在")
	}

	// 检查邮箱是否已存在
	if err := s.db.Model(&models.User{}).Where("email = ?", req.Email).Count(&count).Error; err != nil {
		return nil, fmt.Errorf("检查邮箱失败: %v", err)
	}
	if count > 0 {
		return nil, fmt.Errorf("邮箱已存在")
	}

	// 加密密码
	hashedPassword, err := models.HashPassword(req.Password)
	if err != nil {
		return nil, fmt.Errorf("密码加密失败: %w", err)
	}

	status := req.Status
	if status == "" {
		status = "active"
	}

	user := models.User{
		Username:     req.Username,
		Email:        req.Email,
		DisplayName:  req.DisplayName,
		PasswordHash: hashedPassword,
		Status:       status,
		IsActive:     status == "active",
	}

	if err := s.db.Create(&user).Error; err != nil {
		return nil, fmt.Errorf("创建用户失败: %w", err)
	}

	lastLogin := ""
	if user.LastLogin != nil {
		lastLogin = user.LastLogin.Format("2006-01-02 15:04:05")
	}

	return &UserDetailResponse{
		ID:          user.ID,
		Username:    user.Username,
		Email:       user.Email,
		DisplayName: user.DisplayName,
		Status:      user.Status,
		IsActive:    user.IsActive,
		LastLogin:   lastLogin,
		LastLoginIP: user.LastLoginIP,
		Roles:       []UserRoleInfo{},
		CreatedAt:   user.CreatedAt.Format("2006-01-02 15:04:05"),
		UpdatedAt:   user.UpdatedAt.Format("2006-01-02 15:04:05"),
	}, nil
}

// UpdateUser 更新用户
func (s *UserService) UpdateUser(userID uint, req *UpdateUserRequest) (*UserDetailResponse, error) {
	var user models.User
	if err := s.db.First(&user, userID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("用户不存在")
		}
		return nil, fmt.Errorf("获取用户失败: %w", err)
	}

	// 检查用户名是否已被其他用户使用
	if req.Username != "" && req.Username != user.Username {
		var count int64
		if err := s.db.Model(&models.User{}).Where("username = ? AND id != ?", req.Username, userID).Count(&count).Error; err != nil {
			return nil, fmt.Errorf("检查用户名失败: %v", err)
		}
		if count > 0 {
			return nil, fmt.Errorf("用户名已被使用")
		}
		user.Username = req.Username
	}

	// 检查邮箱是否已被其他用户使用
	if req.Email != "" && req.Email != user.Email {
		var count int64
		if err := s.db.Model(&models.User{}).Where("email = ? AND id != ?", req.Email, userID).Count(&count).Error; err != nil {
			return nil, fmt.Errorf("检查邮箱失败: %v", err)
		}
		if count > 0 {
			return nil, fmt.Errorf("邮箱已被使用")
		}
		user.Email = req.Email
	}

	if req.DisplayName != "" {
		user.DisplayName = req.DisplayName
	}

	if req.Status != "" {
		user.Status = req.Status
		user.IsActive = req.Status == "active"
	}

	if err := s.db.Save(&user).Error; err != nil {
		return nil, fmt.Errorf("更新用户失败: %w", err)
	}

	// 重新获取用户详情
	return s.GetUserDetailByID(userID)
}

// DeleteUser 删除用户
func (s *UserService) DeleteUser(userID uint) error {
	var user models.User
	if err := s.db.First(&user, userID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("用户不存在")
		}
		return fmt.Errorf("获取用户失败: %w", err)
	}

	// 开始事务
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 删除用户角色关联
	if err := tx.Where("user_id = ?", userID).Delete(&models.UserRole{}).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("删除用户角色关联失败: %w", err)
	}

	// 删除用户
	if err := tx.Delete(&user).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("删除用户失败: %w", err)
	}

	return tx.Commit().Error
}

// AssignRoles 为用户分配角色
func (s *UserService) AssignRoles(userID uint, req *AssignRolesRequest) (*UserDetailResponse, error) {
	var user models.User
	if err := s.db.First(&user, userID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("用户不存在")
		}
		return nil, fmt.Errorf("获取用户失败: %w", err)
	}

	// 验证角色ID是否存在
	var roles []models.Role
	if err := s.db.Where("id IN ?", req.RoleIDs).Find(&roles).Error; err != nil {
		return nil, fmt.Errorf("获取角色失败: %w", err)
	}

	if len(roles) != len(req.RoleIDs) {
		return nil, fmt.Errorf("部分角色ID不存在")
	}

	// 开始事务
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 删除现有的用户角色关联
	if err := tx.Where("user_id = ?", userID).Delete(&models.UserRole{}).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("删除现有角色关联失败: %w", err)
	}

	// 创建新的用户角色关联
	for _, roleID := range req.RoleIDs {
		userRole := models.UserRole{
			UserID: userID,
			RoleID: roleID,
		}
		if err := tx.Create(&userRole).Error; err != nil {
			tx.Rollback()
			return nil, fmt.Errorf("创建角色关联失败: %w", err)
		}
	}

	if err := tx.Commit().Error; err != nil {
		return nil, fmt.Errorf("提交事务失败: %w", err)
	}

	// 重新获取用户详情
	return s.GetUserDetailByID(userID)
}

// GetUserRoles 获取用户角色
func (s *UserService) GetUserRoles(userID uint) ([]UserRoleInfo, error) {
	var user models.User
	if err := s.db.Preload("Roles").First(&user, userID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("用户不存在")
		}
		return nil, fmt.Errorf("获取用户失败: %w", err)
	}

	roles := make([]UserRoleInfo, len(user.Roles))
	for i, role := range user.Roles {
		roles[i] = UserRoleInfo{
			ID:          role.ID,
			Name:        role.Name,
			DisplayName: role.DisplayName,
			Description: role.Description,
		}
	}

	return roles, nil
}

// GetUserDetailByID 根据ID获取用户详情
func (s *UserService) GetUserDetailByID(userID uint) (*UserDetailResponse, error) {
	var user models.User
	if err := s.db.Preload("Roles").First(&user, userID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, fmt.Errorf("用户不存在")
		}
		return nil, fmt.Errorf("获取用户失败: %w", err)
	}

	roles := make([]UserRoleInfo, len(user.Roles))
	for i, role := range user.Roles {
		roles[i] = UserRoleInfo{
			ID:          role.ID,
			Name:        role.Name,
			DisplayName: role.DisplayName,
			Description: role.Description,
		}
	}

	lastLogin := ""
	if user.LastLogin != nil {
		lastLogin = user.LastLogin.Format("2006-01-02 15:04:05")
	}

	return &UserDetailResponse{
		ID:          user.ID,
		Username:    user.Username,
		Email:       user.Email,
		DisplayName: user.DisplayName,
		Status:      user.Status,
		IsActive:    user.IsActive,
		LastLogin:   lastLogin,
		LastLoginIP: user.LastLoginIP,
		Roles:       roles,
		CreatedAt:   user.CreatedAt.Format("2006-01-02 15:04:05"),
		UpdatedAt:   user.UpdatedAt.Format("2006-01-02 15:04:05"),
	}, nil
}

// BatchUpdateStatus 批量更新用户状态
func (s *UserService) BatchUpdateStatus(userIDs []uint, status string) error {
	return s.db.Model(&models.User{}).Where("id IN ?", userIDs).Update("status", status).Error
}

// BatchDeleteUsers 批量删除用户
func (s *UserService) BatchDeleteUsers(userIDs []uint) error {
	return s.db.Transaction(func(tx *gorm.DB) error {
		// 先删除用户角色关联
		if err := tx.Where("user_id IN ?", userIDs).Delete(&models.UserRole{}).Error; err != nil {
			return err
		}

		// 再删除用户
		return tx.Where("id IN ?", userIDs).Delete(&models.User{}).Error
	})
}

// PasswordResetResult 密码重置结果
type PasswordResetResult struct {
	UserID      uint   `json:"user_id"`
	Username    string `json:"username"`
	Email       string `json:"email"`
	NewPassword string `json:"new_password"`
	Success     bool   `json:"success"`
	Error       string `json:"error,omitempty"`
}

// BatchResetPassword 批量重置密码
func (s *UserService) BatchResetPassword(userIDs []uint) ([]PasswordResetResult, error) {
	var users []models.User
	if err := s.db.Where("id IN ?", userIDs).Find(&users).Error; err != nil {
		return nil, err
	}

	results := make([]PasswordResetResult, 0, len(users))

	for _, user := range users {
		result := PasswordResetResult{
			UserID:   user.ID,
			Username: user.Username,
			Email:    user.Email,
			Success:  false,
		}

		// 生成随机密码
		newPassword := generateRandomPassword(8)
		hashedPassword, err := models.HashPassword(newPassword)
		if err != nil {
			result.Error = "密码加密失败"
			results = append(results, result)
			continue
		}

		// 更新密码
		if err := s.db.Model(&user).Update("password_hash", hashedPassword).Error; err != nil {
			result.Error = "更新密码失败"
			results = append(results, result)
			continue
		}

		result.NewPassword = newPassword
		result.Success = true
		results = append(results, result)
	}

	return results, nil
}

// ResetPassword 重置单个用户密码
func (s *UserService) ResetPassword(userID uint) (*PasswordResetResult, error) {
	var user models.User
	if err := s.db.First(&user, userID).Error; err != nil {
		return nil, fmt.Errorf("用户不存在")
	}

	// 生成随机密码
	newPassword := generateRandomPassword(8)
	hashedPassword, err := models.HashPassword(newPassword)
	if err != nil {
		return nil, fmt.Errorf("密码加密失败: %v", err)
	}

	// 更新密码
	if err := s.db.Model(&user).Update("password_hash", hashedPassword).Error; err != nil {
		return nil, fmt.Errorf("更新密码失败: %v", err)
	}

	return &PasswordResetResult{
		UserID:      user.ID,
		Username:    user.Username,
		Email:       user.Email,
		NewPassword: newPassword,
		Success:     true,
	}, nil
}

// ImportUserData 导入用户数据结构
type ImportUserData struct {
	Username    string `json:"username" binding:"required"`
	Email       string `json:"email" binding:"required,email"`
	DisplayName string `json:"displayName" binding:"required"`
	Roles       string `json:"roles"`
	Status      string `json:"status"`
	Password    string `json:"password"`
	Description string `json:"description"`
}

// ImportResult 导入结果
type ImportResult struct {
	Username string `json:"username"`
	Email    string `json:"email"`
	Success  bool   `json:"success"`
	Error    string `json:"error,omitempty"`
	UserID   uint   `json:"user_id,omitempty"`
}

// ImportUsers 导入用户
func (s *UserService) ImportUsers(userData []ImportUserData) ([]ImportResult, error) {
	results := make([]ImportResult, 0, len(userData))

	for _, data := range userData {
		result := ImportResult{
			Username: data.Username,
			Email:    data.Email,
			Success:  false,
		}

		// 检查用户名是否已存在
		var existingUser models.User
		if err := s.db.Where("username = ? OR email = ?", data.Username, data.Email).First(&existingUser).Error; err == nil {
			result.Error = "用户名或邮箱已存在"
			results = append(results, result)
			continue
		}

		// 生成密码
		password := data.Password
		if password == "" {
			password = generateRandomPassword(8)
		}

		hashedPassword, err := models.HashPassword(password)
		if err != nil {
			result.Error = "密码加密失败"
			results = append(results, result)
			continue
		}

		// 设置默认状态
		status := data.Status
		if status == "" {
			status = "active"
		}

		// 创建用户
		user := models.User{
			Username:     data.Username,
			Email:        data.Email,
			DisplayName:  data.DisplayName,
			PasswordHash: hashedPassword,
			Status:       status,
			IsActive:     status == "active",
		}

		if err := s.db.Create(&user).Error; err != nil {
			result.Error = "创建用户失败"
			results = append(results, result)
			continue
		}

		// 分配角色
		if data.Roles != "" {
			var role models.Role
			if err := s.db.Where("name = ?", data.Roles).First(&role).Error; err == nil {
				userRole := models.UserRole{
					UserID: user.ID,
					RoleID: role.ID,
				}
				s.db.Create(&userRole)
			}
		}

		result.Success = true
		result.UserID = user.ID
		results = append(results, result)
	}

	return results, nil
}

// generateRandomPassword 生成随机密码
func generateRandomPassword(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	password := make([]byte, length)

	for i := range password {
		// 使用当前时间纳秒和索引来生成伪随机数
		seed := time.Now().UnixNano() + int64(i*7919) // 7919是一个质数
		password[i] = charset[seed%int64(len(charset))]
	}

	return string(password)
}
