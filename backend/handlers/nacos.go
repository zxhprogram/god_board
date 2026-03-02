package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"

	"god-board/db"
	"god-board/models"

	"github.com/gin-gonic/gin"
)

// HandleLogin 处理 Nacos 登录，使用数据库中保存的配置
func HandleLogin(c *gin.Context) {
	// 从数据库获取 Nacos 配置
	var nacosConfig models.NacosConfig
	result := db.DB.First(&nacosConfig)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "未找到 Nacos 服务器配置，请先配置服务器",
			Data:    nil,
		})
		return
	}

	loginURL := fmt.Sprintf("%s/nacos/v1/auth/users/login", nacosConfig.Address)
	payload := fmt.Sprintf("username=%s&password=%s", nacosConfig.Username, nacosConfig.Password)

	httpReq, err := http.NewRequest("POST", loginURL, strings.NewReader(payload))
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "创建请求失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	httpReq.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	client := &http.Client{}
	resp, err := client.Do(httpReq)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "请求Nacos失败: " + err.Error(),
			Data:    nil,
		})
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "读取响应失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	if resp.StatusCode != http.StatusOK {
		c.JSON(http.StatusUnauthorized, models.Response{
			Code:    401,
			Message: "登录失败: " + string(body),
			Data:    nil,
		})
		return
	}

	var loginResp models.LoginResponse
	if err := json.Unmarshal(body, &loginResp); err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "解析响应失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	accessToken = loginResp.AccessToken

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "登录成功",
		Data:    loginResp,
	})
}

// HandleGetNamespaces 获取 Nacos 命名空间列表
func HandleGetNamespaces(c *gin.Context) {
	if accessToken == "" {
		c.JSON(http.StatusUnauthorized, models.Response{
			Code:    401,
			Message: "未登录或登录已过期",
			Data:    nil,
		})
		return
	}

	// 从数据库获取 Nacos 配置
	var nacosConfig models.NacosConfig
	result := db.DB.First(&nacosConfig)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "未找到 Nacos 服务器配置，请先配置服务器",
			Data:    nil,
		})
		return
	}

	url := fmt.Sprintf("%s/nacos/v1/console/namespaces?accessToken=%s", nacosConfig.Address, accessToken)

	resp, err := http.Get(url)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "请求Nacos失败: " + err.Error(),
			Data:    nil,
		})
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "读取响应失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	if resp.StatusCode != http.StatusOK {
		c.JSON(resp.StatusCode, models.Response{
			Code:    resp.StatusCode,
			Message: "获取命名空间失败: " + string(body),
			Data:    nil,
		})
		return
	}

	var nsResp models.NamespaceResponse
	if err := json.Unmarshal(body, &nsResp); err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "解析响应失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "获取命名空间成功",
		Data:    nsResp.Data,
	})
}

// HandleGetConfigs 获取 Nacos 配置列表
func HandleGetConfigs(c *gin.Context) {
	if accessToken == "" {
		c.JSON(http.StatusUnauthorized, models.Response{
			Code:    401,
			Message: "未登录或登录已过期",
			Data:    nil,
		})
		return
	}

	// 从数据库获取 Nacos 配置
	var nacosConfig models.NacosConfig
	result := db.DB.First(&nacosConfig)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "未找到 Nacos 服务器配置，请先配置服务器",
			Data:    nil,
		})
		return
	}

	namespaceID := c.Query("namespaceId")
	pageNo := c.DefaultQuery("pageNo", "1")
	pageSize := c.DefaultQuery("pageSize", "1000")
	dataID := c.Query("dataID")
	group := c.Query("group")
	url := fmt.Sprintf("%s/nacos/v1/cs/configs?dataId=%s&group=%s&appName=&config_tags=&pageNo=%s&pageSize=%s&tenant=%s&search=blur&accessToken=%s&username=nacos",
		nacosConfig.Address, dataID, group, pageNo, pageSize, namespaceID, accessToken)

	resp, err := http.Get(url)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "请求Nacos失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "读取响应失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	if resp.StatusCode != http.StatusOK {
		c.JSON(resp.StatusCode, models.Response{
			Code:    resp.StatusCode,
			Message: "获取配置列表失败: " + string(body),
			Data:    nil,
		})
		return
	}

	var configResp models.ConfigListResponse
	if err := json.Unmarshal(body, &configResp); err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "解析响应失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "获取配置列表成功",
		Data:    configResp,
	})
}

