package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"god-board/models"

	"github.com/gin-gonic/gin"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

// 全局变量
var (
	accessToken      string
	k8sClient        *kubernetes.Clientset
	k8sConfig        *rest.Config
	kubeSphereToken  string
	kubeSphereServer string
)

// Response 包装统一的响应格式
type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}

// SendError 发送错误响应
func SendError(c *gin.Context, code int, message string) {
	c.JSON(code, models.Response{
		Code:    code,
		Message: message,
		Data:    nil,
	})
}

// SendSuccess 发送成功响应
func SendSuccess(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusOK, models.Response{
		Code:    200,
		Message: message,
		Data:    data,
	})
}

// CheckNacosAuth 检查 Nacos 是否已登录
func CheckNacosAuth() bool {
	return accessToken != ""
}

// CheckK8sAuth 检查 K8s 是否已登录
func CheckK8sAuth() bool {
	return k8sClient != nil
}

// MakeHTTPRequest 发送 HTTP 请求
func MakeHTTPRequest(method, url string, body io.Reader, headers map[string]string) (*http.Response, error) {
	req, err := http.NewRequest(method, url, body)
	if err != nil {
		return nil, err
	}

	for key, value := range headers {
		req.Header.Set(key, value)
	}

	client := &http.Client{}
	return client.Do(req)
}

// ParseJSONResponse 解析 JSON 响应
func ParseJSONResponse(resp *http.Response, v interface{}) error {
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	return json.Unmarshal(body, v)
}

// convertToK8sNamespaces 将 corev1.Namespace 转换为 K8sNamespace
func convertToK8sNamespaces(namespaces []corev1.Namespace) []models.K8sNamespace {
	result := make([]models.K8sNamespace, 0, len(namespaces))
	for _, ns := range namespaces {
		status := string(ns.Status.Phase)
		result = append(result, models.K8sNamespace{
			Name:              ns.Name,
			Status:            status,
			CreationTimestamp: ns.CreationTimestamp.Format("2006-01-02T15:04:05Z"),
			Labels:            ns.Labels,
			Annotations:       ns.Annotations,
		})
	}
	return result
}

// getKubeSphereDeployments 通过 KubeSphere API 获取 deployment 列表
func getKubeSphereDeployments(namespace string) ([]models.K8sDeployment, error) {
	url := fmt.Sprintf("%s/api/v1/namespaces/%s/deployments", kubeSphereServer, namespace)

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
		return getKubeSphereDeploymentsSimple(namespace)
	}

	var result struct {
		Items []struct {
			Metadata struct {
				Name              string            `json:"name"`
				Namespace         string            `json:"namespace"`
				CreationTimestamp string            `json:"creationTimestamp"`
				Labels            map[string]string `json:"labels"`
				Annotations       map[string]string `json:"annotations"`
			} `json:"metadata"`
			Spec struct {
				Replicas int32 `json:"replicas"`
				Template struct {
					Spec struct {
						Containers []struct {
							Name            string   `json:"name"`
							Image           string   `json:"image"`
							ImagePullPolicy string   `json:"imagePullPolicy"`
							Command         []string `json:"command"`
							Args            []string `json:"args"`
							WorkingDir      string   `json:"workingDir"`
							Ports           []struct {
								Name          string `json:"name"`
								ContainerPort int32  `json:"containerPort"`
								Protocol      string `json:"protocol"`
							} `json:"ports"`
							Env []struct {
								Name  string `json:"name"`
								Value string `json:"value"`
							} `json:"env"`
							Resources struct {
								Limits   map[string]string `json:"limits"`
								Requests map[string]string `json:"requests"`
							} `json:"resources"`
						} `json:"containers"`
					} `json:"spec"`
				} `json:"template"`
			} `json:"spec"`
			Status struct {
				AvailableReplicas int32 `json:"availableReplicas"`
				ReadyReplicas     int32 `json:"readyReplicas"`
			} `json:"status"`
		} `json:"items"`
	}

	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}

	deployments := make([]models.K8sDeployment, 0, len(result.Items))
	for _, item := range result.Items {
		status := "Running"
		if item.Status.ReadyReplicas < item.Spec.Replicas {
			status = "Progressing"
		}
		if item.Status.ReadyReplicas == 0 {
			status = "Pending"
		}

		containers := make([]models.K8sContainerSpec, 0, len(item.Spec.Template.Spec.Containers))
		for _, c := range item.Spec.Template.Spec.Containers {
			ports := make([]models.K8sContainerPort, 0, len(c.Ports))
			for _, p := range c.Ports {
				ports = append(ports, models.K8sContainerPort{
					Name:          p.Name,
					ContainerPort: p.ContainerPort,
					Protocol:      p.Protocol,
				})
			}

			envs := make([]models.K8sEnvVar, 0, len(c.Env))
			for _, e := range c.Env {
				envs = append(envs, models.K8sEnvVar{
					Name:  e.Name,
					Value: e.Value,
				})
			}

			resources := models.K8sResourceRequirements{
				Limits:   models.K8sResourceList{CPU: c.Resources.Limits["cpu"], Memory: c.Resources.Limits["memory"]},
				Requests: models.K8sResourceList{CPU: c.Resources.Requests["cpu"], Memory: c.Resources.Requests["memory"]},
			}

			containers = append(containers, models.K8sContainerSpec{
				Name:            c.Name,
				Image:           c.Image,
				ImagePullPolicy: c.ImagePullPolicy,
				Command:         c.Command,
				Args:            c.Args,
				WorkingDir:      c.WorkingDir,
				Ports:           ports,
				Env:             envs,
				Resources:       resources,
			})
		}

		deployments = append(deployments, models.K8sDeployment{
			Name:              item.Metadata.Name,
			Namespace:         item.Metadata.Namespace,
			Replicas:          item.Spec.Replicas,
			AvailableReplicas: item.Status.AvailableReplicas,
			ReadyReplicas:     item.Status.ReadyReplicas,
			Status:            status,
			CreationTimestamp: item.Metadata.CreationTimestamp,
			Labels:            item.Metadata.Labels,
			Annotations:       item.Metadata.Annotations,
			Containers:        containers,
		})
	}

	return deployments, nil
}

