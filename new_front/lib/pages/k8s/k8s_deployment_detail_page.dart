import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals.dart';
import 'package:signals/signals_flutter.dart';

import '../../service/k8s_service_api.dart';
import '../../service/log_service_api.dart';
import '../../service/nacos_service_api.dart';

class K8sDeploymentDetailPage extends StatefulWidget {
  final K8sDeploymentsDataItem? deployment;
  final String? namespace;

  K8sDeploymentDetailPage({this.namespace, this.deployment, super.key});

  @override
  State<StatefulWidget> createState() => _K8sDeploymentDetailPage();
}

class _K8sDeploymentDetailPage extends State<K8sDeploymentDetailPage> {
  var podsState = Signal<K8sPodsResponse?>(null);
  var logPathInfoState = Signal<DeploymentLogPathResponse?>(null);
  final _isLoadingStatus = Signal(true);
  final _fullLogState = Signal<CheckboxState>(.unchecked);
  final _selectedNacosNamespace = Signal<String?>(null);
  final _configsOfNacosNamespace = Signal<NacosConfigResponse?>(null);

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
    var nr = await getDeploymentLogPathConfig(
      k8sNamespace: widget.namespace!,
      k8sDeployment: widget.deployment!.name,
    );
    logPathInfoState.value = nr;
  }

  @override
  Widget build(BuildContext context) {
    var isLoading = _isLoadingStatus.watch(context);
    var r = podsState.watch(context);
    var logPathInfo = logPathInfoState.watch(context);

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
    var selectedNacosNamespace = _selectedNacosNamespace.watch(context);
    var configsOfNacosNamespace = _configsOfNacosNamespace.watch(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 4,
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              spacing: 20,
              children: [
                Expanded(
                  child: TextField(
                    placeholder: Text(
                      logPathInfo == null
                          ? '/app/logs/'
                          : logPathInfo.data!.logPath,
                    ),
                  ),
                ),
                Checkbox(
                  state: state,
                  onChanged: (value) {
                    _fullLogState.value = value;
                  },
                  trailing: const Text('拉取全量日志'),
                ),
              ],
            ),
          ),
          Card(
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
          Column(
            children: [
              Text('Pod 列表:').h4,
              ...r.data!.items.map((e) {
                return Card(
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      Text('name: ${e.name}'),
                      Text('namespace: ${e.namespace}'),
                      Text('status: ${e.status}'),
                      Text('ip: ${e.podIP}'),
                      Text('node: ${e.nodeName}'),
                      Text('restartCount: ${e.restartCount}'),
                      Text('creationTimestamp: ${e.creationTimestamp}'),
                    ],
                  ),
                );
              }),
            ],
          ),
          Row(
            mainAxisAlignment: .center,
            children: [
              Button.primary(
                child: Text('配置nacos关联关系'),
                onPressed: () async {
                  await nacosLogin();
                  var r = await getNacosNamespaces();
                  if (r.data == null || r.data!.isEmpty) {
                    return;
                  }
                  var _list = r.data!.map((e) {
                    return SelectItemButton(
                      value: e.namespace,
                      child: Text(e.namespaceShowName),
                    );
                  }).toList();
                  showDialog(
                    context: context,
                    builder: (context) {
                      final FormController controller = FormController();
                      return AlertDialog(
                        title: Text(
                          '配置${widget.deployment!.name}关联的nacos托管配置文件',
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('选择nacos的namespace和配置id'),
                            const Gap(8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Select<String>(
                                itemBuilder: (context, item) {
                                  return Text(item);
                                },
                                popupConstraints: const BoxConstraints(
                                  maxHeight: 300,
                                  maxWidth: 200,
                                ),
                                onChanged: (value) async {
                                  _selectedNacosNamespace.value = value;
                                  if (value == null) {
                                    return;
                                  }
                                  var r = await getNacosConfigs(value);
                                  _configsOfNacosNamespace.value = r;
                                },
                                value: selectedNacosNamespace,
                                placeholder: const Text('选择nacos的namespace'),
                                popup: SelectPopup(
                                  items: SelectItemList(children: _list),
                                ).call,
                              ),
                            ),
                            (configsOfNacosNamespace != null &&
                                    configsOfNacosNamespace!.totalCount > 0)
                                ? ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 400,
                                    ),
                                    child: Select<String>(
                                      itemBuilder: (context, item) {
                                        return Text(item);
                                      },
                                      popupConstraints: const BoxConstraints(
                                        maxHeight: 300,
                                        maxWidth: 200,
                                      ),
                                      onChanged: (value) {
                                        _selectedNacosNamespace.value = value;
                                      },
                                      value: selectedNacosNamespace,
                                      placeholder: const Text(
                                        '选择nacos的namespace',
                                      ),
                                      popup: SelectPopup(
                                        items: SelectItemList(children: _list),
                                      ).call,
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                        actions: [
                          PrimaryButton(
                            child: const Text('保存'),
                            onPressed: () async {
                              Navigator.of(context).pop(controller.values);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              Button.primary(
                child: Text('配置默认日志路径'),
                onPressed: () {
                  _configLogPath(logPathInfo);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _configLogPath(DeploymentLogPathResponse? logPathInfo) {
    showDialog(
      context: context,
      builder: (context) {
        final FormController controller = FormController();
        return AlertDialog(
          title: Text('配置${widget.deployment!.name}默认日志路径'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('配置的日志路径需要确保正确，日志路径应该是绝对路径'),
              const Gap(16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  controller: controller,
                  child: FormTableLayout(
                    rows: [
                      FormField<String>(
                        key: FormKey(#name),
                        label: Text('Name'),
                        child: TextField(
                          initialValue: logPathInfo?.data!.logPath,
                          autofocus: true,
                        ),
                      ),
                    ],
                  ),
                ).withPadding(vertical: 16),
              ),
            ],
          ),
          actions: [
            PrimaryButton(
              child: const Text('保存'),
              onPressed: () async {
                print(controller.values[FormKey(#name)]);
                var logPath = controller.values[FormKey(#name)] as String?;
                if (logPath == null) {
                  return;
                }
                await saveLogPathConfig(
                  id: logPathInfo?.data!.id,
                  k8sNamespace: widget.namespace!,
                  k8sDeployment: widget.deployment!.name,
                  logPath: logPath,
                );
                Navigator.of(context).pop(controller.values);
              },
            ),
          ],
        );
      },
    );
  }
}
