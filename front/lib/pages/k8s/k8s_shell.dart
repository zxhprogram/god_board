import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../services/api_service.dart';

// K8s 树节点数据类
class K8sTreeNode {
  final String id;
  final String label;
  final IconData icon;
  final IconData? expandedIcon;
  final Color? iconColor;
  final dynamic data;

  K8sTreeNode({
    required this.id,
    required this.label,
    required this.icon,
    this.expandedIcon,
    this.iconColor,
    required this.data,
  });
}

class K8sShell extends StatefulWidget {
  final Widget child;

  const K8sShell({super.key, required this.child});

  @override
  State<K8sShell> createState() => _K8sShellState();
}

class _K8sShellState extends State<K8sShell> {
  bool _isLoading = true;
  String? _errorMessage;
  List<TreeItem<K8sTreeNode>> _treeItems = [];

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
          return TreeItem<K8sTreeNode>(
            data: K8sTreeNode(
              id: 'ns:$name',
              label: name,
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

  Future<void> _loadDeployments(
    String namespace,
    TreeItem<K8sTreeNode> parentItem,
  ) async {
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
    TreeItem<K8sTreeNode> parentItem,
    List<dynamic> deployments,
  ) {
    final index = _treeItems.indexWhere(
      (item) => item.data.id == 'ns:$namespace',
    );
    if (index == -1) return;

    final newChildren = deployments.map((dep) {
      final name = dep['name'] as String;
      final readyReplicas = dep['readyReplicas'] ?? 0;
      final replicas = dep['replicas'] ?? 0;

      return TreeItem<K8sTreeNode>(
        data: K8sTreeNode(
          id: 'dep:$namespace:$name',
          label: '$name ($readyReplicas/$replicas)',
          icon: BootstrapIcons.grid,
          expandedIcon: BootstrapIcons.gridFill,
          data: dep,
        ),
        expanded: false,
        children: [],
      );
    }).toList();

    setState(() {
      _treeItems[index] = TreeItem<K8sTreeNode>(
        data: _treeItems[index].data,
        expanded: true,
        children: newChildren,
      );
    });
  }

  Future<void> _loadPods(
    String namespace,
    String deployment,
    TreeItem<K8sTreeNode> parentItem,
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
    TreeItem<K8sTreeNode> parentItem,
    List<dynamic> pods,
  ) {
    final nsIndex = _treeItems.indexWhere(
      (item) => item.data.id == 'ns:$namespace',
    );
    if (nsIndex == -1) return;

    final depIndex = _treeItems[nsIndex].children.indexWhere(
      (item) =>
          (item as TreeItem<K8sTreeNode>).data.id ==
          'dep:$namespace:$deployment',
    );
    if (depIndex == -1) return;

    final newChildren = pods.map((pod) {
      final name = pod['name'] as String;
      final status = pod['status'] as String;

      IconData podIcon;
      Color podColor;
      switch (status.toLowerCase()) {
        case 'running':
          podIcon = BootstrapIcons.circleFill;
          podColor = Colors.green;
        case 'pending':
          podIcon = BootstrapIcons.hourglass;
          podColor = Colors.orange;
        case 'failed':
          podIcon = BootstrapIcons.xCircleFill;
          podColor = Colors.red;
        default:
          podIcon = BootstrapIcons.questionCircle;
          podColor = Colors.gray;
      }

      return TreeItem<K8sTreeNode>(
        data: K8sTreeNode(
          id: 'pod:$namespace:$deployment:$name',
          label: name,
          icon: podIcon,
          iconColor: podColor,
          data: pod,
        ),
        expanded: false,
        children: [],
      );
    }).toList();

    final updatedChildren = List<TreeItem<K8sTreeNode>>.from(
      _treeItems[nsIndex].children.cast<TreeItem<K8sTreeNode>>(),
    );
    updatedChildren[depIndex] = TreeItem<K8sTreeNode>(
      data: updatedChildren[depIndex].data,
      expanded: true,
      children: newChildren,
    );

    setState(() {
      _treeItems[nsIndex] = TreeItem<K8sTreeNode>(
        data: _treeItems[nsIndex].data,
        expanded: _treeItems[nsIndex].expanded,
        children: updatedChildren,
      );
    });
  }

  void _onItemExpand(TreeItem<K8sTreeNode> item) {
    final id = item.data.id;
    if (id.startsWith('ns:')) {
      final namespace = id.substring(3);
      _loadDeployments(namespace, item);
    } else if (id.startsWith('dep:')) {
      final parts = id.split(':');
      if (parts.length >= 3) {
        final namespace = parts[1];
        final deployment = parts[2];
        _loadPods(namespace, deployment, item);
      }
    }
  }

  void _onItemTap(TreeItem<K8sTreeNode> item) {
    final id = item.data.id;
    if (id.startsWith('ns:')) {
      final namespace = id.substring(3);
      context.go('/k8s/namespace/$namespace');
    } else if (id.startsWith('dep:')) {
      final parts = id.split(':');
      if (parts.length >= 3) {
        final namespace = parts[1];
        final deployment = parts[2];
        context.go('/k8s/namespace/$namespace/deployment/$deployment');
      }
    } else if (id.startsWith('pod:')) {
      final parts = id.split(':');
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
                    : TreeView<K8sTreeNode>(
                        shrinkWrap: true,
                        branchLine: BranchLine.line,
                        nodes: _treeItems,
                        onSelectionChanged: TreeView.defaultSelectionHandler(
                          _treeItems,
                          (value) {
                            setState(() {
                              _treeItems = value.cast<TreeItem<K8sTreeNode>>();
                            });
                          },
                        ),
                        builder: (context, node) {
                          final item = node as TreeItem<K8sTreeNode>;
                          final data = item.data;
                          final isExpanded = item.expanded;
                          // 根据节点类型判断是否可以展开（namespace 和 deployment 可以展开）
                          final canExpand =
                              data.id.startsWith('ns:') ||
                              data.id.startsWith('dep:');

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
                                              .cast<TreeItem<K8sTreeNode>>();
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
