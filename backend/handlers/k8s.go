package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"god-board/db"
	"god-board/models"

	"github.com/gin-gonic/gin"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/remotecommand"
)

// HandleK8sLogin 处理 K8s 登录，使用数据库中保存的配置
func HandleK8sLogin(c *gin.Context) {
	// 从数据库获取 K8s 配置
	var k8sConfigModel models.K8sConfig
	result := db.DB.First(&k8sConfigModel)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "未找到 K8s 服务器配置，请先配置服务器",
			Data:    nil,
		})
		return
	}

	// 使用数据库中的配置创建 K8s 客户端配置
	k8sConfig = &rest.Config{
		Host:            k8sConfigModel.Address,
		Username:        k8sConfigModel.Username,
		Password:        k8sConfigModel.Password,
		TLSClientConfig: rest.TLSClientConfig{Insecure: true},
	}

	// 创建客户端
	client, err := kubernetes.NewForConfig(k8sConfig)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "创建K8s客户端失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	k8sClient = client

	loginResp := models.K8sLoginResponse{
		APIServer: k8sConfigModel.Address,
		Message:   "K8s连接成功",
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "登录成功",
		Data:    loginResp,
	})
}

// HandleGetK8sNamespaces 获取 K8s 命名空间列表
func HandleGetK8sNamespaces(c *gin.Context) {
	if k8sClient == nil {
		c.JSON(http.StatusUnauthorized, models.Response{
			Code:    401,
			Message: "未登录K8s，请先调用登录接口",
			Data:    nil,
		})
		return
	}

	labelSelector := c.Query("labelSelector")

	listOptions := metav1.ListOptions{}
	if labelSelector != "" {
		listOptions.LabelSelector = labelSelector
	}

	namespaceList, err := k8sClient.CoreV1().Namespaces().List(context.Background(), listOptions)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "获取K8s命名空间失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	k8sNamespaces := convertToK8sNamespaces(namespaceList.Items)

	nsResp := models.K8sNamespaceListResponse{
		Items: k8sNamespaces,
		Total: len(k8sNamespaces),
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "获取K8s命名空间成功",
		Data:    nsResp,
	})
}

// HandleGetK8sDeployments 获取指定 namespace 下的所有 deployment
func HandleGetK8sDeployments(c *gin.Context) {
	namespace := c.Param("namespace")
	if namespace == "" {
		c.JSON(http.StatusBadRequest, models.Response{
			Code:    400,
			Message: "namespace 参数不能为空",
			Data:    nil,
		})
		return
	}

	// 检查是否是 KubeSphere 模式
	if kubeSphereToken != "" && kubeSphereServer != "" {
		// 使用 KubeSphere API 获取 deployment
		deployments, err := getKubeSphereDeployments(namespace)
		if err != nil {
			c.JSON(http.StatusInternalServerError, models.Response{
				Code:    500,
				Message: "获取KubeSphere deployment失败: " + err.Error(),
				Data:    nil,
			})
			return
		}

		resp := models.K8sDeploymentListResponse{
			Items: deployments,
			Total: len(deployments),
		}

		c.JSON(http.StatusOK, models.Response{
			Code:    200,
			Message: "获取 deployment 成功",
			Data:    resp,
		})
		return
	}

	// 原生 K8s 模式
	if k8sClient == nil {
		c.JSON(http.StatusUnauthorized, models.Response{
			Code:    401,
			Message: "未登录K8s，请先调用登录接口",
			Data:    nil,
		})
		return
	}

	deploymentList, err := k8sClient.AppsV1().Deployments(namespace).List(context.Background(), metav1.ListOptions{})
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "获取K8s deployment失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	deployments := convertToK8sDeployments(deploymentList.Items)

	resp := models.K8sDeploymentListResponse{
		Items: deployments,
		Total: len(deployments),
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "获取 deployment 成功",
		Data:    resp,
	})
}

