package domain

// StartLogStreamRequest 启动实时日志流的请求
type StartLogStreamRequest struct {
	Namespace string `json:"namespace" binding:"required"`
	PodName   string `json:"podName" binding:"required"`
	Container string `json:"container,omitempty"` // 可选，指定容器名
}

// StartLogStreamResponse 启动实时日志流的响应
type StartLogStreamResponse struct {
	Success   bool   `json:"success"`
	Message   string `json:"message"`
	ProcessID string `json:"processId,omitempty"` // 进程 ID
}

// LogStreamWebSocketRequest WebSocket 日志流传输请求
type LogStreamWebSocketRequest struct {
	Namespace string `json:"namespace"`
	PodName   string `json:"podName"`
	Container string `json:"container,omitempty"` // 可选，指定容器名
	LogPath   string `json:"logPath"`             // 容器内的日志文件路径
}
