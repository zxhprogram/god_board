package models

import (
	"time"
)

// K8sConfig 存储 K8s 服务器配置
type K8sConfig struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Address   string    `json:"address" gorm:"not null"`
	Username  string    `json:"username" gorm:"not null"`
	Password  string    `json:"password" gorm:"not null"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// NacosConfig 存储 Nacos 服务器配置
type NacosConfig struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Address   string    `json:"address" gorm:"not null"`
	Username  string    `json:"username" gorm:"not null"`
	Password  string    `json:"password" gorm:"not null"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// K8sNacosMapping 存储 K8s Deployment 与 Nacos 配置的关联关系
type K8sNacosMapping struct {
	ID             uint      `json:"id" gorm:"primaryKey"`
	K8sNamespace   string    `json:"k8sNamespace" gorm:"not null;index"`
	K8sDeployment  string    `json:"k8sDeployment" gorm:"not null;index"`
	NacosNamespace string    `json:"nacosNamespace" gorm:"not null"`
	NacosConfigID  string    `json:"nacosConfigId" gorm:"not null"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

// K8sNacosMappingRequest 保存关联关系的请求参数
type K8sNacosMappingRequest struct {
	K8sNamespace   string `json:"k8sNamespace" binding:"required"`
	K8sDeployment  string `json:"k8sDeployment" binding:"required"`
	NacosNamespace string `json:"nacosNamespace" binding:"required"`
	NacosConfigID  string `json:"nacosConfigId" binding:"required"`
}

// NodeServerConfig 存储 NodeServer 服务器配置
type NodeServerConfig struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Address   string    `json:"address" gorm:"not null"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// Newland9894Config 存储新大陆 9894 服务配置
type Newland9894Config struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Address   string    `json:"address" gorm:"not null"`
	Username  string    `json:"username" gorm:"not null"`
	Password  string    `json:"password" gorm:"not null"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// Newland9895Config 存储新大陆 9895 服务配置
type Newland9895Config struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Address   string    `json:"address" gorm:"not null"`
	Username  string    `json:"username" gorm:"not null"`
	Password  string    `json:"password" gorm:"not null"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// RedisConfig 存储 Redis 服务配置
type RedisConfig struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Host      string    `json:"host" gorm:"not null"`
	Port      int       `json:"port" gorm:"not null"`
	IsCluster bool      `json:"is_cluster" gorm:"default:false"`
	Password  string    `json:"password"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// MySQLConfig 存储 MySQL 服务配置
type MySQLConfig struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Host      string    `json:"host" gorm:"not null"`
	Port      int       `json:"port" gorm:"not null"`
	Username  string    `json:"username" gorm:"not null"`
	Password  string    `json:"password" gorm:"not null"`
	Database  string    `json:"database" gorm:"not null"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// CacheMetadataConfig 存储缓存元数据配置
type CacheMetadataConfig struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	CacheKey    string    `json:"cache_key" gorm:"not null;uniqueIndex"`
	CacheValue  string    `json:"cache_value" gorm:"not null"` // 缓存值
	ExpireTime  string    `json:"expire_time" gorm:"not null"` // 过期时间，固定值 2099-12-31 00:00:00
	Description string    `json:"description"`                 // 描述说明
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// CacheMetadataRequest 保存缓存元数据配置的请求参数
type CacheMetadataRequest struct {
	CacheKey    string `json:"cache_key" binding:"required"`
	CacheValue  string `json:"cache_value" binding:"required"`
	ExpireTime  string `json:"expire_time"`
	Description string `json:"description"`
}

// K8sNacosServiceMapping 存储 K8s Deployment 与 Nacos 服务的关联关系
type K8sNacosServiceMapping struct {
	ID               uint      `json:"id" gorm:"primaryKey"`
	K8sNamespace     string    `json:"k8sNamespace" gorm:"not null;index"`
	K8sDeployment    string    `json:"k8sDeployment" gorm:"not null;index"`
	NacosNamespace   string    `json:"nacosNamespace" gorm:"not null"`
	NacosServiceName string    `json:"nacosServiceName" gorm:"not null"`
	NacosGroupName   string    `json:"nacosGroupName" gorm:"not null;default:'DEFAULT_GROUP'"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

// K8sNacosServiceMappingRequest 保存服务关联关系的请求参数
type K8sNacosServiceMappingRequest struct {
	K8sNamespace     string `json:"k8sNamespace" binding:"required"`
	K8sDeployment    string `json:"k8sDeployment" binding:"required"`
	NacosNamespace   string `json:"nacosNamespace" binding:"required"`
	NacosServiceName string `json:"nacosServiceName" binding:"required"`
	NacosGroupName   string `json:"nacosGroupName"`
}

// IndustryMongoAuthConfig 存储行业调用mongo授权配置
type IndustryMongoAuthConfig struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	CacheKey    string    `json:"cache_key" gorm:"not null;uniqueIndex;default:'industryAkAuthConfig'"`
	CacheValue  string    `json:"cache_value" gorm:"not null"`
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// IndustryMongoAuthRequest 保存行业调用mongo授权配置的请求参数
type IndustryMongoAuthRequest struct {
	ID          *uint  `json:"id"`
	CacheKey    string `json:"cache_key" binding:"required"`
	CacheValue  string `json:"cache_value" binding:"required"`
	Description string `json:"description"`
}
