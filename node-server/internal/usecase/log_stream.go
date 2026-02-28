package usecase

import (
	"bufio"
	"fmt"
	"io"
	"node-server/internal/domain"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// LogStreamProcess 存储日志流进程信息
type LogStreamProcess struct {
	Cmd       *exec.Cmd
	Stdout    io.ReadCloser
	Stderr    io.ReadCloser
	PodKey    string // namespace/podName
	StartTime time.Time
}

// 全局进程管理 map
var (
	logStreamProcesses = make(map[string]*LogStreamProcess) // key: namespace/podName
	logStreamMutex     sync.RWMutex
)

// LogStreamUseCase 处理日志流的业务逻辑
type LogStreamUseCase struct{}

// NewLogStreamUseCase 创建新的用例实例
func NewLogStreamUseCase() *LogStreamUseCase {
	return &LogStreamUseCase{}
}

// StartLogStream 在宿主机上启动 kubectl logs -f 进程
func (uc *LogStreamUseCase) StartLogStream(req domain.StartLogStreamRequest) (*domain.StartLogStreamResponse, error) {
	podKey := fmt.Sprintf("%s/%s", req.Namespace, req.PodName)

	// 检查是否已有进程在运行
	logStreamMutex.RLock()
	if existingProc, exists := logStreamProcesses[podKey]; exists {
		// 检查进程是否还在运行
		if existingProc.Cmd.Process != nil {
			if err := existingProc.Cmd.Process.Signal(os.Signal(nil)); err == nil {
				logStreamMutex.RUnlock()
				return &domain.StartLogStreamResponse{
					Success:   true,
					Message:   "日志流已在运行",
					ProcessID: fmt.Sprintf("%d", existingProc.Cmd.Process.Pid),
				}, nil
			}
		}
	}
	logStreamMutex.RUnlock()

	// 构建 kubectl logs -f 命令
	args := []string{"logs", "-n", req.Namespace, req.PodName, "-f"}
	if req.Container != "" {
		args = append(args, "-c", req.Container)
	}

	cmd := exec.Command("kubectl", args...)

	// 获取 stdout 和 stderr
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return nil, fmt.Errorf("获取 stdout pipe 失败: %w", err)
	}

	stderr, err := cmd.StderrPipe()
	if err != nil {
		return nil, fmt.Errorf("获取 stderr pipe 失败: %w", err)
	}

	// 启动进程
	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("启动 kubectl logs 失败: %w", err)
	}

	// 保存到全局 map
	proc := &LogStreamProcess{
		Cmd:       cmd,
		Stdout:    stdout,
		Stderr:    stderr,
		PodKey:    podKey,
		StartTime: time.Now(),
	}

	logStreamMutex.Lock()
	logStreamProcesses[podKey] = proc
	logStreamMutex.Unlock()

	// 启动 goroutine 等待进程结束并清理
	go func() {
		cmd.Wait()
		logStreamMutex.Lock()
		delete(logStreamProcesses, podKey)
		logStreamMutex.Unlock()
	}()

	return &domain.StartLogStreamResponse{
		Success:   true,
		Message:   "日志流启动成功",
		ProcessID: fmt.Sprintf("%d", cmd.Process.Pid),
	}, nil
}

// GetLogStreamProcess 获取日志流进程
func (uc *LogStreamUseCase) GetLogStreamProcess(namespace, podName string) (*LogStreamProcess, bool) {
	podKey := fmt.Sprintf("%s/%s", namespace, podName)
	logStreamMutex.RLock()
	defer logStreamMutex.RUnlock()
	proc, exists := logStreamProcesses[podKey]
	return proc, exists
}

// copyFullLogsFromPod 使用 kubectl cp 复制全量日志到本地临时目录
func (uc *LogStreamUseCase) copyFullLogsFromPod(req domain.LogStreamWebSocketRequest) (string, error) {
	// 创建临时目录
	tempDir := fmt.Sprintf("/tmp/log-stream-%d", time.Now().Unix())
	if err := os.MkdirAll(tempDir, 0755); err != nil {
		return "", fmt.Errorf("创建临时目录失败: %w", err)
	}

	// 本地临时文件路径
	localLogPath := filepath.Join(tempDir, fmt.Sprintf("%s-%s.log", req.Namespace, req.PodName))

	// 构建 kubectl cp 命令
	// 格式: kubectl cp <namespace>/<pod>:<container_path> <local_path> [-c container]
	remotePath := fmt.Sprintf("%s/%s:%s", req.Namespace, req.PodName, req.LogPath)
	args := []string{"cp", remotePath, localLogPath}
	if req.Container != "" {
		args = append(args, "-c", req.Container)
	}

	cmd := exec.Command("kubectl", args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		// 清理临时目录
		os.RemoveAll(tempDir)
		return "", fmt.Errorf("复制日志文件失败: %w, output: %s", err, string(output))
	}

	return localLogPath, nil
}

