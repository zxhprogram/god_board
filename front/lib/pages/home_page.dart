import 'package:shadcn_flutter/shadcn_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard, size: 64, color: Colors.gray),
          SizedBox(height: 16),
          Text(
            'God Board',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '点击左侧菜单切换页面',
            style: TextStyle(fontSize: 16, color: Colors.gray),
          ),
        ],
      ),
    );
  }
}
