import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../services/api_service.dart';

class K8sShell extends StatefulWidget {
  final Widget child;

  const K8sShell({super.key, required this.child});

  @override
  State<K8sShell> createState() => _K8sShellState();
}

class _K8sShellState extends State<K8sShell> {
  bool _isLoading = true;
  String? _errorMessage;
  List<TreeItem> _treeItems = [];

  // 缓存数据
  final Map<String, List<dynamic>> _deploymentsCache = {};
  final Map<String, List<dynamic>> _podsCache = {};

  @override
  void initState() {
    super.initState();
    _initializeK8s();
  }

  Future<void> _initializeK8s() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 先登录 K8s
    final loginResponse = await ApiService.k8sLogin();
    if (loginResponse['code'] != 200) {
      setState(() {
        _isLoading = false;
        _errorMessage = loginResponse['message'] ?? 'K8s 登录失败';
      });
      return;
    }

    // 获取 namespace 列表
    await _loadNamespaces();
  }

  Future<void> _loadNamespaces() async {
    final response = await ApiService.getK8sNamespaces();

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      final items = data['items'] as List<dynamic>? ?? [];

      setState(() {
        _treeItems = items.map((ns) {
          final name = ns['name'] as String;
          return TreeItem(
            id: 'ns:$name',
            label: name,
            icon: Icons.folder_outlined,
            expandedIcon: Icons.folder_open,
            children: [],
            data: ns,
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

  Future<void> _loadDeployments(String namespace, TreeItem parentItem) async {
    if (_deploymentsCache.containsKey(namespace)) {
      _updateNamespaceChildren(
        namespace,
        parentItem,
        _deploymentsCache[namespace]!,
      );
      return;
    }

    final response = await ApiService.getK8sDeployments(namespace);

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      final items = data['items'] as List<dynamic>? ?? [];
      _deploymentsCache[namespace] = items;
      _updateNamespaceChildren(namespace, parentItem, items);
    }
  }

  void _updateNamespaceChildren(
    String namespace,
    TreeItem parentItem,
    List<dynamic> deployments,
  ) {
    final index = _treeItems.indexWhere((item) => item.id == parentItem.id);
    if (index == -1) return;

    final newChildren = deployments.map((dep) {
      final name = dep['name'] as String;
      final readyReplicas = dep['readyReplicas'] ?? 0;
      final replicas = dep['replicas'] ?? 0;

      return TreeItem(
        id: 'dep:$namespace:$name',
        label: '$name ($readyReplicas/$replicas)',
        icon: Icons.apps_outlined,
        expandedIcon: Icons.apps,
        children: [],
        data: dep,
      );
    }).toList();

    setState(() {
      _treeItems[index] = TreeItem(
        id: parentItem.id,
        label: parentItem.label,
        icon: parentItem.icon,
        expandedIcon: parentItem.expandedIcon,
        children: newChildren,
        data: parentItem.data,
        isExpanded: true,
      );
    });
  }

  Future<void> _loadPods(
    String namespace,
    String deployment,
    TreeItem parentItem,
  ) async {
    final cacheKey = '$namespace:$deployment';

    if (_podsCache.containsKey(cacheKey)) {
      _updateDeploymentChildren(
        namespace,
        deployment,
        parentItem,
        _podsCache[cacheKey]!,
      );
      return;
    }

    final response = await ApiService.getK8sPods(namespace, deployment);

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      final items = data['items'] as List<dynamic>? ?? [];
      _podsCache[cacheKey] = items;
      _updateDeploymentChildren(namespace, deployment, parentItem, items);
    }
  }

  void _updateDeploymentChildren(
    String namespace,
    String deployment,
    TreeItem parentItem,
    List<dynamic> pods,
  ) {
    final nsIndex = _treeItems.indexWhere((item) => item.id == 'ns:$namespace');
    if (nsIndex == -1) return;

    final depIndex = _treeItems[nsIndex].children.indexWhere(
      (item) => item.id == parentItem.id,
    );
    if (depIndex == -1) return;

    final newChildren = pods.map((pod) {
      final name = pod['name'] as String;
      final status = pod['status'] as String;

      IconData podIcon;
      Color podColor;
      switch (status.toLowerCase()) {
        case 'running':
          podIcon = Icons.circle;
          podColor = Colors.green;
        case 'pending':
          podIcon = Icons.hourglass_empty;
          podColor = Colors.orange;
        case 'failed':
          podIcon = Icons.error;
          podColor = Colors.red;
        default:
          podIcon = Icons.help_outline;
          podColor = Colors.gray;
      }

      return TreeItem(
        id: 'pod:$namespace:$deployment:$name',
        label: name,
        icon: podIcon,
        iconColor: podColor,
        children: [],
        data: pod,
      );
    }).toList();

    final updatedDeployment = TreeItem(
      id: parentItem.id,
      label: parentItem.label,
      icon: parentItem.icon,
      expandedIcon: parentItem.expandedIcon,
      children: newChildren,
      data: parentItem.data,
      isExpanded: true,
    );

    final updatedChildren = List<TreeItem>.from(_treeItems[nsIndex].children);
    updatedChildren[depIndex] = updatedDeployment;

    setState(() {
      _treeItems[nsIndex] = TreeItem(
        id: _treeItems[nsIndex].id,
        label: _treeItems[nsIndex].label,
        icon: _treeItems[nsIndex].icon,
        expandedIcon: _treeItems[nsIndex].expandedIcon,
        children: updatedChildren,
        data: _treeItems[nsIndex].data,
        isExpanded: _treeItems[nsIndex].isExpanded,
      );
    });
  }

  void _onItemExpand(TreeItem item) {
    if (item.id.startsWith('ns:')) {
      final namespace = item.id.substring(3);
      _loadDeployments(namespace, item);
    } else if (item.id.startsWith('dep:')) {
      final parts = item.id.split(':');
      if (parts.length >= 3) {
        final namespace = parts[1];
        final deployment = parts[2];
        _loadPods(namespace, deployment, item);
      }
    }
  }

  void _onItemCollapse(TreeItem item) {
    if (item.id.startsWith('ns:')) {
      final index = _treeItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        setState(() {
          _treeItems[index] = TreeItem(
            id: item.id,
            label: item.label,
            icon: item.icon,
            expandedIcon: item.expandedIcon,
            children: item.children,
            data: item.data,
            isExpanded: false,
          );
        });
      }
    } else if (item.id.startsWith('dep:')) {
      final parts = item.id.split(':');
      if (parts.length >= 3) {
        final namespace = parts[1];
        final nsIndex = _treeItems.indexWhere((i) => i.id == 'ns:$namespace');
        if (nsIndex != -1) {
          final depIndex = _treeItems[nsIndex].children.indexWhere(
            (i) => i.id == item.id,
          );
          if (depIndex != -1) {
            final updatedChildren = List<TreeItem>.from(
              _treeItems[nsIndex].children,
            );
            updatedChildren[depIndex] = TreeItem(
              id: item.id,
              label: item.label,
              icon: item.icon,
              expandedIcon: item.expandedIcon,
              children: item.children,
              data: item.data,
              isExpanded: false,
            );
            setState(() {
              _treeItems[nsIndex] = TreeItem(
                id: _treeItems[nsIndex].id,
                label: _treeItems[nsIndex].label,
                icon: _treeItems[nsIndex].icon,
                expandedIcon: _treeItems[nsIndex].expandedIcon,
                children: updatedChildren,
                data: _treeItems[nsIndex].data,
                isExpanded: _treeItems[nsIndex].isExpanded,
              );
            });
          }
        }
      }
    }
  }

  void _onItemTap(TreeItem item) {
    if (item.id.startsWith('ns:')) {
      final namespace = item.id.substring(3);
      context.go('/k8s/namespace/$namespace');
    } else if (item.id.startsWith('dep:')) {
      final parts = item.id.split(':');
      if (parts.length >= 3) {
        final namespace = parts[1];
        final deployment = parts[2];
        context.go('/k8s/namespace/$namespace/deployment/$deployment');
      }
    } else if (item.id.startsWith('pod:')) {
      final parts = item.id.split(':');
      if (parts.length >= 4) {
        final namespace = parts[1];
        final deployment = parts[2];
        final pod = parts[3];
        context.go('/k8s/namespace/$namespace/deployment/$deployment/pod/$pod');
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
            Text('正在连接 K8s...'),
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
            PrimaryButton(onPressed: _initializeK8s, child: const Text('重试')),
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
                    const Icon(Icons.cloud, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'K8s 资源管理器',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    SecondaryButton(
                      onPressed: _initializeK8s,
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
                    : TreeView(
                        items: _treeItems,
                        onItemExpand: _onItemExpand,
                        onItemCollapse: _onItemCollapse,
                        onItemTap: _onItemTap,
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

// TreeItem 数据类
class TreeItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData? expandedIcon;
  final Color? iconColor;
  final List<TreeItem> children;
  final dynamic data;
  final bool isExpanded;

  TreeItem({
    required this.id,
    required this.label,
    required this.icon,
    this.expandedIcon,
    this.iconColor,
    required this.children,
    this.data,
    this.isExpanded = false,
  });
}

// TreeView 组件
class TreeView extends StatelessWidget {
  final List<TreeItem> items;
  final Function(TreeItem)? onItemExpand;
  final Function(TreeItem)? onItemCollapse;
  final Function(TreeItem)? onItemTap;

  const TreeView({
    super.key,
    required this.items,
    this.onItemExpand,
    this.onItemCollapse,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildTreeItem(context, items[index], 0);
      },
    );
  }

  Widget _buildTreeItem(BuildContext context, TreeItem item, int level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TreeItemWidget(
          item: item,
          level: level,
          onExpand: () => onItemExpand?.call(item),
          onCollapse: () => onItemCollapse?.call(item),
          onTap: () => onItemTap?.call(item),
        ),
        if (item.isExpanded && item.children.isNotEmpty)
          ...item.children.map(
            (child) => _buildTreeItem(context, child, level + 1),
          ),
      ],
    );
  }
}

class _TreeItemWidget extends StatelessWidget {
  final TreeItem item;
  final int level;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final VoidCallback onTap;

  const _TreeItemWidget({
    required this.item,
    required this.level,
    required this.onExpand,
    required this.onCollapse,
    required this.onTap,
  });

  void _toggleExpand() {
    if (item.isExpanded) {
      onCollapse();
    } else {
      onExpand();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasChildren =
        item.children.isNotEmpty ||
        item.id.startsWith('ns:') ||
        item.id.startsWith('dep:');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 16.0 + level * 24.0,
          top: 8,
          bottom: 8,
          right: 16,
        ),
        child: Row(
          children: [
            if (hasChildren)
              GestureDetector(
                onTap: _toggleExpand,
                child: Icon(
                  item.isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.gray,
                ),
              )
            else
              const SizedBox(width: 20),
            const SizedBox(width: 4),
            Icon(
              item.isExpanded && item.expandedIcon != null
                  ? item.expandedIcon!
                  : item.icon,
              size: 20,
              color: item.iconColor ?? Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
