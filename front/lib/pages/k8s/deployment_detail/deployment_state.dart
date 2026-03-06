import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../../services/api_service.dart';

/// Deployment 详情页面状态管理类
class DeploymentState extends ChangeNotifier {
  // 基础状态
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? deploymentData;

  // Services 相关
  List<dynamic> matchedServices = [];
  bool isLoadingServices = true;

  // Nacos 配置关联相关
  List<dynamic> nacosNamespaces = [];
  final Map<String, List<dynamic>> nacosConfigs = {};
  final Map<String, bool> isLoadingNacosConfigs = {};
  String? selectedNacosNamespace;
  String? selectedNacosConfigId;
  Map<String, dynamic>? existingMapping;
  Map<String, dynamic>? linkedNacosConfig;
  String? linkedNacosConfigContent; // 配置内容
  bool isLoadingMapping = true;
  bool isLoadingConfigContent = false; // 加载配置内容的状态

  // Nacos 服务关联相关
  Map<String, dynamic>? existingServiceMapping;
  Map<String, dynamic>? linkedNacosService;
  List<dynamic> nacosServiceInstances = [];
  bool isLoadingServiceMapping = true;

  // 日志路径配置相关
  Map<String, dynamic>? logPathConfig;
  bool isLoadingLogPath = true;
  final TextEditingController logPathController = TextEditingController();
  final TextEditingController logPathDescController = TextEditingController();

  String namespace;
  String deployment;
  final BuildContext context;

  DeploymentState({
    required this.namespace,
    required this.deployment,
    required this.context,
  });

  /// 显示 Toast 提示
  void showToast(String message, {bool isError = false}) {
    // 使用页面中的 showToast 方法
    // 这里通过回调方式处理
  }

  /// 重置所有状态
  void resetState() {
    isLoading = true;
    isLoadingServices = true;
    isLoadingMapping = true;
    isLoadingServiceMapping = true;
    isLoadingLogPath = true;
    isLoadingConfigContent = false;
    matchedServices = [];
    deploymentData = null;
    existingMapping = null;
    linkedNacosConfig = null;
    linkedNacosConfigContent = null;
    existingServiceMapping = null;
    linkedNacosService = null;
    nacosServiceInstances = [];
    logPathConfig = null;
    nacosNamespaces = [];
    nacosConfigs.clear();
    isLoadingNacosConfigs.clear();
    selectedNacosNamespace = null;
    selectedNacosConfigId = null;
    notifyListeners();
  }

  /// 加载所有数据
  Future<void> loadAllData() async {
    resetState();
    await loadDeploymentDetail();
    if (deploymentData != null) {
      await Future.wait([
        loadMatchedServices(),
        loadExistingMapping(),
        loadExistingServiceMapping(),
        loadLogPathConfig(),
      ]);
    }
    isLoading = false;
    notifyListeners();
  }

  /// 加载 Deployment 详情
  Future<void> loadDeploymentDetail() async {
    try {
      // 从 deployment 列表中找到对应的 deployment
      final response = await ApiService.getK8sDeployments(namespace);
      if (response['code'] == 200) {
        final deployments = response['data'] as Map<String, dynamic>? ?? {};
        var x = deployments['items'] as List<dynamic>? ?? [];
        deploymentData = x.firstWhere(
          (d) => d['name'] == deployment,
          orElse: () => null,
        );
        if (deploymentData == null) {
          errorMessage = 'Deployment 不存在';
        }
      } else {
        errorMessage = response['message'] ?? '加载失败';
      }
    } catch (e) {
      errorMessage = '加载失败: $e';
    }
    notifyListeners();
  }

