package models

// Response 通用响应结构体
type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}

// Nacos 相关模型

type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type LoginResponse struct {
	AccessToken string `json:"accessToken"`
	TokenTtl    int    `json:"tokenTtl"`
}

type Namespace struct {
	Namespace         string `json:"namespace"`
	NamespaceShowName string `json:"namespaceShowName"`
	NamespaceDesc     string `json:"namespaceDesc"`
	Quota             int    `json:"quota"`
	ConfigCount       int    `json:"configCount"`
	Type              int    `json:"type"`
}

type NamespaceResponse struct {
	Code      int         `json:"code"`
	Message   interface{} `json:"message"`
	Data      []Namespace `json:"data"`
	PageItems interface{} `json:"pageItems"`
}

type ServiceListResponse struct {
	Count       int           `json:"count"`
	ServiceList []ServiceItem `json:"serviceList"`
}

type ServiceItem struct {
	Name                 string `json:"name"`
	GroupName            string `json:"groupName"`
	ClusterName          string `json:"clusterName"`
	IPCount              int    `json:"ipCount"`
	HealthyInstanceCount int    `json:"healthyInstanceCount"`
	TriggerFlag          string `json:"triggerFlag"`
}

type ServiceInstance struct {
	List []ServiceInstanceItem `json:"list"`
}

type ServiceInstanceItem struct {
	InstanceId                string      `json:"instanceId"`
	IP                        string      `json:"ip"`
	Port                      int         `json:"port"`
	Weight                    float64     `json:"weight"`
	Healthy                   bool        `json:"healthy"`
	Enabled                   bool        `json:"enabled"`
	Ephemeral                 bool        `json:"ephemeral"`
	ClusterName               string      `json:"clusterName"`
	ServiceName               string      `json:"serviceName"`
	Metadata                  interface{} `json:"metadata"`
	InstanceHeartBeatInterval int         `json:"instanceHeartBeatInterval"`
	InstanceHeartBeatTimeout  int         `json:"instanceHeartBeatTimeout"`
	IPDeleteTimeout           int         `json:"ipDeleteTimeout"`
}

type ConfigItem struct {
	ID               string `json:"id"`
	DataID           string `json:"dataId"`
	GroupName        string `json:"group"`
	Content          string `json:"content,omitempty"`
	MD5              string `json:"md5,omitempty"`
	EncryptedDataKey string `json:"encryptedDataKey,omitempty"`
	Tenant           string `json:"tenant,omitempty"`
	AppName          string `json:"appName,omitempty"`
	Type             string `json:"type,omitempty"`
}

type ConfigListResponse struct {
	TotalCount     int          `json:"totalCount"`
	PageNumber     int          `json:"pageNumber"`
	PagesAvailable int          `json:"pagesAvailable"`
	PageItems      []ConfigItem `json:"pageItems"`
}

// K8s 相关模型

type K8sNamespace struct {
	Name              string            `json:"name"`
	Status            string            `json:"status"`
	CreationTimestamp string            `json:"creationTimestamp"`
	Labels            map[string]string `json:"labels,omitempty"`
	Annotations       map[string]string `json:"annotations,omitempty"`
}

type K8sNamespaceListResponse struct {
	Items []K8sNamespace `json:"items"`
	Total int            `json:"total"`
}

type K8sLoginRequest struct {
	APIServer string `json:"apiServer" binding:"required"`
	Username  string `json:"username"`
	Password  string `json:"password"`
	Token     string `json:"token"`
}

type K8sLoginResponse struct {
	APIServer string `json:"apiServer"`
	Message   string `json:"message"`
}

// Deployment 相关模型
type K8sDeployment struct {
	Name              string             `json:"name"`
	Namespace         string             `json:"namespace"`
	Replicas          int32              `json:"replicas"`
	AvailableReplicas int32              `json:"availableReplicas"`
	ReadyReplicas     int32              `json:"readyReplicas"`
	Status            string             `json:"status"`
	CreationTimestamp string             `json:"creationTimestamp"`
	Labels            map[string]string  `json:"labels"`
	Annotations       map[string]string  `json:"annotations"`
	Containers        []K8sContainerSpec `json:"containers"`
}

