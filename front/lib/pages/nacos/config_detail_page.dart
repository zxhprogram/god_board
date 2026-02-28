import 'package:shadcn_flutter/shadcn_flutter.dart';

class NacosConfigDetailPage extends StatelessWidget {
  final String namespaceId;
  final String group;
  final String dataId;

  const NacosConfigDetailPage({
    super.key,
    required this.namespaceId,
    required this.group,
    required this.dataId,
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
                const Icon(BootstrapIcons.fileText, size: 32, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '配置详情',
                        style: TextStyle(fontSize: 14, color: Colors.gray),
                      ),
                      Text(
                        dataId,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Group: $group | Namespace: $namespaceId',
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
                      BootstrapIcons.fileText,
                      size: 64,
                      color: Colors.gray.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '配置详情页面',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.gray.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '双击配置项查看服务列表',
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
