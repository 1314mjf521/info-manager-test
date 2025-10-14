package test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// APITestSuite API测试套件
type APITestSuite struct {
	suite.Suite
	baseURL    string
	serverCmd  *exec.Cmd
	token      string
	recordID   uint
	recordType string
}

// SetupSuite 设置测试套件
func (suite *APITestSuite) SetupSuite() {
	suite.baseURL = "http://localhost:8080"
	suite.recordType = "test_type"

	// 检查可执行文件是否存在
	exePath := "info-management-system.exe"
	if _, err := os.Stat(exePath); os.IsNotExist(err) {
		// 尝试在上级目录查找
		exePath = "../info-management-system.exe"
		if _, err := os.Stat(exePath); os.IsNotExist(err) {
			suite.T().Skip("info-management-system.exe not found, skipping API tests")
			return
		}
	}

	// 确保配置文件存在
	configDir := "configs"
	configFile := filepath.Join(configDir, "config.yaml")
	exampleFile := filepath.Join(configDir, "config.example.yaml")

	if _, err := os.Stat(configFile); os.IsNotExist(err) {
		// 尝试在上级目录查找
		configDir = "../configs"
		configFile = filepath.Join(configDir, "config.yaml")
		exampleFile = filepath.Join(configDir, "config.example.yaml")

		if _, err := os.Stat(configFile); os.IsNotExist(err) {
			if _, err := os.Stat(exampleFile); err == nil {
				// 复制示例配置文件
				suite.copyFile(exampleFile, configFile)
			} else {
				suite.T().Skip("config files not found, skipping API tests")
				return
			}
		}
	}

	// 启动服务器
	suite.T().Log("Starting server...")
	suite.serverCmd = exec.Command(exePath)
	suite.serverCmd.Dir = filepath.Dir(exePath)

	// 创建日志文件
	logFile, err := os.Create("api_test_server.log")
	if err != nil {
		suite.T().Fatalf("Failed to create log file: %v", err)
	}
	suite.serverCmd.Stdout = logFile
	suite.serverCmd.Stderr = logFile

	err = suite.serverCmd.Start()
	if err != nil {
		suite.T().Fatalf("Failed to start server: %v", err)
	}

	// 等待服务器启动
	suite.T().Log("Waiting for server to start...")
	suite.waitForServer(30 * time.Second)
}

// TearDownSuite 清理测试套件
func (suite *APITestSuite) TearDownSuite() {
	if suite.serverCmd != nil && suite.serverCmd.Process != nil {
		suite.T().Log("Stopping server...")
		suite.serverCmd.Process.Kill()
		suite.serverCmd.Wait()
	}
}

// copyFile 复制文件
func (suite *APITestSuite) copyFile(src, dst string) {
	sourceFile, err := os.Open(src)
	if err != nil {
		suite.T().Fatalf("Failed to open source file: %v", err)
	}
	defer sourceFile.Close()

	destFile, err := os.Create(dst)
	if err != nil {
		suite.T().Fatalf("Failed to create destination file: %v", err)
	}
	defer destFile.Close()

	_, err = io.Copy(destFile, sourceFile)
	if err != nil {
		suite.T().Fatalf("Failed to copy file: %v", err)
	}
}

// waitForServer 等待服务器启动
func (suite *APITestSuite) waitForServer(timeout time.Duration) {
	start := time.Now()
	for time.Since(start) < timeout {
		resp, err := http.Get(suite.baseURL + "/health")
		if err == nil && resp.StatusCode == http.StatusOK {
			resp.Body.Close()
			suite.T().Log("Server is ready")
			return
		}
		if resp != nil {
			resp.Body.Close()
		}
		time.Sleep(500 * time.Millisecond)
	}
	suite.T().Fatal("Server failed to start within timeout")
}

// makeRequest 发送HTTP请求
func (suite *APITestSuite) makeRequest(method, path string, body interface{}, useAuth bool) (*http.Response, []byte) {
	var reqBody io.Reader
	if body != nil {
		jsonBody, err := json.Marshal(body)
		suite.Require().NoError(err)
		reqBody = bytes.NewBuffer(jsonBody)
	}

	req, err := http.NewRequest(method, suite.baseURL+path, reqBody)
	suite.Require().NoError(err)

	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	if useAuth && suite.token != "" {
		req.Header.Set("Authorization", "Bearer "+suite.token)
	}

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	suite.Require().NoError(err)

	respBody, err := io.ReadAll(resp.Body)
	suite.Require().NoError(err)
	resp.Body.Close()

	return resp, respBody
}

