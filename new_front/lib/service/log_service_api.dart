import 'package:new_front/base/Response.dart';

import '../config/global_config.dart';

Future<bool> saveLogPathConfig({
  int? id,
  required String logPath,
  required String k8sNamespace,
  required String k8sDeployment,
}) async {
  var data = {
    'id': id,
    'k8s_namespace': k8sNamespace,
    'k8s_deployment': k8sDeployment,
    'log_path': logPath,
  };
  var response = await dio.post('/api/deployment-log-path', data: data);
  logger.i(response.data);
  return response.statusCode == 200;
}

Future<DeploymentLogPathResponse> getDeploymentLogPathConfig({
  required String k8sNamespace,
  required String k8sDeployment,
}) async {
  var response = await dio.get(
    '/api/deployment-log-path?k8s_namespace=$k8sNamespace&k8s_deployment=$k8sDeployment',
  );
  logger.i(response.data);
  return .fromJson(response.data);
}

class DeploymentLogPathResponse extends Response {
  DeploymentLogPathData? data;

  DeploymentLogPathResponse({required super.code, super.message, this.data});

  factory DeploymentLogPathResponse.fromJson(Map<String, dynamic> json) {
    return .new(
      code: json['code'],
      message: json['message'],
      data: DeploymentLogPathData.fromJson(json['data']),
    );
  }
}

class DeploymentLogPathData {
  int id;
  String k8sNamespace;
  String k8sDeployment;
  String logPath;
  String? description;

  DeploymentLogPathData({
    required this.id,
    required this.k8sNamespace,
    required this.k8sDeployment,
    required this.logPath,
    this.description,
  });

  factory DeploymentLogPathData.fromJson(Map<String, dynamic> json) {
    return .new(
      id: json['id'],
      k8sNamespace: json['k8s_namespace'],
      k8sDeployment: json['k8s_deployment'],
      logPath: json['log_path'],
      description: json['description'],
    );
  }
}
