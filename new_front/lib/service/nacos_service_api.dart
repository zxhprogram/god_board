import '../base/Response.dart';
import '../config/global_config.dart';

Future<NacosLoginResponse?> nacosLogin() async {
  try {
    var res = await dio.post('/api/nacos/login');
    logger.i(res.data);
    return .fromJson(res.data);
  } catch (e) {
    logger.e('error => ', stackTrace: .current);
    return null;
  }
}

// 获取 Nacos namespace 列表
Future<NacosNamespacesResponse> getNacosNamespaces() async {
  final response = await dio.get('/api/nacos/namespaces');
  logger.i(response.data);
  return .fromJson(response.data);
}

Future<NacosConfigResponse> getNacosConfigs(String namespaceId) async {
  var response = await dio.get('/api/nacos/configs?namespaceId=${namespaceId}');
  logger.i(response.data);
  return .fromJson(response.data);
}

Future<NacosServicesResponse> getNacosServices(String namespaceId) async {
  var response = await dio.get('/api/nacos/services?namespaceId=$namespaceId');
  logger.i(response.data);
  return .fromJson(response.data);
}

Future<NacosInstancesResponse> getNacosServiceInstances({
  required String namespace,
  required String serviceName,
}) async {
  var response = await dio.get(
    '/api/nacos/instances?namespaceId=$namespace&serviceName=$serviceName',
  );
  logger.i(response.data);
  return .fromJson(response.data);
}

Future<NacosConfigDetailResponse> getNacosConfigDetail({
  required String namespace,
  required String serviceName,
  String group = 'DEFAULT_GROUP',
}) async {
  var response = await dio.get(
    '/api/nacos/config/detail?namespaceId=$namespace&dataId=$serviceName&group=$group',
  );
  logger.i(response.data);
  return .fromJson(response.data);
}

class NacosConfigDetailResponse extends Response {
  NacosConfigDetailData? data;

  NacosConfigDetailResponse({required super.code, this.data, super.message});

  factory NacosConfigDetailResponse.fromJson(Map<String, dynamic> json) {
    return .new(
      code: json['code'],
      message: json['message'],
      data: NacosConfigDetailData.fromJson(json['data']),
    );
  }
}

class NacosConfigDetailData {
  String dataId;
  String group;
  String namespaceId;
  String content;

  NacosConfigDetailData({
    required this.dataId,
    required this.group,
    required this.namespaceId,
    required this.content,
  });

  factory NacosConfigDetailData.fromJson(Map<String, dynamic> json) {
    return .new(
      dataId: json['dataId'],
      group: json['group'],
      namespaceId: json['namespaceId'],
      content: json['content'],
    );
  }
}

class NacosInstancesResponse extends Response {
  NacosInstancesData? data;

  NacosInstancesResponse({required super.code, super.message, this.data});

  factory NacosInstancesResponse.fromJson(Map<String, dynamic> json) {
    return .new(
      code: json['code'],
      message: json['message'],
      data: NacosInstancesData.fromJson(json['data']),
    );
  }
}

class NacosInstancesData {
  List<NacosInstancesDataItem> list;

  NacosInstancesData({required this.list});

  factory NacosInstancesData.fromJson(Map<String, dynamic> json) {
    return .new(
      list: (json['list'] as List<dynamic>? ?? [])
          .map((e) => NacosInstancesDataItem.fromJson(e))
          .toList(),
    );
  }
}

class NacosInstancesDataItem {
  String instanceId;
  String ip;
  int port;
  int weight;
  bool healthy;
  bool enabled;
  bool ephemeral;
  String clusterName;
  String serviceName;
  dynamic metadata;
  int? instanceHeartBeatInterval;
  int? instanceHeartBeatTimeout;
  int? ipDeleteTimeout;

  NacosInstancesDataItem({
    required this.instanceId,
    required this.ip,
    required this.port,
    required this.weight,
    required this.healthy,
    required this.enabled,
    required this.ephemeral,
    required this.clusterName,
    required this.serviceName,
    this.metadata,
    this.instanceHeartBeatInterval,
    this.instanceHeartBeatTimeout,
    this.ipDeleteTimeout,
  });

  factory NacosInstancesDataItem.fromJson(Map<String, dynamic> json) {
    return .new(
      instanceId: json['instanceId'],
      ip: json['ip'],
      port: json['port'],
      weight: json['weight'],
      healthy: json['healthy'],
      enabled: json['enabled'],
      ephemeral: json['ephemeral'],
      clusterName: json['clusterName'],
      serviceName: json['serviceName'],
    );
  }
}

class NacosServicesResponse extends Response {
  NacosServicesData? data;

  NacosServicesResponse({required super.code, super.message, this.data});

