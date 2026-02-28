import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../services/api_service.dart';

// Nacos 树节点数据类
class NacosTreeNode {
  final String id;
  final String label;
  final IconData icon;
  final IconData? expandedIcon;
  final Color? iconColor;
  final dynamic data;

  NacosTreeNode({
    required this.id,
    required this.label,
    required this.icon,
    this.expandedIcon,
    this.iconColor,
    required this.data,
  });
}

class NacosShell extends StatefulWidget {
  final Widget child;

  const NacosShell({super.key, required this.child});

  @override
  State<NacosShell> createState() => _NacosShellState();
}

class _NacosShellState extends State<NacosShell> {
  bool _isLoading = true;
  String? _errorMessage;
  List<TreeItem<NacosTreeNode>> _treeItems = [];

  // 缓存数据
  final Map<String, List<dynamic>> _configsCache = {};
  final Map<String, List<dynamic>> _servicesCache = {};

  @override
  void initState() {
    super.initState();
    _initializeNacos();
  }

  Future<void> _initializeNacos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 先登录 Nacos
    final loginResponse = await ApiService.nacosLogin();
    if (loginResponse['code'] != 200) {
      setState(() {
        _isLoading = false;
        _errorMessage = loginResponse['message'] ?? 'Nacos 登录失败';
      });
      return;
    }