// HandleGetConfigDetail 获取 Nacos 单个配置详情
func HandleGetConfigDetail(c *gin.Context) {
	if accessToken == "" {
		c.JSON(http.StatusUnauthorized, models.Response{
			Code:    401,
			Message: "未登录或登录已过期",
			Data:    nil,
		})
		return
	}

	// 从数据库获取 Nacos 配置
	var nacosConfig models.NacosConfig
	result := db.DB.First(&nacosConfig)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "未找到 Nacos 服务器配置，请先配置服务器",
			Data:    nil,
		})
		return
	}

	namespaceID := c.Query("namespaceId")
	dataID := c.Query("dataId")
	group := c.Query("group")

	// Nacos 获取配置内容的 API
	url := fmt.Sprintf("%s/nacos/v1/cs/configs?dataId=%s&group=%s&tenant=%s&accessToken=%s",
		nacosConfig.Address, dataID, group, namespaceID, accessToken)

	resp, err := http.Get(url)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "请求Nacos失败: " + err.Error(),
			Data:    nil,
		})
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "读取响应失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	if resp.StatusCode != http.StatusOK {
		c.JSON(resp.StatusCode, models.Response{
			Code:    resp.StatusCode,
			Message: "获取配置详情失败: " + string(body),
			Data:    nil,
		})
		return
	}

	// 返回配置内容
	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "获取配置详情成功",
		Data: map[string]string{
			"content":     string(body),
			"dataId":      dataID,
			"group":       group,
			"namespaceId": namespaceID,
		},
	})
}

// HandleGetServices 获取 Nacos 服务列表
func HandleGetServices(c *gin.Context) {
	if accessToken == "" {
		c.JSON(http.StatusUnauthorized, models.Response{
			Code:    401,
			Message: "未登录或登录已过期",
			Data:    nil,
		})
		return
	}

	// 从数据库获取 Nacos 配置
	var nacosConfig models.NacosConfig
	result := db.DB.First(&nacosConfig)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "未找到 Nacos 服务器配置，请先配置服务器",
			Data:    nil,
		})
		return
	}

	namespaceID := c.Query("namespaceId")
	pageNo := c.DefaultQuery("pageNo", "1")
	pageSize := c.DefaultQuery("pageSize", "1000")
	url := fmt.Sprintf("%s/nacos/v1/ns/catalog/services?hasIpCount=true&withInstances=false&pageNo=%s&pageSize=%s&serviceNameParam=&groupNameParam=&accessToken=%s&namespaceId=%s",
		nacosConfig.Address, pageNo, pageSize, accessToken, namespaceID)

	resp, err := http.Get(url)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "请求Nacos失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "读取响应失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	if resp.StatusCode != http.StatusOK {
		c.JSON(resp.StatusCode, models.Response{
			Code:    resp.StatusCode,
			Message: "获取服务列表失败: " + string(body),
			Data:    nil,
		})
		return
	}

	var serviceResp models.ServiceListResponse
	if err := json.Unmarshal(body, &serviceResp); err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "解析响应失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "获取服务列表成功",
		Data:    serviceResp,
	})
}

// HandleInstances 获取 Nacos 服务实例列表
func HandleInstances(c *gin.Context) {
	if accessToken == "" {
		c.JSON(http.StatusUnauthorized, models.Response{
			Code:    401,
			Message: "未登录或登录已过期",
			Data:    nil,
		})
		return
	}

	// 从数据库获取 Nacos 配置
	var nacosConfig models.NacosConfig
	result := db.DB.First(&nacosConfig)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "未找到 Nacos 服务器配置，请先配置服务器",
			Data:    nil,
		})
		return
	}

	namespaceID := c.Query("namespaceId")
	serviceName := c.Query("serviceName")
	clusterName := c.DefaultQuery("clusterName", "DEFAULT")
	groupName := c.DefaultQuery("groupName", "DEFAULT_GROUP")
	pageNo := c.DefaultQuery("pageNo", "1")
	pageSize := c.DefaultQuery("pageSize", "10")

	url := fmt.Sprintf("%s/nacos/v1/ns/catalog/instances?accessToken=%s&serviceName=%s&clusterName=%s&groupName=%s&pageSize=%s&pageNo=%s&namespaceId=%s",
		nacosConfig.Address, accessToken, serviceName, clusterName, groupName, pageSize, pageNo, namespaceID)

	resp, err := http.Get(url)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "请求Nacos失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "读取响应失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	if resp.StatusCode != http.StatusOK {
		c.JSON(resp.StatusCode, models.Response{
			Code:    resp.StatusCode,
			Message: "获取服务列表失败: " + string(body),
			Data:    nil,
		})
		return
	}

	var serviceResp models.ServiceInstance
	if err := json.Unmarshal(body, &serviceResp); err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "解析响应失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "获取服务列表成功",
		Data:    serviceResp,
	})
}