  /// 加载匹配的 Services
  Future<void> loadMatchedServices() async {
    isLoadingServices = true;
    notifyListeners();

    try {
      final response = await ApiService.getK8sServices(namespace);
      if (response['code'] == 200) {
        final data = response['data'];
        List<dynamic> allServices = [];
        if (data is List) {
          allServices = data;
        } else if (data is Map<String, dynamic>) {
          allServices = data['items'] as List<dynamic>? ?? [];
        }
        final labels = deploymentData?['labels'] as Map<String, dynamic>? ?? {};

        matchedServices = allServices.where((service) {
          final selector = service['selector'] as Map<String, dynamic>? ?? {};
          if (selector.isEmpty) return false;
          return selector.entries.every((entry) {
            return labels[entry.key] == entry.value;
          });
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading services: $e');
    }

    isLoadingServices = false;
    notifyListeners();
  }

  /// 加载已存在的 Nacos 配置关联
  Future<void> loadExistingMapping() async {
    isLoadingMapping = true;
    notifyListeners();

    try {
      final response = await ApiService.getK8sNacosMapping(
        k8sNamespace: namespace,
        k8sDeployment: deployment,
      );

      if (response['code'] == 200 && response['data'] != null) {
        existingMapping = response['data'] as Map<String, dynamic>;
        selectedNacosNamespace = existingMapping!['nacosNamespace'];
        selectedNacosConfigId = existingMapping!['nacosConfigId'];

        if (selectedNacosNamespace != null && selectedNacosConfigId != null) {
          await loadLinkedNacosConfig(
            selectedNacosNamespace!,
            selectedNacosConfigId!,
          );
        }
        await loadNacosNamespaces();
        if (selectedNacosNamespace != null) {
          await loadNacosConfigs(selectedNacosNamespace!);
        }
      } else {
        await loadNacosNamespaces();
      }
    } catch (e) {
      debugPrint('Error loading mapping: $e');
      await loadNacosNamespaces();
    }

    isLoadingMapping = false;
    notifyListeners();
  }

  /// 加载已关联的 Nacos 配置详情
  Future<void> loadLinkedNacosConfig(
    String namespaceId,
    String configId,
  ) async {
    try {
      final response = await ApiService.getNacosConfigById(
        namespaceId: namespaceId,
        configId: configId,
      );

      if (response['code'] == 200 && response['data'] != null) {
        linkedNacosConfig = response['data'] as Map<String, dynamic>;
        notifyListeners();

        // 加载配置内容
        await loadNacosConfigContent(namespaceId, linkedNacosConfig!);
      }
    } catch (e) {
      debugPrint('Error loading linked config: $e');
    }
  }

  /// 加载 Nacos 配置内容
  Future<void> loadNacosConfigContent(
    String namespaceId,
    Map<String, dynamic> config,
  ) async {
    isLoadingConfigContent = true;
    notifyListeners();

    try {
      final dataId = config['dataId'] as String?;
      final group = config['group'] as String? ?? 'DEFAULT_GROUP';

      if (dataId != null) {
        final response = await ApiService.getNacosConfigDetail(
          namespaceId: namespaceId,
          dataId: dataId,
          group: group,
        );

        if (response['code'] == 200 && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          linkedNacosConfigContent = data['content'] as String?;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading config content: $e');
    }

    isLoadingConfigContent = false;
    notifyListeners();
  }

  /// 加载已存在的服务关联关系
  Future<void> loadExistingServiceMapping() async {
    isLoadingServiceMapping = true;
    notifyListeners();

    try {
      final response = await ApiService.getK8sNacosServiceMapping(
        k8sNamespace: namespace,
        k8sDeployment: deployment,
      );

      if (response['code'] == 200 && response['data'] != null) {
        existingServiceMapping = response['data'] as Map<String, dynamic>;
        final nacosNamespace =
            existingServiceMapping!['nacosNamespace'] as String?;
        final nacosServiceName =
            existingServiceMapping!['nacosServiceName'] as String?;
        final nacosGroupName =
            existingServiceMapping!['nacosGroupName'] as String?;

        if (nacosNamespace != null && nacosServiceName != null) {
          await loadNacosServiceInstances(
            nacosNamespace,
            nacosServiceName,
            nacosGroupName,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading service mapping: $e');
    }

    isLoadingServiceMapping = false;
    notifyListeners();
  }

  /// 加载 Nacos 服务实例
  Future<void> loadNacosServiceInstances(
    String ns,
    String serviceName,
    String? groupName,
  ) async {
    try {
      final response = await ApiService.getNacosServiceInstances(
        namespace: ns,
        serviceName: serviceName,
        groupName: groupName ?? 'DEFAULT_GROUP',
      );

      if (response['code'] == 200 && response['data'] != null) {
        linkedNacosService = {
          'serviceName': serviceName,
          'groupName': groupName ?? 'DEFAULT_GROUP',
          'namespace': ns,
        };
        nacosServiceInstances = response['data'] as List<dynamic>? ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading service instances: $e');
    }
  }

  /// 加载 Nacos Namespaces
  Future<void> loadNacosNamespaces() async {
    try {
      final response = await ApiService.getNacosNamespaces();
      if (response['code'] == 200 && response['data'] != null) {
        nacosNamespaces = response['data'] as List<dynamic>? ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading nacos namespaces: $e');
    }
  }

  /// 加载 Nacos Configs
  Future<void> loadNacosConfigs(String namespaceId) async {
    isLoadingNacosConfigs[namespaceId] = true;
    notifyListeners();

    try {
      final response = await ApiService.getNacosConfigs(namespaceId);
      if (response['code'] == 200 && response['data'] != null) {
        final data = response['data'];
        nacosConfigs[namespaceId] = data['pageItems'] as List<dynamic>? ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading nacos configs: $e');
    }

    isLoadingNacosConfigs[namespaceId] = false;
    notifyListeners();
  }

  /// 加载日志路径配置
  Future<void> loadLogPathConfig() async {
    isLoadingLogPath = true;
    notifyListeners();

    try {
      final response = await ApiService.getDeploymentLogPathConfig(
        k8sNamespace: namespace,
        k8sDeployment: deployment,
      );

      if (response['code'] == 200 && response['data'] != null) {
        logPathConfig = response['data'] as Map<String, dynamic>;
        logPathController.text = logPathConfig!['log_path'] ?? '';
        logPathDescController.text = logPathConfig!['description'] ?? '';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading log path config: $e');
    }

    isLoadingLogPath = false;
    notifyListeners();
  }

  /// 保存日志路径配置
  Future<bool> saveLogPathConfig() async {
    if (logPathController.text.isEmpty) {
      return false;
    }

    try {
      final response = await ApiService.saveDeploymentLogPathConfig(
        id: logPathConfig?['id'],
        k8sNamespace: namespace,
        k8sDeployment: deployment,
        logPath: logPathController.text,
        description: logPathDescController.text,
      );

      if (response['code'] == 200) {
        await loadLogPathConfig();
        return true;
      }
    } catch (e) {
      debugPrint('Error saving log path config: $e');
    }
    return false;
  }

  /// 删除日志路径配置
  Future<bool> deleteLogPathConfig() async {
    if (logPathConfig == null || logPathConfig!['id'] == null) return false;

    try {
      final response = await ApiService.deleteDeploymentLogPathConfig(
        logPathConfig!['id'],
      );

      if (response['code'] == 200) {
        logPathConfig = null;
        logPathController.clear();
        logPathDescController.clear();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting log path config: $e');
    }
    return false;
  }

  @override
  void dispose() {
    logPathController.dispose();
    logPathDescController.dispose();
    super.dispose();
  }
}
