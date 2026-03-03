package handlers

import (
	"context"
	"fmt"
	"net"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

// RedisQueryRequest Redis查询请求参数
type RedisQueryRequest struct {
	Host      string `json:"host" binding:"required"`      // Redis IP，集群模式为逗号分割的ip:port
	Port      int    `json:"port"`                         // 端口号（非集群模式使用）
	IsCluster bool   `json:"isCluster"`                    // 是否集群模式
	Password  string `json:"password"`                     // 密码
	QueryType string `json:"queryType" binding:"required"` // 查询类型：get/hget
	Key       string `json:"key" binding:"required"`       // Redis key
	HKey      string `json:"hkey"`                         // Hash key（hget时使用）
}

// RedisQueryResponse Redis查询响应
type RedisQueryResponse struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}

// HandleRedisQuery 处理Redis查询请求
func HandleRedisQuery(c *gin.Context) {
	var req RedisQueryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, RedisQueryResponse{
			Code:    400,
			Message: "请求参数错误: " + err.Error(),
		})
		return
	}

	// 验证查询类型
	if req.QueryType != "get" && req.QueryType != "hget" {
		c.JSON(400, RedisQueryResponse{
			Code:    400,
			Message: "不支持的查询类型，仅支持 get/hget",
		})
		return
	}

	// hget 类型需要 hkey
	if req.QueryType == "hget" && req.HKey == "" {
		c.JSON(400, RedisQueryResponse{
			Code:    400,
			Message: "hget 查询类型需要提供 hkey 参数",
		})
		return
	}

	var result interface{}
	var err error

	if req.IsCluster {
		result, err = queryRedisCluster(req)
	} else {
		result, err = queryRedisStandalone(req)
	}

	if err != nil {
		c.JSON(500, RedisQueryResponse{
			Code:    500,
			Message: "Redis查询失败: " + err.Error(),
		})
		return
	}

	c.JSON(200, RedisQueryResponse{
		Code:    200,
		Message: "查询成功",
		Data:    result,
	})
}

// queryRedisStandalone 查询单机版Redis
func queryRedisStandalone(req RedisQueryRequest) (interface{}, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	addr := fmt.Sprintf("%s:%d", req.Host, req.Port)
	if req.Port == 0 {
		// 如果没有指定端口，尝试从host中解析（兼容host:port格式）
		if strings.Contains(req.Host, ":") {
			addr = req.Host
		} else {
			addr = net.JoinHostPort(req.Host, "6379")
		}
	}

	rdb := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: req.Password,
		DB:       0,
	})
	defer rdb.Close()

	// 测试连接
	if err := rdb.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("连接Redis失败: %v", err)
	}

	switch req.QueryType {
	case "get":
		val, err := rdb.Get(ctx, req.Key).Result()
		if err == redis.Nil {
			return nil, fmt.Errorf("key不存在")
		}
		if err != nil {
			return nil, err
		}
		return val, nil
	case "hget":
		val, err := rdb.HGet(ctx, req.Key, req.HKey).Result()
		if err == redis.Nil {
			return nil, fmt.Errorf("key或field不存在")
		}
		if err != nil {
			return nil, err
		}
		return val, nil
	default:
		return nil, fmt.Errorf("不支持的查询类型")
	}
}

// queryRedisCluster 查询集群版Redis
func queryRedisCluster(req RedisQueryRequest) (interface{}, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// 解析集群节点地址
	// 支持格式：ip1:port1,ip2:port2 或 ip1,ip2（使用默认端口6379）
	addrs := parseClusterAddrs(req.Host)

	rdb := redis.NewClusterClient(&redis.ClusterOptions{
		Addrs:    addrs,
		Password: req.Password,
	})
	defer rdb.Close()

	// 测试连接
	if err := rdb.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("连接Redis集群失败: %v", err)
	}

	switch req.QueryType {
	case "get":
		val, err := rdb.Get(ctx, req.Key).Result()
		if err == redis.Nil {
			return nil, fmt.Errorf("key不存在")
		}
		if err != nil {
			return nil, err
		}
		return val, nil
	case "hget":
		val, err := rdb.HGet(ctx, req.Key, req.HKey).Result()
		if err == redis.Nil {
			return nil, fmt.Errorf("key或field不存在")
		}
		if err != nil {
			return nil, err
		}
		return val, nil
	default:
		return nil, fmt.Errorf("不支持的查询类型")
	}
}

// parseClusterAddrs 解析集群地址
// 支持格式：
// - ip1:port1,ip2:port2
// - ip1,ip2（使用默认端口6379）
func parseClusterAddrs(host string) []string {
	addrs := strings.Split(host, ",")
	var result []string

	for _, addr := range addrs {
		addr = strings.TrimSpace(addr)
		if addr == "" {
			continue
		}

		// 检查是否已包含端口
		if strings.Contains(addr, ":") {
			result = append(result, addr)
		} else {
			// 添加默认端口
			result = append(result, net.JoinHostPort(addr, "6379"))
		}
	}

	return result
}

// HandleRedisQueryBatch 批量查询Redis（用于缓存配置检查页面）
func HandleRedisQueryBatch(c *gin.Context) {
	type BatchRequest struct {
		Host      string `json:"host" binding:"required"`
		Port      int    `json:"port"`
		IsCluster bool   `json:"isCluster"`
		Password  string `json:"password"`
		Queries   []struct {
			QueryType string `json:"queryType" binding:"required"`
			Key       string `json:"key" binding:"required"`
			HKey      string `json:"hkey"`
		} `json:"queries" binding:"required"`
	}

	var req BatchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, RedisQueryResponse{
			Code:    400,
			Message: "请求参数错误: " + err.Error(),
		})
		return
	}

	type QueryResult struct {
		Key     string      `json:"key"`
		HKey    string      `json:"hkey,omitempty"`
		Success bool        `json:"success"`
		Value   interface{} `json:"value,omitempty"`
		Error   string      `json:"error,omitempty"`
	}

	var results []QueryResult

	for _, query := range req.Queries {
		singleReq := RedisQueryRequest{
			Host:      req.Host,
			Port:      req.Port,
			IsCluster: req.IsCluster,
			Password:  req.Password,
			QueryType: query.QueryType,
			Key:       query.Key,
			HKey:      query.HKey,
		}

		var val interface{}
		var err error

		if req.IsCluster {
			val, err = queryRedisCluster(singleReq)
		} else {
			val, err = queryRedisStandalone(singleReq)
		}

		result := QueryResult{
			Key:  query.Key,
			HKey: query.HKey,
		}

		if err != nil {
			result.Success = false
			result.Error = err.Error()
		} else {
			result.Success = true
			result.Value = val
		}

		results = append(results, result)
	}

	c.JSON(200, RedisQueryResponse{
		Code:    200,
		Message: "批量查询完成",
		Data:    results,
	})
}
