import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter/material.dart' as m;
import 'router.dart';

void main() {
  final baseTypography = Typography.geist(
    sans: const TextStyle(fontFamily: 'AlibabaPuHuiTi'),
    mono: const TextStyle(fontFamily: 'AlibabaPuHuiTi'),
    xSmall: const TextStyle(fontFamily: 'AlibabaPuHuiTi', fontSize: 12),
    small: const TextStyle(fontFamily: 'AlibabaPuHuiTi', fontSize: 14),
    medium: const TextStyle(fontFamily: 'AlibabaPuHuiTi', fontSize: 16),
    large: const TextStyle(fontFamily: 'AlibabaPuHuiTi', fontSize: 20),
    xLarge: const TextStyle(fontFamily: 'AlibabaPuHuiTi', fontSize: 24),
    base: const TextStyle(fontFamily: 'AlibabaPuHuiTi', fontSize: 16),
  );

  runApp(
    ShadcnApp.router(
      title: 'God Board',
      routerConfig: router,
      materialTheme: m.ThemeData(fontFamily: 'AlibabaPuHuiTi'),
      theme: ThemeData(
        typography: baseTypography.copyWith(
          inlineCode: () => const TextStyle(
            fontFamily: 'AlibabaPuHuiTi',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}
