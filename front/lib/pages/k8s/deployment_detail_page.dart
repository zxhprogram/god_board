import 'package:flutter/material.dart'
    show
        ElevatedButton,
        DataTable,
        DataColumn,
        DataRow,
        DataCell,
        ScaffoldMessenger,
        SnackBar,
        ListTile,
        Scaffold,
        ListView;
import 'package:shadcn_flutter/shadcn_flutter.dart'
    hide Scaffold, ListTile, ListView;

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

  // Nacos 关联相关状态
  List<dynamic> _nacosNamespaces = [];
  bool _isLoadingNacosNamespaces = false;
  final Map<String, List<dynamic>> _nacosConfigs = {};
  final Map<String, bool> _isLoadingNacosConfigs = {};
  String? _selectedNacosNamespace;
  String? _selectedNacosConfigId;
  Map<String, dynamic>? _existingMapping;
  Map<String, dynamic>? _linkedNacosConfig; // 已关联的 Nacos 配置详情
  bool _isLoadingMapping = true;
  bool _isSavingMapping = false;

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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isLoadingServices = true;
      _isLoadingMapping = true;
      _matchedServices = [];
      _deploymentData = null;
      _existingMapping = null;
      _linkedNacosConfig = null;
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

  // 加载 Nacos namespaces
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nacos 登录失败: ${loginResponse['message']}')),
        );
      }
      return;
    }

    final response = await ApiService.getNacosNamespaces();

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      // 确保 data 是 Map 类型
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取 Nacos Namespaces 失败: ${response['message']}'),
          ),
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

  // 保存关联关系
  Future<void> _saveMapping() async {
    if (_selectedNacosNamespace == null || _selectedNacosConfigId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择 Nacos Namespace 和 Config')),
      );
      return;
    }

    setState(() {
      _isSavingMapping = true;
    });

    final response = await ApiService.saveK8sNacosMapping(
      k8sNamespace: widget.namespace,
      k8sDeployment: widget.deployment,
      nacosNamespace: _selectedNacosNamespace!,
      nacosConfigId: _selectedNacosConfigId!,
    );

    setState(() {
      _isSavingMapping = false;
    });

    if (response['code'] == 200) {
      setState(() {
        _existingMapping = response['data'] as Map<String, dynamic>;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('关联关系保存成功')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: ${response['message']}')));
      }
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
    return Scaffold(body: _buildBody());
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
            ElevatedButton(onPressed: _loadData, child: const Text('重试')),
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
                ],
              ),
            ),
          ),
        ],
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

  // 构建 Nacos TreeView
  Widget _buildNacosTreeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择 Nacos 配置:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.gray.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: _nacosNamespaces.map((ns) {
              final namespaceId = ns['namespace'] ?? '';
              final namespaceName =
                  ns['namespaceShowName'] ?? ns['namespace'] ?? '未知 Namespace';
              final isExpanded = _nacosConfigs.containsKey(namespaceId);
              final isLoading = _isLoadingNacosConfigs[namespaceId] ?? false;
              final isSelected = _selectedNacosNamespace == namespaceId;

              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      isExpanded ? Icons.folder_open : Icons.folder,
                      color: isSelected ? Colors.blue : Colors.orange,
                    ),
                    title: Text(
                      namespaceName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : null,
                        color: isSelected ? Colors.blue : null,
                      ),
                    ),
                    trailing: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                          ),
                    onTap: () {
                      if (isExpanded) {
                        // 折叠
                        setState(() {
                          _nacosConfigs.remove(namespaceId);
                          if (_selectedNacosNamespace == namespaceId) {
                            _selectedNacosNamespace = null;
                            _selectedNacosConfigId = null;
                          }
                        });
                      } else {
                        // 展开并加载 configs
                        setState(() {
                          _selectedNacosNamespace = namespaceId;
                        });
                        _loadNacosConfigs(namespaceId);
                      }
                    },
                  ),
                  // 子节点 - Configs
                  if (isExpanded && _nacosConfigs.containsKey(namespaceId))
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Column(
                        children: _nacosConfigs[namespaceId]!.map((config) {
                          final configId = config['id']?.toString() ?? '';
                          final configDataId = config['dataId'] ?? '';
                          final configGroup = config['group'] ?? '';
                          final isConfigSelected =
                              _selectedNacosConfigId == configId;

                          return ListTile(
                            leading: Icon(
                              Icons.description,
                              color: isConfigSelected
                                  ? Colors.blue
                                  : Colors.gray,
                            ),
                            title: Text(
                              configDataId,
                              style: TextStyle(
                                fontWeight: isConfigSelected
                                    ? FontWeight.bold
                                    : null,
                                color: isConfigSelected ? Colors.blue : null,
                              ),
                            ),
                            subtitle: Text('Group: $configGroup'),
                            trailing: isConfigSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade700,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedNacosConfigId = configId;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        if (_selectedNacosConfigId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '已选择: ${_nacosConfigs[_selectedNacosNamespace]?.firstWhere((c) => c['id']?.toString() == _selectedNacosConfigId, orElse: () => {'dataId': '未知'})['dataId'] ?? '未知'}',
              style: TextStyle(fontSize: 12, color: Colors.green.shade700),
            ),
          ),
      ],
    );
  }

  // 构建已关联的 Nacos 配置摘要
  Widget _buildLinkedConfigSummary() {
    final dataId = _linkedNacosConfig!['dataId'] ?? '未知';
    final group = _linkedNacosConfig!['group'] ?? '未知';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nacos 登录失败: ${loginResponse['message']}')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取 Nacos Namespaces 失败: ${response['message']}'),
          ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('关联关系保存成功')));
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: ${response['message']}')));
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
                onPressed: () => Navigator.of(context).pop(),
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

                      return ListTile(
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedNacosConfigId = configId;
                          });
                        },
                        title: Text(dataId),
                        subtitle: Text('Group: $group'),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Colors.green.shade600,
                              )
                            : null,
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
                onPressed: () => Navigator.of(context).pop(),
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
