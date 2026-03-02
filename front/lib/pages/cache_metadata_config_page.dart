import 'package:flutter/material.dart'
    show AlertDialog, DataTable, DataColumn, DataCell, DataRow;
import 'package:shadcn_flutter/shadcn_flutter.dart' hide AlertDialog;
import '../services/api_service.dart';

class CacheMetadataConfig {
  String cacheKey;
  String cacheValue;
  String description;

  CacheMetadataConfig({
    this.cacheKey = '',
    this.cacheValue = '',
    this.description = '',
  });
}

class CacheMetadataConfigPage extends StatefulWidget {
  const CacheMetadataConfigPage({super.key});

  @override
  State<CacheMetadataConfigPage> createState() =>
      _CacheMetadataConfigPageState();
}

class _CacheMetadataConfigPageState extends State<CacheMetadataConfigPage> {
  List<CacheMetadataConfig> _configRows = [CacheMetadataConfig()];

  bool _isLoading = false;
  bool _isSaving = false;
  List<dynamic> _savedConfigs = [];

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.getCacheMetadataConfigs();
      print('API Response: $response');

      if (response['code'] == 200 && response['data'] != null) {
        final data = response['data'];
        print('Data type: ${data.runtimeType}');
        print('Data: $data');

        if (data is List) {
          setState(() {
            _savedConfigs = List<dynamic>.from(data);
          });
          print('Loaded ${_savedConfigs.length} configs');
        } else {
          print('Data is not a List: ${data.runtimeType}');
          setState(() {
            _savedConfigs = [];
          });
        }
      } else {
        print('Failed to load configs: ${response['message']}');
        setState(() {
          _savedConfigs = [];
        });
      }
    } catch (e) {
      print('Error loading configs: $e');
      setState(() {
        _savedConfigs = [];
      });
    }

    setState(() => _isLoading = false);
  }

  void _addRow() {
    setState(() {
      _configRows.add(CacheMetadataConfig());
    });
  }

  void _removeRow(int index) {
    setState(() {
      if (_configRows.length > 1) {
        _configRows.removeAt(index);
      }
    });
  }

  Future<void> _saveConfigs() async {
    // 验证所有行
    for (int i = 0; i < _configRows.length; i++) {
      final row = _configRows[i];
      if (row.cacheKey.isEmpty) {
        _showError('第${i + 1}行：请输入缓存Key');
        return;
      }
      if (row.cacheValue.isEmpty) {
        _showError('第${i + 1}行：请输入缓存Value');
        return;
      }
    }

    setState(() => _isSaving = true);

    int successCount = 0;
    int failCount = 0;
    String lastError = '';

    // 逐条保存，过期时间使用固定值
    for (final row in _configRows) {
      final response = await ApiService.saveCacheMetadataConfig(
        cacheKey: row.cacheKey,
        cacheValue: row.cacheValue,
        expireTime: '2099-12-31 00:00:00',
        description: row.description,
      );

      if (response['code'] == 200) {
        successCount++;
      } else {
        failCount++;
        lastError = response['message'] ?? '保存失败';
      }
    }

    setState(() => _isSaving = false);

    if (failCount == 0) {
      _showSuccess('成功保存 $successCount 条配置');
      _clearForm();
      _loadConfigs();
    } else {
      _showError(
        '保存完成：成功 $successCount 条，失败 $failCount 条${lastError.isNotEmpty ? '\n最后错误：$lastError' : ''}',
      );
      if (successCount > 0) {
        _loadConfigs();
      }
    }
  }

  Future<void> _deleteConfig(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条缓存元数据配置吗？'),
        actions: [
          SecondaryButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          PrimaryButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final response = await ApiService.deleteCacheMetadataConfig(id);

    if (response['code'] == 200) {
      _showSuccess('删除成功');
      _loadConfigs();
    } else {
      _showError(response['message'] ?? '删除失败');
    }
  }

  void _clearForm() {
    setState(() {
      _configRows = [CacheMetadataConfig()];
    });
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

  void _showSuccess(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('成功'),
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
              '通用平台路由缓存配置元数据配置',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '配置缓存的元数据，包括缓存Key和过期时间',
              style: TextStyle(fontSize: 14, color: Colors.gray.shade500),
            ),
            const Divider(),
            const SizedBox(height: 24),

            // 添加配置表单
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '添加缓存元数据',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        SecondaryButton(
                          onPressed: _addRow,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 16),
                              SizedBox(width: 4),
                              Text('增加行'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 表头
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.gray.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              '缓存Key',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '缓存Value',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '过期时间',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '描述（可选）',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(width: 16),
                          SizedBox(
                            width: 80,
                            child: Text(
                              '操作',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 配置行列表
                    ...List.generate(_configRows.length, (index) {
                      final row = _configRows[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                placeholder: const Text('请输入缓存Key'),
                                onChanged: (value) => row.cacheKey = value,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                placeholder: const Text('请输入缓存Value'),
                                onChanged: (value) => row.cacheValue = value,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                '2099-12-31 00:00:00',
                                style: TextStyle(
                                  color: Colors.gray,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                placeholder: const Text('请输入描述'),
                                onChanged: (value) => row.description = value,
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 80,
                              child: IconButton.ghost(
                                onPressed: _configRows.length > 1
                                    ? () => _removeRow(index)
                                    : null,
                                icon: const Icon(
                                  BootstrapIcons.trash,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // 按钮
                    Row(
                      children: [
                        SecondaryButton(
                          onPressed: _clearForm,
                          child: const Text('清空'),
                        ),
                        const SizedBox(width: 16),
                        PrimaryButton(
                          onPressed: _isSaving ? null : _saveConfigs,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('确认保存'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 配置列表
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '已保存的缓存元数据列表',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          SecondaryButton(
                            onPressed: _isLoading ? null : _loadConfigs,
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
                      const SizedBox(height: 16),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _savedConfigs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      BootstrapIcons.database,
                                      size: 64,
                                      color: Colors.gray.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '暂无缓存元数据配置',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.gray.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Builder(
                                builder: (context) {
                                  print(
                                    'Building DataTable with ${_savedConfigs.length} rows',
                                  );
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('ID')),
                                        DataColumn(label: Text('缓存Key')),
                                        DataColumn(label: Text('缓存Value')),
                                        DataColumn(label: Text('过期时间')),
                                        DataColumn(label: Text('描述')),
                                        DataColumn(label: Text('创建时间')),
                                        DataColumn(label: Text('操作')),
                                      ],
                                      rows: _savedConfigs.map((config) {
                                        final configMap =
                                            config is Map<String, dynamic>
                                            ? config
                                            : <String, dynamic>{};
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text('${configMap['id'] ?? ''}'),
                                            ),
                                            DataCell(
                                              Text(
                                                configMap['cache_key']
                                                        ?.toString() ??
                                                    '',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                configMap['cache_value']
                                                        ?.toString() ??
                                                    '',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                configMap['expire_time']
                                                        ?.toString() ??
                                                    '',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                configMap['description']
                                                        ?.toString() ??
                                                    '',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                configMap['created_at'] != null
                                                    ? configMap['created_at']
                                                          .toString()
                                                          .substring(0, 19)
                                                    : '',
                                              ),
                                            ),
                                            DataCell(
                                              IconButton.ghost(
                                                onPressed: () => _deleteConfig(
                                                  configMap['id'],
                                                ),
                                                icon: const Icon(
                                                  BootstrapIcons.trash,
                                                  color: Colors.red,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
