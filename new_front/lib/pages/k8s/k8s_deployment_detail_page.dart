import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals.dart';
import 'package:signals/signals_flutter.dart';

import '../../service/k8s_service_api.dart';

class K8sDeploymentDetailPage extends StatefulWidget {
  final String? deployment;
  final String? namespace;

  K8sDeploymentDetailPage({this.namespace, this.deployment, super.key});

  @override
  State<StatefulWidget> createState() => _K8sDeploymentDetailPage();
}

class _K8sDeploymentDetailPage extends State<K8sDeploymentDetailPage> {
  var podsState = Signal<K8sPodsResponse?>(null);
  final _isLoadingStatus = Signal(true);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    if (widget.deployment == null || widget.deployment!.isEmpty) {
      return;
    }
    var r = await k8sPods(
      namespace: widget.namespace!,
      deployment: widget.deployment!,
    );
    podsState.value = r;
    _isLoadingStatus.value = false;
  }

  @override
  Widget build(BuildContext context) {
    var isLoading = _isLoadingStatus.watch(context);
    var r = podsState.watch(context);
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
    // return Center(child: Text('data1'));
    return ListView.builder(
      itemBuilder: (context, index) {
        return Card(
          borderColor: Colors.blue,
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text('name: ${r.data!.items[index].name}'),
              Text('namepsace: ${r.data!.items[index].namespace}'),
              Text('status: ${r.data!.items[index].status}'),
              Text('ip: ${r.data!.items[index].podIP}'),
              Text('node: ${r.data!.items[index].nodeName}'),
              Text('restartCount: ${r.data!.items[index].restartCount}'),
              Text(
                'creationTimestamp: ${r.data!.items[index].creationTimestamp}',
              ),
            ],
          ),
        );
      },
      itemCount: r.data!.items.length,
    );
  }
}
