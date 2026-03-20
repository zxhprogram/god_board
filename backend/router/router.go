package router

import (
	"god-board/config"
	"god-board/db"
	"god-board/handlers"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	r := gin.Default()
	r.Use(cors.Default())

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

	// K8s 与 Nacos 配置关联关系路由
	r.POST("/api/mappings/k8s-nacos", handlers.HandleSaveK8sNacosMapping)
	r.GET("/api/mappings/k8s-nacos", handlers.HandleGetK8sNacosMapping)
	r.DELETE("/api/mappings/k8s-nacos", handlers.HandleDeleteK8sNacosMapping)

	// K8s 与 Nacos 服务关联关系路由
	r.POST("/api/mappings/k8s-nacos-service", handlers.HandleSaveK8sNacosServiceMapping)
	r.GET("/api/mappings/k8s-nacos-service", handlers.HandleGetK8sNacosServiceMapping)

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

	// Redis查询路由
	r.POST("/api/redis/query", handlers.HandleRedisQuery)
	r.POST("/api/redis/query/batch", handlers.HandleRedisQueryBatch)

	// 行业调用mongo授权配置路由
	r.GET("/api/industry-mongo-auth", func(c *gin.Context) {
		handlers.GetIndustryMongoAuthConfig(c, db.DB)
	})
	r.GET("/api/industry-mongo-auth/list", func(c *gin.Context) {
		handlers.GetIndustryMongoAuthConfigs(c, db.DB)
	})
	r.POST("/api/industry-mongo-auth", func(c *gin.Context) {
		handlers.SaveIndustryMongoAuthConfig(c, db.DB)
	})
	r.DELETE("/api/industry-mongo-auth/:id", func(c *gin.Context) {
		handlers.DeleteIndustryMongoAuthConfig(c, db.DB)
	})

	// Deployment 日志路径配置路由
	r.GET("/api/deployment-log-path", func(c *gin.Context) {
		handlers.GetDeploymentLogPathConfig(c, db.DB)
	})
	r.GET("/api/deployment-log-path/list", func(c *gin.Context) {
		handlers.GetDeploymentLogPathConfigs(c, db.DB)
	})
	r.POST("/api/deployment-log-path", func(c *gin.Context) {
		handlers.SaveDeploymentLogPathConfig(c, db.DB)
	})
	r.DELETE("/api/deployment-log-path/:id", func(c *gin.Context) {
		handlers.DeleteDeploymentLogPathConfig(c, db.DB)
	})

	return r
}

func RunServer() {
	r := SetupRouter()
	r.Run(config.ServerPort)
}
