package handlers

import (
	"net/http"
	"strconv"

	"god-board/db"
	"god-board/models"

	"github.com/gin-gonic/gin"
)

// HandleGetCacheMetadataConfigs 获取所有缓存元数据配置
func HandleGetCacheMetadataConfigs(c *gin.Context) {
	var configs []models.CacheMetadataConfig
	result := db.DB.Order("cache_key asc").Find(&configs)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "获取缓存元数据配置失败: " + result.Error.Error(),
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "获取缓存元数据配置成功",
		Data:    configs,
	})
}

// HandleSaveCacheMetadataConfig 保存缓存元数据配置
func HandleSaveCacheMetadataConfig(c *gin.Context) {
	var req models.CacheMetadataRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Code:    400,
			Message: "请求参数错误: " + err.Error(),
			Data:    nil,
		})
		return
	}

	// 如果过期时间为空，使用默认值
	expireTime := req.ExpireTime
	if expireTime == "" {
		expireTime = "2099-12-31 00:00:00"
	}

	// 检查是否已存在相同的 cache_key
	var existingConfig models.CacheMetadataConfig
	result := db.DB.Where("cache_key = ?", req.CacheKey).First(&existingConfig)

	if result.Error == nil {
		// 已存在，更新配置
		existingConfig.CacheValue = req.CacheValue
		existingConfig.ExpireTime = expireTime
		existingConfig.Description = req.Description
		saveResult := db.DB.Save(&existingConfig)
		if saveResult.Error != nil {
			c.JSON(http.StatusInternalServerError, models.Response{
				Code:    500,
				Message: "更新缓存元数据配置失败: " + saveResult.Error.Error(),
				Data:    nil,
			})
			return
		}
		c.JSON(http.StatusOK, models.Response{
			Code:    200,
			Message: "更新缓存元数据配置成功",
			Data:    existingConfig,
		})
		return
	}

	// 不存在，创建新配置
	config := models.CacheMetadataConfig{
		CacheKey:    req.CacheKey,
		CacheValue:  req.CacheValue,
		ExpireTime:  expireTime,
		Description: req.Description,
	}

	createResult := db.DB.Create(&config)
	if createResult.Error != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "创建缓存元数据配置失败: " + createResult.Error.Error(),
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "创建缓存元数据配置成功",
		Data:    config,
	})
}

// HandleDeleteCacheMetadataConfig 删除缓存元数据配置
func HandleDeleteCacheMetadataConfig(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Code:    400,
			Message: "无效的ID参数",
			Data:    nil,
		})
		return
	}

	result := db.DB.Delete(&models.CacheMetadataConfig{}, id)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "删除缓存元数据配置失败: " + result.Error.Error(),
			Data:    nil,
		})
		return
	}

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, models.Response{
			Code:    404,
			Message: "未找到指定的缓存元数据配置",
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "删除缓存元数据配置成功",
		Data:    nil,
	})
}
