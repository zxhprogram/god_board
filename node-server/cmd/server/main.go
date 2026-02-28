package main

import (
	"flag"
	"log"
	"node-server/internal/usecase"

	httphandler "node-server/internal/delivery/http"

	"github.com/gin-gonic/gin"
)

func main() {
	// 1. Parse Command-line flags
	httpListenAddr := flag.String("http-listen", ":28402", "Port for the HTTP management server")
	flag.Parse()
	// 4. Instantiate Adapters and Use Cases
	logStreamUC := usecase.NewLogStreamUseCase()
	// 5. Setup and Start HTTP Server
	gin.SetMode(gin.ReleaseMode)
	router := gin.Default()
	httpHandler := httphandler.NewHandler(logStreamUC)
	httpHandler.RegisterRoutes(router)
	log.Printf("Node-server HTTP management interface starting on %s...", *httpListenAddr)
	if err := router.Run(*httpListenAddr); err != nil {
		log.Fatalf("Failed to start HTTP management server: %v", err)
	}
}
