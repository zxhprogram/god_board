package adapter

// KubernetesGateway defines the interface for interacting with Kubernetes.
type KubernetesGateway interface {
	// 新增方法用于日志流
	StartLogStream(namespace, podName, container string) (string, error)
	CopyFileFromPod(namespace, podName, container, sourcePath, destPath string) error
}
