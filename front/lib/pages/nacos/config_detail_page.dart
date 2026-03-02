import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../services/api_service.dart';

class NacosConfigDetailPage extends StatefulWidget {
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
  State<NacosConfigDetailPage> createState() => _NacosConfigDetailPageState();
}

class _NacosConfigDetailPageState extends State<NacosConfigDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  String _configContent = '';

  @override
  void initState() {
    super.initState();
    _loadConfigDetail();
  }

  Future<void> _loadConfigDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiService.getNacosConfigDetail(
      namespaceId: widget.namespaceId,
      dataId: widget.dataId,
      group: widget.group,
    );

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      setState(() {
        _configContent = data['content'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response['message'] ?? '获取配置详情失败';
        _isLoading = false;
      });
    }
  }

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
                        widget.dataId,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Group: ${widget.group} | Namespace: ${widget.namespaceId}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.gray.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                SecondaryButton(
                  onPressed: _loadConfigDetail,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 16),
                      SizedBox(width: 4),
                      Text('刷新'),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            // 配置内容区域
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载配置内容...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              onPressed: _loadConfigDetail,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_configContent.isEmpty) {
      return Center(
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
              '配置内容为空',
              style: TextStyle(
                fontSize: 18,
                color: Colors.gray.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // 显示配置内容
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.gray.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.gray.shade200),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          _configContent,
          style: const TextStyle(
            fontFamily: 'Consolas',
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
