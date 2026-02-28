package handlers

import (
	"god-board/db"
	"god-board/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// HandleGetNewland9894Config 获取新大陆 9894 服务配置
func HandleGetNewland9894Config(c *gin.Context) {
	var config models.Newland9894Config
	result := db.DB.First(&config)
	if result.Error != nil {
		c.JSON(http.StatusOK, gin.H{
			"code":    200,
			"message": "未找到配置",
			"data":    nil,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "获取配置成功",
		"data":    config,
	})
}

// HandleSaveNewland9894Config 保存新大陆 9894 服务配置
func HandleSaveNewland9894Config(c *gin.Context) {
	var config models.Newland9894Config
	if err := c.ShouldBindJSON(&config); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "请求参数错误: " + err.Error(),
			"data":    nil,
		})
		return
	}

	// 检查是否已有配置
	var existingConfig models.Newland9894Config
	result := db.DB.First(&existingConfig)
	if result.Error == nil {
		// 更新现有配置
		existingConfig.Address = config.Address
		existingConfig.Username = config.Username
		existingConfig.Password = config.Password
		db.DB.Save(&existingConfig)
	} else {
		// 创建新配置
		db.DB.Create(&config)
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "保存配置成功",
		"data":    nil,
	})
}

// HandleGetNewland9895Config 获取新大陆 9895 服务配置
func HandleGetNewland9895Config(c *gin.Context) {
	var config models.Newland9895Config
	result := db.DB.First(&config)
	if result.Error != nil {
		c.JSON(http.StatusOK, gin.H{
			"code":    200,
			"message": "未找到配置",
			"data":    nil,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "获取配置成功",
		"data":    config,
	})
}

// HandleSaveNewland9895Config 保存新大陆 9895 服务配置
func HandleSaveNewland9895Config(c *gin.Context) {
	var config models.Newland9895Config
	if err := c.ShouldBindJSON(&config); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "请求参数错误: " + err.Error(),
			"data":    nil,
		})
		return
	}

	// 检查是否已有配置
	var existingConfig models.Newland9895Config
	result := db.DB.First(&existingConfig)
	if result.Error == nil {
		// 更新现有配置
		existingConfig.Address = config.Address
		existingConfig.Username = config.Username
		existingConfig.Password = config.Password
		db.DB.Save(&existingConfig)
	} else {
		// 创建新配置
		db.DB.Create(&config)
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "保存配置成功",
		"data":    nil,
	})
}