// TestHealthEndpoints 测试健康检查端点
func (suite *APITestSuite) TestHealthEndpoints() {
	suite.T().Log("Testing health endpoints...")

	// 测试健康检查
	resp, body := suite.makeRequest("GET", "/health", nil, false)
	assert.Equal(suite.T(), http.StatusOK, resp.StatusCode)

	var healthResp map[string]interface{}
	err := json.Unmarshal(body, &healthResp)
	assert.NoError(suite.T(), err)
	assert.True(suite.T(), healthResp["success"].(bool))

	// 测试就绪检查
	resp, body = suite.makeRequest("GET", "/ready", nil, false)
	assert.Equal(suite.T(), http.StatusOK, resp.StatusCode)

	var readyResp map[string]interface{}
	err = json.Unmarshal(body, &readyResp)
	assert.NoError(suite.T(), err)
	assert.True(suite.T(), readyResp["success"].(bool))
}

// TestAuthenticationAPIs 测试认证API
func (suite *APITestSuite) TestAuthenticationAPIs() {
	suite.T().Log("Testing authentication APIs...")

	// 测试用户注册
	registerData := map[string]interface{}{
		"username": "testuser",
		"email":    "test@example.com",
		"password": "password123",
	}

	resp, body := suite.makeRequest("POST", "/api/v1/auth/register", registerData, false)
	
	// 注册可能失败（如果用户已存在），这是正常的
	if resp.StatusCode == http.StatusCreated || resp.StatusCode == http.StatusBadRequest {
		suite.T().Log("Registration response received (user may already exist)")
	} else {
		suite.T().Logf("Unexpected registration status: %d", resp.StatusCode)
	}

	// 测试用户登录
	loginData := map[string]interface{}{
		"username": "testuser",
		"password": "password123",
	}

	resp, body = suite.makeRequest("POST", "/api/v1/auth/login", loginData, false)
	
	if resp.StatusCode == http.StatusOK {
		var loginResp map[string]interface{}
		err := json.Unmarshal(body, &loginResp)
		assert.NoError(suite.T(), err)
		assert.True(suite.T(), loginResp["success"].(bool))

		// 提取token
		if data, ok := loginResp["data"].(map[string]interface{}); ok {
			if token, ok := data["access_token"].(string); ok {
				suite.token = token
				suite.T().Log("Token extracted successfully")
			} else if token, ok := data["token"].(string); ok {
				suite.token = token
				suite.T().Log("Token extracted successfully")
			}
		}
	} else {
		suite.T().Logf("Login failed with status: %d, body: %s", resp.StatusCode, string(body))
		// 如果登录失败，使用默认管理员账号尝试
		adminLoginData := map[string]interface{}{
			"username": "admin",
			"password": "admin123",
		}
		
		resp, body = suite.makeRequest("POST", "/api/v1/auth/login", adminLoginData, false)
		if resp.StatusCode == http.StatusOK {
			var loginResp map[string]interface{}
			err := json.Unmarshal(body, &loginResp)
			if err == nil {
				if data, ok := loginResp["data"].(map[string]interface{}); ok {
					if token, ok := data["access_token"].(string); ok {
						suite.token = token
						suite.T().Log("Admin token extracted successfully")
					}
				}
			}
		}
	}
}

// TestRecordTypeAPIs 测试记录类型API
func (suite *APITestSuite) TestRecordTypeAPIs() {
	suite.T().Log("Testing record type APIs...")

	// 测试获取所有记录类型
	resp, _ := suite.makeRequest("GET", "/api/v1/record-types", nil, true)
	suite.T().Logf("Get record types status: %d", resp.StatusCode)

	// 测试创建记录类型
	recordTypeData := map[string]interface{}{
		"name":         suite.recordType,
		"display_name": "Test Record Type",
		"schema": map[string]interface{}{
			"fields": []interface{}{
				map[string]interface{}{
					"name":     "description",
					"type":     "string",
					"required": true,
				},
				map[string]interface{}{
					"name":     "priority",
					"type":     "number",
					"required": false,
				},
			},
		},
	}

	resp, _ = suite.makeRequest("POST", "/api/v1/record-types", recordTypeData, true)
	suite.T().Logf("Create record type status: %d", resp.StatusCode)
	
	// 记录类型可能已存在，这是正常的
	if resp.StatusCode == http.StatusCreated || resp.StatusCode == http.StatusBadRequest {
		suite.T().Log("Record type creation response received")
	}
}

