import 'package:new_front/base/Response.dart';

import '../config/global_config.dart';

Future<void> saveK8sConfig({
  required String address,
  required String username,
  required String password,
}) async {
  var data = {'address': address, 'username': username, 'password': password};
  var r = await dio.post('/api/configs/k8s', data: data);
  logger.i(r.data);
}

Future<void> saveNacosConfig({
  required String address,
  required String username,
  required String password,
}) async {
  var data = {'address': address, 'username': username, 'password': password};
  var r = await dio.post('/api/configs/nacos', data: data);
  logger.i(r.data);
}

Future<ApiConfigsResponse> getConfigs() async {
  var response = await dio.get('/api/configs');
  logger.i(response.data);
  return .fromJson(response.data);
}

class ApiConfigsResponse extends Response {
  ApiConfigsData? data;

  ApiConfigsResponse({required super.code, super.message, this.data});

  factory ApiConfigsResponse.fromJson(Map<String, dynamic> json) {
    return .new(
      code: json['code'],
      message: json['message'],
      data: json['data'] == null ? null : ApiConfigsData.fromJson(json['data']),
    );
  }
}

class ApiConfigsData {
  ConfigItem? k8s;
  ConfigItem? nacos;
  ConfigItem? nodeServer;

  ApiConfigsData({this.k8s, this.nacos, this.nodeServer});

  factory ApiConfigsData.fromJson(Map<String, dynamic> json) {
    return .new(
      k8s: json['k8s'] == null ? null : ConfigItem.fromJson(json['k8s']),
      nacos: json['nacos'] == null ? null : ConfigItem.fromJson(json['nacos']),
      nodeServer: json['nodeServer'] == null
          ? null
          : ConfigItem.fromJson(json['nodeServer']),
    );
  }
}

class ConfigItem {
  int id;
  String address;
  String? username;
  String? password;

  ConfigItem({
    required this.id,
    required this.address,
    this.username,
    this.password,
  });

  factory ConfigItem.fromJson(Map<String, dynamic> json) {
    return .new(
      id: json['id'],
      address: json['address'],
      username: json['username'],
      password: json['password'],
    );
  }
}
