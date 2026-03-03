import 'package:flutter/material.dart'
    show AlertDialog, DataTable, DataColumn, DataRow, DataCell;
import 'package:shadcn_flutter/shadcn_flutter.dart' hide AlertDialog;
import '../services/api_service.dart';

class IndustryMongoAuthConfigPage extends StatefulWidget {
  const IndustryMongoAuthConfigPage({super.key});

  @override
  State<IndustryMongoAuthConfigPage> createState() =>
      _IndustryMongoAuthConfigPageState();
}

class _IndustryMongoAuthConfigPageState
    extends State<IndustryMongoAuthConfigPage> {
  // 固定缓存key
  static const String cacheKey = 'industryAkAuthConfig';

  // 配置字段
  final TextEditingController _cacheValueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  int? _configId;

  // 已保存的配置列表
  List<dynamic> _savedConfigs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _cacheValueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadConfig(), _loadSavedConfigs()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadConfig() async {
    try {
      final response = await ApiService.getIndustryMongoAuthConfig();
      if (response['code'] == 200 && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _configId = data['id'];
          _cacheValueController.text = data['cache_value'] ?? '';
          _descriptionController.text = data['description'] ?? '';
        });
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error loading config: $e');
    }
  }

  Future<void> _loadSavedConfigs() async {
    try {
      final response = await ApiService.getIndustryMongoAuthConfigs();
      if (response['code'] == 200 && response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          setState(() {
            _savedConfigs = List<dynamic>.from(data);
          });
        }
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error loading saved configs: $e');
    }
  }

  Future<void> _saveConfig() async {
    // 验证输入
    if (_cacheValueController.text.isEmpty) {
      _showError('请输入缓存 Value');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await ApiService.saveIndustryMongoAuthConfig(
        id: _configId,
        cacheKey: cacheKey,
        cacheValue: _cacheValueController.text,
        description: _descriptionController.text,
      );

      if (response['code'] == 200) {
        _showSuccess('保存成功');
        _loadData();
      } else {
        _showError(response['message'] ?? '保存失败');
      }
    } catch (e) {
      _showError('保存失败: $e');
    }

    setState(() => _isSaving = false);
  }

  Future<void> _deleteConfig(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条配置吗？'),
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

    final response = await ApiService.deleteIndustryMongoAuthConfig(id);

    if (response['code'] == 200) {
      _showSuccess('删除成功');
      _loadData();
    } else {
      _showError(response['message'] ?? '删除失败');
    }
  }

  void _editConfig(dynamic config) {
    setState(() {
      _configId = config['id'];
      _cacheValueController.text = config['cache_value'] ?? '';
      _descriptionController.text = config['description'] ?? '';
    });
    // 滚动到表单顶部
    // ignore: avoid_print
    debugPrint('编辑配置: ${config['id']}');
  }

  void _clearForm() {
    setState(() {
      _configId = null;
      _cacheValueController.clear();
      _descriptionController.clear();
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面标题
            const Text(
              '行业调用mongo授权配置',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '配置行业调用mongo的授权信息（缓存 Value）',
              style: TextStyle(fontSize: 14, color: Colors.gray.shade500),
            ),
            const Divider(),
            const SizedBox(height: 24),

            // 配置表单
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '添加/编辑配置',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_configId != null)
                          SecondaryButton(
                            onPressed: _clearForm,
                            child: const Text('新增'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 缓存Key（只读）
                    Row(
                      children: [
                        const Text(
                          '缓存Key',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.gray.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            cacheKey,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.gray.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 缓存 Value
                    TextField(
                      controller: _cacheValueController,
                      placeholder: const Text('缓存 Value'),
                      hintText: '请输入缓存 Value（JSON格式或其他格式）',
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),

                    // 描述
                    TextField(
                      controller: _descriptionController,
                      placeholder: const Text('描述'),
                      hintText: '可选：输入配置描述信息',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // 保存按钮
                    Row(
                      children: [
                        PrimaryButton(
                          onPressed: _isSaving ? null : _saveConfig,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_configId == null ? '确认保存' : '更新'),
                        ),
                        const SizedBox(width: 12),
                        SecondaryButton(
                          onPressed: _isLoading ? null : _loadData,
                          child: const Text('刷新'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 已保存的配置列表
            const Text(
              '已保存的配置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_savedConfigs.isEmpty)
              const Center(
                child: Text('暂无已保存的配置', style: TextStyle(color: Colors.gray)),
              )
            else
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('缓存Key')),
                      DataColumn(label: Text('缓存Value')),
                      DataColumn(label: Text('描述')),
                      DataColumn(label: Text('创建时间')),
                      DataColumn(label: Text('更新时间')),
                      DataColumn(label: Text('操作')),
                    ],
                    rows: _savedConfigs.map((config) {
                      return DataRow(
                        cells: [
                          DataCell(Text('${config['id'] ?? ''}')),
                          DataCell(
                            SelectableText(
                              config['cache_key'] ?? '',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: Text(
                                config['cache_value'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          ),
                          DataCell(Text(config['description'] ?? '')),
                          DataCell(Text(config['created_at'] ?? '')),
                          DataCell(Text(config['updated_at'] ?? '')),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SecondaryButton(
                                  onPressed: () => _editConfig(config),
                                  child: const Text('编辑'),
                                ),
                                const SizedBox(width: 8),
                                SecondaryButton(
                                  onPressed: () => _deleteConfig(config['id']),
                                  child: const Text('删除'),
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
