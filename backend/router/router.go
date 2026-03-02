package router

import (
	"god-board/config"
	"god-board/handlers"

	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	r := gin.Default()

	// Nacos 路由
	r.POST("/api/nacos/login", handlers.HandleLogin)
	r.GET("/api/nacos/namespaces", handlers.HandleGetNamespaces)
	r.GET("/api/nacos/configs", handlers.HandleGetConfigs)
	r.GET("/api/nacos/config/detail", handlers.HandleGetConfigDetail)
	r.GET("/api/nacos/services", handlers.HandleGetServices)
	r.GET("/api/nacos/instances", handlers.HandleInstances)

	// K8s 路由
	r.GET("/api/k8s/namespaces", handlers.HandleGetK8sNamespaces)
	r.POST("/api/k8s/login", handlers.HandleK8sLogin)
	r.GET("/api/k8s/namespaces/:namespace/deployments", handlers.HandleGetK8sDeployments)
	r.GET("/api/k8s/namespaces/:namespace/deployments/:deployment/pods", handlers.HandleGetK8sPods)
	r.GET("/api/k8s/namespaces/:namespace/services", handlers.HandleGetK8sServices)
	r.POST("/api/k8s/exec", handlers.HandleK8sExec)

	// 服务器配置路由
	r.GET("/api/configs", handlers.HandleGetServerConfigs)
	r.POST("/api/configs/k8s", handlers.HandleSaveK8sConfig)
	r.POST("/api/configs/nacos", handlers.HandleSaveNacosConfig)
	r.POST("/api/configs/nodeserver", handlers.HandleSaveNodeServerConfig)
	r.GET("/api/configs/nodeserver", handlers.HandleGetNodeServerConfig)

	// K8s 与 Nacos 关联关系路由
	r.POST("/api/mappings/k8s-nacos", handlers.HandleSaveK8sNacosMapping)
	r.GET("/api/mappings/k8s-nacos", handlers.HandleGetK8sNacosMapping)
	r.DELETE("/api/mappings/k8s-nacos", handlers.HandleDeleteK8sNacosMapping)

	// 新大陆网关配置路由
	r.GET("/api/configs/newland/9894", handlers.HandleGetNewland9894Config)
	r.POST("/api/configs/newland/9894", handlers.HandleSaveNewland9894Config)
	r.GET("/api/configs/newland/9895", handlers.HandleGetNewland9895Config)
	r.POST("/api/configs/newland/9895", handlers.HandleSaveNewland9895Config)

	// 存储服务器配置路由
	r.GET("/api/configs/redis", handlers.GetRedisConfig)
	r.POST("/api/configs/redis", handlers.SaveRedisConfig)
	r.GET("/api/configs/mysql", handlers.GetMySQLConfig)
	r.POST("/api/configs/mysql", handlers.SaveMySQLConfig)

	// 缓存元数据配置路由
	r.GET("/api/cache-metadata", handlers.HandleGetCacheMetadataConfigs)
	r.POST("/api/cache-metadata", handlers.HandleSaveCacheMetadataConfig)
	r.DELETE("/api/cache-metadata/:id", handlers.HandleDeleteCacheMetadataConfig)

	return r
}

func RunServer() {
	r := SetupRouter()
	r.Run(config.ServerPort)
}
