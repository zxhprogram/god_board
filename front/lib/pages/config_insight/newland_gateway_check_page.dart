import 'package:shadcn_flutter/shadcn_flutter.dart';

class NewlandGatewayCheckPage extends StatelessWidget {
  const NewlandGatewayCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 页面标题
        const Text(
          '新大陆网关配置检查',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '检查新大陆 9894/9895 网关配置的正确性和连通性',
          style: TextStyle(fontSize: 14, color: Colors.gray),
        ),
        const SizedBox(height: 32),
        // 占位内容
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.settings,
                  size: 64,
                  color: Colors.gray.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  '功能开发中...',
                  style: TextStyle(fontSize: 18, color: Colors.gray.shade500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
