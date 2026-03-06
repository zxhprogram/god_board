import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'deployment_state.dart';

/// Nacos 配置关联卡片
class NacosConfigCard extends StatelessWidget {
  final DeploymentState state;
  final VoidCallback onAssociate;

  const NacosConfigCard({
    super.key,
    required this.state,
    required this.onAssociate,
  });

  @override
  Widget build(BuildContext context) {
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
                  'Nacos 配置关联',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (state.isLoadingMapping)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (state.existingMapping != null)
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
            if (state.linkedNacosConfig != null) ...[
              _buildLinkedConfigSummary(),
              const SizedBox(height: 16),
            ],
            PrimaryButton(
              onPressed: onAssociate,
              child: Text(
                state.existingMapping != null ? '重新关联配置' : '关联 Nacos 配置',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedConfigSummary() {
    final config = state.linkedNacosConfig!;
    final namespace = config['namespace'] ?? '';
    final namespaceName =
        state.nacosNamespaces.firstWhere(
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
                Icon(Icons.settings, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  '已关联的 Nacos 配置',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Data ID', config['dataId'] ?? '-'),
            _buildInfoRow('Group', config['group'] ?? '-'),
            _buildInfoRow('Namespace', namespaceName),
            // 显示配置内容
            if (state.isLoadingConfigContent)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '加载配置内容...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.gray.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else if (state.linkedNacosConfigContent != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.gray.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.gray.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.code, size: 14, color: Colors.gray.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '配置内容',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.gray.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      state.linkedNacosConfigContent!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.gray.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.gray.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nacos 服务关联卡片
class NacosServiceCard extends StatelessWidget {
  final DeploymentState state;
  final VoidCallback onAssociate;

  const NacosServiceCard({
    super.key,
    required this.state,
    required this.onAssociate,
  });

  @override
  Widget build(BuildContext context) {
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
                  'Nacos 服务关联',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (state.isLoadingServiceMapping)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (state.existingServiceMapping != null)
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
            if (state.linkedNacosService != null) ...[
              _buildLinkedServiceSummary(),
              const SizedBox(height: 16),
            ],
            PrimaryButton(
              onPressed: onAssociate,
              child: Text(
                state.existingServiceMapping != null ? '重新关联服务' : '关联 Nacos 服务',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedServiceSummary() {
    final service = state.linkedNacosService!;
    final serviceName = service['serviceName'] ?? '未知';
    final groupName = service['groupName'] ?? 'DEFAULT_GROUP';
    final namespace = service['namespace'] ?? '';
    final namespaceName =
        state.nacosNamespaces.firstWhere(
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
            Text(
              '服务实例 (${state.nacosServiceInstances.length}个)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            if (state.nacosServiceInstances.isEmpty)
              const Text(
                '暂无实例',
                style: TextStyle(color: Colors.gray, fontSize: 12),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: state.nacosServiceInstances.map<Widget>((
                      instance,
                    ) {
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
                                        color: Colors.gray.shade600,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.gray.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
