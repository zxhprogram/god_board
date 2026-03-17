import 'package:new_front/base/Response.dart';

import '../config/global_config.dart';

Future<K8sLoginResponse?> k8sLogin() async {
  try {
    var res = await dio.post('/api/k8s/login');
    logger.i(res.data);
    return .fromJson(res.data);
  } catch (e) {
    logger.e('error => ', stackTrace: .current);
    return null;
  }
}

Future<K8sNamespacesResponse> k8sNamespaces() async {
  try {
    var response = await dio.get('/api/k8s/namespaces');
    logger.i(response.data);
    return .fromJson(response.data);
  } catch (e) {
    logger.e(e);
    return .new(code: 500, message: '服务器返回错误');
  }
}

Future<K8sDeploymentsResponse> k8sDeployments(String namespace) async {
  var response = await dio.get('/api/k8s/namespaces/$namespace/deployments');
  logger.i(response.data);
  return .fromJson(response.data);
}

Future<K8sPodsResponse> k8sPods({
  required String namespace,
  required String deployment,
}) async {
  var response = await dio.get(
    '/api/k8s/namespaces/$namespace/deployments/$deployment/pods',
  );
  logger.i(response.data);
  return .fromJson(response.data);
}

class K8sPodsResponse extends Response {
  K8sPodsData? data;

  K8sPodsResponse({required super.code, super.message, this.data});

  factory K8sPodsResponse.fromJson(Map<String, dynamic> json) {
    return .new(
      code: json['code'],
      message: json['message'],
      data: K8sPodsData.fromJson(json['data']),
    );
  }
}

Future<void> saveK8sNacosMapping({
  required String k8sNamespace,
  required String k8sDeployment,
  required String nacosNamespace,
  required String nacosConfigId,
}) async {
  var data = {
    'k8sNamespace': k8sNamespace,
    'k8sDeployment': k8sDeployment,
    'nacosNamespace': nacosNamespace,
    'nacosConfigId': nacosConfigId,
  };
  var response = await dio.post('/api/mappings/k8s-nacos', data: data);
  logger.i(response.data);
}

class K8sPodsData {
  List<K8sPodsDataItem> items;
  int total;

  K8sPodsData({required this.items, required this.total});

  factory K8sPodsData.fromJson(Map<String, dynamic> json) {
    return .new(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => K8sPodsDataItem.fromJson(e))
          .toList(),
      total: json['total'],
    );
  }
}

class K8sPodsDataItem {
  String name;
  String namespace;
  String status;
  String phase;
  String podIP;
  String nodeName;
  int restartCount;
  String creationTimestamp;
  Map<String, dynamic>? labels;
  Map<String, dynamic>? annotations;
  dynamic? containers;

  K8sPodsDataItem({
    required this.name,
    required this.namespace,
    required this.status,
    required this.phase,
    required this.podIP,
    this.labels,
    required this.creationTimestamp,
    this.containers,
    this.annotations,
    required this.nodeName,
    required this.restartCount,
  });

  factory K8sPodsDataItem.fromJson(Map<String, dynamic> json) {
    return .new(
      name: json['name'],
      namespace: json['namespace'],
      status: json['status'],
      phase: json['phase'],
      podIP: json['podIP'],
      creationTimestamp: json['creationTimestamp'],
      nodeName: json['nodeName'],
      restartCount: json['restartCount'],
    );
  }
}

class K8sDeploymentsResponse extends Response {
  K8sDeploymentsData? data;

  K8sDeploymentsResponse({required super.code, super.message, this.data});

  factory K8sDeploymentsResponse.fromJson(Map<String, dynamic> json) {
    return .new(
      code: json['code'],
      message: json['message'],
      data: K8sDeploymentsData.fromJson(json['data']),
    );
  }
}

class K8sDeploymentsData {
  List<K8sDeploymentsDataItem> items;
  int total;

  K8sDeploymentsData({required this.items, required this.total});

  factory K8sDeploymentsData.fromJson(Map<String, dynamic> json) {
    return .new(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => K8sDeploymentsDataItem.fromJson(e))
          .toList(),
      total: json['total'],
    );
  }
}

class K8sDeploymentsDataItem {
  String name;
  String namespace;
  int replicas;
  int availableReplicas;
  int readyReplicas;
  String status;
  String creationTimestamp;
  Map<String, dynamic>? labels;
  Map<String, dynamic>? annotations;
  List<K8sContainer> containers;

  K8sDeploymentsDataItem({
    required this.name,
    required this.namespace,
    required this.replicas,
    required this.annotations,
    required this.availableReplicas,
    required this.containers,
    required this.creationTimestamp,
    required this.labels,
    required this.readyReplicas,
    required this.status,
  });

