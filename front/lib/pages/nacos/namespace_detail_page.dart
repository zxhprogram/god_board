import 'package:shadcn_flutter/shadcn_flutter.dart';

class NacosNamespaceDetailPage extends StatelessWidget {
  final String namespaceId;

  const NacosNamespaceDetailPage({super.key, required this.namespaceId});

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
                const Icon(BootstrapIcons.folder, size: 32, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Namespace',
                        style: TextStyle(fontSize: 14, color: Colors.gray),
                      ),
                      Text(
                        namespaceId,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
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
                      BootstrapIcons.folder,
                      size: 64,
                      color: Colors.gray.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Namespace 详情页面',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.gray.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Namespace ID: $namespaceId',
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