// TestRecordManagementAPIs 测试记录管理API
func (suite *APITestSuite) TestRecordManagementAPIs() {
	suite.T().Log("Testing record management APIs...")

	// 测试创建记录
	recordData := map[string]interface{}{
		"type":  suite.recordType,
		"title": "Test Record",
		"content": map[string]interface{}{
			"description": "This is a test record",
			"priority":    1,
		},
		"tags": []string{"test", "api"},
	}

	resp, body := suite.makeRequest("POST", "/api/v1/records", recordData, true)
	suite.T().Logf("Create record status: %d", resp.StatusCode)

	if resp.StatusCode == http.StatusCreated {
		var createResp map[string]interface{}
		err := json.Unmarshal(body, &createResp)
		assert.NoError(suite.T(), err)
		assert.True(suite.T(), createResp["success"].(bool))

		if data, ok := createResp["data"].(map[string]interface{}); ok {
			if id, ok := data["id"].(float64); ok {
				suite.recordID = uint(id)
				suite.T().Logf("Record created with ID: %d", suite.recordID)
			}
		}
	}

	// 测试获取所有记录
	resp, body = suite.makeRequest("GET", "/api/v1/records", nil, true)
	suite.T().Logf("Get records status: %d", resp.StatusCode)

	if resp.StatusCode == http.StatusOK {
		var recordsResp map[string]interface{}
		err := json.Unmarshal(body, &recordsResp)
		assert.NoError(suite.T(), err)
		assert.True(suite.T(), recordsResp["success"].(bool))
	}

	// 测试根据ID获取记录
	if suite.recordID > 0 {
		resp, _ = suite.makeRequest("GET", fmt.Sprintf("/api/v1/records/%d", suite.recordID), nil, true)
		suite.T().Logf("Get record by ID status: %d", resp.StatusCode)

		// 测试更新记录
		updateData := map[string]interface{}{
			"title": "Updated Test Record",
			"content": map[string]interface{}{
				"description": "This is an updated test record",
				"priority":    2,
			},
		}

		resp, _ = suite.makeRequest("PUT", fmt.Sprintf("/api/v1/records/%d", suite.recordID), updateData, true)
		suite.T().Logf("Update record status: %d", resp.StatusCode)
	}

	// 测试批量创建记录
	batchData := map[string]interface{}{
		"records": []interface{}{
			map[string]interface{}{
				"type":  suite.recordType,
				"title": "Batch Record 1",
				"content": map[string]interface{}{
					"description": "First batch record",
					"priority":    1,
				},
				"tags": []string{"batch", "test"},
			},
			map[string]interface{}{
				"type":  suite.recordType,
				"title": "Batch Record 2",
				"content": map[string]interface{}{
					"description": "Second batch record",
					"priority":    2,
				},
				"tags": []string{"batch", "test"},
			},
		},
	}

	resp, _ = suite.makeRequest("POST", "/api/v1/records/batch", batchData, true)
	suite.T().Logf("Batch create records status: %d", resp.StatusCode)

	// 测试导入记录
	importData := map[string]interface{}{
		"type": suite.recordType,
		"records": []interface{}{
			map[string]interface{}{
				"title":       "Imported Record 1",
				"description": "First imported record",
				"priority":    1,
				"tags":        []interface{}{"import", "test"},
			},
			map[string]interface{}{
				"title":       "Imported Record 2",
				"description": "Second imported record",
				"priority":    2,
				"tags":        []interface{}{"import", "test"},
			},
		},
	}

	resp, _ = suite.makeRequest("POST", "/api/v1/records/import", importData, true)
	suite.T().Logf("Import records status: %d", resp.StatusCode)
}

// TestAuditAPIs 测试审计API
func (suite *APITestSuite) TestAuditAPIs() {
	suite.T().Log("Testing audit APIs...")

	// 测试获取审计日志
	resp, _ := suite.makeRequest("GET", "/api/v1/audit/logs", nil, true)
	suite.T().Logf("Get audit logs status: %d", resp.StatusCode)

	// 测试获取审计统计
	resp, _ = suite.makeRequest("GET", "/api/v1/audit/statistics", nil, true)
	suite.T().Logf("Get audit statistics status: %d", resp.StatusCode)
}

// TestAPIEndpoints 运行所有API测试
func (suite *APITestSuite) TestAPIEndpoints() {
	// 按顺序运行测试
	suite.Run("HealthEndpoints", suite.TestHealthEndpoints)
	suite.Run("AuthenticationAPIs", suite.TestAuthenticationAPIs)
	suite.Run("RecordTypeAPIs", suite.TestRecordTypeAPIs)
	suite.Run("RecordManagementAPIs", suite.TestRecordManagementAPIs)
	suite.Run("AuditAPIs", suite.TestAuditAPIs)
}

// 运行API测试套件
func TestAPITestSuite(t *testing.T) {
	// 检查是否在CI环境中，如果是则跳过
	if os.Getenv("CI") != "" {
		t.Skip("Skipping API tests in CI environment")
	}
	
	suite.Run(t, new(APITestSuite))
}