import 'package:shadcn_flutter/shadcn_flutter.dart';

class InspectionPage extends StatefulWidget {
  const InspectionPage({super.key});

  @override
  State<InspectionPage> createState() => _InspectionPageState();
}

class _InspectionPageState extends State<InspectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.clipboardCheck,
              size: 64,
              color: Colors.gray.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '自动巡检',
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
