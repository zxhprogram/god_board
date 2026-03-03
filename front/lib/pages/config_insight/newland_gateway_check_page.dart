import 'package:flutter/material.dart'
    show DataTable, DataColumn, DataRow, DataCell;
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Checkbox;
import 'package:flutter/material.dart' show Checkbox;

import '../../services/api_service.dart';

class CacheCheckResult {
  final int configId;
  final String cacheKey;
  final String expectedValue;
  bool isChecking;
  bool? isMatched;
  String? actualValue;
  String? errorMessage;

  CacheCheckResult({
    required this.configId,
    required this.cacheKey,
    required this.expectedValue,
    this.isChecking = false,
    this.isMatched,
    this.actualValue,
    this.errorMessage,
  });
}

class NewlandGatewayCheckPage extends StatefulWidget {
  const NewlandGatewayCheckPage({super.key});

  @override
  State<NewlandGatewayCheckPage> createState() =>
      _NewlandGatewayCheckPageState();
}

class _NewlandGatewayCheckPageState extends State<NewlandGatewayCheckPage> {
  bool _isLoading = false;
  bool _isCheckingAll = false;
  List<dynamic> _cacheConfigs = [];
  List<CacheCheckResult> _checkResults = [];

  // Redis 配置
  String _redisHost = '';
  int _redisPort = 6379;
  bool _isCluster = false;
  String _redisPassword = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await Future.wait([_loadCacheConfigs(), _loadRedisConfig()]);

