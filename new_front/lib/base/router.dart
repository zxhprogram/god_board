import 'package:go_router/go_router.dart';
import 'package:new_front/base/log_server_settings_page.dart';
import 'package:new_front/base/nacos_settings_page.dart';
import 'package:new_front/base/redis_settings_page.dart';
import 'package:new_front/base/settings_page.dart';
import 'package:new_front/base/shell_layout.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../pages/k8s/k8s_namespace_detail_page.dart';
import '../pages/k8s/k8s_namespace_page.dart';
import '../pages/k8s_page.dart';
import 'home_page.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return ShellLayout(child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(path: '/settings', builder: (context, state) => SettingsPage()),
        GoRoute(
          path: '/nacosSettings',
          builder: (context, state) => NacosSettingsPage(),
        ),
        GoRoute(
          path: '/logServerSettings',
          builder: (context, state) => LogServerSettingsPage(),
        ),
        GoRoute(
          path: '/redisSettings',
          builder: (context, state) => RedisSettingsPage(),
        ),
        ShellRoute(
          builder: (context, state, child) => Column(
            crossAxisAlignment: .start,
            children: [
              K8sBreadHeader(),
              Expanded(
                child: Row(
                  children: [
                    K8sNamespacePage(),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
          routes: [
            GoRoute(
              path: '/k8s',
              builder: (context, state) {
                return K8sWelcomePage();
              },
            ),
            GoRoute(
              path: '/k8s/namespace/:namespace',
              builder: (context, state) {
                var namespace = state.pathParameters['namespace'];
                if (context.canPop()) {
                  context.pop();
                }
                return K8sNamespaceDetailPage(
                  namespace: namespace!,
                  key: ValueKey(namespace),
                );
              },
            ),
            ShellRoute(
              builder: (context, state, child) {
                return Row(children: [Expanded(child: child)]);
              },
              routes: [
                GoRoute(
                  path: '/k8s/deployment',
                  builder: (context, state) {
                    return K8sWelcomePage();
                  },
                ),
              ],
            ),
          ],
        ),
        // GoRoute(path: '/k8s', builder: (context, state) => const K8sPage()),
      ],
    ),
  ],
);
