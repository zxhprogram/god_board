import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'shell/shell_layout.dart';
import 'pages/k8s/k8s_shell.dart';
import 'pages/k8s/namespace_detail_page.dart';
import 'pages/k8s/deployment_detail_page.dart';
import 'pages/k8s/pod_detail_page.dart';
import 'pages/home_page.dart';
import 'pages/server_settings_page.dart';
import 'pages/newland_gateway_page.dart';
import 'pages/inspection_page.dart';
import 'pages/config_insight_page.dart';
import 'pages/storage_config_page.dart';
import 'pages/nacos/nacos_shell.dart';
import 'pages/nacos/namespace_detail_page.dart';
import 'pages/nacos/config_detail_page.dart';
import 'pages/nacos/service_detail_page.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return ShellLayout(child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        // K8s 路由使用嵌套 ShellRoute
        ShellRoute(
          builder: (context, state, child) {
            return K8sShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/k8s',
              builder: (context, state) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      '请从左侧选择一个 Namespace',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            GoRoute(
              path: '/k8s/namespace/:namespace',
              builder: (context, state) {
                final namespace = state.pathParameters['namespace']!;
                return NamespaceDetailPage(namespace: namespace);
              },
            ),
            GoRoute(
              path: '/k8s/namespace/:namespace/deployment/:deployment',
              builder: (context, state) {
                final namespace = state.pathParameters['namespace']!;
                final deployment = state.pathParameters['deployment']!;
                return DeploymentDetailPage(
                  namespace: namespace,
                  deployment: deployment,
                );
              },
            ),
            GoRoute(
              path: '/k8s/namespace/:namespace/deployment/:deployment/pod/:pod',
              builder: (context, state) {
                final namespace = state.pathParameters['namespace']!;
                final deployment = state.pathParameters['deployment']!;
                final pod = state.pathParameters['pod']!;
                return PodDetailPage(
                  namespace: namespace,
                  deployment: deployment,
                  pod: pod,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const ServerSettingsPage(),
        ),
        GoRoute(
          path: '/newland-gateway',
          builder: (context, state) => const NewlandGatewayPage(),
        ),
        GoRoute(
          path: '/inspection',
          builder: (context, state) => const InspectionPage(),
        ),
        GoRoute(
          path: '/config-insight',
          builder: (context, state) => const ConfigInsightPage(),
        ),
        GoRoute(
          path: '/storage-config',
          builder: (context, state) => const StorageConfigPage(),
        ),
        // Nacos 路由使用嵌套 ShellRoute
        ShellRoute(
          builder: (context, state, child) {
            return NacosShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/nacos',
              builder: (context, state) =>
                  const Center(child: Text('请选择一个 Namespace 查看详情')),
            ),
            GoRoute(
              path: '/nacos/namespace/:namespaceId',
              builder: (context, state) {
                final namespaceId = state.pathParameters['namespaceId']!;
                return NacosNamespaceDetailPage(namespaceId: namespaceId);
              },
            ),
            GoRoute(
              path: '/nacos/namespace/:namespaceId/config/:group/:dataId',
              builder: (context, state) {
                final namespaceId = state.pathParameters['namespaceId']!;
                final group = state.pathParameters['group']!;
                final dataId = state.pathParameters['dataId']!;
                return NacosConfigDetailPage(
                  namespaceId: namespaceId,
                  group: group,
                  dataId: dataId,
                );
              },
            ),
            GoRoute(
              path:
                  '/nacos/namespace/:namespaceId/config/:group/:dataId/service/:serviceName',
              builder: (context, state) {
                final namespaceId = state.pathParameters['namespaceId']!;
                final group = state.pathParameters['group']!;
                final dataId = state.pathParameters['dataId']!;
                final serviceName = state.pathParameters['serviceName']!;
                return NacosServiceDetailPage(
                  namespaceId: namespaceId,
                  group: group,
                  dataId: dataId,
                  serviceName: serviceName,
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
