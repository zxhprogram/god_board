import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'deployment_state.dart';

/// 基本信息卡片
class BasicInfoCard extends StatelessWidget {
  final DeploymentState state;

  const BasicInfoCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final data = state.deploymentData!;

    return Card(
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
            _buildInfoRow('名称', data['name'] ?? '-'),
            _buildInfoRow('Namespace', state.namespace),
            _buildInfoRow('Replicas', '${data['replicas'] ?? 0}'),
            _buildInfoRow('Ready Replicas', '${data['readyReplicas'] ?? 0}'),
            _buildInfoRow('创建时间', data['creationTimestamp'] ?? '-'),
          ],
        ),
      ),
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
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.gray.shade600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Labels 卡片
class LabelsCard extends StatelessWidget {
  final Map<String, dynamic> labels;

  const LabelsCard({super.key, required this.labels});

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Labels',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    );
  }
}

/// Annotations 卡片
class AnnotationsCard extends StatelessWidget {
  final Map<String, dynamic> annotations;

  const AnnotationsCard({super.key, required this.annotations});

  @override
  Widget build(BuildContext context) {
    if (annotations.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Annotations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      style: const TextStyle(fontWeight: FontWeight.w500),
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
    );
  }
}

/// Services 卡片
class ServicesCard extends StatelessWidget {
  final DeploymentState state;

  const ServicesCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '关联的 Services',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (state.isLoadingServices)
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
                      '${state.matchedServices.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.isLoadingServices)
              const Center(child: Text('加载中...'))
            else if (state.matchedServices.isEmpty)
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
    );
  }

  Widget _buildServiceTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 表头
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.gray.shade100,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  '名称',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  '类型',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  'Cluster IP',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '端口',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Selector',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        // 数据行
        ...state.matchedServices.map((service) {
          final ports = service['ports'] as List<dynamic>? ?? [];
          final portStr = ports
              .map((p) => '${p['port']}/${p['protocol']}')
              .join(', ');
          final selector = service['selector'] as Map<String, dynamic>? ?? {};
          final selectorStr = selector.entries
              .map((e) => '${e.key}=${e.value}')
              .join(', ');

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.gray.shade200)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(service['name'] ?? '-')),
                Expanded(child: Text(service['type'] ?? '-')),
                Expanded(child: Text(service['clusterIP'] ?? '-')),
                Expanded(flex: 2, child: Text(portStr)),
                Expanded(flex: 2, child: Text(selectorStr)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Container 卡片
class ContainerCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> container;

  const ContainerCard({
    super.key,
    required this.index,
    required this.container,
  });

  @override
  Widget build(BuildContext context) {
    final env = container['env'] as List<dynamic>? ?? [];
    final ports = container['ports'] as List<dynamic>? ?? [];
    final volumeMounts = container['volumeMounts'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  container['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  container['image'] ?? '-',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.gray.shade600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (ports.isNotEmpty) ...[
              const Text(
                'Ports',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: ports.map((port) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${port['containerPort']}/${port['protocol']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (env.isNotEmpty) ...[
              const Text(
                'Environment Variables',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ...env.take(5).map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${e['name']}: ${e['value'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }),
              if (env.length > 5)
                Text(
                  '... 还有 ${env.length - 5} 个',
                  style: TextStyle(fontSize: 12, color: Colors.gray.shade500),
                ),
              const SizedBox(height: 12),
            ],
            if (volumeMounts.isNotEmpty) ...[
              const Text(
                'Volume Mounts',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ...volumeMounts.map((vm) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${vm['mountPath']} (${vm['name']})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
