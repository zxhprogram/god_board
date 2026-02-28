package handlers

import (
	"net/http"

	"god-board/db"
	"god-board/models"

	"github.com/gin-gonic/gin"
)

// SaveK8sConfigRequest 保存 K8s 配置请求
type SaveK8sConfigRequest struct {
	Address  string `json:"address" binding:"required"`
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// SaveNacosConfigRequest 保存 Nacos 配置请求
type SaveNacosConfigRequest struct {
	Address  string `json:"address" binding:"required"`
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// ServerConfigsResponse 服务器配置响应
type ServerConfigsResponse struct {
	K8s        *models.K8sConfig        `json:"k8s"`
	Nacos      *models.NacosConfig      `json:"nacos"`
	NodeServer *models.NodeServerConfig `json:"nodeServer"`
}

// SaveNodeServerConfigRequest 保存 NodeServer 配置请求
type SaveNodeServerConfigRequest struct {
	Address string `json:"address" binding:"required"`
}

// HandleSaveK8sConfig 保存 K8s 配置
func HandleSaveK8sConfig(c *gin.Context) {
	var req SaveK8sConfigRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Code:    400,
			Message: "请求参数错误: " + err.Error(),
			Data:    nil,
		})
		return
	}

	var k8sConfig models.K8sConfig
	result := db.DB.First(&k8sConfig)
	if result.Error != nil && result.Error.Error() != "record not found" {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "查询数据库失败: " + result.Error.Error(),
			Data:    nil,
		})
		return
	}

	k8sConfig.Address = req.Address
	k8sConfig.Username = req.Username
	k8sConfig.Password = req.Password

	if result.Error != nil && result.Error.Error() == "record not found" {
		if err := db.DB.Create(&k8sConfig).Error; err != nil {
			c.JSON(http.StatusInternalServerError, models.Response{
				Code:    500,
				Message: "保存K8s配置失败: " + err.Error(),
				Data:    nil,
			})
			return
		}
	} else {
		if err := db.DB.Save(&k8sConfig).Error; err != nil {
			c.JSON(http.StatusInternalServerError, models.Response{
				Code:    500,
				Message: "更新K8s配置失败: " + err.Error(),
				Data:    nil,
			})
			return
		}
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "K8s配置保存成功",
		Data:    nil,
	})
}

// HandleSaveNacosConfig 保存 Nacos 配置
func HandleSaveNacosConfig(c *gin.Context) {
	var req SaveNacosConfigRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Code:    400,
			Message: "请求参数错误: " + err.Error(),
			Data:    nil,
		})
		return
	}

	var nacosConfig models.NacosConfig
	result := db.DB.First(&nacosConfig)
	if result.Error != nil && result.Error.Error() != "record not found" {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "查询数据库失败: " + result.Error.Error(),
			Data:    nil,
		})
		return
	}

	nacosConfig.Address = req.Address
	nacosConfig.Username = req.Username
	nacosConfig.Password = req.Password

	if result.Error != nil && result.Error.Error() == "record not found" {
		if err := db.DB.Create(&nacosConfig).Error; err != nil {
			c.JSON(http.StatusInternalServerError, models.Response{
				Code:    500,
				Message: "保存Nacos配置失败: " + err.Error(),
				Data:    nil,
			})
			return
		}
	} else {
		if err := db.DB.Save(&nacosConfig).Error; err != nil {
			c.JSON(http.StatusInternalServerError, models.Response{
				Code:    500,
				Message: "更新Nacos配置失败: " + err.Error(),
				Data:    nil,
			})
			return
		}
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "Nacos配置保存成功",
		Data:    nil,
	})
}

// HandleGetServerConfigs 获取服务器配置
func HandleGetServerConfigs(c *gin.Context) {
	var k8sConfig models.K8sConfig
	var nacosConfig models.NacosConfig
	var nodeServerConfig models.NodeServerConfig

	// 获取 K8s 配置
	k8sResult := db.DB.First(&k8sConfig)
	var k8sConfigPtr *models.K8sConfig
	if k8sResult.Error == nil {
		k8sConfigPtr = &k8sConfig
	}

	// 获取 Nacos 配置
	nacosResult := db.DB.First(&nacosConfig)
	var nacosConfigPtr *models.NacosConfig
	if nacosResult.Error == nil {
		nacosConfigPtr = &nacosConfig
	}

	// 获取 NodeServer 配置
	nodeServerResult := db.DB.First(&nodeServerConfig)
	var nodeServerConfigPtr *models.NodeServerConfig
	if nodeServerResult.Error == nil {
		nodeServerConfigPtr = &nodeServerConfig
	}

	response := ServerConfigsResponse{
		K8s:        k8sConfigPtr,
		Nacos:      nacosConfigPtr,
		NodeServer: nodeServerConfigPtr,
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "获取服务器配置成功",
		Data:    response,
	})
}

// HandleSaveNodeServerConfig 保存 NodeServer 配置
func HandleSaveNodeServerConfig(c *gin.Context) {
	var req SaveNodeServerConfigRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Code:    400,
			Message: "请求参数错误: " + err.Error(),
			Data:    nil,
		})
		return
	}

	var nodeServerConfig models.NodeServerConfig
	result := db.DB.First(&nodeServerConfig)
	if result.Error != nil && result.Error.Error() != "record not found" {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "查询数据库失败: " + result.Error.Error(),
			Data:    nil,
		})
		return
	}

	nodeServerConfig.Address = req.Address

	if result.Error != nil && result.Error.Error() == "record not found" {
		if err := db.DB.Create(&nodeServerConfig).Error; err != nil {
			c.JSON(http.StatusInternalServerError, models.Response{
				Code:    500,
				Message: "保存NodeServer配置失败: " + err.Error(),
				Data:    nil,
			})
			return
		}
	} else {
		if err := db.DB.Save(&nodeServerConfig).Error; err != nil {
			c.JSON(http.StatusInternalServerError, models.Response{
				Code:    500,
				Message: "更新NodeServer配置失败: " + err.Error(),
				Data:    nil,
			})
			return
		}
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "NodeServer配置保存成功",
		Data:    nil,
	})
}

