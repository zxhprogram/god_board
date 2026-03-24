import 'package:new_front/base/Response.dart';
import 'package:new_front/config/global_config.dart';

Future<void> saveRedisConfig({
  required String host,
  required int port,
  required bool isCluster,
  required String password,
}) async {
  var data = {
    'host': host,
    'port': port,
    'is_cluster': isCluster,
    'password': password,
  };
  var response = await dio.post('/api/configs/redis', data: data);
  logger.i(response.data);
}

Future<RedisConfigResponse> getRedisConfig() async {
  var response = await dio.get('/api/configs/redis');
  logger.i(response.data);
  return .fromJson(response.data);
}

class RedisConfigResponse extends Response {
  RedisConfigData? data;

  RedisConfigResponse({required super.code, super.message, this.data});

  factory RedisConfigResponse.fromJson(Map<String, dynamic> json) {
    return .new(
      code: json['code'],
      message: json['message'],
      data: json['data'] == null
          ? null
          : RedisConfigData.fromJson(json['data']),
    );
  }
}

class RedisConfigData {
  int id;
  String host;
  int port;
  bool isCluster;
  String password;

  RedisConfigData({
    required this.id,
    required this.host,
    required this.isCluster,
    required this.port,
    required this.password,
  });

  factory RedisConfigData.fromJson(Map<String, dynamic> json) {
    return .new(
      id: json['id'],
      host: json['host'],
      isCluster: json['is_cluster'],
      port: json['port'],
      password: json['password'],
    );
  }
}