// getKubeSphereDeploymentsSimple 使用 KubeSphere API 获取简单的 deployment 列表
func getKubeSphereDeploymentsSimple(namespace string) ([]models.K8sDeployment, error) {
	url := fmt.Sprintf("%s/kapis/resources.kubesphere.io/v1alpha3/namespaces/%s/deployments", kubeSphereServer, namespace)

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
				Annotations       map[string]string `json:"annotations"`
			} `json:"metadata"`
			Spec struct {
				Replicas int32 `json:"replicas"`
			} `json:"spec"`
			Status struct {
				AvailableReplicas int32 `json:"availableReplicas"`
				ReadyReplicas     int32 `json:"readyReplicas"`
			} `json:"status"`
		} `json:"items"`
	}

	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}

	deployments := make([]models.K8sDeployment, 0, len(result.Items))
	for _, item := range result.Items {
		status := "Running"
		if item.Status.ReadyReplicas < item.Spec.Replicas {
			status = "Progressing"
		}
		if item.Status.ReadyReplicas == 0 {
			status = "Pending"
		}

		deployments = append(deployments, models.K8sDeployment{
			Name:              item.Metadata.Name,
			Namespace:         item.Metadata.Namespace,
			Replicas:          item.Spec.Replicas,
			AvailableReplicas: item.Status.AvailableReplicas,
			ReadyReplicas:     item.Status.ReadyReplicas,
			Status:            status,
			CreationTimestamp: item.Metadata.CreationTimestamp,
			Labels:            item.Metadata.Labels,
			Annotations:       item.Metadata.Annotations,
		})
	}

	return deployments, nil
}

// convertToK8sDeployments 将 appsv1.Deployment 转换为 K8sDeployment
func convertToK8sDeployments(deployments []appsv1.Deployment) []models.K8sDeployment {
	result := make([]models.K8sDeployment, 0, len(deployments))
	for _, d := range deployments {
		status := "Running"
		if d.Status.ReadyReplicas < *d.Spec.Replicas {
			status = "Progressing"
		}
		if d.Status.ReadyReplicas == 0 {
			status = "Pending"
		}

		containers := make([]models.K8sContainerSpec, 0, len(d.Spec.Template.Spec.Containers))
		for _, c := range d.Spec.Template.Spec.Containers {
			ports := make([]models.K8sContainerPort, 0, len(c.Ports))
			for _, p := range c.Ports {
				ports = append(ports, models.K8sContainerPort{
					Name:          p.Name,
					ContainerPort: p.ContainerPort,
					Protocol:      string(p.Protocol),
				})
			}

			envs := make([]models.K8sEnvVar, 0, len(c.Env))
			for _, e := range c.Env {
				envs = append(envs, models.K8sEnvVar{
					Name:  e.Name,
					Value: e.Value,
				})
			}

			resources := models.K8sResourceRequirements{
				Limits:   models.K8sResourceList{CPU: c.Resources.Limits.Cpu().String(), Memory: c.Resources.Limits.Memory().String()},
				Requests: models.K8sResourceList{CPU: c.Resources.Requests.Cpu().String(), Memory: c.Resources.Requests.Memory().String()},
			}

			containers = append(containers, models.K8sContainerSpec{
				Name:            c.Name,
				Image:           c.Image,
				ImagePullPolicy: string(c.ImagePullPolicy),
				Command:         c.Command,
				Args:            c.Args,
				WorkingDir:      c.WorkingDir,
				Ports:           ports,
				Env:             envs,
				Resources:       resources,
			})
		}

		result = append(result, models.K8sDeployment{
			Name:              d.Name,
			Namespace:         d.Namespace,
			Replicas:          *d.Spec.Replicas,
			AvailableReplicas: d.Status.AvailableReplicas,
			ReadyReplicas:     d.Status.ReadyReplicas,
			Status:            status,
			CreationTimestamp: d.CreationTimestamp.Format("2006-01-02T15:04:05Z"),
			Labels:            d.Labels,
			Annotations:       d.Annotations,
			Containers:        containers,
		})
	}
	return result
}
