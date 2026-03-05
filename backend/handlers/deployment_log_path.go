package handlers

import (
	"net/http"
	"strconv"

	"god-board/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// GetDeploymentLogPathConfig 获取 Deployment 日志路径配置
func GetDeploymentLogPathConfig(c *gin.Context, db *gorm.DB) {
	k8sNamespace := c.Query("k8s_namespace")
	k8sDeployment := c.Query("k8s_deployment")

	if k8sNamespace == "" || k8sDeployment == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "k8s_namespace 和 k8s_deployment 参数不能为空",
			"data":    nil,
		})
		return
	}

	var config models.DeploymentLogPathConfig
	result := db.Where("k8s_namespace = ? AND k8s_deployment = ?", k8sNamespace, k8sDeployment).First(&config)

	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			c.JSON(http.StatusOK, gin.H{
				"code":    200,
				"message": "配置不存在",
				"data":    nil,
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    500,
			"message": "查询失败: " + result.Error.Error(),
			"data":    nil,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "查询成功",
		"data":    config,
	})
}

// GetDeploymentLogPathConfigs 获取所有 Deployment 日志路径配置
func GetDeploymentLogPathConfigs(c *gin.Context, db *gorm.DB) {
	var configs []models.DeploymentLogPathConfig
	result := db.Order("id desc").Find(&configs)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    500,
			"message": "查询失败: " + result.Error.Error(),
			"data":    nil,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "查询成功",
		"data":    configs,
	})
}

// SaveDeploymentLogPathConfig 保存 Deployment 日志路径配置
func SaveDeploymentLogPathConfig(c *gin.Context, db *gorm.DB) {
	var req models.DeploymentLogPathRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "请求参数错误: " + err.Error(),
			"data":    nil,
		})
		return
	}

	// 检查是否已存在配置
	var config models.DeploymentLogPathConfig
	result := db.Where("k8s_namespace = ? AND k8s_deployment = ?", req.K8sNamespace, req.K8sDeployment).First(&config)

	if req.ID != nil && *req.ID > 0 {
		// 更新现有配置
		config.ID = *req.ID
		config.K8sNamespace = req.K8sNamespace
		config.K8sDeployment = req.K8sDeployment
		config.LogPath = req.LogPath
		config.Description = req.Description

		if err := db.Save(&config).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"code":    500,
				"message": "更新失败: " + err.Error(),
				"data":    nil,
			})
			return
		}
	} else if result.Error == nil {
		// 已存在配置，更新
		config.LogPath = req.LogPath
		config.Description = req.Description

		if err := db.Save(&config).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"code":    500,
				"message": "更新失败: " + err.Error(),
				"data":    nil,
			})
			return
		}
	} else {
		// 创建新配置
		config = models.DeploymentLogPathConfig{
			K8sNamespace:  req.K8sNamespace,
			K8sDeployment: req.K8sDeployment,
			LogPath:       req.LogPath,
			Description:   req.Description,
		}

		if err := db.Create(&config).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"code":    500,
				"message": "保存失败: " + err.Error(),
				"data":    nil,
			})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "保存成功",
		"data":    config,
	})
}

// DeleteDeploymentLogPathConfig 删除 Deployment 日志路径配置
func DeleteDeploymentLogPathConfig(c *gin.Context, db *gorm.DB) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "无效的ID",
			"data":    nil,
		})
		return
	}

	result := db.Delete(&models.DeploymentLogPathConfig{}, id)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    500,
			"message": "删除失败: " + result.Error.Error(),
			"data":    nil,
		})
		return
	}

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    404,
			"message": "配置不存在",
			"data":    nil,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "删除成功",
		"data":    nil,
	})
}