// K8sContainerSpec 容器规格信息
type K8sContainerSpec struct {
	Name            string                  `json:"name"`
	Image           string                  `json:"image"`
	ImagePullPolicy string                  `json:"imagePullPolicy"`
	Command         []string                `json:"command"`
	Args            []string                `json:"args"`
	WorkingDir      string                  `json:"workingDir"`
	Ports           []K8sContainerPort      `json:"ports"`
	Env             []K8sEnvVar             `json:"env"`
	Resources       K8sResourceRequirements `json:"resources"`
}

// K8sContainerPort 容器端口
type K8sContainerPort struct {
	Name          string `json:"name"`
	ContainerPort int32  `json:"containerPort"`
	Protocol      string `json:"protocol"`
}

// K8sEnvVar 环境变量
type K8sEnvVar struct {
	Name  string `json:"name"`
	Value string `json:"value"`
}

// K8sResourceRequirements 资源需求
type K8sResourceRequirements struct {
	Limits   K8sResourceList `json:"limits"`
	Requests K8sResourceList `json:"requests"`
}

// K8sResourceList 资源列表
type K8sResourceList struct {
	CPU    string `json:"cpu"`
	Memory string `json:"memory"`
}

type K8sDeploymentListResponse struct {
	Items []K8sDeployment `json:"items"`
	Total int             `json:"total"`
}

// Pod 相关模型
type K8sPod struct {
	Name              string            `json:"name"`
	Namespace         string            `json:"namespace"`
	Status            string            `json:"status"`
	Phase             string            `json:"phase"`
	PodIP             string            `json:"podIP"`
	NodeName          string            `json:"nodeName"`
	RestartCount      int32             `json:"restartCount"`
	CreationTimestamp string            `json:"creationTimestamp"`
	Labels            map[string]string `json:"labels"`
	Annotations       map[string]string `json:"annotations"`
	Containers        []K8sContainer    `json:"containers"`
}

type K8sContainer struct {
	Name         string `json:"name"`
	Image        string `json:"image"`
	Ready        bool   `json:"ready"`
	RestartCount int32  `json:"restartCount"`
}

type K8sPodListResponse struct {
	Items []K8sPod `json:"items"`
	Total int      `json:"total"`
}

// Service 相关模型
type K8sServicePort struct {
	Name       string `json:"name"`
	Port       int32  `json:"port"`
	TargetPort int32  `json:"targetPort"`
	NodePort   int32  `json:"nodePort"`
	Protocol   string `json:"protocol"`
}

type K8sService struct {
	Name              string            `json:"name"`
	Namespace         string            `json:"namespace"`
	Type              string            `json:"type"`
	ClusterIP         string            `json:"clusterIP"`
	ExternalIPs       []string          `json:"externalIPs"`
	LoadBalancerIP    string            `json:"loadBalancerIP"`
	Ports             []K8sServicePort  `json:"ports"`
	Selector          map[string]string `json:"selector"`
	Labels            map[string]string `json:"labels"`
	Annotations       map[string]string `json:"annotations"`
	CreationTimestamp string            `json:"creationTimestamp"`
}

type K8sServiceListResponse struct {
	Items []K8sService `json:"items"`
	Total int          `json:"total"`
}

// Exec 命令执行相关模型
type K8sExecRequest struct {
	Namespace string   `json:"namespace" binding:"required"`
	Pod       string   `json:"pod" binding:"required"`
	Container string   `json:"container"`
	Command   []string `json:"command" binding:"required"`
}

type K8sExecResponse struct {
	Stdout string `json:"stdout"`
	Stderr string `json:"stderr"`
}