// sendFullLogs 发送全量日志内容（逐行发送，带限流）
func (uc *LogStreamUseCase) sendFullLogs(localLogPath string, sendMessage func(message string) error) error {
	file, err := os.Open(localLogPath)
	if err != nil {
		return fmt.Errorf("打开日志文件失败: %w", err)
	}
	defer file.Close()

	// 使用更大的缓冲区（1MB），避免超长行导致 scanner 失败
	const maxCapacity = 1024 * 1024 // 1MB
	buf := make([]byte, maxCapacity)

	scanner := bufio.NewScanner(file)
	scanner.Buffer(buf, maxCapacity)

	lineCount := 0
	ticker := time.NewTicker(10 * time.Microsecond) // 限流：每 10ms 发送一行
	defer ticker.Stop()

	for scanner.Scan() {
		line := scanner.Text()

		// 限流等待
		<-ticker.C

		if err := sendMessage(line); err != nil {
			return fmt.Errorf("发送全量日志消息失败: %w", err)
		}
		lineCount++

		// 每 1000 行打印一次进度
		if lineCount%1000 == 0 {
			fmt.Printf("[INFO] 已发送 %d 行日志...\n", lineCount)
		}
	}

	if err := scanner.Err(); err != nil {
		return fmt.Errorf("读取日志文件失败: %w", err)
	}

	// 发送分隔线，表示全量日志结束
	separator := fmt.Sprintf("\n--- 全量日志结束（共 %d 行），开始实时日志流 ---\n", lineCount)
	if err := sendMessage(separator); err != nil {
		return fmt.Errorf("发送分隔线失败: %w", err)
	}
	fmt.Print(separator)

	return nil
}

// StreamLogsToWebSocket 将日志流传输到 WebSocket
// 流程：1. 复制全量日志 -> 2. 回写全量日志 -> 3. 处理实时日志流
func (uc *LogStreamUseCase) StreamLogsToWebSocket(
	req domain.LogStreamWebSocketRequest,
	sendMessage func(message string) error,
	stopChan chan struct{},
) error {
	// 步骤 1: 复制全量日志到本地临时目录
	localLogPath, err := uc.copyFullLogsFromPod(req)
	if err != nil {
		// 如果复制失败（可能文件不存在），继续尝试实时日志
		sendMessage(fmt.Sprintf("[INFO] 全量日志复制失败（可能文件不存在）: %v", err))
		sendMessage("[INFO] 直接开始实时日志流...")
	} else {
		// 步骤 2: 回写全量日志
		defer os.RemoveAll(filepath.Dir(localLogPath)) // 清理临时目录
		fmt.Println("[INFO] 开始发送全量日志...")
		sendMessage("[INFO] 开始发送全量日志...")
		if err := uc.sendFullLogs(localLogPath, sendMessage); err != nil {
			return fmt.Errorf("发送全量日志失败: %w", err)
		}
	}

	// 步骤 3: 获取或启动实时日志流进程
	proc, exists := uc.GetLogStreamProcess(req.Namespace, req.PodName)
	if !exists {
		// 自动启动日志流
		startReq := domain.StartLogStreamRequest{
			Namespace: req.Namespace,
			PodName:   req.PodName,
			Container: req.Container,
		}
		_, err := uc.StartLogStream(startReq)
		if err != nil {
			return fmt.Errorf("启动日志流失败: %w", err)
		}
		// 重新获取
		proc, exists = uc.GetLogStreamProcess(req.Namespace, req.PodName)
		if !exists {
			return fmt.Errorf("无法获取日志流进程")
		}
	}

	// 创建扫描器读取 stdout 和 stderr
	stdoutScanner := bufio.NewScanner(proc.Stdout)
	stderrScanner := bufio.NewScanner(proc.Stderr)

	// 使用 channel 来协调读取和停止
	doneChan := make(chan struct{})
	errChan := make(chan error, 2)

	// 读取 stdout
	go func() {
		for stdoutScanner.Scan() {
			line := stdoutScanner.Text()
			if err := sendMessage(line); err != nil {
				errChan <- fmt.Errorf("发送日志消息失败: %w", err)
				return
			}
		}
		doneChan <- struct{}{}
	}()

	// 读取 stderr
	go func() {
		for stderrScanner.Scan() {
			line := stderrScanner.Text()
			if line != "" {
				if err := sendMessage("[ERROR] " + line); err != nil {
					errChan <- fmt.Errorf("发送错误消息失败: %w", err)
					return
				}
			}
		}
		doneChan <- struct{}{}
	}()

	// 等待停止信号或错误
	select {
	case <-stopChan:
		return nil
	case err := <-errChan:
		return err
	case <-doneChan:
		return nil
	}
}

// StopLogStream 停止日志流进程
func (uc *LogStreamUseCase) StopLogStream(namespace, podName string) error {
	podKey := fmt.Sprintf("%s/%s", namespace, podName)
	logStreamMutex.Lock()
	defer logStreamMutex.Unlock()

	proc, exists := logStreamProcesses[podKey]
	if !exists {
		return fmt.Errorf("日志流进程不存在")
	}

	if err := proc.Cmd.Process.Kill(); err != nil {
		return fmt.Errorf("停止日志流进程失败: %w", err)
	}

	delete(logStreamProcesses, podKey)
	return nil
}

// LogStreamProcessInfo 进程信息
type LogStreamProcessInfo struct {
	Namespace string    `json:"namespace"`
	PodName   string    `json:"podName"`
	ProcessID string    `json:"processId"`
	StartTime time.Time `json:"startTime"`
}

// GetAllLogStreamProcesses 获取所有日志流进程
func (uc *LogStreamUseCase) GetAllLogStreamProcesses() []LogStreamProcessInfo {
	logStreamMutex.RLock()
	defer logStreamMutex.RUnlock()

	processes := make([]LogStreamProcessInfo, 0, len(logStreamProcesses))
	for podKey, proc := range logStreamProcesses {
		parts := strings.Split(podKey, "/")
		if len(parts) == 2 {
			processes = append(processes, LogStreamProcessInfo{
				Namespace: parts[0],
				PodName:   parts[1],
				ProcessID: fmt.Sprintf("%d", proc.Cmd.Process.Pid),
				StartTime: proc.StartTime,
			})
		}
	}
	return processes
}
