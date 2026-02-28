import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../services/api_service.dart';

class NewlandGatewayPage extends StatefulWidget {
  const NewlandGatewayPage({super.key});

  @override
  State<NewlandGatewayPage> createState() => _NewlandGatewayPageState();
}

class _NewlandGatewayPageState extends State<NewlandGatewayPage> {
  // 9894 服务配置
  final TextEditingController _9894AddressController = TextEditingController();
  final TextEditingController _9894UsernameController = TextEditingController();
  final TextEditingController _9894PasswordController = TextEditingController();

  // 9895 服务配置
  final TextEditingController _9895AddressController = TextEditingController();
  final TextEditingController _9895UsernameController = TextEditingController();
  final TextEditingController _9895PasswordController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  @override
  void dispose() {
    _9894AddressController.dispose();
    _9894UsernameController.dispose();
    _9894PasswordController.dispose();
    _9895AddressController.dispose();
    _9895UsernameController.dispose();
    _9895PasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadConfigs() async {
    setState(() {
      _isLoading = true;
    });

    // 加载 9894 配置
    final response9894 = await ApiService.getNewland9894Config();
    if (response9894['code'] == 200 && response9894['data'] != null) {
      final data = response9894['data'];
      setState(() {
        _9894AddressController.text = data['address'] ?? '';
        _9894UsernameController.text = data['username'] ?? '';
        _9894PasswordController.text = data['password'] ?? '';
      });
    }

    // 加载 9895 配置
    final response9895 = await ApiService.getNewland9895Config();
    if (response9895['code'] == 200 && response9895['data'] != null) {
      final data = response9895['data'];
      setState(() {
        _9895AddressController.text = data['address'] ?? '';
        _9895UsernameController.text = data['username'] ?? '';
        _9895PasswordController.text = data['password'] ?? '';
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

    // 保存 9894 配置
    final response9894 = await ApiService.saveNewland9894Config(
      address: _9894AddressController.text,
      username: _9894UsernameController.text,
      password: _9894PasswordController.text,
    );

    // 保存 9895 配置
    final response9895 = await ApiService.saveNewland9895Config(
      address: _9895AddressController.text,
      username: _9895UsernameController.text,
      password: _9895PasswordController.text,
    );

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (response9894['code'] == 200 && response9895['code'] == 200) {
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
                    Text('新大陆网关配置已保存'),
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
                      response9894['code'] != 200
                          ? response9894['message'] ?? '保存失败'
                          : response9895['message'] ?? '保存失败',
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
            '新大陆网关配置',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '配置新大陆 9894 和 9895 服务连接信息',
            style: TextStyle(fontSize: 14, color: Colors.gray),
          ),
          const SizedBox(height: 32),

          // 9894 服务配置卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings_ethernet, size: 24, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Text(
                        '9894 服务配置',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _9894AddressController,
                    placeholder: const Text('请输入 9894 服务地址'),
                  ),
                  const SizedBox(height: 8),
                  const Text('服务器地址').small.muted,
                  const SizedBox(height: 16),
                  TextField(
                    controller: _9894UsernameController,
                    placeholder: const Text('请输入 9894 服务账号'),
                  ),
                  const SizedBox(height: 8),
                  const Text('账号').small.muted,
                  const SizedBox(height: 16),
                  TextField(
                    controller: _9894PasswordController,
                    placeholder: const Text('请输入 9894 服务密码'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  const Text('密码').small.muted,
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 9895 服务配置卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings_ethernet, size: 24, color: Colors.green),
                      const SizedBox(width: 12),
                      const Text(
                        '9895 服务配置',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _9895AddressController,
                    placeholder: const Text('请输入 9895 服务地址'),
                  ),
                  const SizedBox(height: 8),
                  const Text('服务器地址').small.muted,
                  const SizedBox(height: 16),
                  TextField(
                    controller: _9895UsernameController,
                    placeholder: const Text('请输入 9895 服务账号'),
                  ),
                  const SizedBox(height: 8),
                  const Text('账号').small.muted,
                  const SizedBox(height: 16),
                  TextField(
                    controller: _9895PasswordController,
                    placeholder: const Text('请输入 9895 服务密码'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  const Text('密码').small.muted,
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 保存按钮
          SizedBox(
            width: double.infinity,
            child: Button(
              style: const ButtonStyle.primary(),
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('保存中...'),
                      ],
                    )
                  : const Text('保存配置'),
            ),
          ),
        ],
      ),
    );
  }
}