// HandleGetK8sPods 获取指定 deployment 下的所有 pod
func HandleGetK8sPods(c *gin.Context) {
	namespace := c.Param("namespace")
	deployment := c.Param("deployment")

	if namespace == "" || deployment == "" {
		c.JSON(http.StatusBadRequest, models.Response{
			Code:    400,
			Message: "namespace 和 deployment 参数不能为空",
			Data:    nil,
		})
		return
	}

	// 检查是否是 KubeSphere 模式
	if kubeSphereToken != "" && kubeSphereServer != "" {
		pods, err := getKubeSpherePods(namespace, deployment)
		if err != nil {
			c.JSON(http.StatusInternalServerError, models.Response{
				Code:    500,
				Message: "获取KubeSphere pods失败: " + err.Error(),
				Data:    nil,
			})
			return
		}

		resp := models.K8sPodListResponse{
			Items: pods,
			Total: len(pods),
		}

		c.JSON(http.StatusOK, models.Response{
			Code:    200,
			Message: "获取 pods 成功",
			Data:    resp,
		})
		return
	}

	// 原生 K8s 模式
	if k8sClient == nil {
		c.JSON(http.StatusUnauthorized, models.Response{
			Code:    401,
			Message: "未登录K8s，请先调用登录接口",
			Data:    nil,
		})
		return
	}

	// 获取 deployment 的 label selector
	dep, err := k8sClient.AppsV1().Deployments(namespace).Get(context.Background(), deployment, metav1.GetOptions{})
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "获取 deployment 失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	// 使用 label selector 获取 pods
	selector := metav1.FormatLabelSelector(dep.Spec.Selector)
	podList, err := k8sClient.CoreV1().Pods(namespace).List(context.Background(), metav1.ListOptions{
		LabelSelector: selector,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "获取 pods 失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	pods := convertToK8sPods(podList.Items)

	resp := models.K8sPodListResponse{
		Items: pods,
		Total: len(pods),
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "获取 pods 成功",
		Data:    resp,
	})
}

// HandleK8sExec 在 pod 中执行命令
func HandleK8sExec(c *gin.Context) {
	var req models.K8sExecRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	// 检查是否是 KubeSphere 模式
	if kubeSphereToken != "" && kubeSphereServer != "" {
		result, err := execKubeSphereCommand(req.Namespace, req.Pod, req.Container, req.Command)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":  "Execution failed: " + err.Error(),
				"stderr": result,
			})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"stdout": result,
			"stderr": "",
		})
		return
	}

	// 原生 K8s 模式
	if k8sClient == nil || k8sConfig == nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未登录K8s，请先调用登录接口"})
		return
	}

	// 构建执行请求
	execReq := k8sClient.CoreV1().RESTClient().
		Post().
		Resource("pods").
		Name(req.Pod).
		Namespace(req.Namespace).
		SubResource("exec").
		Param("container", req.Container).
		Param("stdout", "true").
		Param("stderr", "true")

	for _, cmd := range req.Command {
		execReq = execReq.Param("command", cmd)
	}

	// 创建执行器
	exec, err := remotecommand.NewSPDYExecutor(k8sConfig, "POST", execReq.URL())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create executor: " + err.Error()})
		return
	}

	// 执行命令
	var stdout, stderr bytes.Buffer
	err = exec.Stream(remotecommand.StreamOptions{
		Stdout: &stdout,
		Stderr: &stderr,
		Stdin:  nil,
		Tty:    false,
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":  "Execution failed: " + err.Error(),
			"stderr": stderr.String(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"stdout": stdout.String(),
		"stderr": stderr.String(),
	})
}

// getKubeSpherePods 通过 KubeSphere API 获取 pod 列表
func getKubeSpherePods(namespace, deployment string) ([]models.K8sPod, error) {
	url := fmt.Sprintf("%s/api/v1/namespaces/%s/pods?labelSelector=app=%s", kubeSphereServer, namespace, deployment)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", "Bearer "+kubeSphereToken)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("请求失败: %s", string(body))
	}

	var result struct {
		Items []struct {
			Metadata struct {
				Name              string            `json:"name"`
				Namespace         string            `json:"namespace"`
				CreationTimestamp string            `json:"creationTimestamp"`
				Labels            map[string]string `json:"labels"`
			} `json:"metadata"`
			Spec struct {
				NodeName string `json:"nodeName"`
			} `json:"spec"`
			Status struct {
				Phase      string `json:"phase"`
				PodIP      string `json:"podIP"`
				Conditions []struct {
					Type   string `json:"type"`
					Status string `json:"status"`
				} `json:"conditions"`
				ContainerStatuses []struct {
					Name         string `json:"name"`
					RestartCount int32  `json:"restartCount"`
					Ready        bool   `json:"ready"`
					State        struct {
						Running *struct {
							StartedAt string `json:"startedAt"`
						} `json:"running"`
						Terminated *struct {
							ExitCode    int32  `json:"exitCode"`
							Reason      string `json:"reason"`
							FinishedAt  string `json:"finishedAt"`
							ContainerID string `json:"containerID"`
						} `json:"terminated"`
						Waiting *struct {
							Reason  string `json:"reason"`
							Message string `json:"message"`
						} `json:"waiting"`
					} `json:"state"`
				} `json:"containerStatuses"`
			} `json:"status"`
		} `json:"items"`
	}

	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}

	pods := make([]models.K8sPod, 0, len(result.Items))
	for _, item := range result.Items {
		status := item.Status.Phase
		restartCount := int32(0)

		if len(item.Status.ContainerStatuses) > 0 {
			restartCount = item.Status.ContainerStatuses[0].RestartCount
		}

		pods = append(pods, models.K8sPod{
			Name:              item.Metadata.Name,
			Namespace:         item.Metadata.Namespace,
			Status:            status,
			RestartCount:      restartCount,
			NodeName:          item.Spec.NodeName,
			PodIP:             item.Status.PodIP,
			CreationTimestamp: item.Metadata.CreationTimestamp,
			Labels:            item.Metadata.Labels,
		})
	}

	return pods, nil
}

