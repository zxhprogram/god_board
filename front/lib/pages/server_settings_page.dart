import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../services/api_service.dart';

class ServerSettingsPage extends StatefulWidget {
  const ServerSettingsPage({super.key});

  @override
  State<ServerSettingsPage> createState() => _ServerSettingsPageState();
}

class _ServerSettingsPageState extends State<ServerSettingsPage> {
  // K8s 配置
  final TextEditingController _k8sAddressController = TextEditingController();
  final TextEditingController _k8sUsernameController = TextEditingController();
  final TextEditingController _k8sPasswordController = TextEditingController();

  // Nacos 配置
  final TextEditingController _nacosAddressController = TextEditingController();
  final TextEditingController _nacosUsernameController =
      TextEditingController();
  final TextEditingController _nacosPasswordController =
      TextEditingController();

  // NodeServer 配置
  final TextEditingController _nodeServerAddressController =
      TextEditingController();

  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  @override
  void dispose() {
    _k8sAddressController.dispose();
    _k8sUsernameController.dispose();
    _k8sPasswordController.dispose();
    _nacosAddressController.dispose();
    _nacosUsernameController.dispose();
    _nacosPasswordController.dispose();
    _nodeServerAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadConfigs() async {
    setState(() {
      _isLoading = true;
    });

    final response = await ApiService.getServerConfigs();

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      final k8sConfig = data['k8s'];
      final nacosConfig = data['nacos'];
      final nodeServerConfig = data['nodeServer'];

      setState(() {
        _k8sAddressController.text = k8sConfig?['address'] ?? '';
        _k8sUsernameController.text = k8sConfig?['username'] ?? '';
        _k8sPasswordController.text = k8sConfig?['password'] ?? '';
        _nacosAddressController.text = nacosConfig?['address'] ?? '';
        _nacosUsernameController.text = nacosConfig?['username'] ?? '';
        _nacosPasswordController.text = nacosConfig?['password'] ?? '';
        _nodeServerAddressController.text = nodeServerConfig?['address'] ?? '';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    // 保存 K8s 配置
    final k8sResponse = await ApiService.saveK8sConfig(
      address: _k8sAddressController.text,
      username: _k8sUsernameController.text,
      password: _k8sPasswordController.text,
    );

    // 保存 Nacos 配置
    final nacosResponse = await ApiService.saveNacosConfig(
      address: _nacosAddressController.text,
      username: _nacosUsernameController.text,
      password: _nacosPasswordController.text,
    );

    // 保存 NodeServer 配置
    final nodeServerResponse = await ApiService.saveNodeServerConfig(
      address: _nodeServerAddressController.text,
    );

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (k8sResponse['code'] == 200 &&
          nacosResponse['code'] == 200 &&
          nodeServerResponse['code'] == 200) {
        showToast(
          context: context,
          builder: (context, overlay) {
            return SurfaceCard(
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('服务器配置已保存'),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        showToast(
          context: context,
          builder: (context, overlay) {
            return SurfaceCard(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      k8sResponse['code'] != 200
                          ? k8sResponse['message'] ?? '保存失败'
                          : nacosResponse['code'] != 200
                          ? nacosResponse['message'] ?? '保存失败'
                          : nodeServerResponse['message'] ?? '保存失败',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    }
  }

  void _testK8sConnection() {
    showToast(
      context: context,
      builder: (context, overlay) {
        return SurfaceCard(
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text('正在测试 K8s 连接...'),
              ],
            ),
          ),
        );
      },
    );
    // TODO: 实现 K8s 连接测试
  }

  void _testNacosConnection() {
    showToast(
      context: context,
      builder: (context, overlay) {
        return SurfaceCard(
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text('正在测试 Nacos 连接...'),
              ],
            ),
          ),
        );
      },
    );
    // TODO: 实现 Nacos 连接测试
  }

  void _testNodeServerConnection() {
    showToast(
      context: context,
      builder: (context, overlay) {
        return SurfaceCard(
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text('正在测试 NodeServer 连接...'),
              ],
            ),
          ),
        );
      },
    );
    // TODO: 实现 NodeServer 连接测试
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 页面标题
          const Text(
            '服务器设置',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '配置 K8s、Nacos 和 NodeServer 服务器连接信息',
            style: TextStyle(fontSize: 14, color: Colors.gray),
          ),
          const SizedBox(height: 32),

          // K8s 配置卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud, size: 24, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Text(
                        'K8s 配置',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Button(
                        style: const ButtonStyle.primary(),
                        onPressed: _testK8sConnection,
                        child: const Text('测试连接'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _k8sAddressController,
                    placeholder: const Text('请输入 K8s API Server 地址'),
                  ),
                  const SizedBox(height: 8),
                  const Text('K8s 地址').small.muted,
                  const SizedBox(height: 16),
                  TextField(
                    controller: _k8sUsernameController,
                    placeholder: const Text('请输入 K8s 用户名'),
                  ),
                  const SizedBox(height: 8),
                  const Text('K8s 账号').small.muted,
                  const SizedBox(height: 16),
                  TextField(
                    controller: _k8sPasswordController,
                    placeholder: const Text('请输入 K8s 密码'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  const Text('K8s 密码').small.muted,
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Nacos 配置卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dns, size: 24, color: Colors.green),
                      const SizedBox(width: 12),
                      const Text(
                        'Nacos 配置',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Button(
                        style: const ButtonStyle.primary(),
                        onPressed: _testNacosConnection,
                        child: const Text('测试连接'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nacosAddressController,
                    placeholder: const Text('请输入 Nacos 服务器地址'),
                  ),
                  const SizedBox(height: 8),
                  const Text('Nacos 地址').small.muted,
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nacosUsernameController,
                    placeholder: const Text('请输入 Nacos 用户名'),
                  ),
                  const SizedBox(height: 8),
                  const Text('Nacos 账号').small.muted,
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nacosPasswordController,
                    placeholder: const Text('请输入 Nacos 密码'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  const Text('Nacos 密码').small.muted,
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // NodeServer 配置卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.computer,
                        size: 24,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'NodeServer 配置',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Button(
                        style: const ButtonStyle.primary(),
                        onPressed: _testNodeServerConnection,
                        child: const Text('测试连接'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nodeServerAddressController,
                    placeholder: const Text('请输入 NodeServer 服务器地址'),
                  ),
                  const SizedBox(height: 8),
                  const Text('NodeServer 地址').small.muted,
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 保存按钮
          Row(
            children: [
              PrimaryButton(
                onPressed: _isSaving ? null : _saveSettings,
                child: _isSaving
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('保存中...'),
                        ],
                      )
                    : const Text('保存配置'),
              ),
              const SizedBox(width: 12),
              Button(
                style: const ButtonStyle.secondary(),
                onPressed: () {
                  // 重置表单
                  _k8sAddressController.clear();
                  _k8sUsernameController.clear();
                  _k8sPasswordController.clear();
                  _nacosAddressController.clear();
                  _nacosUsernameController.clear();
                  _nacosPasswordController.clear();
                  _nodeServerAddressController.clear();
                },
                child: const Text('重置'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
