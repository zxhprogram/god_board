import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../../services/api_service.dart';

/// Nacos 配置关联 Drawer 内容组件
class NacosMappingDrawerContent extends StatefulWidget {
  final String deployment;
  final String namespace;
  final Future<Map<String, dynamic>> Function(
    String nacosNamespace,
    String nacosConfigId,
  )?
  onSave;
  final void Function(String message, {bool isError})? onShowToast;

  const NacosMappingDrawerContent({
    super.key,
    required this.deployment,
    required this.namespace,
    this.onSave,
    this.onShowToast,
  });

  @override
  State<NacosMappingDrawerContent> createState() =>
      _NacosMappingDrawerContentState();
}

class _NacosMappingDrawerContentState extends State<NacosMappingDrawerContent> {
  List<dynamic> _nacosNamespaces = [];
  bool _isLoadingNacosNamespaces = true;
  final Map<String, List<dynamic>> _nacosConfigs = {};
  final Map<String, bool> _isLoadingNacosConfigs = {};
  String? _selectedNacosNamespace;
  String? _selectedNacosConfigId;
  bool _isSavingMapping = false;

  void _showToast(String message, {bool isError = false}) {
    if (widget.onShowToast != null) {
      widget.onShowToast!(message, isError: isError);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNacosNamespaces();
  }

  Future<void> _loadNacosNamespaces() async {
    setState(() => _isLoadingNacosNamespaces = true);

    final loginResponse = await ApiService.nacosLogin();
    if (loginResponse['code'] != 200) {
      setState(() => _isLoadingNacosNamespaces = false);
      if (mounted) {
        _showToast('Nacos 登录失败: ${loginResponse['message']}', isError: true);
      }
      return;
    }

    final response = await ApiService.getNacosNamespaces();

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      if (data is List<dynamic>) {
        setState(() {
          _nacosNamespaces = data;
          _isLoadingNacosNamespaces = false;
        });
      } else {
        setState(() {
          _nacosNamespaces = [];
          _isLoadingNacosNamespaces = false;
        });
      }
    } else {
      setState(() => _isLoadingNacosNamespaces = false);
      if (mounted && response['code'] != 200) {
        _showToast(
          '获取 Nacos Namespaces 失败: ${response['message']}',
          isError: true,
        );
      }
    }
  }