    setState(() => _isLoading = false);
  }

  Future<void> _loadCacheConfigs() async {
    try {
      final response = await ApiService.getCacheMetadataConfigs();
      if (response['code'] == 200 && response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          setState(() {
            _cacheConfigs = List<dynamic>.from(data);
            _checkResults = _cacheConfigs.map((config) {
              return CacheCheckResult(
                configId: config['id'] ?? 0,
                cacheKey: config['cache_key'] ?? '',
                expectedValue: config['cache_value'] ?? '',
              );
            }).toList();
          });
        }
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error loading cache configs: $e');
    }
  }

  Future<void> _loadRedisConfig() async {
    try {
      final response = await ApiService.getRedisConfig();
      if (response['code'] == 200 && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _redisHost = data['host'] ?? '';
          _redisPort = data['port'] ?? 6379;
          _isCluster = data['is_cluster'] ?? false;
          _redisPassword = data['password'] ?? '';
        });
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error loading Redis config: $e');
    }
  }

  Future<void> _checkSingleItem(int index) async {
    if (_redisHost.isEmpty) {
      _showError('Redis 配置未设置，请先配置 Redis 连接信息');
      return;
    }

    final result = _checkResults[index];
    if (result.cacheKey.isEmpty) return;

    setState(() {
      _checkResults[index] = CacheCheckResult(
        configId: result.configId,
        cacheKey: result.cacheKey,
        expectedValue: result.expectedValue,
        isChecking: true,
      );
    });

    try {
      final response = await ApiService.queryRedis(
        host: _redisHost,
        port: _redisPort,
        isCluster: _isCluster,
        password: _redisPassword,
        queryType: 'get',
        key: result.cacheKey,
      );

      setState(() {
        if (response['code'] == 200) {
          final actualValue =
              response['data']?.toString().substring(
                1,
                response['data']!.toString().length - 1,
              ) ??
              '';
          final isMatched = actualValue == result.expectedValue;
          _checkResults[index] = CacheCheckResult(
            configId: result.configId,
            cacheKey: result.cacheKey,
            expectedValue: result.expectedValue,
            isChecking: false,
            isMatched: isMatched,
            actualValue: actualValue,
          );
        } else {
          _checkResults[index] = CacheCheckResult(
            configId: result.configId,
            cacheKey: result.cacheKey,
            expectedValue: result.expectedValue,
            isChecking: false,
            isMatched: false,
            errorMessage: response['message'] ?? '查询失败',
          );
        }
      });
    } catch (e) {
      setState(() {
        _checkResults[index] = CacheCheckResult(
          configId: result.configId,
          cacheKey: result.cacheKey,
          expectedValue: result.expectedValue,
          isChecking: false,
          isMatched: false,
          errorMessage: '请求异常: $e',
        );
      });
    }
  }

  Future<void> _checkAllItems() async {
    if (_redisHost.isEmpty) {
      _showError('Redis 配置未设置，请先配置 Redis 连接信息');
      return;
    }

    setState(() => _isCheckingAll = true);

    for (int i = 0; i < _checkResults.length; i++) {
      await _checkSingleItem(i);
    }

    setState(() => _isCheckingAll = false);
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          PrimaryButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showRedisConfigDialog() {
    final hostController = TextEditingController(text: _redisHost);
    final portController = TextEditingController(text: _redisPort.toString());
    final passwordController = TextEditingController(text: _redisPassword);
    bool isCluster = _isCluster;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Redis 配置'),
          content: Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: hostController,
                  placeholder: const Text('Host'),
                  hintText: '单机: 127.0.0.1  集群: ip1:port1,ip2:port2',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: portController,
                  placeholder: const Text('Port'),
                  hintText: '6379',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  placeholder: const Text('Password'),
                  hintText: '可选',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isCluster,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          isCluster = value ?? false;
                        });
                      },
                    ),
                    const Text('集群模式'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            SecondaryButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            PrimaryButton(
              onPressed: () {
                setState(() {
                  _redisHost = hostController.text;
                  _redisPort = int.tryParse(portController.text) ?? 6379;
                  _redisPassword = passwordController.text;
                  _isCluster = isCluster;
                });
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
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
            const Text(
              '新大陆网关配置检查',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '检查缓存元数据在 Redis 中的一致性',
              style: TextStyle(fontSize: 14, color: Colors.gray),
            ),
            const SizedBox(height: 24),

            // Redis 配置卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(LucideIcons.database, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Redis 连接配置',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _redisHost.isEmpty
                                ? '未配置'
                                : '$_redisHost:$_redisPort${_isCluster ? " (集群)" : ""}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.gray.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SecondaryButton(
                      onPressed: _showRedisConfigDialog,
                      child: const Text('配置'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 操作按钮
            Row(
              children: [
                PrimaryButton(
                  onPressed: _isCheckingAll || _checkResults.isEmpty
                      ? null
                      : _checkAllItems,
                  child: _isCheckingAll
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('全部检测'),
                ),
                const SizedBox(width: 12),
                SecondaryButton(
                  onPressed: _isLoading ? null : _loadData,
                  child: const Text('刷新数据'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 检查结果表格
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _checkResults.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无缓存元数据配置',
                        style: TextStyle(color: Colors.gray),
                      ),
                    )
                  : SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('缓存 Key')),
                          DataColumn(label: Text('期望值')),
                          DataColumn(label: Text('操作')),
                          DataColumn(label: Text('检测结果')),
                        ],
                        rows: _checkResults.asMap().entries.map((entry) {
                          final index = entry.key;
                          final result = entry.value;

                          return DataRow(
                            cells: [
                              DataCell(Text('${result.configId}')),
                              DataCell(
                                SelectableText(
                                  result.cacheKey,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              DataCell(
                                SelectableText(
                                  result.expectedValue,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              DataCell(
                                SecondaryButton(
                                  onPressed: result.isChecking
                                      ? null
                                      : () => _checkSingleItem(index),
                                  child: result.isChecking
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('检测'),
                                ),
                              ),
                              DataCell(
                                result.isChecking
                                    ? const Text('检测中...')
                                    : result.isMatched == null
                                    ? const Text(
                                        '未检测',
                                        style: TextStyle(color: Colors.gray),
                                      )
                                    : result.isMatched!
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.circleCheck,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          const Text('一致'),
                                        ],
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.circleX,
                                            color: Colors.red,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text('不一致'),
                                                if (result.actualValue != null)
                                                  Text(
                                                    '实际值: ${result.actualValue}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.gray.shade500,
                                                    ),
                                                  ),
                                                if (result.errorMessage != null)
                                                  Text(
                                                    result.errorMessage!,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
