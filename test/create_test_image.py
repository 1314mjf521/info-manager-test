#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
创建OCR测试图片
生成包含中英文文字的测试图片用于OCR识别测试
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_test_image():
    """创建包含中英文文字的测试图片"""
    
    # 创建图片
    width, height = 800, 600
    image = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(image)
    
    # 尝试使用系统字体
    try:
        # Windows系统字体
        font_large = ImageFont.truetype("arial.ttf", 48)
        font_medium = ImageFont.truetype("arial.ttf", 32)
        font_small = ImageFont.truetype("arial.ttf", 24)
    except:
        try:
            # 备用字体
            font_large = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 48)
            font_medium = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 32)
            font_small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 24)
        except:
            # 使用默认字体
            font_large = ImageFont.load_default()
            font_medium = ImageFont.load_default()
            font_small = ImageFont.load_default()
    
    # 绘制标题
    title_text = "OCR Test Image"
    draw.text((50, 50), title_text, fill='black', font=font_large)
    
    # 绘制英文文本
    english_text = "Hello World! This is a test for OCR recognition."
    draw.text((50, 120), english_text, fill='blue', font=font_medium)
    
    # 绘制数字
    number_text = "Phone: +86 138-0013-8000"
    draw.text((50, 170), number_text, fill='red', font=font_medium)
    
    # 绘制邮箱
    email_text = "Email: test@example.com"
    draw.text((50, 220), email_text, fill='green', font=font_medium)
    
    # 绘制日期
    date_text = "Date: 2025-10-03"
    draw.text((50, 270), date_text, fill='purple', font=font_medium)
    
    # 绘制地址
    address_text = "Address: 123 Main Street, City, Country"
    draw.text((50, 320), address_text, fill='brown', font=font_small)
    
    # 绘制多行文本
    multiline_text = """This is a multi-line text example.
It contains multiple sentences.
Each line should be recognized separately.
OCR should handle this correctly."""
    
    y_position = 370
    for line in multiline_text.split('\n'):
        draw.text((50, y_position), line, fill='black', font=font_small)
        y_position += 30
    
    # 绘制边框
    draw.rectangle([10, 10, width-10, height-10], outline='black', width=2)
    
    # 保存图片
    output_dir = "test/test_images"
    os.makedirs(output_dir, exist_ok=True)
    
    image_path = os.path.join(output_dir, "ocr_test_english.png")
    image.save(image_path)
    print(f"测试图片已创建: {image_path}")
    
    return image_path

def create_chinese_test_image():
    """创建包含中文的测试图片"""
    
    # 创建图片
    width, height = 800, 600
    image = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(image)
    
    # 尝试使用中文字体
    try:
        # Windows中文字体
        font_large = ImageFont.truetype("C:/Windows/Fonts/simsun.ttc", 48)
        font_medium = ImageFont.truetype("C:/Windows/Fonts/simsun.ttc", 32)
        font_small = ImageFont.truetype("C:/Windows/Fonts/simsun.ttc", 24)
    except:
        try:
            # 备用中文字体
            font_large = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 48)
            font_medium = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 32)
            font_small = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 24)
        except:
            # 使用默认字体
            font_large = ImageFont.load_default()
            font_medium = ImageFont.load_default()
            font_small = ImageFont.load_default()
    
    # 绘制中文标题
    title_text = "OCR中文测试图片"
    draw.text((50, 50), title_text, fill='black', font=font_large)
    
    # 绘制中文文本
    chinese_text = "你好世界！这是一个OCR识别测试。"
    draw.text((50, 120), chinese_text, fill='blue', font=font_medium)
    
    # 绘制联系信息
    contact_text = "联系电话：138-0013-8000"
    draw.text((50, 170), contact_text, fill='red', font=font_medium)
    
    # 绘制邮箱
    email_text = "电子邮箱：测试@示例.com"
    draw.text((50, 220), email_text, fill='green', font=font_medium)
    
    # 绘制日期
    date_text = "日期：2025年10月3日"
    draw.text((50, 270), date_text, fill='purple', font=font_medium)
    
    # 绘制地址
    address_text = "地址：北京市朝阳区某某街道123号"
    draw.text((50, 320), address_text, fill='brown', font=font_small)
    
    # 绘制多行中文文本
    multiline_text = """这是一个多行中文文本示例。
它包含多个句子和段落。
每一行都应该被正确识别。
OCR应该能够处理中文字符。"""
    
    y_position = 370
    for line in multiline_text.split('\n'):
        draw.text((50, y_position), line, fill='black', font=font_small)
        y_position += 35
    
    # 绘制边框
    draw.rectangle([10, 10, width-10, height-10], outline='black', width=2)
    
    # 保存图片
    output_dir = "test/test_images"
    os.makedirs(output_dir, exist_ok=True)
    
    image_path = os.path.join(output_dir, "ocr_test_chinese.png")
    image.save(image_path)
    print(f"中文测试图片已创建: {image_path}")
    
    return image_path

