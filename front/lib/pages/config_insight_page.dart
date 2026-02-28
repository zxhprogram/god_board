import 'package:flutter/material.dart' show ListTile;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'config_insight/newland_gateway_check_page.dart';
import 'config_insight/cache_config_check_page.dart';

class ConfigInsightPage extends StatefulWidget {
  const ConfigInsightPage({super.key});

  @override
  State<ConfigInsightPage> createState() => _ConfigInsightPageState();
}

class _ConfigInsightPageState extends State<ConfigInsightPage> {
  // 当前选中的导航项
  String _selectedNavItem = 'newland';

  // 导航项配置
  final List<Map<String, dynamic>> _navItems = [
    {'id': 'newland', 'label': '新大陆网关配置检查', 'icon': LucideIcons.settings},
    {'id': 'cache', 'label': '缓存配置检查', 'icon': LucideIcons.database},
  ];

  @override
  void dispose() {
    _navItems.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧导航栏
        Container(
          width: 280,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.gray.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.lightbulb,
                      size: 24,
                      color: Colors.yellow.shade600,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '配置洞察',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // 导航菜单
              Expanded(
                child: ListView.builder(
                  itemCount: _navItems.length,
                  itemBuilder: (context, index) {
                    final item = _navItems[index];
                    final isSelected = _selectedNavItem == item['id'];

                    return ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        size: 20,
                        color: isSelected ? Colors.blue : Colors.gray,
                      ),
                      title: Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected ? Colors.blue : Colors.black,
                        ),
                      ),
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedNavItem = item['id'] as String;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // 右侧内容区域
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedNavItem) {
      case 'newland':
        return const NewlandGatewayCheckPage();
      case 'cache':
        return const CacheConfigCheckPage();
      default:
        return const Center(child: Text('请选择检查项'));
    }
  }
}
