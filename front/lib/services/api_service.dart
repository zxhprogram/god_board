import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8080';

  // 保存 K8s 配置
  static Future<Map<String, dynamic>> saveK8sConfig({
    required String address,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/configs/k8s'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'address': address,
          'username': username,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 保存 Nacos 配置
  static Future<Map<String, dynamic>> saveNacosConfig({
    required String address,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/configs/nacos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'address': address,
          'username': username,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 保存 NodeServer 配置
  static Future<Map<String, dynamic>> saveNodeServerConfig({
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/configs/nodeserver'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'address': address}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 获取服务器配置
  static Future<Map<String, dynamic>> getServerConfigs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/configs'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // K8s 登录
  static Future<Map<String, dynamic>> k8sLogin() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/k8s/login'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // Nacos 登录
  static Future<Map<String, dynamic>> nacosLogin() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/nacos/login'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 获取 K8s namespace 列表
  static Future<Map<String, dynamic>> getK8sNamespaces() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/k8s/namespaces'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 获取指定 namespace 下的 deployment 列表
  static Future<Map<String, dynamic>> getK8sDeployments(
    String namespace,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/k8s/namespaces/$namespace/deployments'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 获取指定 deployment 下的 pod 列表
  static Future<Map<String, dynamic>> getK8sPods(
    String namespace,
    String deployment,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/k8s/namespaces/$namespace/deployments/$deployment/pods',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 获取指定 namespace 下的 service 列表
  static Future<Map<String, dynamic>> getK8sServices(String namespace) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/k8s/namespaces/$namespace/services'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 获取 Nacos namespace 列表
  static Future<Map<String, dynamic>> getNacosNamespaces() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/nacos/namespaces'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 获取指定 Nacos namespace 下的配置列表
  static Future<Map<String, dynamic>> getNacosConfigs(
    String namespaceId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/nacos/configs?namespaceId=$namespaceId'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 保存 K8s 与 Nacos 的关联关系
  static Future<Map<String, dynamic>> saveK8sNacosMapping({
    required String k8sNamespace,
    required String k8sDeployment,
    required String nacosNamespace,
    required String nacosConfigId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/mappings/k8s-nacos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'k8sNamespace': k8sNamespace,
          'k8sDeployment': k8sDeployment,
          'nacosNamespace': nacosNamespace,
          'nacosConfigId': nacosConfigId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 获取 Nacos 服务列表
  static Future<Map<String, dynamic>> getNacosServices(
    String namespaceId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/nacos/services?namespaceId=$namespaceId'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 获取 K8s 与 Nacos 的关联关系
  static Future<Map<String, dynamic>> getK8sNacosMapping({
    required String k8sNamespace,
    required String k8sDeployment,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/mappings/k8s-nacos?k8sNamespace=$k8sNamespace&k8sDeployment=$k8sDeployment',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 获取单个 Nacos 配置的详情
  static Future<Map<String, dynamic>> getNacosConfigDetail({
    required String namespaceId,
    required String configId,
  }) async {
    try {
      // 先获取配置列表，然后找到匹配的配置
      final response = await http.get(
        Uri.parse('$baseUrl/api/nacos/configs?namespaceId=$namespaceId'),
        headers: {'Content-Type': 'application/json'},
      );

      final result = jsonDecode(response.body);
      if (result['code'] == 200 && result['data'] != null) {
        final data = result['data'];
        if (data is Map<String, dynamic> && data['pageItems'] is List) {
          final items = data['pageItems'] as List<dynamic>;
          // 根据 id 查找匹配的配置
          final config = items.firstWhere(
            (item) => item['id']?.toString() == configId,
            orElse: () => null,
          );
          if (config != null) {
            return {'code': 200, 'message': 'success', 'data': config};
          }
        }
        return {'code': 404, 'message': '未找到配置', 'data': null};
      }
      return result;
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 获取 NodeServer 配置
  static Future<Map<String, dynamic>> getNodeServerConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/configs/nodeserver'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 启动日志流（调用 node-server 的接口）
  static Future<Map<String, dynamic>> startLogStream({
    required String namespace,
    required String podName,
    required String logPath,
    String? container,
  }) async {
    try {
      // 1. 先获取 NodeServer 配置
      final configResponse = await getNodeServerConfig();
      if (configResponse['code'] != 200 || configResponse['data'] == null) {
        return {
          'success': false,
          'message': configResponse['message'] ?? '未配置 NodeServer 地址',
        };
      }

      final nodeServerAddress = configResponse['data']['address'] as String?;
      if (nodeServerAddress == null || nodeServerAddress.isEmpty) {
        return {'success': false, 'message': 'NodeServer 地址为空'};
      }

      // 2. 调用 node-server 的 start-log-stream 接口
      final response = await http.post(
        Uri.parse('$nodeServerAddress/start-log-stream'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'namespace': namespace,
          'podName': podName,
          'container': container,
        }),
      );

      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        // 返回 WebSocket URL 和 nodeServer 地址供后续连接使用
        String wsUrl =
            '${nodeServerAddress.replaceAll('http', 'ws')}/ws/log-stream?namespace=$namespace&podName=$podName&logPath=$logPath';
        if (container != null && container.isNotEmpty) {
          wsUrl += '&container=$container';
        }
        result['wsUrl'] = wsUrl;
        result['nodeServerAddress'] = nodeServerAddress;
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': '请求失败: $e'};
    }
  }

  // 获取新大陆 9894 配置
  static Future<Map<String, dynamic>> getNewland9894Config() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/configs/newland/9894'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 保存新大陆 9894 配置
  static Future<Map<String, dynamic>> saveNewland9894Config({
    required String address,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/configs/newland/9894'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'address': address,
          'username': username,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 获取新大陆 9895 配置
  static Future<Map<String, dynamic>> getNewland9895Config() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/configs/newland/9895'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 保存新大陆 9895 配置
  static Future<Map<String, dynamic>> saveNewland9895Config({
    required String address,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/configs/newland/9895'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'address': address,
          'username': username,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 获取 Redis 配置
  static Future<Map<String, dynamic>> getRedisConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/configs/redis'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 保存 Redis 配置
  static Future<Map<String, dynamic>> saveRedisConfig({
    required String host,
    required int port,
    required bool isCluster,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/configs/redis'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'host': host,
          'port': port,
          'is_cluster': isCluster,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 获取 MySQL 配置
  static Future<Map<String, dynamic>> getMySQLConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/configs/mysql'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }

  // 保存 MySQL 配置
  static Future<Map<String, dynamic>> saveMySQLConfig({
    required String host,
    required int port,
    required String username,
    required String password,
    required String database,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/configs/mysql'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'host': host,
          'port': port,
          'username': username,
          'password': password,
          'database': database,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'code': 500, 'message': '请求失败: $e', 'data': null};
    }
  }
}
