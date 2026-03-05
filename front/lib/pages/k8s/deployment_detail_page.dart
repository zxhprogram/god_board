import 'package:flutter/material.dart'
    show AlertDialog, DataTable, DataColumn, DataRow, DataCell;
import 'package:shadcn_flutter/shadcn_flutter.dart' hide AlertDialog;

import '../../services/api_service.dart';

class DeploymentDetailPage extends StatefulWidget {
  final String namespace;
  final String deployment;

  const DeploymentDetailPage({
    super.key,
    required this.namespace,
    required this.deployment,
  });

  @override
  State<DeploymentDetailPage> createState() => _DeploymentDetailPageState();
}

class _DeploymentDetailPageState extends State<DeploymentDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _deploymentData;
  List<dynamic> _matchedServices = [];
  bool _isLoadingServices = true;

  // Nacos 配置关联相关状态
  List<dynamic> _nacosNamespaces = [];
  final Map<String, List<dynamic>> _nacosConfigs = {};
  final Map<String, bool> _isLoadingNacosConfigs = {};
  String? _selectedNacosNamespace;
  String? _selectedNacosConfigId;
  Map<String, dynamic>? _existingMapping;
  Map<String, dynamic>? _linkedNacosConfig; // 已关联的 Nacos 配置详情
  bool _isLoadingMapping = true;

  // Nacos 服务关联相关状态
  Map<String, dynamic>? _existingServiceMapping;
  Map<String, dynamic>? _linkedNacosService; // 已关联的 Nacos 服务详情
  List<dynamic> _nacosServiceInstances = []; // 服务实例列表
  bool _isLoadingServiceMapping = true;

  // 日志路径配置相关状态
  Map<String, dynamic>? _logPathConfig;
  bool _isLoadingLogPath = true;
  final TextEditingController _logPathController = TextEditingController();
  final TextEditingController _logPathDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(DeploymentDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 namespace 或 deployment 发生变化时重新加载数据
    if (oldWidget.namespace != widget.namespace ||
        oldWidget.deployment != widget.deployment) {
      _loadData();
    }
  }

  // 显示 Toast 提示
  void _showToast(String message, {bool isError = false}) {
    showToast(
      context: context,
      builder: (context, overlay) => Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error : Icons.info,
                color: isError ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 12),
              Text(message),
              const SizedBox(width: 8),
              IconButton.ghost(
                onPressed: overlay.close,
                icon: const Icon(Icons.close, size: 16),
              ),
            ],
          ),
        ),
      ),
      location: ToastLocation.topRight,
      showDuration: const Duration(seconds: 3),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isLoadingServices = true;
      _isLoadingMapping = true;
      _isLoadingServiceMapping = true;
      _isLoadingLogPath = true;
      _matchedServices = [];
      _deploymentData = null;
      _existingMapping = null;
      _linkedNacosConfig = null;
      _existingServiceMapping = null;
      _linkedNacosService = null;
      _nacosServiceInstances = [];
      _logPathConfig = null;
      // 重置 Nacos 相关状态
      _nacosNamespaces = [];
      _nacosConfigs.clear();
      _isLoadingNacosConfigs.clear();
      _selectedNacosNamespace = null;
      _selectedNacosConfigId = null;
    });
    // 先加载 Deployment 详情，确保 _deploymentData 可用后再加载 Services
    await _loadDeploymentDetail();
    if (_deploymentData != null) {
      await _loadMatchedServices();
      await _loadExistingMapping();
      await _loadExistingServiceMapping();
      await _loadLogPathConfig();
    }
  }

  // 加载日志路径配置
  Future<void> _loadLogPathConfig() async {
    setState(() => _isLoadingLogPath = true);

    try {
      final response = await ApiService.getDeploymentLogPathConfig(
        k8sNamespace: widget.namespace,
        k8sDeployment: widget.deployment,
      );

      if (response['code'] == 200 && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        setState(() {
          _logPathConfig = data;
          _logPathController.text = data['log_path'] ?? '';
          _logPathDescController.text = data['description'] ?? '';
        });
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error loading log path config: $e');
    }

    setState(() => _isLoadingLogPath = false);
  }

  // 保存日志路径配置
  Future<void> _saveLogPathConfig() async {
    if (_logPathController.text.isEmpty) {
      _showToast('请输入日志路径', isError: true);
      return;
    }

    try {
      final response = await ApiService.saveDeploymentLogPathConfig(
        id: _logPathConfig?['id'],
        k8sNamespace: widget.namespace,
        k8sDeployment: widget.deployment,
        logPath: _logPathController.text,
        description: _logPathDescController.text,
      );

      if (response['code'] == 200) {
        _showToast('保存成功');
        _loadLogPathConfig();
      } else {
        _showToast(response['message'] ?? '保存失败', isError: true);
      }
    } catch (e) {
      _showToast('保存失败: $e', isError: true);
    }
  }

  // 删除日志路径配置
  Future<void> _deleteLogPathConfig() async {
    if (_logPathConfig == null || _logPathConfig!['id'] == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除日志路径配置吗？'),
        actions: [
          SecondaryButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          PrimaryButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.deleteDeploymentLogPathConfig(
        _logPathConfig!['id'],
      );

      if (response['code'] == 200) {
        _showToast('删除成功');
        setState(() {
          _logPathConfig = null;
          _logPathController.clear();
          _logPathDescController.clear();
        });
      } else {
        _showToast(response['message'] ?? '删除失败', isError: true);
      }
    } catch (e) {
      _showToast('删除失败: $e', isError: true);
    }
  }

  // 加载已存在的关联关系
  Future<void> _loadExistingMapping() async {
    final response = await ApiService.getK8sNacosMapping(
      k8sNamespace: widget.namespace,
      k8sDeployment: widget.deployment,
    );

    if (response['code'] == 200 && response['data'] != null) {
      setState(() {
        _existingMapping = response['data'] as Map<String, dynamic>;
        _selectedNacosNamespace = _existingMapping!['nacosNamespace'];
        _selectedNacosConfigId = _existingMapping!['nacosConfigId'];
        _isLoadingMapping = false;
      });
      // 加载已关联的 Nacos 配置详情
      if (_selectedNacosNamespace != null && _selectedNacosConfigId != null) {
        await _loadLinkedNacosConfig(
          _selectedNacosNamespace!,
          _selectedNacosConfigId!,
        );
      }
      // 加载 Nacos namespaces
      await _loadNacosNamespaces();
      // 如果有关联的配置，加载对应的 configs
      if (_selectedNacosNamespace != null) {
        await _loadNacosConfigs(_selectedNacosNamespace!);
      }
    } else {
      setState(() {
        _isLoadingMapping = false;
      });
      // 加载 Nacos namespaces
      await _loadNacosNamespaces();
    }
  }

  // 加载已关联的 Nacos 配置详情
  Future<void> _loadLinkedNacosConfig(
    String namespaceId,
    String configId,
  ) async {
    final response = await ApiService.getNacosConfigById(
      namespaceId: namespaceId,
      configId: configId,
    );

    if (response['code'] == 200 && response['data'] != null) {
      setState(() {
        _linkedNacosConfig = response['data'] as Map<String, dynamic>;
      });
    }
  }

  // 加载已存在的服务关联关系
  Future<void> _loadExistingServiceMapping() async {
    final response = await ApiService.getK8sNacosServiceMapping(
      k8sNamespace: widget.namespace,
      k8sDeployment: widget.deployment,
    );

    if (response['code'] == 200 && response['data'] != null) {
      setState(() {
        _existingServiceMapping = response['data'] as Map<String, dynamic>;
        _isLoadingServiceMapping = false;
      });
      // 加载已关联的 Nacos 服务实例
      final nacosNamespace =
          _existingServiceMapping!['nacosNamespace'] as String?;
      final nacosServiceName =
          _existingServiceMapping!['nacosServiceName'] as String?;
      final nacosGroupName =
          _existingServiceMapping!['nacosGroupName'] as String?;
      if (nacosNamespace != null && nacosServiceName != null) {
        await _loadNacosServiceInstances(
          nacosNamespace,
          nacosServiceName,
          nacosGroupName,
        );
      }
    } else {
      setState(() {
        _isLoadingServiceMapping = false;
      });
    }
  }

  // 加载 Nacos 服务实例列表
  Future<void> _loadNacosServiceInstances(
    String namespace,
    String serviceName,
    String? groupName,
  ) async {
    final response = await ApiService.getNacosServiceInstances(
      namespace: namespace,
      serviceName: serviceName,
      groupName: groupName,
    );

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      setState(() {
        _nacosServiceInstances = data['list'] as List<dynamic>? ?? [];
        _linkedNacosService = {
          'namespace': namespace,
          'serviceName': serviceName,
          'groupName': groupName ?? 'DEFAULT_GROUP',
        };
      });
    }
  }

  // 加载 Nacos namespaces
  Future<void> _loadNacosNamespaces() async {
    // 先调用 Nacos 登录
    final loginResponse = await ApiService.nacosLogin();
    if (loginResponse['code'] != 200) {
      if (mounted) {
        _showToast('Nacos 登录失败: ${loginResponse['message']}', isError: true);
      }
      return;
    }

    final response = await ApiService.getNacosNamespaces();

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      // 确保 data 是 Map 类型
      if (data is List<dynamic>) {
      } else {
        setState(() {
          _nacosNamespaces = [];
        });
      }
    } else {
      if (mounted && response['code'] != 200) {
        _showToast(
          '获取 Nacos Namespaces 失败: ${response['message']}',
          isError: true,
        );
      }
    }
  }

  // 加载指定 Nacos namespace 下的 configs
  Future<void> _loadNacosConfigs(String namespaceId) async {
    if (_nacosConfigs.containsKey(namespaceId)) return;

    setState(() {
      _isLoadingNacosConfigs[namespaceId] = true;
    });

    final response = await ApiService.getNacosConfigs(namespaceId);

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      setState(() {
        _nacosConfigs[namespaceId] = data['pageItems'] as List<dynamic>? ?? [];
        _isLoadingNacosConfigs[namespaceId] = false;
      });
    } else {
      setState(() {
        _nacosConfigs[namespaceId] = [];
        _isLoadingNacosConfigs[namespaceId] = false;
      });
    }
  }

  Future<void> _loadDeploymentDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 获取指定 namespace 下的所有 deployment，然后找到当前 deployment
    final response = await ApiService.getK8sDeployments(widget.namespace);

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      final items = data['items'] as List<dynamic>? ?? [];

      // 查找当前 deployment
      final dep = items.firstWhere(
        (item) => item['name'] == widget.deployment,
        orElse: () => null,
      );

      if (dep != null) {
        setState(() {
          _deploymentData = dep;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '未找到 deployment: ${widget.deployment}';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = response['message'] ?? '获取 deployment 详情失败';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMatchedServices() async {
    final response = await ApiService.getK8sServices(widget.namespace);

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      final allServices = data['items'] as List<dynamic>? ?? [];

      // 获取 deployment 的 labels
      final deploymentLabels =
          _deploymentData?['labels'] as Map<String, dynamic>? ?? {};

      // 筛选匹配的 service（service 的 selector 与 deployment 的 labels 匹配）
      final matched = allServices.where((service) {
        final selector = service['selector'] as Map<String, dynamic>? ?? {};
        if (selector.isEmpty) return false;

        // 检查 deployment 的 labels 是否包含 service selector 的所有键值对
        for (final entry in selector.entries) {
          if (deploymentLabels[entry.key] != entry.value) {
            return false;
          }
        }
        return true;
      }).toList();

      setState(() {
        _matchedServices = matched;
        _isLoadingServices = false;
      });
    } else {
      setState(() {
        _isLoadingServices = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(child: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载中...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.gray),
            ),
            const SizedBox(height: 16),
            PrimaryButton(onPressed: _loadData, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_deploymentData == null) {
      return const Center(child: Text('暂无数据'));
    }

    final labels = _deploymentData!['labels'] as Map<String, dynamic>? ?? {};
    final annotations =
        _deploymentData!['annotations'] as Map<String, dynamic>? ?? {};
    final containers = _deploymentData!['containers'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              const Icon(Icons.apps, size: 32, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.deployment,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 状态标签
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_deploymentData!['readyReplicas'] ?? 0}/${_deploymentData!['replicas'] ?? 0} Ready',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Namespace: ${widget.namespace}',
                style: const TextStyle(fontSize: 14, color: Colors.gray),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // 基本信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '基本信息',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('名称', _deploymentData!['name'] ?? '-'),
                  _buildInfoRow('Namespace', widget.namespace),
                  _buildInfoRow(
                    'Replicas',
                    '${_deploymentData!['replicas'] ?? 0}',
                  ),
                  _buildInfoRow(
                    'Ready Replicas',
                    '${_deploymentData!['readyReplicas'] ?? 0}',
                  ),
                  _buildInfoRow(
                    '创建时间',
                    _deploymentData!['creationTimestamp'] ?? '-',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Labels 卡片
          if (labels.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Labels',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: labels.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.gray.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${entry.key}: ${entry.value}'),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Annotations 卡片
          if (annotations.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Annotations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...annotations.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: const TextStyle(color: Colors.gray),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Containers 卡片
          if (containers.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Containers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...containers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final container = entry.value as Map<String, dynamic>;
                      return _buildContainerCard(index, container);
                    }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Services 卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '关联的 Services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isLoadingServices)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_matchedServices.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingServices)
                    const Center(child: Text('加载中...'))
                  else if (_matchedServices.isEmpty)
                    const Center(
                      child: Text(
                        '暂无关联的 Service',
                        style: TextStyle(color: Colors.gray),
                      ),
                    )
                  else
                    _buildServiceTable(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Nacos 关联卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nacos 配置关联',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isLoadingMapping)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_existingMapping != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '已关联',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 显示已关联的配置摘要
                  if (_linkedNacosConfig != null) ...[
                    _buildLinkedConfigSummary(),
                    const SizedBox(height: 16),
                  ],
                  // 关联配置按钮
                  PrimaryButton(
                    onPressed: () => _showNacosMappingDrawer(),
                    child: Text(
                      _existingMapping != null ? '重新关联配置' : '关联 Nacos 配置',
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Nacos 服务关联
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nacos 服务关联',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isLoadingServiceMapping)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_existingServiceMapping != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '已关联',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 显示已关联的服务摘要和实例列表
                  if (_linkedNacosService != null) ...[
                    _buildLinkedServiceSummary(),
                    const SizedBox(height: 16),
                  ],
                  // 关联服务按钮
                  PrimaryButton(
                    onPressed: () => _showNacosServiceMappingDrawer(),
                    child: Text(
                      _existingServiceMapping != null
                          ? '重新关联服务'
                          : '关联 Nacos 服务',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 日志路径配置卡片
          _buildLogPathConfigCard(),
        ],
      ),
    );
  }

  // 构建日志路径配置卡片
  Widget _buildLogPathConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '日志路径配置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isLoadingLogPath)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_logPathConfig != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '已配置',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // 已配置的日志路径显示
            if (_logPathConfig != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.folder,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '当前日志路径',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _logPathConfig!['log_path'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    if (_logPathConfig!['description'] != null &&
                        _logPathConfig!['description']
                            .toString()
                            .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '描述: ${_logPathConfig!['description']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.gray.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // 日志路径输入框
            TextField(
              controller: _logPathController,
              placeholder: const Text('日志路径'),
              hintText: '请输入日志文件路径，例如: /var/log/app/app.log',
            ),
            const SizedBox(height: 12),
            // 描述输入框
            TextField(
              controller: _logPathDescController,
              placeholder: const Text('描述（可选）'),
              hintText: '请输入日志路径的描述信息',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            // 操作按钮
            Row(
              children: [
                PrimaryButton(
                  onPressed: _saveLogPathConfig,
                  child: Text(_logPathConfig != null ? '更新配置' : '保存配置'),
                ),
                const SizedBox(width: 12),
                if (_logPathConfig != null)
                  SecondaryButton(
                    onPressed: _deleteLogPathConfig,
                    child: const Text('删除配置'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建已关联的 Nacos 服务摘要和实例列表
  Widget _buildLinkedServiceSummary() {
    final serviceName = _linkedNacosService?['serviceName'] ?? '未知';
    final groupName = _linkedNacosService?['groupName'] ?? 'DEFAULT_GROUP';
    final namespace = _linkedNacosService?['namespace'] ?? '';
    final namespaceName =
        _nacosNamespaces.firstWhere(
          (ns) => ns['namespace'] == namespace,
          orElse: () => {'namespaceShowName': namespace},
        )['namespaceShowName'] ??
        namespace;

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  '已关联的 Nacos 服务',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('服务名', serviceName),
            _buildInfoRow('分组', groupName),
            _buildInfoRow('Namespace', namespaceName),
            const SizedBox(height: 12),
            // 服务实例列表
            Text(
              '服务实例 (${_nacosServiceInstances.length}个)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            if (_nacosServiceInstances.isEmpty)
              const Text(
                '暂无实例',
                style: TextStyle(color: Colors.gray, fontSize: 12),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: _nacosServiceInstances.map<Widget>((instance) {
                      final ip = instance['ip'] ?? '-';
                      final port = instance['port'] ?? '-';
                      final healthy = instance['healthy'] ?? false;
                      final weight = instance['weight'] ?? 1.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: healthy
                                  ? Colors.green.shade200
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.dns,
                                size: 16,
                                color: healthy
                                    ? Colors.green.shade600
                                    : Colors.red.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$ip:$port',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '权重: $weight | 健康: ${healthy ? "是" : "否"}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: healthy
                                            ? Colors.green.shade600
                                            : Colors.red.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 显示 Nacos 服务关联 Drawer
  void _showNacosServiceMappingDrawer() {
    openDrawerOverlay(
      context: context,
      position: OverlayPosition.right,
      builder: (context) => NacosServiceMappingDrawerContent(
        deployment: widget.deployment,
        namespace: widget.namespace,
        existingMapping: _existingServiceMapping,
        onSave: (nacosNamespace, nacosServiceName, nacosGroupName) async {
          final response = await ApiService.saveK8sNacosServiceMapping(
            k8sNamespace: widget.namespace,
            k8sDeployment: widget.deployment,
            nacosNamespace: nacosNamespace,
            nacosServiceName: nacosServiceName,
            nacosGroupName: nacosGroupName,
          );
          if (response['code'] == 200) {
            setState(() {
              _existingServiceMapping =
                  response['data'] as Map<String, dynamic>;
            });
            // 加载服务实例
            await _loadNacosServiceInstances(
              nacosNamespace,
              nacosServiceName,
              nacosGroupName,
            );
          }
          return response;
        },
      ),
    );
  }

  Widget _buildServiceTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('名称')),
          DataColumn(label: Text('类型')),
          DataColumn(label: Text('Cluster IP')),
          DataColumn(label: Text('端口')),
          DataColumn(label: Text('Selector')),
        ],
        rows: _matchedServices.map((service) {
          final ports = service['ports'] as List<dynamic>? ?? [];
          final selector = service['selector'] as Map<String, dynamic>? ?? {};

          return DataRow(
            cells: [
              DataCell(Text(service['name'] ?? '-')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getServiceTypeColor(service['type']),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    service['type'] ?? '-',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
              DataCell(Text(service['clusterIP'] ?? '-')),
              DataCell(
                ports.isEmpty
                    ? const Text('-')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: ports.map((port) {
                          return Text(
                            '${port['port']}:${port['targetPort']}',
                            style: const TextStyle(fontSize: 12),
                          );
                        }).toList(),
                      ),
              ),
              DataCell(
                selector.isEmpty
                    ? const Text('-')
                    : Wrap(
                        spacing: 4,
                        children: selector.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.gray.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${e.key}=${e.value}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getServiceTypeColor(String? type) {
    switch (type) {
      case 'ClusterIP':
        return Colors.blue;
      case 'NodePort':
        return Colors.green;
      case 'LoadBalancer':
        return Colors.orange;
      case 'ExternalName':
        return Colors.purple;
      default:
        return Colors.gray;
    }
  }

  Widget _buildContainerCard(int index, Map<String, dynamic> container) {
    final resources = container['resources'] as Map<String, dynamic>? ?? {};
    final requests = resources['requests'] as Map<String, dynamic>? ?? {};
    final limits = resources['limits'] as Map<String, dynamic>? ?? {};
    final ports = container['ports'] as List<dynamic>? ?? [];
    final env = container['env'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) const Divider(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.gray.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.gray.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container 名称
              Row(
                children: [
                  const Icon(Icons.memory, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    container['name'] ?? 'Container ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Image
              _buildInfoRow('Image', container['image'] ?? '-'),
              // Command
              if (container['command'] != null)
                _buildInfoRow(
                  'Command',
                  (container['command'] as List).join(' '),
                ),
              // Args
              if (container['args'] != null)
                _buildInfoRow('Args', (container['args'] as List).join(' ')),
              const SizedBox(height: 12),
              // Resources
              if (requests.isNotEmpty || limits.isNotEmpty)
                const Text(
                  'Resources:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              if (requests.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Requests:',
                        style: TextStyle(fontSize: 12, color: Colors.gray),
                      ),
                      ...requests.entries.map(
                        (e) => Text('  ${e.key}: ${e.value}'),
                      ),
                    ],
                  ),
                ),
              if (limits.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Limits:',
                        style: TextStyle(fontSize: 12, color: Colors.gray),
                      ),
                      ...limits.entries.map(
                        (e) => Text('  ${e.key}: ${e.value}'),
                      ),
                    ],
                  ),
                ),
              // Ports
              if (ports.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Ports:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ports.map((port) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        '${port['containerPort']}/${port['protocol'] ?? 'TCP'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              // Environment Variables
              if (env.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Environment Variables:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                ...env.take(5).map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 2),
                    child: Text(
                      '${e['name']}: ${e['value'] ?? '***'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
                if (env.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      '... and ${env.length - 5} more',
                      style: const TextStyle(fontSize: 12, color: Colors.gray),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.gray),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // 构建已关联的 Nacos 配置摘要
  Widget _buildLinkedConfigSummary() {
    final dataId = _linkedNacosConfig!['dataId'] ?? '未知';
    final group = _linkedNacosConfig!['group'] ?? '未知';
    final content = _linkedNacosConfig!['content'] ?? '';
    final namespaceId = _linkedNacosConfig!['tenant'] ?? '';
    final namespaceName =
        _nacosNamespaces.firstWhere(
          (ns) => ns['namespace'] == namespaceId,
          orElse: () => {'namespaceShowName': namespaceId},
        )['namespaceShowName'] ??
        namespaceId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  '已关联的 Nacos 配置',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Data ID', dataId),
            _buildInfoRow('Group', group),
            _buildInfoRow('Namespace', namespaceName),
            const SizedBox(height: 12),
            // 配置内容
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code, size: 14, color: Colors.green.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '配置内容',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        content.isEmpty ? '（空配置）' : content,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: content.isEmpty
                              ? Colors.gray.shade400
                              : Colors.gray.shade900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 显示 Nacos 关联配置 Drawer
  void _showNacosMappingDrawer() {
    // 重置选择状态
    setState(() {
      _selectedNacosNamespace = null;
      _selectedNacosConfigId = null;
    });

    openDrawerOverlay(
      context: context,
      position: OverlayPosition.right,
      builder: (context) => NacosMappingDrawerContent(
        deployment: widget.deployment,
        namespace: widget.namespace,
        onSave: (nacosNamespace, nacosConfigId) async {
          final response = await ApiService.saveK8sNacosMapping(
            k8sNamespace: widget.namespace,
            k8sDeployment: widget.deployment,
            nacosNamespace: nacosNamespace,
            nacosConfigId: nacosConfigId,
          );
          if (response['code'] == 200) {
            setState(() {
              _existingMapping = response['data'] as Map<String, dynamic>;
            });
            // 重新加载关联的配置详情
            await _loadLinkedNacosConfig(nacosNamespace, nacosConfigId);
          }
          return response;
        },
      ),
    );
  }
}

// Nacos 配置关联 Drawer 内容组件
class NacosMappingDrawerContent extends StatefulWidget {
  final String deployment;
  final String namespace;
  final Future<Map<String, dynamic>> Function(
    String nacosNamespace,
    String nacosConfigId,
  )?
  onSave;

  const NacosMappingDrawerContent({
    super.key,
    required this.deployment,
    required this.namespace,
    this.onSave,
  });

  @override
  State<NacosMappingDrawerContent> createState() =>
      _NacosMappingDrawerContentState();
}

class _NacosMappingDrawerContentState extends State<NacosMappingDrawerContent> {
  List<dynamic> _nacosNamespaces = [];
  bool _isLoadingNacosNamespaces = true;
  final Map<String, List<dynamic>> _nacosConfigs = {};
  final Map<String, bool> _isLoadingNacosConfigs = {};
  String? _selectedNacosNamespace;
  String? _selectedNacosConfigId;
  bool _isSavingMapping = false;

  // 显示 Toast 提示
  void _showToast(String message, {bool isError = false}) {
    showToast(
      context: context,
      builder: (context, overlay) => Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error : Icons.info,
                color: isError ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 12),
              Text(message),
              const SizedBox(width: 8),
              IconButton.ghost(
                onPressed: overlay.close,
                icon: const Icon(Icons.close, size: 16),
              ),
            ],
          ),
        ),
      ),
      location: ToastLocation.topRight,
      showDuration: const Duration(seconds: 3),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadNacosNamespaces();
  }

  Future<void> _loadNacosNamespaces() async {
    setState(() {
      _isLoadingNacosNamespaces = true;
    });

    // 先调用 Nacos 登录
    final loginResponse = await ApiService.nacosLogin();
    if (loginResponse['code'] != 200) {
      setState(() {
        _isLoadingNacosNamespaces = false;
      });
      if (mounted) {
        _showToast('Nacos 登录失败: ${loginResponse['message']}', isError: true);
      }
      return;
    }

    final response = await ApiService.getNacosNamespaces();

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      if (data is List<dynamic>) {
        setState(() {
          _nacosNamespaces = data;
          _isLoadingNacosNamespaces = false;
        });
      } else {
        setState(() {
          _nacosNamespaces = [];
          _isLoadingNacosNamespaces = false;
        });
      }
    } else {
      setState(() {
        _isLoadingNacosNamespaces = false;
      });
      if (mounted && response['code'] != 200) {
        _showToast(
          '获取 Nacos Namespaces 失败: ${response['message']}',
          isError: true,
        );
      }
    }
  }

  Future<void> _loadNacosConfigs(String namespaceId) async {
    if (_nacosConfigs.containsKey(namespaceId)) return;

    setState(() {
      _isLoadingNacosConfigs[namespaceId] = true;
    });

    final response = await ApiService.getNacosConfigs(namespaceId);

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      setState(() {
        _nacosConfigs[namespaceId] = data['pageItems'] as List<dynamic>? ?? [];
        _isLoadingNacosConfigs[namespaceId] = false;
      });
    } else {
      setState(() {
        _nacosConfigs[namespaceId] = [];
        _isLoadingNacosConfigs[namespaceId] = false;
      });
    }
  }

  Future<void> _saveMapping() async {
    if (_selectedNacosNamespace == null || _selectedNacosConfigId == null) {
      return;
    }

    setState(() {
      _isSavingMapping = true;
    });

    Map<String, dynamic> response;
    if (widget.onSave != null) {
      response = await widget.onSave!(
        _selectedNacosNamespace!,
        _selectedNacosConfigId!,
      );
    } else {
      response = {'code': 500, 'message': '未配置保存回调'};
    }

    setState(() {
      _isSavingMapping = false;
    });

    if (response['code'] == 200) {
      if (mounted) {
        _showToast('关联关系保存成功');
        closeOverlay(context);
      }
    } else {
      if (mounted) {
        _showToast('保存失败: ${response['message']}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawer 标题
          Row(
            children: [
              const Text(
                '关联 Nacos 配置',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton.ghost(
                onPressed: () => closeOverlay(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),

          // 当前 Deployment 信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deployment: ${widget.deployment}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Namespace: ${widget.namespace}',
                    style: TextStyle(fontSize: 12, color: Colors.gray.shade500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 选择 Namespace
          const Text(
            '选择 Nacos Namespace',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_isLoadingNacosNamespaces)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_nacosNamespaces.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '暂无 Nacos Namespace 数据',
                  style: TextStyle(color: Colors.gray),
                ),
              ),
            )
          else
            Select<String>(
              value: _selectedNacosNamespace,
              onChanged: (value) {
                setState(() {
                  _selectedNacosNamespace = value;
                  _selectedNacosConfigId = null;
                });
                if (value != null) {
                  _loadNacosConfigs(value);
                }
              },
              placeholder: const Text('请选择 Namespace'),
              itemBuilder: (context, value) => Text(
                _nacosNamespaces.firstWhere(
                      (ns) => ns['namespace'] == value,
                      orElse: () => {'namespaceShowName': '未知'},
                    )['namespaceShowName'] ??
                    '未知',
              ),
              popup: (context) => SelectPopup(
                items: SelectItemList(
                  children: _nacosNamespaces.map<Widget>((ns) {
                    final namespaceShowName = ns['namespaceShowName'] ?? '未知';
                    final namespace = ns['namespace'] ?? '';
                    return SelectItemButton<String>(
                      value: namespace,
                      child: Text(namespaceShowName),
                    );
                  }).toList(),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // 选择 Config
          if (_selectedNacosNamespace != null) ...[
            const Text(
              '选择 Nacos 配置',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_isLoadingNacosConfigs[_selectedNacosNamespace] == true)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_nacosConfigs[_selectedNacosNamespace]?.isEmpty ?? true)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '该 Namespace 下暂无配置',
                    style: TextStyle(color: Colors.gray),
                  ),
                ),
              )
            else
              Expanded(
                child: Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount:
                        _nacosConfigs[_selectedNacosNamespace]?.length ?? 0,
                    itemBuilder: (context, index) {
                      final config =
                          _nacosConfigs[_selectedNacosNamespace]![index];
                      final dataId = config['dataId'] ?? '未知';
                      final group = config['group'] ?? '未知';
                      final configId = config['id']?.toString() ?? '';
                      final isSelected = _selectedNacosConfigId == configId;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedNacosConfigId = configId;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: isSelected ? Colors.blue.shade50 : null,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dataId),
                                    Text(
                                      'Group: $group',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.gray.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade600,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],

          const Divider(),
          const SizedBox(height: 16),

          // 底部按钮
          Row(
            children: [
              SecondaryButton(
                onPressed: () => closeOverlay(context),
                child: const Text('取消'),
              ),
              const Spacer(),
              PrimaryButton(
                onPressed: _selectedNacosConfigId == null || _isSavingMapping
                    ? null
                    : _saveMapping,
                child: _isSavingMapping
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存关联'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Nacos 服务关联 Drawer 内容组件
class NacosServiceMappingDrawerContent extends StatefulWidget {
  final String deployment;
  final String namespace;
  final Map<String, dynamic>? existingMapping;
  final Future<Map<String, dynamic>> Function(
    String nacosNamespace,
    String nacosServiceName,
    String? nacosGroupName,
  )?
  onSave;

  const NacosServiceMappingDrawerContent({
    super.key,
    required this.deployment,
    required this.namespace,
    this.existingMapping,
    this.onSave,
  });

  @override
  State<NacosServiceMappingDrawerContent> createState() =>
      _NacosServiceMappingDrawerContentState();
}

class _NacosServiceMappingDrawerContentState
    extends State<NacosServiceMappingDrawerContent> {
  List<dynamic> _nacosNamespaces = [];
  bool _isLoadingNacosNamespaces = true;
  List<dynamic> _nacosServices = [];
  bool _isLoadingNacosServices = false;
  String? _selectedNacosNamespace;
  String? _selectedNacosServiceName;
  bool _isSavingMapping = false;

  // 显示 Toast 提示
  void _showToast(String message, {bool isError = false}) {
    showToast(
      context: context,
      builder: (context, overlay) => Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error : Icons.info,
                color: isError ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 12),
              Text(message),
              const SizedBox(width: 8),
              IconButton.ghost(
                onPressed: overlay.close,
                icon: const Icon(Icons.close, size: 16),
              ),
            ],
          ),
        ),
      ),
      location: ToastLocation.topRight,
      showDuration: const Duration(seconds: 3),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadNacosNamespaces();
    // 如果已有映射，设置初始值
    if (widget.existingMapping != null) {
      _selectedNacosNamespace = widget.existingMapping!['nacosNamespace'];
      _selectedNacosServiceName = widget.existingMapping!['nacosServiceName'];
    }
  }

  Future<void> _loadNacosNamespaces() async {
    setState(() {
      _isLoadingNacosNamespaces = true;
    });

    // 先调用 Nacos 登录
    final loginResponse = await ApiService.nacosLogin();
    if (loginResponse['code'] != 200) {
      setState(() {
        _isLoadingNacosNamespaces = false;
      });
      if (mounted) {
        _showToast('Nacos 登录失败: ${loginResponse['message']}', isError: true);
      }
      return;
    }

    final response = await ApiService.getNacosNamespaces();

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      if (data is List<dynamic>) {
        setState(() {
          _nacosNamespaces = data;
          _isLoadingNacosNamespaces = false;
        });
      } else {
        setState(() {
          _nacosNamespaces = [];
          _isLoadingNacosNamespaces = false;
        });
      }
    } else {
      setState(() {
        _nacosNamespaces = [];
        _isLoadingNacosNamespaces = false;
      });
      if (mounted) {
        _showToast(
          '获取 Namespace 失败: ${response['message'] ?? '未知错误'}',
          isError: true,
        );
      }
    }

    // 如果已有选中的 namespace，加载服务列表
    if (_selectedNacosNamespace != null) {
      await _loadNacosServices(_selectedNacosNamespace!);
    }
  }

  Future<void> _loadNacosServices(String namespace) async {
    setState(() {
      _isLoadingNacosServices = true;
      _nacosServices = [];
    });

    final response = await ApiService.getNacosServices(namespace);

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      final serviceList = data['serviceList'] as List<dynamic>? ?? [];
      setState(() {
        _nacosServices = serviceList;
        _isLoadingNacosServices = false;
      });
    } else {
      setState(() {
        _nacosServices = [];
        _isLoadingNacosServices = false;
      });
      if (mounted) {
        _showToast('获取服务列表失败: ${response['message'] ?? '未知错误'}', isError: true);
      }
    }
  }

  Future<void> _saveMapping() async {
    if (_selectedNacosNamespace == null || _selectedNacosServiceName == null) {
      return;
    }

    setState(() {
      _isSavingMapping = true;
    });

    try {
      if (widget.onSave != null) {
        final response = await widget.onSave!(
          _selectedNacosNamespace!,
          _selectedNacosServiceName!,
          'DEFAULT_GROUP',
        );

        if (response['code'] == 200) {
          if (mounted) {
            closeOverlay(context);
            _showToast('关联保存成功');
          }
        } else {
          if (mounted) {
            _showToast('保存失败: ${response['message'] ?? '未知错误'}', isError: true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showToast('保存失败: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingMapping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(Icons.cloud, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '关联 Nacos 服务',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              GhostButton(
                onPressed: () => closeOverlay(context),
                child: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),

          // 显示当前 Deployment 信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deployment: ${widget.deployment}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Namespace: ${widget.namespace}',
                    style: TextStyle(fontSize: 12, color: Colors.gray.shade500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 选择 Namespace
          const Text(
            '选择 Nacos Namespace',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_isLoadingNacosNamespaces)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_nacosNamespaces.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '暂无 Nacos Namespace 数据',
                  style: TextStyle(color: Colors.gray),
                ),
              ),
            )
          else
            Select<String>(
              value: _selectedNacosNamespace,
              onChanged: (value) {
                setState(() {
                  _selectedNacosNamespace = value;
                  _selectedNacosServiceName = null;
                });
                if (value != null) {
                  _loadNacosServices(value);
                }
              },
              placeholder: const Text('请选择 Namespace'),
              itemBuilder: (context, value) => Text(
                _nacosNamespaces.firstWhere(
                      (ns) => ns['namespace'] == value,
                      orElse: () => {'namespaceShowName': '未知'},
                    )['namespaceShowName'] ??
                    '未知',
              ),
              popup: (context) => SelectPopup(
                items: SelectItemList(
                  children: _nacosNamespaces.map<Widget>((ns) {
                    final namespaceShowName = ns['namespaceShowName'] ?? '未知';
                    final namespace = ns['namespace'] ?? '';
                    return SelectItemButton<String>(
                      value: namespace,
                      child: Text(namespaceShowName),
                    );
                  }).toList(),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // 选择 Service
          if (_selectedNacosNamespace != null) ...[
            const Text(
              '选择 Nacos 服务',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_isLoadingNacosServices)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_nacosServices.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '该 Namespace 下暂无服务',
                    style: TextStyle(color: Colors.gray),
                  ),
                ),
              )
            else
              Expanded(
                child: Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _nacosServices.length,
                    itemBuilder: (context, index) {
                      final service = _nacosServices[index];
                      final name = service['name'] ?? '未知';
                      final groupName = service['groupName'] ?? 'DEFAULT_GROUP';
                      final ipCount = service['ipCount'] ?? 0;
                      final healthyCount = service['healthyInstanceCount'] ?? 0;
                      final isSelected = _selectedNacosServiceName == name;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedNacosServiceName = name;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: isSelected ? Colors.blue.shade50 : null,
                          child: Row(
                            children: [
                              Icon(
                                Icons.dns,
                                color: isSelected ? Colors.blue : Colors.gray,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name),
                                    Text(
                                      'Group: $groupName',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.gray.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$healthyCount/$ipCount',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade600,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],

          const Divider(),
          const SizedBox(height: 16),

          // 底部按钮
          Row(
            children: [
              SecondaryButton(
                onPressed: () => closeOverlay(context),
                child: const Text('取消'),
              ),
              const Spacer(),
              PrimaryButton(
                onPressed: _selectedNacosServiceName == null || _isSavingMapping
                    ? null
                    : _saveMapping,
                child: _isSavingMapping
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存关联'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
