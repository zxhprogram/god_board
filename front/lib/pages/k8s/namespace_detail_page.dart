import 'package:flutter/material.dart'
    show ElevatedButton, DataTable, DataColumn, DataRow, DataCell;
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../services/api_service.dart';

class NamespaceDetailPage extends StatefulWidget {
  final String namespace;

  const NamespaceDetailPage({super.key, required this.namespace});

  @override
  State<NamespaceDetailPage> createState() => _NamespaceDetailPageState();
}

class _NamespaceDetailPageState extends State<NamespaceDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _namespaceData;
  List<dynamic> _services = [];
  bool _isLoadingServices = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(NamespaceDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 namespace 发生变化时重新加载数据
    if (oldWidget.namespace != widget.namespace) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isLoadingServices = true;
      _services = [];
    });
    await Future.wait([_loadNamespaceDetail(), _loadServices()]);
  }

  Future<void> _loadNamespaceDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 获取所有 namespace 列表，然后找到当前 namespace 的详细信息
    final response = await ApiService.getK8sNamespaces();

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      final items = data['items'] as List<dynamic>? ?? [];

      // 查找当前 namespace
      final ns = items.firstWhere(
        (item) => item['name'] == widget.namespace,
        orElse: () => null,
      );

      if (ns != null) {
        setState(() {
          _namespaceData = ns;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '未找到 namespace: ${widget.namespace}';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = response['message'] ?? '获取 namespace 详情失败';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadServices() async {
    final response = await ApiService.getK8sServices(widget.namespace);

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      setState(() {
        _services = data['items'] as List<dynamic>? ?? [];
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

    if (_namespaceData == null) {
      return const Center(child: Text('暂无数据'));
    }

    final labels = _namespaceData!['labels'] as Map<String, dynamic>? ?? {};
    final annotations =
        _namespaceData!['annotations'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              const Icon(Icons.folder_open, size: 32, color: Colors.blue),
              const SizedBox(width: 12),
              Text(
                widget.namespace,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
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
                  _namespaceData!['status'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '创建于: ${_namespaceData!['creationTimestamp'] ?? '-'}',
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
                  _buildInfoRow('名称', _namespaceData!['name'] ?? '-'),
                  _buildInfoRow('状态', _namespaceData!['status'] ?? '-'),
                  _buildInfoRow(
                    '创建时间',
                    _namespaceData!['creationTimestamp'] ?? '-',
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
                        'Services',
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
                            '${_services.length}',
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
                  else if (_services.isEmpty)
                    const Center(
                      child: Text(
                        '暂无 Service',
                        style: TextStyle(color: Colors.gray),
                      ),
                    )
                  else
                    _buildServiceTable(),
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
        rows: _services.map((service) {
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
}
