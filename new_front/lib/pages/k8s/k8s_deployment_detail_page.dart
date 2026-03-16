import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals.dart';
import 'package:signals/signals_flutter.dart';

import '../../service/k8s_service_api.dart';

class K8sDeploymentDetailPage extends StatefulWidget {
  final K8sDeploymentsDataItem? deployment;
  final String? namespace;

  K8sDeploymentDetailPage({this.namespace, this.deployment, super.key});

  @override
  State<StatefulWidget> createState() => _K8sDeploymentDetailPage();
}

class _K8sDeploymentDetailPage extends State<K8sDeploymentDetailPage> {
  var podsState = Signal<K8sPodsResponse?>(null);
  final _isLoadingStatus = Signal(true);
  final _fullLogState = Signal<CheckboxState>(.unchecked);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    if (widget.deployment == null) {
      return;
    }
    var r = await k8sPods(
      namespace: widget.namespace!,
      deployment: widget.deployment!.name,
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
    var state = _fullLogState.watch(context);
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 4,
      children: [
        Checkbox(
          state: state,
          onChanged: (value) {
            _fullLogState.value = value;
          },
          trailing: const Text('拉取全量日志'),
        ),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            child: Card(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text('Deployment information').h4,
                  Text('name: ${widget.deployment!.name}'),
                  Text('namespace : ${widget.deployment!.namespace}'),
                  Text('replicas : ${widget.deployment!.replicas}'),
                  Text(
                    'availableReplicas : ${widget.deployment!.availableReplicas}',
                  ),
                  Text('status : ${widget.deployment!.status}'),
                  Text(
                    'creationTimestamp : ${widget.deployment!.creationTimestamp}',
                  ),
                  Text('image : ${widget.deployment!.containers[0].image}'),
                  Text('name : ${widget.deployment!.containers[0].name}'),
                  Text(
                    'imagePullPolicy : ${widget.deployment!.containers[0].imagePullPolicy}',
                  ),
                  Text('command : ${widget.deployment!.containers[0].command}'),
                  Text('args : ${widget.deployment!.containers[0].args}'),
                  Text('ports : ${widget.deployment!.containers[0].ports}'),
                  Text('env : ${widget.deployment!.containers[0].env}'),
                  Text(
                    'resource : ${widget.deployment!.containers[0].resources}',
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemBuilder: (context, index) {
              return Card(
                borderColor: Colors.blue,
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text('name: ${r.data!.items[index].name}'),
                    Text('namespace: ${r.data!.items[index].namespace}'),
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
          ),
        ),
        Button.primary(child: Text('配置nacos关联关系'), onPressed: () {}),
        Button.primary(child: Text('配置默认日志路径'), onPressed: () {}),
      ],
    );
  }
}
