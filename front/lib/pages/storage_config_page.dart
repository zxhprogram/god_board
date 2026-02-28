import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../services/api_service.dart';

class StorageConfigPage extends StatefulWidget {
  const StorageConfigPage({super.key});

  @override
  State<StorageConfigPage> createState() => _StorageConfigPageState();
}

class _StorageConfigPageState extends State<StorageConfigPage> {
  // Redis 配置控制器
  final _redisHostController = TextEditingController();
  final _redisPortController = TextEditingController(text: '6379');
  final _redisPasswordController = TextEditingController();
  bool _redisIsCluster = false;
  bool _isLoadingRedis = false;

  // MySQL 配置控制器
  final _mysqlHostController = TextEditingController();
  final _mysqlPortController = TextEditingController(text: '3306');
  final _mysqlUsernameController = TextEditingController();
  final _mysqlPasswordController = TextEditingController();
  final _mysqlDatabaseController = TextEditingController();
  bool _isLoadingMySQL = false;

  @override
  void initState() {
    super.initState();
    _loadRedisConfig();
    _loadMySQLConfig();
  }

  @override
  void dispose() {
    _redisHostController.dispose();
    _redisPortController.dispose();
    _redisPasswordController.dispose();
    _mysqlHostController.dispose();
    _mysqlPortController.dispose();
    _mysqlUsernameController.dispose();
    _mysqlPasswordController.dispose();
    _mysqlDatabaseController.dispose();
    super.dispose();
  }

  Future<void> _loadRedisConfig() async {
    final response = await ApiService.getRedisConfig();
    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      setState(() {
        _redisHostController.text = data['host'] ?? '';
        _redisPortController.text = data['port']?.toString() ?? '6379';
        _redisIsCluster = data['is_cluster'] ?? false;
        _redisPasswordController.text = data['password'] ?? '';
      });
    }
  }

  Future<void> _loadMySQLConfig() async {
    final response = await ApiService.getMySQLConfig();
    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      setState(() {
        _mysqlHostController.text = data['host'] ?? '';
        _mysqlPortController.text = data['port']?.toString() ?? '3306';
        _mysqlUsernameController.text = data['username'] ?? '';
        _mysqlPasswordController.text = data['password'] ?? '';
        _mysqlDatabaseController.text = data['database'] ?? '';
      });
    }
  }

  Future<void> _saveRedisConfig() async {
    if (_redisHostController.text.isEmpty) {
      _showError('请输入 Redis 服务器地址');
      return;
    }
    if (_redisPortController.text.isEmpty) {
      _showError('请输入 Redis 端口号');
      return;
    }

    setState(() => _isLoadingRedis = true);

    final response = await ApiService.saveRedisConfig(
      host: _redisHostController.text,
      port: int.tryParse(_redisPortController.text) ?? 6379,
      isCluster: _redisIsCluster,
      password: _redisPasswordController.text,
    );

    setState(() => _isLoadingRedis = false);

    if (response['code'] == 200) {
      _showSuccess('Redis 配置保存成功');
    } else {
      _showError(response['message'] ?? '保存失败');
    }
  }

  Future<void> _saveMySQLConfig() async {
    if (_mysqlHostController.text.isEmpty) {
      _showError('请输入 MySQL 服务器地址');
      return;
    }
    if (_mysqlPortController.text.isEmpty) {
      _showError('请输入 MySQL 端口号');
      return;
    }
    if (_mysqlUsernameController.text.isEmpty) {
      _showError('请输入 MySQL 账号');
      return;
    }
    if (_mysqlDatabaseController.text.isEmpty) {
      _showError('请输入 MySQL 数据库名称');
      return;
    }

    setState(() => _isLoadingMySQL = true);

    final response = await ApiService.saveMySQLConfig(
      host: _mysqlHostController.text,
      port: int.tryParse(_mysqlPortController.text) ?? 3306,
      username: _mysqlUsernameController.text,
      password: _mysqlPasswordController.text,
      database: _mysqlDatabaseController.text,
    );

    setState(() => _isLoadingMySQL = false);

    if (response['code'] == 200) {
      _showSuccess('MySQL 配置保存成功');
    } else {
      _showError(response['message'] ?? '保存失败');
    }
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('成功'),
        content: Text(message),
        actions: [
          Button(
            style: const ButtonStyle.primary(),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          Button(
            style: const ButtonStyle.primary(),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面标题
            const Text(
              '存储服务器配置',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '配置 Redis 和 MySQL 服务器连接信息',
              style: TextStyle(fontSize: 14, color: Colors.gray),
            ),
            const SizedBox(height: 32),

            // Redis 配置卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          BootstrapIcons.database,
                          size: 24,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Redis 配置',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),

                    // 服务器地址
                    TextField(
                      controller: _redisHostController,
                      placeholder: const Text('请输入 Redis 服务器地址'),
                    ),
                    const SizedBox(height: 8),
                    const Text('服务器地址').small.muted,
                    const SizedBox(height: 16),

                    // 端口号
                    TextField(
                      controller: _redisPortController,
                      placeholder: const Text('请输入 Redis 端口号'),
                    ),
                    const SizedBox(height: 8),
                    const Text('端口号').small.muted,
                    const SizedBox(height: 16),

                    // 是否集群
                    Row(
                      children: [
                        Checkbox(
                          state: _redisIsCluster
                              ? CheckboxState.checked
                              : CheckboxState.unchecked,
                          onChanged: (state) {
                            setState(() {
                              _redisIsCluster = state == CheckboxState.checked;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text('是否集群模式'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 密码
                    TextField(
                      controller: _redisPasswordController,
                      placeholder: const Text('请输入 Redis 密码（可选）'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    const Text('密码').small.muted,
                    const SizedBox(height: 24),

                    // 保存按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Button(
                          style: const ButtonStyle.primary(),
                          onPressed: _isLoadingRedis ? null : _saveRedisConfig,
                          child: _isLoadingRedis
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('保存 Redis 配置'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // MySQL 配置卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          BootstrapIcons.databaseFill,
                          size: 24,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'MySQL 配置',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),

                    // 服务器地址
                    TextField(
                      controller: _mysqlHostController,
                      placeholder: const Text('请输入 MySQL 服务器地址'),
                    ),
                    const SizedBox(height: 8),
                    const Text('服务器地址').small.muted,
                    const SizedBox(height: 16),

                    // 端口号
                    TextField(
                      controller: _mysqlPortController,
                      placeholder: const Text('请输入 MySQL 端口号'),
                    ),
                    const SizedBox(height: 8),
                    const Text('端口号').small.muted,
                    const SizedBox(height: 16),

                    // 账号
                    TextField(
                      controller: _mysqlUsernameController,
                      placeholder: const Text('请输入 MySQL 账号'),
                    ),
                    const SizedBox(height: 8),
                    const Text('账号').small.muted,
                    const SizedBox(height: 16),

                    // 密码
                    TextField(
                      controller: _mysqlPasswordController,
                      placeholder: const Text('请输入 MySQL 密码'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    const Text('密码').small.muted,
                    const SizedBox(height: 16),

                    // 数据库名称
                    TextField(
                      controller: _mysqlDatabaseController,
                      placeholder: const Text('请输入数据库名称'),
                    ),
                    const SizedBox(height: 8),
                    const Text('数据库名称').small.muted,
                    const SizedBox(height: 24),

                    // 保存按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Button(
                          style: const ButtonStyle.primary(),
                          onPressed: _isLoadingMySQL ? null : _saveMySQLConfig,
                          child: _isLoadingMySQL
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('保存 MySQL 配置'),
                        ),
                      ],
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
