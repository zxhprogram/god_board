import '../config/global_config.dart';

Future<void> saveNodeServerConfig({required String address}) async {
  var response = await dio.post(
    '/api/configs/nodeserver',
    data: {'address': address},
  );
  logger.i(response.data);
}