// execKubeSphereCommand 通过 KubeSphere API 在 pod 中执行命令
func execKubeSphereCommand(namespace, podName, containerName string, command []string) (string, error) {
	url := fmt.Sprintf("%s/api/v1/namespaces/%s/pods/%s/exec", kubeSphereServer, namespace, podName)

	reqBody := map[string]interface{}{
		"container": containerName,
		"command":   command,
		"stdin":     false,
		"tty":       false,
	}

	jsonBody, err := json.Marshal(reqBody)
	if err != nil {
		return "", err
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", err
	}

	req.Header.Set("Authorization", "Bearer "+kubeSphereToken)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("执行失败: %s", string(body))
	}

	return string(body), nil
}

// convertToK8sPods 将 corev1.Pod 转换为 K8sPod
func convertToK8sPods(pods []corev1.Pod) []models.K8sPod {
	result := make([]models.K8sPod, 0, len(pods))
	for _, p := range pods {
		restartCount := int32(0)
		if len(p.Status.ContainerStatuses) > 0 {
			restartCount = p.Status.ContainerStatuses[0].RestartCount
		}

		result = append(result, models.K8sPod{
			Name:              p.Name,
			Namespace:         p.Namespace,
			Status:            string(p.Status.Phase),
			RestartCount:      restartCount,
			NodeName:          p.Spec.NodeName,
			PodIP:             p.Status.PodIP,
			CreationTimestamp: p.CreationTimestamp.Format("2006-01-02T15:04:05Z"),
			Labels:            p.Labels,
		})
	}
	return result
}

// HandleGetK8sServices 获取指定 namespace 下的 Service 列表
func HandleGetK8sServices(c *gin.Context) {
	if k8sClient == nil {
		c.JSON(http.StatusUnauthorized, models.Response{
			Code:    401,
			Message: "未登录K8s，请先调用登录接口",
			Data:    nil,
		})
		return
	}

	namespace := c.Param("namespace")
	if namespace == "" {
		c.JSON(http.StatusBadRequest, models.Response{
			Code:    400,
			Message: "namespace 不能为空",
			Data:    nil,
		})
		return
	}

	labelSelector := c.Query("labelSelector")

	listOptions := metav1.ListOptions{}
	if labelSelector != "" {
		listOptions.LabelSelector = labelSelector
	}

	serviceList, err := k8sClient.CoreV1().Services(namespace).List(context.Background(), listOptions)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.Response{
			Code:    500,
			Message: "获取K8s Service列表失败: " + err.Error(),
			Data:    nil,
		})
		return
	}

	k8sServices := convertToK8sServices(serviceList.Items)

	serviceResp := models.K8sServiceListResponse{
		Items: k8sServices,
		Total: len(k8sServices),
	}

	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: "success",
		Data:    serviceResp,
	})
}

// convertToK8sServices 将 K8s Service 对象转换为响应模型
func convertToK8sServices(services []corev1.Service) []models.K8sService {
	result := make([]models.K8sService, 0, len(services))
	for _, s := range services {
		ports := make([]models.K8sServicePort, 0, len(s.Spec.Ports))
		for _, port := range s.Spec.Ports {
			ports = append(ports, models.K8sServicePort{
				Name:       port.Name,
				Port:       port.Port,
				TargetPort: port.TargetPort.IntVal,
				NodePort:   port.NodePort,
				Protocol:   string(port.Protocol),
			})
		}

		result = append(result, models.K8sService{
			Name:              s.Name,
			Namespace:         s.Namespace,
			Type:              string(s.Spec.Type),
			ClusterIP:         s.Spec.ClusterIP,
			ExternalIPs:       s.Spec.ExternalIPs,
			LoadBalancerIP:    s.Spec.LoadBalancerIP,
			Ports:             ports,
			Selector:          s.Spec.Selector,
			Labels:            s.Labels,
			Annotations:       s.Annotations,
			CreationTimestamp: s.CreationTimestamp.Format("2006-01-02T15:04:05Z"),
		})
	}
	return result
}
