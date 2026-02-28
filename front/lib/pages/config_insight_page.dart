import 'package:shadcn_flutter/shadcn_flutter.dart';

class ConfigInsightPage extends StatefulWidget {
  const ConfigInsightPage({super.key});

  @override
  State<ConfigInsightPage> createState() => _ConfigInsightPageState();
}

class _ConfigInsightPageState extends State<ConfigInsightPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.lightbulb, size: 64, color: Colors.gray.shade400),
            const SizedBox(height: 16),
            Text(
              '配置洞察',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.gray.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '功能开发中...',
              style: TextStyle(fontSize: 14, color: Colors.gray.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
