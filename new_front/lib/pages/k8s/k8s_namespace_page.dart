import 'package:flutter/material.dart' show ListTile;
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../config/global_config.dart';
import '../../service/k8s_service_api.dart';

class K8sNamespacePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _K8sNamespacePageState();
}

class K8sTreeNode {
  String identify;
  K8sTreeNodeType type;
  String data;

  K8sTreeNode({required this.identify, required this.type, required this.data});
}

enum K8sTreeNodeType { namespace, deployment, pod }

class _K8sNamespacePageState extends State<K8sNamespacePage> {
  final _isLoadingStatus = Signal(true);
  final rr = Signal<K8sNamespacesResponse?>(null);
  final treeNodes = Signal<List<TreeItem<K8sTreeNode>>>([]);
  final _selectedIndex = Signal(-1);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    await k8sLogin();
    var r = await k8sNamespaces();
    rr.value = r;
    _isLoadingStatus.value = false;
  }

  @override
  void dispose() {
    logger.i('k8spage disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var isLoading = _isLoadingStatus.watch(context);
    var r = rr.watch(context);
    if (isLoading) {
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
    if (r!.code != 200) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text(r.message!)],
        ),
      );
    }
    var i = _selectedIndex.watch(context);
    return SizedBox(
      width: 300,
      child: ListView.builder(
        itemBuilder: (context, index) {
          if (r.data == null || r.data!.items.isEmpty) {
            return Container();
          }
          return MouseRegion(
            onEnter: (_) {
              print(index);
            },
            child: ListTile(
              selected: i == index,
              selectedColor: Colors.blue,
              dense: true,
              visualDensity: .compact,
              onTap: () {
                _selectedIndex.value = index;
                context.go('/k8s/namespace/${r.data!.items[index].name}');
              },
              leading: HoverCard(
                wait: .new(seconds: 2),
                hoverBuilder: (BuildContext context) {
                  return SurfaceCard(
                    child: Basic(
                      leading: Icon(SimpleIcons.kubernetes),
                      title: Text(r.data!.items[index].name),
                      content: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text('状态:${r.data!.items[index].status}'),
                          Text(
                            '创建时间:${r.data!.items[index].creationTimestamp}',
                          ),
                          Text('标签:${r.data!.items[index].lables}'),
                          Text('注解:${r.data!.items[index].lables}'),
                        ],
                      ),
                    ),
                  ).sized(width: 300);
                },
                child: SizedBox(
                  width: 250,
                  child: Row(
                    spacing: 4,
                    children: [
                      i == index
                          ? const Icon(BootstrapIcons.folder2Open)
                          : const Icon(BootstrapIcons.folder2),
                      Text(r.data!.items[index].name),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        itemCount: r.data == null ? 0 : r.data!.items.length,
      ),
    );
  }
}