  factory NacosServicesResponse.fromJson(Map<String, dynamic> json) {
    return .new(
      code: json['code'],
      message: json['message'],
      data: NacosServicesData.fromJson(json['data']),
    );
  }
}

class NacosServicesData {
  int count;
  List<NacosServiceDataItem> serviceList;

  NacosServicesData({required this.count, required this.serviceList});

  factory NacosServicesData.fromJson(Map<String, dynamic> json) {
    return .new(
      count: json['count'],
      serviceList: (json['serviceList'] as List<dynamic>? ?? [])
          .map((e) => NacosServiceDataItem.fromJson(e))
          .toList(),
    );
  }
}

class NacosServiceDataItem {
  String name;
  String groupName;
  String clusterName;
  int ipCount;
  int healthyInstanceCount;
  String triggerFlag;

  NacosServiceDataItem({
    required this.name,
    required this.groupName,
    required this.clusterName,
    required this.ipCount,
    required this.healthyInstanceCount,
    required this.triggerFlag,
  });

  factory NacosServiceDataItem.fromJson(Map<String, dynamic> json) {
    return .new(
      name: json['name'],
      groupName: json['groupName'],
      clusterName: json['clusterName'],
      ipCount: json['ipCount'],
      healthyInstanceCount: json['healthyInstanceCount'],
      triggerFlag: json['triggerFlag'],
    );
  }
}

class NacosConfigResponse extends Response {
  int totalCount;
  int pageNumber;
  int pagesAvailable;
  List<NacosConfigDataItem>? pageItems;

  NacosConfigResponse({
    required super.code,
    super.message,
    required this.totalCount,
    required this.pageNumber,
    required this.pagesAvailable,
    required this.pageItems,
  });

  factory NacosConfigResponse.fromJson(Map<String, dynamic> json) {
    return .new(
      code: json['code'],
      message: json['message'],
      totalCount: json['data']['totalCount'],
      pageNumber: json['data']['pageNumber'],
      pagesAvailable: json['data']['pagesAvailable'],
      pageItems: (json['data']['pageItems'] as List<dynamic>? ?? [])
          .map((e) => NacosConfigDataItem.fromJson(e))
          .toList(),
    );
  }
}

class NacosConfigDataItem {
  String id;
  String dataId;
  String group;
  String content;
  String? encryptedDataKey;
  String tenant;
  String? appName;
  String? type;

  NacosConfigDataItem({
    required this.id,
    required this.dataId,
    required this.group,
    required this.content,
    this.encryptedDataKey,
    required this.tenant,
    this.appName,
    this.type,
  });

  factory NacosConfigDataItem.fromJson(Map<String, dynamic> json) {
    return .new(
      id: json['id'],
      dataId: json['dataId'],
      group: json['group'],
      content: json['content'],
      encryptedDataKey: json['encryptedDataKey'],
      tenant: json['tenant'],
      appName: json['appName'],
      type: json['type'],
    );
  }
}

class NacosNamespacesResponse extends Response {
  List<NacosNamespacesDataItem>? data;

  NacosNamespacesResponse({required super.code, super.message, this.data});

  factory NacosNamespacesResponse.fromJson(Map<String, dynamic> json) {
    return .new(
      code: json['code'],
      message: json['message'],
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => NacosNamespacesDataItem.fromJson(e))
          .toList(),
    );
  }
}

class NacosNamespacesDataItem {
  String namespace;
  String namespaceShowName;
  String namespaceDesc;
  int quota;
  int configCount;
  int type;

  NacosNamespacesDataItem({
    required this.namespace,
    required this.namespaceShowName,
    required this.namespaceDesc,
    required this.quota,
    required this.configCount,
    required this.type,
  });

  factory NacosNamespacesDataItem.fromJson(Map<String, dynamic> json) {
    return .new(
      namespace: json['namespace'],
      namespaceShowName: json['namespaceShowName'],
      namespaceDesc: json['namespaceDesc'],
      quota: json['quota'],
      configCount: json['configCount'],
      type: json['type'],
    );
  }
}

class NacosLoginResponse extends Response {
  NacosLoginData? data;

  NacosLoginResponse({required super.code, super.message, this.data});

  factory NacosLoginResponse.fromJson(Map<String, dynamic> json) {
    return .new(
      code: json['code'],
      message: json['message'],
      data: NacosLoginData.fromJson(json['data']),
    );
  }
}

class NacosLoginData {
  String accessToken;
  int tokenTtl;

  NacosLoginData({required this.accessToken, required this.tokenTtl});

  factory NacosLoginData.fromJson(Map<String, dynamic> json) {
    return .new(accessToken: json['accessToken'], tokenTtl: json['tokenTtl']);
  }
}