    // 获取 namespace 列表
    await _loadNamespaces();
  }

  Future<void> _loadNamespaces() async {
    final response = await ApiService.getNacosNamespaces();

    if (response['code'] == 200 && response['data'] != null) {
      final items = response['data'] as List<dynamic>? ?? [];

      setState(() {
        _treeItems = items.map((ns) {
          final namespace = ns['namespace'] as String;
          final showName = ns['namespaceShowName'] as String? ?? namespace;
          return TreeItem<NacosTreeNode>(
            data: NacosTreeNode(
              id: 'ns:$namespace',
              label: showName.isEmpty ? namespace : showName,
              icon: BootstrapIcons.folder,
              expandedIcon: BootstrapIcons.folder2Open,
              data: ns,
            ),
            expanded: false,
            children: [],
          );
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = response['message'] ?? '获取 namespace 失败';
      });
    }
  }

  Future<void> _loadConfigs(
    String namespaceId,
    TreeItem<NacosTreeNode> parentItem,
  ) async {
    if (_configsCache.containsKey(namespaceId)) {
      _updateNamespaceChildren(
        namespaceId,
        parentItem,
        _configsCache[namespaceId]!,
      );
      return;
    }

    final response = await ApiService.getNacosConfigs(namespaceId);

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      final items = data['pageItems'] as List<dynamic>? ?? [];
      _configsCache[namespaceId] = items;
      _updateNamespaceChildren(namespaceId, parentItem, items);
    }
  }

  void _updateNamespaceChildren(
    String namespaceId,
    TreeItem<NacosTreeNode> parentItem,
    List<dynamic> configs,
  ) {
    final index = _treeItems.indexWhere(
      (item) => item.data.id == 'ns:$namespaceId',
    );
    if (index == -1) return;

    final newChildren = configs.map((config) {
      final dataId = config['dataId'] as String;
      final group = config['group'] as String? ?? 'DEFAULT_GROUP';

      return TreeItem<NacosTreeNode>(
        data: NacosTreeNode(
          id: 'cfg:$namespaceId:$group:$dataId',
          label: '$dataId ($group)',
          icon: BootstrapIcons.fileText,
          expandedIcon: BootstrapIcons.fileTextFill,
          data: config,
        ),
        expanded: false,
        children: [],
      );
    }).toList();

    setState(() {
      _treeItems[index] = TreeItem<NacosTreeNode>(
        data: _treeItems[index].data,
        expanded: true,
        children: newChildren,
      );
    });
  }

  Future<void> _loadServices(
    String namespaceId,
    String group,
    String dataId,
    TreeItem<NacosTreeNode> parentItem,
  ) async {
    final cacheKey = '$namespaceId:$group:$dataId';

    if (_servicesCache.containsKey(cacheKey)) {
      _updateConfigChildren(
        namespaceId,
        group,
        dataId,
        parentItem,
        _servicesCache[cacheKey]!,
      );
      return;
    }

    final response = await ApiService.getNacosServices(namespaceId);

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      final items = data['serviceList'] as List<dynamic>? ?? [];
      _servicesCache[cacheKey] = items;
      _updateConfigChildren(namespaceId, group, dataId, parentItem, items);
    }
  }

  void _updateConfigChildren(
    String namespaceId,
    String group,
    String dataId,
    TreeItem<NacosTreeNode> parentItem,
    List<dynamic> services,
  ) {
    final nsIndex = _treeItems.indexWhere(
      (item) => item.data.id == 'ns:$namespaceId',
    );
    if (nsIndex == -1) return;

    final cfgIndex = _treeItems[nsIndex].children.indexWhere(
      (item) =>
          (item as TreeItem<NacosTreeNode>).data.id ==
          'cfg:$namespaceId:$group:$dataId',
    );
    if (cfgIndex == -1) return;

    final newChildren = services.map((service) {
      final name = service['name'] as String;
      final healthyCount = service['healthyInstanceCount'] ?? 0;
      final totalCount = service['ipCount'] ?? 0;

      return TreeItem<NacosTreeNode>(
        data: NacosTreeNode(
          id: 'svc:$namespaceId:$group:$dataId:$name',
          label: '$name ($healthyCount/$totalCount)',
          icon: BootstrapIcons.hddStack,
          iconColor: healthyCount > 0 ? Colors.green : Colors.red,
          data: service,
        ),
        expanded: false,
        children: [],
      );
    }).toList();

    final updatedChildren = List<TreeItem<NacosTreeNode>>.from(
      _treeItems[nsIndex].children.cast<TreeItem<NacosTreeNode>>(),
    );
    updatedChildren[cfgIndex] = TreeItem<NacosTreeNode>(
      data: updatedChildren[cfgIndex].data,
      expanded: true,
      children: newChildren,
    );

    setState(() {
      _treeItems[nsIndex] = TreeItem<NacosTreeNode>(
        data: _treeItems[nsIndex].data,
        expanded: _treeItems[nsIndex].expanded,
        children: updatedChildren,
      );
    });
  }

  void _onItemExpand(TreeItem<NacosTreeNode> item) {
    final id = item.data.id;
    if (id.startsWith('ns:')) {
      final namespaceId = id.substring(3);
      _loadConfigs(namespaceId, item);
    } else if (id.startsWith('cfg:')) {
      final parts = id.split(':');
      if (parts.length >= 4) {
        final namespaceId = parts[1];
        final group = parts[2];
        final dataId = parts.sublist(3).join(':');
        _loadServices(namespaceId, group, dataId, item);
      }
    }
  }

  void _onItemTap(TreeItem<NacosTreeNode> item) {
    final id = item.data.id;
    if (id.startsWith('ns:')) {
      final namespaceId = id.substring(3);
      context.go('/nacos/namespace/$namespaceId');
    } else if (id.startsWith('cfg:')) {
      final parts = id.split(':');
      if (parts.length >= 4) {
        final namespaceId = parts[1];
        final group = parts[2];
        final dataId = parts.sublist(3).join(':');
        context.go('/nacos/namespace/$namespaceId/config/$group/$dataId');
      }
    } else if (id.startsWith('svc:')) {
      final parts = id.split(':');
      if (parts.length >= 5) {
        final namespaceId = parts[1];
        final group = parts[2];
        final dataId = parts[3];
        final serviceName = parts.sublist(4).join(':');
        context.go(
          '/nacos/namespace/$namespaceId/config/$group/$dataId/service/$serviceName',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在连接 Nacos...'),
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
            const Text(
              '连接失败',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 14, color: Colors.gray),
            ),
            const SizedBox(height: 16),
            PrimaryButton(onPressed: _initializeNacos, child: const Text('重试')),
          ],
        ),
      );
    }

    return Row(
      children: [
        // 左侧导航树（半宽）
        Container(
          width: MediaQuery.of(context).size.width * 0.35,
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
                    const Icon(BootstrapIcons.cloud, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Nacos 配置管理',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    SecondaryButton(
                      onPressed: _initializeNacos,
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
              ),
              const Divider(),
              // TreeView
              Expanded(
                child: _treeItems.isEmpty
                    ? const Center(child: Text('暂无数据'))
                    : TreeView<NacosTreeNode>(
                        shrinkWrap: true,
                        branchLine: BranchLine.line,
                        nodes: _treeItems,
                        onSelectionChanged: TreeView.defaultSelectionHandler(
                          _treeItems,
                          (value) {
                            setState(() {
                              _treeItems = value
                                  .cast<TreeItem<NacosTreeNode>>();
                            });
                          },
                        ),
                        builder: (context, node) {
                          final item = node;
                          final data = item.data;
                          final isExpanded = item.expanded;
                          // 根据节点类型判断是否可以展开（namespace 和 config 可以展开）
                          final canExpand =
                              data.id.startsWith('ns:') ||
                              data.id.startsWith('cfg:');

                          return TreeItemView(
                            onPressed: () => _onItemTap(item),
                            onDoublePressed: canExpand
                                ? () {
                                    // 双击展开/折叠
                                    final newExpanded = !isExpanded;
                                    setState(() {
                                      TreeView.defaultItemExpandHandler(
                                        _treeItems,
                                        node,
                                        (value) {
                                          _treeItems = value
                                              .cast<TreeItem<NacosTreeNode>>();
                                        },
                                      )(newExpanded);
                                    });
                                    // 如果展开，加载数据
                                    if (newExpanded) {
                                      _onItemExpand(item);
                                    }
                                  }
                                : null,
                            leading: Icon(
                              isExpanded && data.expandedIcon != null
                                  ? data.expandedIcon!
                                  : data.icon,
                              size: 18,
                              color: data.iconColor ?? Colors.blue,
                            ),
                            child: Text(
                              data.label,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        // 右侧内容区域
        Expanded(child: widget.child),
      ],
    );
  }
}
