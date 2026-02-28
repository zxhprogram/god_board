import 'package:shadcn_flutter/shadcn_flutter.dart';

class NacosServiceDetailPage extends StatelessWidget {
  final String namespaceId;
  final String group;
  final String dataId;
  final String serviceName;

  const NacosServiceDetailPage({
    super.key,
    required this.namespaceId,
    required this.group,
    required this.dataId,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面标题
            Row(
              children: [
                const Icon(BootstrapIcons.hddStack, size: 32, color: Colors.green),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '服务详情',
                        style: TextStyle(fontSize: 14, color: Colors.gray),
                      ),
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Config: $dataId | Group: $group | Namespace: $namespaceId',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.gray.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 32),
            // 占位内容
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      BootstrapIcons.hddStack,
                      size: 64,
                      color: Colors.gray.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '服务详情页面',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.gray.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '服务实例列表功能开发中...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.gray.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
