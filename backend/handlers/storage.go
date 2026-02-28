package handlers

import (
	"god-board/db"
	"god-board/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// GetRedisConfig 获取 Redis 配置
func GetRedisConfig(c *gin.Context) {
	var config models.RedisConfig
	result := db.DB.First(&config)
	if result.Error != nil {
		c.JSON(http.StatusOK, Response{
			Code:    200,
			Message: "未找到配置",
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Code:    200,
		Message: "获取成功",
		Data:    config,
	})
}

// SaveRedisConfig 保存 Redis 配置
func SaveRedisConfig(c *gin.Context) {
	var config models.RedisConfig
	if err := c.ShouldBindJSON(&config); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Code:    400,
			Message: "参数错误: " + err.Error(),
			Data:    nil,
		})
		return
	}

	// 清空 ID，确保是新增或更新
	config.ID = 0

	// 删除旧配置
	db.DB.Exec("DELETE FROM redis_configs")

	// 保存新配置
	if result := db.DB.Create(&config); result.Error != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Code:    500,
			Message: "保存失败: " + result.Error.Error(),
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Code:    200,
		Message: "保存成功",
		Data:    config,
	})
}

// GetMySQLConfig 获取 MySQL 配置
func GetMySQLConfig(c *gin.Context) {
	var config models.MySQLConfig
	result := db.DB.First(&config)
	if result.Error != nil {
		c.JSON(http.StatusOK, Response{
			Code:    200,
			Message: "未找到配置",
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Code:    200,
		Message: "获取成功",
		Data:    config,
	})
}

// SaveMySQLConfig 保存 MySQL 配置
func SaveMySQLConfig(c *gin.Context) {
	var config models.MySQLConfig
	if err := c.ShouldBindJSON(&config); err != nil {
		c.JSON(http.StatusBadRequest, Response{
			Code:    400,
			Message: "参数错误: " + err.Error(),
			Data:    nil,
		})
		return
	}

	// 清空 ID，确保是新增或更新
	config.ID = 0

	// 删除旧配置
	db.DB.Exec("DELETE FROM mysql_configs")

	// 保存新配置
	if result := db.DB.Create(&config); result.Error != nil {
		c.JSON(http.StatusInternalServerError, Response{
			Code:    500,
			Message: "保存失败: " + result.Error.Error(),
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, Response{
		Code:    200,
		Message: "保存成功",
		Data:    config,
	})
}
