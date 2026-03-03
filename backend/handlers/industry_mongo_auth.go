package handlers

import (
	"net/http"
	"strconv"

	"god-board/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// GetIndustryMongoAuthConfig 获取行业调用mongo授权配置（第一条）
func GetIndustryMongoAuthConfig(c *gin.Context, db *gorm.DB) {
	var config models.IndustryMongoAuthConfig
	result := db.First(&config)

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

// GetIndustryMongoAuthConfigs 获取所有行业调用mongo授权配置
func GetIndustryMongoAuthConfigs(c *gin.Context, db *gorm.DB) {
	var configs []models.IndustryMongoAuthConfig
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

// DeleteIndustryMongoAuthConfig 删除行业调用mongo授权配置
func DeleteIndustryMongoAuthConfig(c *gin.Context, db *gorm.DB) {
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

	result := db.Delete(&models.IndustryMongoAuthConfig{}, id)
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

// SaveIndustryMongoAuthConfig 保存行业调用mongo授权配置
func SaveIndustryMongoAuthConfig(c *gin.Context, db *gorm.DB) {
	var req models.IndustryMongoAuthRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "请求参数错误: " + err.Error(),
			"data":    nil,
		})
		return
	}

	// 如果没有提供 cache_key，使用默认值
	if req.CacheKey == "" {
		req.CacheKey = "industryAkAuthConfig"
	}

	var config models.IndustryMongoAuthConfig

	// 如果提供了 ID，尝试更新现有配置
	if req.ID != nil && *req.ID > 0 {
		result := db.First(&config, *req.ID)
		if result.Error == nil {
			// 更新现有配置
			config.CacheKey = req.CacheKey
			config.CacheValue = req.CacheValue
			config.Description = req.Description

			if err := db.Save(&config).Error; err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{
					"code":    500,
					"message": "更新失败: " + err.Error(),
					"data":    nil,
				})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"code":    200,
				"message": "更新成功",
				"data":    config,
			})
			return
		}
	}

	// 尝试查找是否已存在相同 cache_key 的配置
	result := db.Where("cache_key = ?", req.CacheKey).First(&config)
	if result.Error == nil {
		// 更新现有配置
		config.CacheValue = req.CacheValue
		config.Description = req.Description

		if err := db.Save(&config).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"code":    500,
				"message": "更新失败: " + err.Error(),
				"data":    nil,
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"code":    200,
			"message": "更新成功",
			"data":    config,
		})
		return
	}

	// 创建新配置
	config = models.IndustryMongoAuthConfig{
		CacheKey:    req.CacheKey,
		CacheValue:  req.CacheValue,
		Description: req.Description,
	}

	if err := db.Create(&config).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    500,
			"message": "创建失败: " + err.Error(),
			"data":    nil,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "创建成功",
		"data":    config,
	})
}
