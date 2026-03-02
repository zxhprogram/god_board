package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"

	"god-board/db"
	"god-board/models"

	"github.com/gin-gonic/gin"
)

// HandleGetNacosServices 获取 Nacos 服务列表
func HandleGetNacosServices(c *gin.Context) {
	if accessToken == "" {
		c.JSON(http.StatusUnauthorized, models.Response{
			Code:    401,
			Message: "未登录或登录已过期",
			Data:    nil,
		})
		return
	}

	namespace := c.Query("namespace")
	if namespace == "" {
		namespace = c.Query("namespaceId")
	}
	if namespace == "" {
		c.JSON(http.StatusBadRequest, models.Response{
			Code:    400,
			Message: "namespace 或 namespaceId 参数不能为空",
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
			Message: "未找到 Nacos 服务器配置",
			Data:    nil,
		})
		return
	}

	// 构建请求 URL
	requestURL := fmt.Sprintf("%s/nacos/v1/ns/service/list", nacosConfig.Address)
	params := url.Values{}
	params.Set("namespaceId", namespace)
	params.Set("pageNo", "1")
	params.Set("pageSize", "100")
	params.Set("accessToken", accessToken)

	fullURL := fmt.Sprintf("%s?%s", requestURL, params.Encode())

	resp, err := http.Get(fullURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "请求 Nacos 服务列表失败: " + err.Error(),
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

// HandleGetNacosServiceInstances 获取 Nacos 服务实例列表
func HandleGetNacosServiceInstances(c *gin.Context) {
	if accessToken == "" {
		c.JSON(http.StatusUnauthorized, models.Response{
			Code:    401,
			Message: "未登录或登录已过期",
			Data:    nil,
		})
		return
	}

	namespace := c.Query("namespace")
	serviceName := c.Query("serviceName")
	groupName := c.Query("groupName")

	if namespace == "" || serviceName == "" {
		c.JSON(http.StatusBadRequest, models.Response{
			Code:    400,
			Message: "namespace 和 serviceName 参数不能为空",
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
			Message: "未找到 Nacos 服务器配置",
			Data:    nil,
		})
		return
	}

	// 构建请求 URL
	requestURL := fmt.Sprintf("%s/nacos/v1/ns/instance/list", nacosConfig.Address)
	params := url.Values{}
	params.Set("namespaceId", namespace)
	params.Set("serviceName", serviceName)
	if groupName != "" {
		params.Set("groupName", groupName)
	}
	params.Set("accessToken", accessToken)

	fullURL := fmt.Sprintf("%s?%s", requestURL, params.Encode())

	resp, err := http.Get(fullURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "请求 Nacos 服务实例失败: " + err.Error(),
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
			Message: "获取服务实例失败: " + string(body),
			Data:    nil,
		})
		return
	}

	var instanceResp models.ServiceInstance
	if err := json.Unmarshal(body, &instanceResp); err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "解析响应失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "获取服务实例成功",
		Data:    instanceResp,
	})
}

// HandleSaveK8sNacosServiceMapping 保存 K8s Deployment 与 Nacos 服务的关联关系
func HandleSaveK8sNacosServiceMapping(c *gin.Context) {
	var req models.K8sNacosServiceMappingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Code:    400,
			Message: "请求参数错误: " + err.Error(),
			Data:    nil,
		})
		return
	}

	// 设置默认 Group
	if req.NacosGroupName == "" {
		req.NacosGroupName = "DEFAULT_GROUP"
	}

	// 查找是否已存在关联关系
	var existingMapping models.K8sNacosServiceMapping
	result := db.DB.Where("k8s_namespace = ? AND k8s_deployment = ?",
		req.K8sNamespace, req.K8sDeployment).First(&existingMapping)

	if result.Error == nil {
		// 更新现有记录
		existingMapping.NacosNamespace = req.NacosNamespace
		existingMapping.NacosServiceName = req.NacosServiceName
		existingMapping.NacosGroupName = req.NacosGroupName
		db.DB.Save(&existingMapping)
		c.JSON(http.StatusOK, models.Response{
			Code:    200,
			Message: "关联关系更新成功",
			Data:    existingMapping,
		})
	} else {
		// 创建新记录
		newMapping := models.K8sNacosServiceMapping{
			K8sNamespace:     req.K8sNamespace,
			K8sDeployment:    req.K8sDeployment,
			NacosNamespace:   req.NacosNamespace,
			NacosServiceName: req.NacosServiceName,
			NacosGroupName:   req.NacosGroupName,
		}
		db.DB.Create(&newMapping)
		c.JSON(http.StatusOK, models.Response{
			Code:    200,
			Message: "关联关系保存成功",
			Data:    newMapping,
		})
	}
}

// HandleGetK8sNacosServiceMapping 获取 K8s Deployment 与 Nacos 服务的关联关系
func HandleGetK8sNacosServiceMapping(c *gin.Context) {
	k8sNamespace := c.Query("k8sNamespace")
	k8sDeployment := c.Query("k8sDeployment")

	if k8sNamespace == "" || k8sDeployment == "" {
		c.JSON(http.StatusBadRequest, models.Response{
			Code:    400,
			Message: "k8sNamespace 和 k8sDeployment 参数不能为空",
			Data:    nil,
		})
		return
	}

	var mapping models.K8sNacosServiceMapping
	result := db.DB.Where("k8s_namespace = ? AND k8s_deployment = ?",
		k8sNamespace, k8sDeployment).First(&mapping)

	if result.Error != nil {
		c.JSON(http.StatusOK, models.Response{
			Code:    200,
			Message: "未找到关联关系",
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "获取关联关系成功",
		Data:    mapping,
	})
}
