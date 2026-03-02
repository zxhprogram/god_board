package db

import (
	"god-board/models"
	"log"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var DB *gorm.DB

func InitDB() {
	var err error
	DB, err = gorm.Open(sqlite.Open("god-board.db"), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// Auto migrate models
	err = DB.AutoMigrate(&models.K8sConfig{}, &models.NacosConfig{}, &models.K8sNacosMapping{}, &models.NodeServerConfig{}, &models.Newland9894Config{}, &models.Newland9895Config{}, &models.RedisConfig{}, &models.MySQLConfig{}, &models.CacheMetadataConfig{})
	if err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	log.Println("Database initialized successfully")
}
