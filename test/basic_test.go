package test

import (
	"fmt"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

// TestBasicConcurrency 测试基本并发功能
func TestBasicConcurrency(t *testing.T) {
	t.Run("AtomicOperations", func(t *testing.T) {
		var counter int64
		var wg sync.WaitGroup
		goroutines := 100
		incrementsPerGoroutine := 1000
		
		start := time.Now()
		
		for i := 0; i < goroutines; i++ {
			wg.Add(1)
			go func() {
				defer wg.Done()
				for j := 0; j < incrementsPerGoroutine; j++ {
					atomic.AddInt64(&counter, 1)
				}
			}()
		}
		
		wg.Wait()
		duration := time.Since(start)
		
		expectedValue := int64(goroutines * incrementsPerGoroutine)
		finalCounter := atomic.LoadInt64(&counter)
		
		assert.Equal(t, expectedValue, finalCounter, "原子操作应该得到正确结果")
		
		t.Logf("原子操作测试结果:")
		t.Logf("  Goroutines: %d", goroutines)
		t.Logf("  每个Goroutine增量: %d", incrementsPerGoroutine)
		t.Logf("  期望值: %d", expectedValue)
		t.Logf("  实际值: %d", finalCounter)
		t.Logf("  耗时: %v", duration)
		t.Logf("  操作速率: %.2f ops/second", float64(expectedValue)/duration.Seconds())
	})
}

// TestRecordDataStructures 测试记录数据结构
func TestRecordDataStructures(t *testing.T) {
	t.Run("RecordCreation", func(t *testing.T) {
		record := map[string]interface{}{
			"id":    1,
			"type":  "test_record",
			"title": "测试记录",
			"content": map[string]interface{}{
				"description": "这是一个测试记录",
				"priority":    1,
				"status":      "active",
			},
			"tags":       []string{"test", "example"},
			"created_at": time.Now().Unix(),
			"version":    1,
		}
		
		// 验证记录结构
		assert.NotNil(t, record)
		assert.Equal(t, 1, record["id"])
		assert.Equal(t, "test_record", record["type"])
		assert.Equal(t, "测试记录", record["title"])
		assert.NotNil(t, record["content"])
		assert.Len(t, record["tags"], 2)
		assert.Equal(t, 1, record["version"])
		
		// 验证内容结构
		content := record["content"].(map[string]interface{})
		assert.Equal(t, "这是一个测试记录", content["description"])
		assert.Equal(t, 1, content["priority"])
		assert.Equal(t, "active", content["status"])
		
		t.Logf("记录创建测试通过，记录ID: %v", record["id"])
	})
	
	t.Run("BatchRecordCreation", func(t *testing.T) {
		batchSize := 1000
		records := make([]map[string]interface{}, batchSize)
		
		start := time.Now()
		
		for i := 0; i < batchSize; i++ {
			records[i] = map[string]interface{}{
				"id":    i + 1,
				"type":  "batch_test",
				"title": fmt.Sprintf("批量测试记录 %d", i+1),
				"content": map[string]interface{}{
					"description": fmt.Sprintf("这是第 %d 个批量测试记录", i+1),
					"index":       i,
				},
				"tags":       []string{"batch", "test"},
				"created_at": time.Now().Unix(),
				"version":    1,
			}
		}
		
		duration := time.Since(start)
		
		// 验证批量创建结果
		assert.Len(t, records, batchSize)
		
		// 验证第一条和最后一条记录
		assert.Equal(t, 1, records[0]["id"])
		assert.Equal(t, batchSize, records[batchSize-1]["id"])
		
		t.Logf("批量记录创建测试结果:")
		t.Logf("  批量大小: %d", batchSize)
		t.Logf("  创建耗时: %v", duration)
		t.Logf("  平均每条记录耗时: %v", duration/time.Duration(batchSize))
		t.Logf("  创建速率: %.2f records/second", float64(batchSize)/duration.Seconds())
	})
}

// TestConcurrentMapOperations 测试并发Map操作
func TestConcurrentMapOperations(t *testing.T) {
	t.Run("ConcurrentMapReadWrite", func(t *testing.T) {
		records := make(map[int]map[string]interface{})
		var mu sync.RWMutex
		var wg sync.WaitGroup
		
		writers := 10
		readers := 20
		recordsPerWriter := 100
		readsPerReader := 200
		
		var writeCount, readCount int64
		
		start := time.Now()
		
		// 启动写入goroutines
		for i := 0; i < writers; i++ {
			wg.Add(1)
			go func(writerID int) {
				defer wg.Done()
				
				for j := 0; j < recordsPerWriter; j++ {
					recordID := writerID*recordsPerWriter + j
					record := map[string]interface{}{
						"id":        recordID,
						"type":      "concurrent_test",
						"title":     fmt.Sprintf("并发测试记录 %d", recordID),
						"writer_id": writerID,
						"index":     j,
					}
					
					mu.Lock()
					records[recordID] = record
					mu.Unlock()
					
					atomic.AddInt64(&writeCount, 1)
				}
			}(i)
		}
		
		// 启动读取goroutines
		for i := 0; i < readers; i++ {
			wg.Add(1)
			go func(readerID int) {
				defer wg.Done()
				
				for j := 0; j < readsPerReader; j++ {
					recordID := j % (writers * recordsPerWriter)
					
					mu.RLock()
					record, exists := records[recordID]
					mu.RUnlock()
					
					atomic.AddInt64(&readCount, 1)
					
					if exists {
						assert.NotNil(t, record)
						assert.Equal(t, recordID, record["id"])
					}
				}
			}(i)
		}
		
		wg.Wait()
		duration := time.Since(start)
		
		finalWriteCount := atomic.LoadInt64(&writeCount)
		finalReadCount := atomic.LoadInt64(&readCount)
		
		mu.RLock()
		finalRecordCount := len(records)
		mu.RUnlock()
		
		// 验证结果
		expectedWrites := int64(writers * recordsPerWriter)
		expectedReads := int64(readers * readsPerReader)
		
		assert.Equal(t, expectedWrites, finalWriteCount)
		assert.Equal(t, expectedReads, finalReadCount)
		assert.Equal(t, int(expectedWrites), finalRecordCount)
		
		t.Logf("并发Map操作测试结果:")
		t.Logf("  写入Goroutines: %d", writers)
		t.Logf("  读取Goroutines: %d", readers)
		t.Logf("  写入操作数: %d", finalWriteCount)
		t.Logf("  读取操作数: %d", finalReadCount)
		t.Logf("  最终记录数: %d", finalRecordCount)
		t.Logf("  总耗时: %v", duration)
		t.Logf("  写入速率: %.2f writes/second", float64(finalWriteCount)/duration.Seconds())
		t.Logf("  读取速率: %.2f reads/second", float64(finalReadCount)/duration.Seconds())
	})
}

// TestRecordValidation 测试记录验证逻辑
func TestRecordValidation(t *testing.T) {
	t.Run("ValidRecord", func(t *testing.T) {
		record := map[string]interface{}{
			"type":  "test_type",
			"title": "有效的测试记录",
			"content": map[string]interface{}{
				"description": "这是一个有效的测试记录",
			},
			"tags": []string{"valid", "test"},
		}
		
		// 模拟验证逻辑
		isValid := validateRecord(record)
		assert.True(t, isValid, "有效记录应该通过验证")
	})
	
	t.Run("InvalidRecord", func(t *testing.T) {
		invalidRecords := []map[string]interface{}{
			// 缺少type
			{
				"title": "无效记录1",
				"content": map[string]interface{}{
					"description": "缺少type字段",
				},
			},
			// 缺少title
			{
				"type": "test_type",
				"content": map[string]interface{}{
					"description": "缺少title字段",
				},
			},
			// 缺少content
			{
				"type":  "test_type",
				"title": "无效记录3",
			},
			// 空title
			{
				"type":  "test_type",
				"title": "",
				"content": map[string]interface{}{
					"description": "空title",
				},
			},
		}
		
		for i, record := range invalidRecords {
			isValid := validateRecord(record)
			assert.False(t, isValid, fmt.Sprintf("无效记录 %d 应该验证失败", i+1))
		}
	})
}

// validateRecord 模拟记录验证逻辑
func validateRecord(record map[string]interface{}) bool {
	// 检查必需字段
	recordType, hasType := record["type"]
	title, hasTitle := record["title"]
	content, hasContent := record["content"]
	
	if !hasType || !hasTitle || !hasContent {
		return false
	}
	
	// 检查字段值
	if recordType == nil || recordType == "" {
		return false
	}
	
	if title == nil || title == "" {
		return false
	}
	
	if content == nil {
		return false
	}
	
	return true
}

// TestPerformanceMetrics 测试性能指标
func TestPerformanceMetrics(t *testing.T) {
	t.Run("RecordProcessingSpeed", func(t *testing.T) {
		recordCount := 10000
		
		start := time.Now()
		
		for i := 0; i < recordCount; i++ {
			record := map[string]interface{}{
				"id":    i + 1,
				"type":  "performance_test",
				"title": fmt.Sprintf("性能测试记录 %d", i+1),
				"content": map[string]interface{}{
					"description": fmt.Sprintf("这是第 %d 个性能测试记录", i+1),
					"index":       i,
					"timestamp":   time.Now().Unix(),
				},
				"tags": []string{"performance", "test"},
			}
			
			// 模拟记录处理
			isValid := validateRecord(record)
			assert.True(t, isValid)
		}
		
		duration := time.Since(start)
		
		t.Logf("记录处理性能测试结果:")
		t.Logf("  处理记录数: %d", recordCount)
		t.Logf("  总耗时: %v", duration)
		t.Logf("  平均每条记录耗时: %v", duration/time.Duration(recordCount))
		t.Logf("  处理速率: %.2f records/second", float64(recordCount)/duration.Seconds())
		
		// 性能断言
		assert.Less(t, duration, 5*time.Second, "处理10000条记录应该在5秒内完成")
		
		recordsPerSecond := float64(recordCount) / duration.Seconds()
		assert.Greater(t, recordsPerSecond, 1000.0, "处理速率应该大于1000 records/second")
	})
}