// HandleSaveK8sNacosMapping 保存 K8s Deployment 与 Nacos 配置的关联关系
func HandleSaveK8sNacosMapping(c *gin.Context) {
	var req models.K8sNacosMappingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Code:    400,
			Message: "请求参数错误: " + err.Error(),
			Data:    nil,
		})
		return
	}

	// 检查是否已存在相同的关联关系
	var existingMapping models.K8sNacosMapping
	result := db.DB.Where("k8s_namespace = ? AND k8s_deployment = ?", req.K8sNamespace, req.K8sDeployment).First(&existingMapping)

	mapping := models.K8sNacosMapping{
		K8sNamespace:   req.K8sNamespace,
		K8sDeployment:  req.K8sDeployment,
		NacosNamespace: req.NacosNamespace,
		NacosConfigID:  req.NacosConfigID,
	}

	if result.Error == nil {
		// 已存在，更新
		existingMapping.NacosNamespace = req.NacosNamespace
		existingMapping.NacosConfigID = req.NacosConfigID
		if err := db.DB.Save(&existingMapping).Error; err != nil {
			c.JSON(http.StatusInternalServerError, models.Response{
				Code:    500,
				Message: "更新关联关系失败: " + err.Error(),
				Data:    nil,
			})
			return
		}
		c.JSON(http.StatusOK, models.Response{
			Code:    200,
			Message: "关联关系更新成功",
			Data:    existingMapping,
		})
	} else {
		// 不存在，创建
		if err := db.DB.Create(&mapping).Error; err != nil {
			c.JSON(http.StatusInternalServerError, models.Response{
				Code:    500,
				Message: "保存关联关系失败: " + err.Error(),
				Data:    nil,
			})
			return
		}
		c.JSON(http.StatusOK, models.Response{
			Code:    200,
			Message: "关联关系保存成功",
			Data:    mapping,
		})
	}
}

// HandleGetK8sNacosMapping 根据 K8s Namespace 和 Deployment 获取关联的 Nacos 配置
func HandleGetK8sNacosMapping(c *gin.Context) {
	k8sNamespace := c.Query("k8sNamespace")
	k8sDeployment := c.Query("k8sDeployment")

	if k8sNamespace == "" || k8sDeployment == "" {
		c.JSON(http.StatusBadRequest, models.Response{
			Code:    400,
			Message: "k8sNamespace 和 k8sDeployment 不能为空",
			Data:    nil,
		})
		return
	}

	var mapping models.K8sNacosMapping
	result := db.DB.Where("k8s_namespace = ? AND k8s_deployment = ?", k8sNamespace, k8sDeployment).First(&mapping)

	if result.Error != nil {
		if result.Error.Error() == "record not found" {
			c.JSON(http.StatusOK, models.Response{
				Code:    200,
				Message: "未找到关联关系",
				Data:    nil,
			})
		} else {
			c.JSON(http.StatusInternalServerError, models.Response{
				Code:    500,
				Message: "查询关联关系失败: " + result.Error.Error(),
				Data:    nil,
			})
		}
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "获取关联关系成功",
		Data:    mapping,
	})
}

// HandleDeleteK8sNacosMapping 删除 K8s Deployment 与 Nacos 配置的关联关系
func HandleDeleteK8sNacosMapping(c *gin.Context) {
	k8sNamespace := c.Query("k8sNamespace")
	k8sDeployment := c.Query("k8sDeployment")

	if k8sNamespace == "" || k8sDeployment == "" {
		c.JSON(http.StatusBadRequest, models.Response{
			Code:    400,
			Message: "k8sNamespace 和 k8sDeployment 不能为空",
			Data:    nil,
		})
		return
	}

	result := db.DB.Where("k8s_namespace = ? AND k8s_deployment = ?", k8sNamespace, k8sDeployment).Delete(&models.K8sNacosMapping{})

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "删除关联关系失败: " + result.Error.Error(),
			Data:    nil,
		})
		return
	}

	if result.RowsAffected == 0 {
		c.JSON(http.StatusOK, models.Response{
			Code:    200,
			Message: "关联关系不存在",
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "关联关系删除成功",
		Data:    nil,
	})
}

// HandleGetNodeServerConfig 获取 NodeServer 配置
func HandleGetNodeServerConfig(c *gin.Context) {
	var nodeServerConfig models.NodeServerConfig
	result := db.DB.First(&nodeServerConfig)

	if result.Error != nil {
		if result.Error.Error() == "record not found" {
			c.JSON(http.StatusOK, models.Response{
				Code:    200,
				Message: "NodeServer 配置不存在",
				Data:    nil,
			})
		} else {
			c.JSON(http.StatusInternalServerError, models.Response{
				Code:    500,
				Message: "查询 NodeServer 配置失败: " + result.Error.Error(),
				Data:    nil,
			})
		}
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "获取 NodeServer 配置成功",
		Data:    nodeServerConfig,
	})
}
