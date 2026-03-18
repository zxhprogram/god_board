import 'package:new_front/base/Response.dart';
import 'package:new_front/config/global_config.dart';

//获取已经配置的nodeServer的远程地址
Future<NodeServerConfigResponse> _getNodeServerConfig() async {
  var response = await dio.get('/api/configs/nodeserver');
  logger.i(response.data);
  return .fromJson(response.data);
}

Future<LogStreamInformation> registerLogStream({
  required String k8sNamespace,
  required String podName,
  required String logPath,
  String? k8sDeployment,
}) async {
  var nodeServerConfig = await _getNodeServerConfig();
  var data = {
    'namespace': k8sNamespace,
    'podName': podName,
    'container': k8sDeployment,
  };
  var response = await dio.post(
    '${nodeServerConfig.data!.address}/start-log-stream',
    data: data,
  );

  logger.i(response.data);
  var r = StartLogStreamResponse.fromJson(response.data);
  String wsUrl =
      '${nodeServerConfig.data!.address.replaceAll('http', 'ws')}/ws/log-stream?namespace=$k8sNamespace&podName=$podName&logPath=$logPath';
  return .new(
    response: r,
    wsUrl: wsUrl,
    nodeServerAddress: nodeServerConfig.data!.address,
  );
}

class LogStreamInformation {
  StartLogStreamResponse? response;
  String? wsUrl;
  String? nodeServerAddress;

  LogStreamInformation({this.response, this.wsUrl, this.nodeServerAddress});
}

class StartLogStreamResponse {
  bool success;
  String message;
  String? processId;

  StartLogStreamResponse({
    required this.success,
    required this.message,
    this.processId,
  });

  factory StartLogStreamResponse.fromJson(Map<String, dynamic> json) {
    return .new(
      success: json['success'],
      message: json['message'],
      processId: json['processId'],
    );
  }
}

class NodeServerConfigResponse extends Response {
  NodeServerConfigData? data;

  NodeServerConfigResponse({required super.code, super.message, this.data});

  factory NodeServerConfigResponse.fromJson(Map<String, dynamic> json) {
    return .new(
      code: json['code'],
      message: json['message'],
      data: json['data'] == null
          ? null
          : NodeServerConfigData.fromJson(json['data']),
    );
  }
}

class NodeServerConfigData {
  int id;
  String address;

  NodeServerConfigData({required this.id, required this.address});

  factory NodeServerConfigData.fromJson(Map<String, dynamic> json) {
    return .new(id: json['id'], address: json['address']);
  }
}
