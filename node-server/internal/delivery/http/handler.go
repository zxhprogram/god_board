package http

import (
	"log"
	"net/http"
	"node-server/internal/domain"
	"node-server/internal/usecase"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

// Handler holds the use cases and serves HTTP requests.
type Handler struct {
	logStreamUseCase *usecase.LogStreamUseCase
}

// NewHandler creates a new HTTP handler.
func NewHandler(logStreamUC *usecase.LogStreamUseCase) *Handler {
	return &Handler{
		logStreamUseCase: logStreamUC,
	}
}

// RegisterRoutes sets up the routing for the HTTP server using a Gin engine.
func (h *Handler) RegisterRoutes(router *gin.Engine) {
	router.POST("/start-log-stream", h.handleStartLogStream)
	router.GET("/ws/log-stream", h.handleLogStreamWebSocket)
	router.GET("/log-stream-processes", h.handleGetLogStreamProcesses)
}

func (h *Handler) handleStartLogStream(c *gin.Context) {
	var req domain.StartLogStreamRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, domain.StartLogStreamResponse{
			Success: false,
			Message: "请求参数错误: " + err.Error(),
		})
		return
	}

	log.Printf("Received start-log-stream request for %s/%s", req.Namespace, req.PodName)

	resp, err := h.logStreamUseCase.StartLogStream(req)
	if err != nil {
		log.Printf("Start log stream for %s/%s failed: %v", req.Namespace, req.PodName, err)
		c.JSON(http.StatusInternalServerError, domain.StartLogStreamResponse{
			Success: false,
			Message: "启动日志流失败: " + err.Error(),
		})
		return
	}

	log.Printf("Start log stream for %s/%s completed successfully, process ID: %s", req.Namespace, req.PodName, resp.ProcessID)
	c.JSON(http.StatusOK, resp)
}

// WebSocket upgrader
var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // 允许所有来源，生产环境应该限制
	},
}

func (h *Handler) handleLogStreamWebSocket(c *gin.Context) {
	// 从查询参数获取信息
	namespace := c.Query("namespace")
	podName := c.Query("podName")
	logPath := c.Query("logPath")
	container := c.Query("container")

	if namespace == "" || podName == "" || logPath == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "namespace, podName and logPath are required"})
		return
	}

	// 升级 HTTP 连接为 WebSocket
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("WebSocket upgrade failed: %v", err)
		return
	}
	defer conn.Close()

	log.Printf("WebSocket connection established for %s/%s, log path: %s", namespace, podName, logPath)

	// 创建停止信号通道
	stopChan := make(chan struct{})

	// 启动 goroutine 处理客户端消息（如关闭信号）
	go func() {
		for {
			_, _, err := conn.ReadMessage()
			if err != nil {
				// 客户端断开连接或出错
				close(stopChan)
				return
			}
		}
	}()

	// 发送消息函数
	sendMessage := func(message string) error {
		return conn.WriteMessage(websocket.TextMessage, []byte(message))
	}

	// 开始日志流传输
	req := domain.LogStreamWebSocketRequest{
		Namespace: namespace,
		PodName:   podName,
		LogPath:   logPath,
	}
	if container != "" {
		req.Container = container
	}

	if err := h.logStreamUseCase.StreamLogsToWebSocket(req, sendMessage, stopChan); err != nil {
		log.Printf("Log stream error: %v", err)
		conn.WriteMessage(websocket.TextMessage, []byte("[ERROR] "+err.Error()))
	}

	// WebSocket 连接断开，停止对应的日志流进程
	log.Printf("WebSocket connection closed for %s/%s, stopping log stream process", namespace, podName)
	if err := h.logStreamUseCase.StopLogStream(namespace, podName); err != nil {
		log.Printf("Failed to stop log stream for %s/%s: %v", namespace, podName, err)
	} else {
		log.Printf("Log stream process for %s/%s stopped successfully", namespace, podName)
	}
}

// handleGetLogStreamProcesses 获取所有日志流进程列表
func (h *Handler) handleGetLogStreamProcesses(c *gin.Context) {
	processes := h.logStreamUseCase.GetAllLogStreamProcesses()
	c.JSON(http.StatusOK, gin.H{
		"success":   true,
		"processes": processes,
		"count":     len(processes),
	})
}
