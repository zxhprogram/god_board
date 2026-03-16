import 'package:new_front/service/nacos_service_api.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../service/k8s_service_api.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // nacosLogin();
    // getNacosNamespaces();
    // getNacosConfigs('da536c77-40f2-48e0-b475-8da7b2fd0cdd');
    // getNacosServices('da536c77-40f2-48e0-b475-8da7b2fd0cdd');
    // getNacosServiceInstances(
    //   namespace: 'da536c77-40f2-48e0-b475-8da7b2fd0cdd',
    //   serviceName: 'video-file',
    // );
    // getNacosConfigDetail(
    //   namespace: 'da536c77-40f2-48e0-b475-8da7b2fd0cdd',
    //   serviceName: 'video-file.yaml',
    // );

    // k8sLogin();
    // k8sNamespaces();
    // k8sDeployments('video-platform');
    // k8sPods(namespace: 'video-platform', deployment: 'common-web');
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard, size: 64, color: Colors.gray),
          SizedBox(height: 4),
          Text(
            'God Board',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            '点击左侧菜单切换页面门',
            style: TextStyle(fontSize: 16, color: Colors.gray),
          ),
        ],
      ),
    );
  }
}