  Future<void> _loadNacosConfigs(String namespaceId) async {
    if (_nacosConfigs.containsKey(namespaceId)) return;

    setState(() => _isLoadingNacosConfigs[namespaceId] = true);

    final response = await ApiService.getNacosConfigs(namespaceId);

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      setState(() {
        _nacosConfigs[namespaceId] = data['pageItems'] as List<dynamic>? ?? [];
        _isLoadingNacosConfigs[namespaceId] = false;
      });
    } else {
      setState(() {
        _nacosConfigs[namespaceId] = [];
        _isLoadingNacosConfigs[namespaceId] = false;
      });
    }
  }

  Future<void> _saveMapping() async {
    if (_selectedNacosNamespace == null || _selectedNacosConfigId == null) {
      return;
    }

    setState(() => _isSavingMapping = true);

    Map<String, dynamic> response;
    if (widget.onSave != null) {
      response = await widget.onSave!(
        _selectedNacosNamespace!,
        _selectedNacosConfigId!,
      );
    } else {
      response = {'code': 500, 'message': '未配置保存回调'};
    }

    setState(() => _isSavingMapping = false);

    if (response['code'] == 200) {
      if (mounted) {
        _showToast('关联关系保存成功');
        closeOverlay(context);
      }
    } else {
      if (mounted) {
        _showToast('保存失败: ${response['message']}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '关联 Nacos 配置',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton.ghost(
                onPressed: () => closeOverlay(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deployment: ${widget.deployment}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Namespace: ${widget.namespace}',
                    style: TextStyle(fontSize: 12, color: Colors.gray.shade500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '选择 Nacos Namespace',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_isLoadingNacosNamespaces)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_nacosNamespaces.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '暂无 Nacos Namespace 数据',
                  style: TextStyle(color: Colors.gray),
                ),
              ),
            )
          else
            Select<String>(
              value: _selectedNacosNamespace,
              onChanged: (value) {
                setState(() {
                  _selectedNacosNamespace = value;
                  _selectedNacosConfigId = null;
                });
                if (value != null) {
                  _loadNacosConfigs(value);
                }
              },
              placeholder: const Text('请选择 Namespace'),
              itemBuilder: (context, value) => Text(
                _nacosNamespaces.firstWhere(
                      (ns) => ns['namespace'] == value,
                      orElse: () => {'namespaceShowName': '未知'},
                    )['namespaceShowName'] ??
                    '未知',
              ),
              popup: (context) => SelectPopup(
                items: SelectItemList(
                  children: _nacosNamespaces.map<Widget>((ns) {
                    final namespaceShowName = ns['namespaceShowName'] ?? '未知';
                    final namespace = ns['namespace'] ?? '';
                    return SelectItemButton<String>(
                      value: namespace,
                      child: Text(namespaceShowName),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (_selectedNacosNamespace != null) ...[
            const Text(
              '选择 Nacos 配置',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_isLoadingNacosConfigs[_selectedNacosNamespace] == true)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_nacosConfigs[_selectedNacosNamespace]?.isEmpty ?? true)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '该 Namespace 下暂无配置',
                    style: TextStyle(color: Colors.gray),
                  ),
                ),
              )
            else
              Expanded(
                child: Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount:
                        _nacosConfigs[_selectedNacosNamespace]?.length ?? 0,
                    itemBuilder: (context, index) {
                      final config =
                          _nacosConfigs[_selectedNacosNamespace]![index];
                      final dataId = config['dataId'] ?? '未知';
                      final group = config['group'] ?? '未知';
                      final configId = config['id']?.toString() ?? '';
                      final isSelected = _selectedNacosConfigId == configId;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedNacosConfigId = configId);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: isSelected ? Colors.blue.shade50 : null,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dataId),
                                    Text(
                                      'Group: $group',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.gray.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade600,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            onPressed:
                (_selectedNacosNamespace != null &&
                    _selectedNacosConfigId != null &&
                    !_isSavingMapping)
                ? _saveMapping
                : null,
            child: _isSavingMapping
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存关联'),
          ),
        ],
      ),
    );
  }
}

/// Nacos 服务关联 Drawer 内容组件
class NacosServiceMappingDrawerContent extends StatefulWidget {
  final String deployment;
  final String namespace;
  final Future<Map<String, dynamic>> Function(
    String nacosNamespace,
    String nacosServiceName,
    String nacosGroupName,
  )?
  onSave;
  final void Function(String message, {bool isError})? onShowToast;

  const NacosServiceMappingDrawerContent({
    super.key,
    required this.deployment,
    required this.namespace,
    this.onSave,
    this.onShowToast,
  });

  @override
  State<NacosServiceMappingDrawerContent> createState() =>
      _NacosServiceMappingDrawerContentState();
}

