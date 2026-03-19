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
