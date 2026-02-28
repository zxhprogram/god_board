import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'router.dart';

void main() {
  runApp(
    ShadcnApp.router(
      title: 'God Board',
      routerConfig: router,
      theme: ThemeData(
        typography: Typography.geist(
          sans: const TextStyle(fontFamily: 'AlibabaPuHuiTi'),
        ),
      ),
    ),
  );
}