def create_mixed_test_image():
    """创建包含中英文混合的测试图片"""
    
    # 创建图片
    width, height = 800, 700
    image = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(image)
    
    # 尝试使用字体
    try:
        font_large = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 48)
        font_medium = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 32)
        font_small = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 24)
    except:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    # 绘制混合标题
    title_text = "OCR Mixed Language Test 中英文混合测试"
    draw.text((50, 50), title_text, fill='black', font=font_large)
    
    # 绘制混合文本
    mixed_texts = [
        "Name 姓名: Zhang San 张三",
        "Company 公司: ABC Technology Ltd. ABC科技有限公司",
        "Position 职位: Software Engineer 软件工程师",
        "Phone 电话: +86 138-0013-8000",
        "Email 邮箱: zhangsan@abc-tech.com",
        "Address 地址: Room 1001, Building A, 北京市朝阳区",
        "Project 项目: Information Management System 信息管理系统",
        "Status 状态: In Development 开发中",
        "Priority 优先级: High 高",
        "Deadline 截止日期: 2025-12-31"
    ]
    
    y_position = 120
    colors = ['blue', 'red', 'green', 'purple', 'brown', 'orange', 'navy', 'darkgreen', 'darkred', 'darkblue']
    
    for i, text in enumerate(mixed_texts):
        color = colors[i % len(colors)]
        draw.text((50, y_position), text, fill=color, font=font_medium)
        y_position += 40
    
    # 绘制表格样式的数据
    table_title = "Test Data 测试数据:"
    draw.text((50, y_position + 20), table_title, fill='black', font=font_medium)
    
    table_data = [
        "ID | Name | Age | City",
        "1  | John | 25  | Beijing 北京",
        "2  | Mary | 30  | Shanghai 上海", 
        "3  | 李四 | 28  | Guangzhou 广州",
        "4  | 王五 | 35  | Shenzhen 深圳"
    ]
    
    y_position += 60
    for data in table_data:
        draw.text((50, y_position), data, fill='black', font=font_small)
        y_position += 25
    
    # 绘制边框
    draw.rectangle([10, 10, width-10, height-10], outline='black', width=2)
    
    # 保存图片
    output_dir = "test/test_images"
    os.makedirs(output_dir, exist_ok=True)
    
    image_path = os.path.join(output_dir, "ocr_test_mixed.png")
    image.save(image_path)
    print(f"混合语言测试图片已创建: {image_path}")
    
    return image_path

if __name__ == "__main__":
    print("开始创建OCR测试图片...")
    
    try:
        # 创建英文测试图片
        english_path = create_test_image()
        
        # 创建中文测试图片
        chinese_path = create_chinese_test_image()
        
        # 创建混合语言测试图片
        mixed_path = create_mixed_test_image()
        
        print("\n所有测试图片创建完成:")
        print(f"1. 英文测试图片: {english_path}")
        print(f"2. 中文测试图片: {chinese_path}")
        print(f"3. 混合语言测试图片: {mixed_path}")
        
    except Exception as e:
        print(f"创建测试图片时出错: {e}")
        print("请确保已安装Pillow库: pip install Pillow")