  factory K8sDeploymentsDataItem.fromJson(Map<String, dynamic> json) {
    return .new(
      name: json['name'],
      namespace: json['namespace'],
      replicas: json['replicas'],
      annotations: json['annotations'],
      availableReplicas: json['availableReplicas'],
      containers: (json['containers'] as List<dynamic>? ?? [])
          .map((e) => K8sContainer.fromJson(e))
          .toList(),
      creationTimestamp: json['creationTimestamp'],
      labels: json['labels'],
      readyReplicas: json['readyReplicas'],
      status: json['status'],
    );
  }
}

class K8sContainer {
  String name;
  String image;
  String imagePullPolicy;
  List<dynamic>? command;
  List<dynamic>? args;
  String workingDir;
  List<K8sPort> ports;
  List<K8sEnv> env;
  K8sResource resources;

  K8sContainer({
    required this.name,
    required this.image,
    required this.imagePullPolicy,
    required this.command,
    required this.args,
    required this.env,
    required this.ports,
    required this.resources,
    required this.workingDir,
  });

  factory K8sContainer.fromJson(Map<String, dynamic> json) {
    return .new(
      name: json['name'],
      image: json['image'],
      imagePullPolicy: json['imagePullPolicy'],
      command: json['command'],
      args: json['args'],
      env: (json['env'] as List<dynamic>? ?? [])
          .map((e) => K8sEnv.fromJson(e))
          .toList(),
      ports: (json['ports'] as List<dynamic>? ?? [])
          .map((e) => K8sPort.fromJson(e))
          .toList(),
      resources: K8sResource.fromJson(json['resources']),
      workingDir: json['workingDir'],
    );
  }
}

class K8sEnv {
  String name;
  String value;

  K8sEnv({required this.name, required this.value});

  factory K8sEnv.fromJson(Map<String, dynamic> json) {
    return .new(name: json['name'], value: json['value']);
  }

  @override
  String toString() {
    return '{name:$name,value:$value}';
  }
}

class K8sResource {
  R limits;
  R requests;

  K8sResource({required this.limits, required this.requests});

  factory K8sResource.fromJson(Map<String, dynamic> json) {
    return .new(
      limits: R.fromJson(json['limits']),
      requests: R.fromJson(json['requests']),
    );
  }

  @override
  String toString() {
    return '{limits:$limits,request:$requests}';
  }
}

class R {
  String cpu;
  String memory;

  R({required this.cpu, required this.memory});

  factory R.fromJson(Map<String, dynamic> json) {
    return .new(cpu: json['cpu'], memory: json['memory']);
  }

  @override
  String toString() {
    return '{cpu:$cpu,memory:$memory}';
  }
}

class K8sPort {
  String name;
  int containerPort;
  String protocol;

  K8sPort({
    required this.name,
    required this.containerPort,
    required this.protocol,
  });

  factory K8sPort.fromJson(Map<String, dynamic> json) {
    return .new(
      name: json['name'],
      containerPort: json['containerPort'],
      protocol: json['protocol'],
    );
  }

  @override
  String toString() {
    return '{name:$name,containerPort:$containerPort,protocol:$protocol}';
  }
}

class K8sNamespacesResponse extends Response {
  K8sNamespacesData? data;

  K8sNamespacesResponse({required super.code, super.message, this.data});

  factory K8sNamespacesResponse.fromJson(Map<String, dynamic> json) {
    return .new(
      code: json['code'],
      message: json['message'],
      data: K8sNamespacesData.fromJson(json['data']),
    );
  }
}

class K8sNamespacesData {
  List<K8sNamespaceDataItem> items;

  K8sNamespacesData({required this.items});

  factory K8sNamespacesData.fromJson(Map<String, dynamic> json) {
    return .new(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => K8sNamespaceDataItem.fromJson(e))
          .toList(),
    );
  }
}

class K8sNamespaceDataItem {
  String name;
  String status;
  String creationTimestamp;
  Map<String, dynamic> lables;
  Map<String, dynamic>? annotations;

  K8sNamespaceDataItem({
    required this.name,
    required this.status,
    required this.creationTimestamp,
    required this.lables,
    required this.annotations,
  });

  factory K8sNamespaceDataItem.fromJson(Map<String, dynamic> json) {
    return .new(
      name: json['name'],
      status: json['status'],
      creationTimestamp: json['creationTimestamp'],
      lables: json['labels'],
      annotations: json['annotations'],
    );
  }
}

class K8sLoginResponse extends Response {
  K8sLoginData? data;

  K8sLoginResponse({required super.code, super.message, this.data});

  factory K8sLoginResponse.fromJson(Map<String, dynamic> json) {
    return .new(
      code: json['code'],
      message: json['message'],
      data: K8sLoginData.fromJson(json['data']),
    );
  }
}

class K8sLoginData {
  String apiServer;
  String message;

  K8sLoginData({required this.apiServer, required this.message});

  factory K8sLoginData.fromJson(Map<String, dynamic> json) {
    return .new(apiServer: json['apiServer'], message: json['message']);
  }
}
