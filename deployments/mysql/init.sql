-- 初始化数据库脚本
-- 设置字符集
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 创建数据库（如果不存在）
CREATE DATABASE IF NOT EXISTS info_system 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- 使用数据库
USE info_system;

-- 创建应用用户（如果不存在）
CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY 'apppassword';
GRANT ALL PRIVILEGES ON info_system.* TO 'appuser'@'%';

-- 刷新权限
FLUSH PRIVILEGES;

-- 设置时区
SET time_zone = '+08:00';

SET FOREIGN_KEY_CHECKS = 1;