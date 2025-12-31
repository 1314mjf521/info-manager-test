-- 数据库性能优化脚本
-- 为工单系统添加必要的索引以提高查询性能

-- 工单表索引优化
-- 复合索引：创建人和状态
CREATE INDEX IF NOT EXISTS idx_tickets_creator_status ON tickets(creator_id, status);

-- 复合索引：处理人和状态
CREATE INDEX IF NOT EXISTS idx_tickets_assignee_status ON tickets(assignee_id, status);

-- 复合索引：创建人和创建时间（用于排序）
CREATE INDEX IF NOT EXISTS idx_tickets_creator_created ON tickets(creator_id, created_at DESC);

-- 复合索引：处理人和创建时间（用于排序）
CREATE INDEX IF NOT EXISTS idx_tickets_assignee_created ON tickets(assignee_id, created_at DESC);

-- 复合索引：状态、类型、优先级（用于筛选）
CREATE INDEX IF NOT EXISTS idx_tickets_status_type_priority ON tickets(status, type, priority);

-- 全文搜索索引（如果支持）
-- CREATE FULLTEXT INDEX IF NOT EXISTS idx_tickets_fulltext ON tickets(title, description);

-- 工单评论表索引
CREATE INDEX IF NOT EXISTS idx_ticket_comments_ticket_created ON ticket_comments(ticket_id, created_at ASC);

-- 工单历史表索引
CREATE INDEX IF NOT EXISTS idx_ticket_history_ticket_created ON ticket_history(ticket_id, created_at ASC);

-- 工单附件表索引
CREATE INDEX IF NOT EXISTS idx_ticket_attachments_ticket ON ticket_attachments(ticket_id);

-- 系统日志表索引优化（减少慢查询）
CREATE INDEX IF NOT EXISTS idx_system_logs_category_message ON system_logs(category, message);
CREATE INDEX IF NOT EXISTS idx_system_logs_created_desc ON system_logs(created_at DESC);

-- 用户角色表索引
CREATE INDEX IF NOT EXISTS idx_user_roles_user ON user_roles(user_id);

-- 公告表索引
CREATE INDEX IF NOT EXISTS idx_announcements_active_time ON announcements(is_active, start_time, end_time);

-- 分析表以更新统计信息（MySQL）
-- ANALYZE TABLE tickets;
-- ANALYZE TABLE ticket_comments;
-- ANALYZE TABLE ticket_history;
-- ANALYZE TABLE ticket_attachments;
-- ANALYZE TABLE system_logs;
-- ANALYZE TABLE users;
-- ANALYZE TABLE announcements;

-- 优化建议：
-- 1. 定期清理旧的系统日志以减少表大小
-- 2. 考虑对大表进行分区
-- 3. 监控慢查询日志并持续优化
-- 4. 考虑使用缓存来减少数据库查询