import 'dart:async';
import 'dart:io';

import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../config/global_config.dart';
import '../../service/k8s_service_api.dart';
import '../../service/log_service_api.dart';
import '../../service/nacos_service_api.dart';
import '../../service/node_service_api.dart';

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
  final _selectedNacosNamespaceDataId = Signal<String?>(null);
  final _configsOfNacosNamespace = Signal<NacosConfigResponse?>(null);
  final serviceListState = Signal<List<SelectItemButton<String>>>([]);
  final _selectedNacosService = Signal<String?>(null);
  final _logPathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    podsState.dispose();
    logPathInfoState.dispose();
    _isLoadingStatus.dispose();
    _fullLogState.dispose();
    _selectedNacosNamespace.dispose();
    _selectedNacosNamespaceDataId.dispose();
    _configsOfNacosNamespace.dispose();
    serviceListState.dispose();
    super.dispose();
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
    var pullMap = pullingLogPodMap.watch(context);
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
                    controller: _logPathController,
                    initialValue:
                        (logPathInfo == null || logPathInfo.data == null)
                        ? '/app/logs/'
                        : logPathInfo.data!.logPath,
                    placeholder: Text(
                      (logPathInfo == null || logPathInfo.data == null)
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
                Column(
                  spacing: 1,
                  children: [
                    Card(
                      child: Row(
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: .start,
                            children: [
                              Text(widget.deployment!.name).h3,
                              Text('ns: ${widget.deployment!.namespace}'),
                            ],
                          ),
                          Container(
                            padding: .all(10),
                            decoration: BoxDecoration(
                              borderRadius: .all(.circular(20)),
                              border: .all(width: 1, color: Colors.green),
                            ),
                            child: Text(
                              widget.deployment!.status,
                              style: TextStyle(
                                foreground: Paint()..color = Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: .center,
                      children: [
                        Card(
                          filled: true,
                          fillColor: Colors.blue,
                          child: Column(
                            children: [
                              Text(
                                'REPLICAS',
                                style: TextStyle(
                                  foreground: Paint()..color = Colors.white,
                                ),
                              ).bold.withOpacity(0.5),
                              Text(
                                '${widget.deployment!.replicas}/${widget.deployment!.availableReplicas} Ready',
                                style: TextStyle(
                                  foreground: Paint()..color = Colors.white,
                                ),
                              ).bold,
                            ],
                          ),
                        ),
                        Card(
                          filled: true,
                          fillColor: Colors.blue,
                          child: Column(
                            children: [
                              Text(
                                'CREATED',
                                style: TextStyle(
                                  foreground: Paint()..color = Colors.white,
                                ),
                              ).bold.withOpacity(0.5),
                              Text(
                                widget.deployment!.creationTimestamp,
                                style: TextStyle(
                                  foreground: Paint()..color = Colors.white,
                                ),
                              ).bold,
                            ],
                          ),
                        ),
                        Card(
                          filled: true,
                          fillColor: Colors.blue,
                          child: Column(
                            children: [
                              Text(
                                'CPU',
                                style: TextStyle(
                                  foreground: Paint()..color = Colors.white,
                                ),
                              ).bold.withOpacity(0.5),
                              Text(
                                '${widget.deployment!.containers[0].resources.requests.cpu}/${widget.deployment!.containers[0].resources.limits.cpu}',
                                style: TextStyle(
                                  foreground: Paint()..color = Colors.white,
                                ),
                              ).bold,
                            ],
                          ),
                        ),
                        Card(
                          filled: true,
                          fillColor: Colors.blue,
                          child: Column(
                            children: [
                              Text(
                                'MEMORY',
                                style: TextStyle(
                                  foreground: Paint()..color = Colors.white,
                                ),
                              ).bold.withOpacity(0.5),
                              Text(
                                '${widget.deployment!.containers[0].resources.requests.memory}/${widget.deployment!.containers[0].resources.limits.memory}',
                                style: TextStyle(
                                  foreground: Paint()..color = Colors.white,
                                ),
                              ).bold,
                            ],
                          ),
                        ),
                      ],
                    ),
                    Card(
                      borderColor: Colors.black,
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Row(
                            children: [
                              Icon(SimpleIcons.codepen),
                              Text('IMAGE'),
                            ],
                          ),
                          Text('${widget.deployment!.containers[0].image}'),
                          Text(
                            'Pull Policy: ${widget.deployment!.containers[0].imagePullPolicy}',
                          ),
                        ],
                      ),
                    ),
                    Card(
                      borderColor: Colors.black,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(SimpleIcons.chainlink),
                              Text('NETWORK & PORTS'),
                            ],
                          ),
                          Text(
                            'ports : ${widget.deployment!.containers[0].ports}',
                          ),
                        ],
                      ),
                    ),
                    Card(
                      borderColor: Colors.black,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(SimpleIcons.termius),
                              Text('COMMAND'),
                            ],
                          ),
                          Text(
                            'command : ${widget.deployment!.containers[0].command}',
                          ),
                        ],
                      ),
                    ),
                    Card(
                      borderColor: Colors.black,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(SimpleIcons.paramountplus),
                              Text('ARGS'),
                            ],
                          ),
                          Text(
                            'args : ${widget.deployment!.containers[0].args}',
                          ),
                        ],
                      ),
                    ),
                    Card(
                      borderColor: Colors.black,
                      child: Column(
                        children: [
                          Row(
                            children: [Icon(SimpleIcons.dotenv), Text('ENV')],
                          ),
                          Text('env : ${widget.deployment!.containers[0].env}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text('Pod 列表:').h4,
              ...r.data!.items.map((e) {
                return Card(
                  child: Row(
                    children: [
                      Expanded(
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
                      ),
                      Button.ghost(
                        key: UniqueKey(),
                        child: pullMap[e.name] == null
                            ? Icon(
                                Icons.play_circle,
                                size: 50,
                                color: Colors.green,
                              )
                            : Icon(
                                Icons.pause_circle,
                                size: 50,
                                color: Colors.red,
                              ),
                        onPressed: () {
                          startOrStopLogStream(pullMap, e);
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          K8sNacosInformationCard(
            namespace: widget.namespace!,
            deployment: widget.deployment!.name,
            key: UniqueKey(),
          ),
          Row(
            mainAxisAlignment: .center,
            children: [
              Button.primary(
                child: Text('配置nacos关联关系'),
                onPressed: () async {
                  _configK8sMappingNacos();
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

  /// 将缓冲区内容写入文件
  Future<void> _flushBufferToFile(List<String> buffer, File file) async {
    if (buffer.isEmpty) return;
    try {
      final content = buffer.join('\n') + '\n';
      await file.writeAsString(content, mode: FileMode.append, flush: true);
    } catch (e, stackTrace) {
      logger.e('写入日志文件失败: $e', stackTrace: stackTrace);
    }
  }

  /// 刷新指定 Pod 的日志缓冲区到文件
  Future<void> _flushPodBuffer(String podName, File file) async {
    final buffer = podLogBuffers[podName];
    if (buffer == null || buffer.isEmpty) return;

    // 复制并清空缓冲区
    final linesToWrite = List<String>.from(buffer);
    buffer.clear();

    await _flushBufferToFile(linesToWrite, file);
  }

  void startOrStopLogStream(
    Map<String, WebSocketChannel?> pullMap,
    K8sPodsDataItem e,
  ) async {
    logger.i('开始输出日志 pullMap = $pullMap, e = $e}');
    if (pullMap[e.name] != null) {
      var ws = pullMap[e.name]!;
      // 先刷新缓冲区再关闭连接，确保数据不丢失
      await _flushPodBuffer(e.name, _podLogFiles[e.name]!);
      _cleanupPodLogResources(e.name);
      ws.sink.close(status.normalClosure);
      pullingLogPodMap.value = Map<String, WebSocketChannel?>.from(
        pullMap..remove(e.name),
      );
      return;
    }
    var logStreamResponse = await registerLogStream(
      k8sNamespace: widget.namespace!,
      podName: e.name,
      logPath: _logPathController.text,
    );
    logger.i('logStreamResponse = $logStreamResponse');
    if (logStreamResponse.wsUrl == null) {
      logger.e('wsUrl is null');
      return;
    }

    final fileName =
        '${e.name}-${_logPathController.text.substring(_logPathController.text.lastIndexOf('/') + 1)}.log';

    logger.i('fileName = $fileName');
    final file = File(fileName);
    try {
      if (file.existsSync()) {
        file.deleteSync();
      }
      file.createSync();
      _podLogFiles[e.name] = file;
    } catch (e, stackTrace) {
      logger.e('文件操作失败: $e', stackTrace: stackTrace);
      return;
    }

    // 初始化该 Pod 的缓冲区
    podLogBuffers[e.name] = <String>[];

    // 启动定时刷新，每 500ms 强制刷新一次，避免数据滞留
    flushTimerMap[e.name]?.cancel();
    flushTimerMap[e.name] = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _flushPodBuffer(e.name, file),
    );

    try {
      final ws = WebSocketChannel.connect(Uri.parse(logStreamResponse.wsUrl!));
      ws.stream.listen(
        (message) {
          final buffer = podLogBuffers[e.name];
          if (buffer == null) return;

          buffer.add(message.toString());

          // 达到阈值时立即刷新
          if (buffer.length >= bufferSizeThreshold) {
            final linesToWrite = List<String>.from(buffer);
            buffer.clear();
            _flushBufferToFile(linesToWrite, file);
          }
        },
        onError: (error) {
          logger.e('ws 返回错误: $error', stackTrace: StackTrace.current);
        },
        onDone: () async {
          logger.i('ws 正常结束，pod: ${e.name}');
          // 连接结束时刷新剩余数据
          await _flushPodBuffer(e.name, file);
          _cleanupPodLogResources(e.name);
        },
      );
      pullingLogPodMap.value = Map<String, WebSocketChannel?>.from(
        pullingLogPodMap.value,
      )..[e.name] = ws;
    } catch (er, stackTrace) {
      logger.e('日志监听失败: $er', stackTrace: stackTrace);
      _cleanupPodLogResources(e.name);
    }
  }

  /// 清理 Pod 日志相关资源
  void _cleanupPodLogResources(String podName) {
    flushTimerMap[podName]?.cancel();
    flushTimerMap.remove(podName);
    podLogBuffers.remove(podName);
    _podLogFiles.remove(podName);
  }

  // 存储每个 Pod 对应的日志文件
  final _podLogFiles = <String, File>{};

  void _configK8sMappingNacos() async {
    var mappingConfig = await getK8sNacosMapping(
      namespace: widget.namespace!,
      deployment: widget.deployment!.name,
    );
    if (mappingConfig.data != null) {
      _selectedNacosNamespace.value = mappingConfig.data!.nacosNamespace;
      _selectedNacosNamespaceDataId.value = mappingConfig.data!.nacosConfigId;
      var r = await getNacosConfigs(mappingConfig.data!.nacosNamespace);
      _configsOfNacosNamespace.value = r;
    }

    await nacosLogin();
    var r = await getNacosNamespaces();
    if (r.data == null || r.data!.isEmpty) {
      return;
    }
    var _list = r.data!.map((e) {
      return SelectItemButton<String>(
        value: e.namespace,
        child: Text(e.namespaceShowName),
      );
    }).toList();
    if (_selectedNacosNamespace.value != null) {
      var serviceListResponse = await getNacosServices(
        _selectedNacosNamespace.value!,
      );
      serviceListState.value = serviceListResponse.data!.serviceList.map((e) {
        return SelectItemButton<String>(value: e.name, child: Text(e.name));
      }).toList();
    }
    var responseOfNacosService = await getK8sNacosServiceMapping(
      k8sNamespace: widget.namespace!,
      k8sDeployment: widget.deployment!.name,
    );
    if (responseOfNacosService.data != null) {
      _selectedNacosService.value =
          responseOfNacosService.data!.nacosServiceName;
    }
    showDialog(
      context: context,
      builder: (context) {
        var selectedNacosNamespace = _selectedNacosNamespace.watch(context);
        var configsOfNacosNamespace = _configsOfNacosNamespace.watch(context);
        var selectedNacosNamespaceDataId = _selectedNacosNamespaceDataId.watch(
          context,
        );
        var selectedNacosService = _selectedNacosService.watch(context);
        var serviceList = serviceListState.watch(context);
        var nacosDataIdList = configsOfNacosNamespace == null
            ? <SelectItemButton<String>>[]
            : configsOfNacosNamespace.pageItems!.map((e) {
                return SelectItemButton<String>(
                  value: e.dataId,
                  child: Text(e.dataId),
                );
              }).toList();
        final FormController controller = FormController();
        return AlertDialog(
          title: Text('配置${widget.deployment!.name}关联的nacos托管配置文件'),
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

                    var serviceListResponse = await getNacosServices(value);
                    serviceListState.value = serviceListResponse
                        .data!
                        .serviceList
                        .map((e) {
                          return SelectItemButton<String>(
                            value: e.name,
                            child: Text(e.name),
                          );
                        })
                        .toList();
                  },
                  value: selectedNacosNamespace,
                  placeholder: const Text('选择nacos的namespace'),
                  popup: SelectPopup(
                    items: SelectItemList(children: _list),
                  ).call,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child:
                    (configsOfNacosNamespace != null &&
                        configsOfNacosNamespace.totalCount > 0)
                    ? Select<String>(
                        itemBuilder: (context, item) {
                          return Text(item);
                        },
                        popupConstraints: const BoxConstraints(
                          maxHeight: 300,
                          maxWidth: 200,
                        ),
                        onChanged: (value) {
                          _selectedNacosNamespaceDataId.value = value;
                        },
                        value: selectedNacosNamespaceDataId,
                        placeholder: const Text('选择nacos的dataId'),
                        popup: SelectPopup(
                          items: SelectItemList(children: nacosDataIdList),
                        ).call,
                      )
                    : Container(),
              ),
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
                    _selectedNacosService.value = value;
                  },
                  value: selectedNacosService,
                  placeholder: const Text('选择nacos的实例服务'),
                  popup: SelectPopup(
                    items: SelectItemList(children: serviceList),
                  ).call,
                ),
              ),
            ],
          ),
          actions: [
            PrimaryButton(
              child: const Text('保存'),
              onPressed: () async {
                if (selectedNacosNamespaceDataId == null ||
                    selectedNacosNamespace == null) {
                  return;
                }
                await saveK8sNacosMapping(
                  k8sNamespace: widget.namespace!,
                  k8sDeployment: widget.deployment!.name,
                  nacosNamespace: selectedNacosNamespace,
                  nacosConfigId: selectedNacosNamespaceDataId,
                );
                if (selectedNacosService != null) {
                  await saveK8sNacosServiceMapping(
                    k8sNamespace: widget.namespace!,
                    k8sDeployment: widget.deployment!.name,
                    nacosNamespace: selectedNacosNamespace,
                    nacosServiceName: selectedNacosService,
                  );
                }
                Navigator.of(context).pop(controller.values);
              },
            ),
          ],
        );
      },
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
                          initialValue: logPathInfo?.data?.logPath,
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
                var logPath = controller.values[FormKey(#name)] as String?;
                if (logPath == null) {
                  return;
                }
                await saveLogPathConfig(
                  id: logPathInfo?.data?.id,
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

class K8sNacosInformationCard extends StatefulWidget {
  final String namespace;
  final String deployment;

  K8sNacosInformationCard({
    required this.namespace,
    required this.deployment,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _K8sNacosInformationCard();
}

class _K8sNacosInformationCard extends State<K8sNacosInformationCard> {
  final _mappingConfigState = Signal<K8sNacosMappingData?>(null);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    var mappingConfig = await getK8sNacosMapping(
      namespace: widget.namespace,
      deployment: widget.deployment,
    );
    _mappingConfigState.value = mappingConfig.data;
  }

  @override
  Widget build(BuildContext context) {
    var mappingConfig = _mappingConfigState.watch(context);
    return Card(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text('nacos namespace :${mappingConfig?.nacosNamespace}'),
          Text('nacos dataId :${mappingConfig?.nacosConfigId}'),
          NacosConfigContent(
            namespace: mappingConfig?.nacosNamespace,
            configId: mappingConfig?.nacosConfigId,
            key: ValueKey(
              '${widget.namespace}-${mappingConfig?.nacosConfigId}',
            ),
          ),
        ],
      ),
    );
  }
}

class NacosConfigContent extends StatefulWidget {
  final String? namespace;
  final String? configId;

  NacosConfigContent({required this.namespace, this.configId, super.key});

  @override
  State<NacosConfigContent> createState() => _NacosConfigContentState();
}

class _NacosConfigContentState extends State<NacosConfigContent> {
  final contentState = Signal<NacosConfigDetailResponse?>(null);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    if (widget.configId == null || widget.namespace == null) {
      return;
    }
    var response = await getNacosConfigDetail(
      namespace: widget.namespace!,
      serviceName: widget.configId!,
    );
    contentState.value = response;
  }

  @override
  Widget build(BuildContext context) {
    var content = contentState.watch(context);
    return Card(child: SelectableText(content?.data?.content ?? ''));
  }
}