class _NacosServiceMappingDrawerContentState
    extends State<NacosServiceMappingDrawerContent> {
  List<dynamic> _nacosNamespaces = [];
  bool _isLoadingNacosNamespaces = true;
  final Map<String, List<dynamic>> _nacosServices = {};
  final Map<String, bool> _isLoadingNacosServices = {};
  String? _selectedNacosNamespace;
  String? _selectedNacosServiceName;
  String? _selectedNacosGroupName;
  bool _isSavingMapping = false;

  void _showToast(String message, {bool isError = false}) {
    if (widget.onShowToast != null) {
      widget.onShowToast!(message, isError: isError);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNacosNamespaces();
  }

  Future<void> _loadNacosNamespaces() async {
    setState(() => _isLoadingNacosNamespaces = true);

    final loginResponse = await ApiService.nacosLogin();
    if (loginResponse['code'] != 200) {
      setState(() => _isLoadingNacosNamespaces = false);
      if (mounted) {
        _showToast('Nacos 登录失败: ${loginResponse['message']}', isError: true);
      }
      return;
    }

    final response = await ApiService.getNacosNamespaces();

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      if (data is List<dynamic>) {
        setState(() {
          _nacosNamespaces = data;
          _isLoadingNacosNamespaces = false;
        });
      } else {
        setState(() {
          _nacosNamespaces = [];
          _isLoadingNacosNamespaces = false;
        });
      }
    } else {
      setState(() => _isLoadingNacosNamespaces = false);
      if (mounted && response['code'] != 200) {
        _showToast(
          '获取 Nacos Namespaces 失败: ${response['message']}',
          isError: true,
        );
      }
    }
  }

  Future<void> _loadNacosServices(String namespace) async {
    if (_nacosServices.containsKey(namespace)) return;

    setState(() => _isLoadingNacosServices[namespace] = true);

    final response = await ApiService.getNacosServices(namespace);

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      setState(() {
        _nacosServices[namespace] = data['serviceList'] as List<dynamic>? ?? [];
        _isLoadingNacosServices[namespace] = false;
      });
    } else {
      setState(() {
        _nacosServices[namespace] = [];
        _isLoadingNacosServices[namespace] = false;
      });
    }
  }

  Future<void> _saveMapping() async {
    if (_selectedNacosNamespace == null || _selectedNacosServiceName == null) {
      return;
    }

    setState(() => _isSavingMapping = true);

    Map<String, dynamic> response;
    if (widget.onSave != null) {
      response = await widget.onSave!(
        _selectedNacosNamespace!,
        _selectedNacosServiceName!,
        _selectedNacosGroupName ?? 'DEFAULT_GROUP',
      );
    } else {
      response = {'code': 500, 'message': '未配置保存回调'};
    }

    setState(() => _isSavingMapping = false);

    if (response['code'] == 200) {
      if (mounted) {
        _showToast('服务关联保存成功');
        closeOverlay(context);
      }
    } else {
      if (mounted) {
        _showToast('保存失败: ${response['message']}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '关联 Nacos 服务',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton.ghost(
                onPressed: () => closeOverlay(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deployment: ${widget.deployment}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Namespace: ${widget.namespace}',
                    style: TextStyle(fontSize: 12, color: Colors.gray.shade500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '选择 Nacos Namespace',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_isLoadingNacosNamespaces)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_nacosNamespaces.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '暂无 Nacos Namespace 数据',
                  style: TextStyle(color: Colors.gray),
                ),
              ),
            )
          else
            Select<String>(
              value: _selectedNacosNamespace,
              onChanged: (value) {
                setState(() {
                  _selectedNacosNamespace = value;
                  _selectedNacosServiceName = null;
                  _selectedNacosGroupName = null;
                });
                if (value != null) {
                  _loadNacosServices(value);
                }
              },
              placeholder: const Text('请选择 Namespace'),
              itemBuilder: (context, value) => Text(
                _nacosNamespaces.firstWhere(
                      (ns) => ns['namespace'] == value,
                      orElse: () => {'namespaceShowName': '未知'},
                    )['namespaceShowName'] ??
                    '未知',
              ),
              popup: (context) => SelectPopup(
                items: SelectItemList(
                  children: _nacosNamespaces.map<Widget>((ns) {
                    final namespaceShowName = ns['namespaceShowName'] ?? '未知';
                    final namespace = ns['namespace'] ?? '';
                    return SelectItemButton<String>(
                      value: namespace,
                      child: Text(namespaceShowName),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (_selectedNacosNamespace != null) ...[
            const Text(
              '选择 Nacos 服务',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_isLoadingNacosServices[_selectedNacosNamespace] == true)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_nacosServices[_selectedNacosNamespace]?.isEmpty ?? true)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '该 Namespace 下暂无服务',
                    style: TextStyle(color: Colors.gray),
                  ),
                ),
              )
            else
              Expanded(
                child: Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount:
                        _nacosServices[_selectedNacosNamespace]?.length ?? 0,
                    itemBuilder: (context, index) {
                      final service =
                          _nacosServices[_selectedNacosNamespace]![index];
                      final serviceName = service['name'] ?? '未知';
                      final groupName = service['groupName'] ?? 'DEFAULT_GROUP';
                      final isSelected =
                          _selectedNacosServiceName == serviceName;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedNacosServiceName = serviceName;
                            _selectedNacosGroupName = groupName;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: isSelected ? Colors.blue.shade50 : null,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(serviceName),
                                    Text(
                                      'Group: $groupName',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.gray.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade600,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            onPressed:
                (_selectedNacosNamespace != null &&
                    _selectedNacosServiceName != null &&
                    !_isSavingMapping)
                ? _saveMapping
                : null,
            child: _isSavingMapping
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存关联'),
          ),
        ],
      ),
    );
  }
}
