import 'package:flutter/material.dart' show ListTile;
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';

import '../../service/k8s_service_api.dart';
import 'k8s_deployment_detail_page.dart';

class K8sNamespaceDetailPage extends StatefulWidget {
  final String namespace;

  K8sNamespaceDetailPage({required this.namespace, super.key});

  @override
  State<K8sNamespaceDetailPage> createState() => _K8sNamespaceDetailPageState();
}

class _K8sNamespaceDetailPageState extends State<K8sNamespaceDetailPage> {
  final _deploymentsState = signal<K8sDeploymentsResponse?>(null);
  final _isLoadingStatus = Signal(true);
  final _selectedIndex = Signal(-1);
  final _selectedDeployment = Signal<String?>(null);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    var r = await k8sDeployments(widget.namespace);
    _deploymentsState.value = r;
    _isLoadingStatus.value = false;
  }

  @override
  Widget build(BuildContext context) {
    var isLoading = _isLoadingStatus.watch(context);
    var r = _deploymentsState.watch(context);
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
    var deployment = _selectedDeployment.watch(context);
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: ListView.builder(
            itemBuilder: (context, index) {
              return ListTile(
                selected: i == index,
                selectedColor: Colors.blue,
                dense: true,
                visualDensity: .compact,
                onTap: () {
                  _selectedIndex.value = index;
                  _selectedDeployment.value = r.data!.items[index].name;
                },
                leading: SizedBox(
                  width: 100,
                  child: Row(
                    children: [
                      i == index
                          ? Icon(BootstrapIcons.folder2Open)
                          : Icon(BootstrapIcons.folder2),
                      Text(r.data!.items[index].name),
                    ],
                  ),
                ),
              );
            },
            itemCount: r.data!.total,
          ),
        ),
        Expanded(
          child: K8sDeploymentDetailPage(
            namespace: widget.namespace,
            deployment: deployment,
            key: ValueKey('${widget.namespace}-$deployment'),
          ),
        ),
      ],
    );
  }
}
