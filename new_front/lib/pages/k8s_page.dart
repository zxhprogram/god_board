import 'package:flutter/material.dart' show ListTile;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';

import '../service/k8s_service_api.dart';

class K8sBreadHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Breadcrumb(
      separator: Breadcrumb.arrowSeparator,
      children: [
        TextButton(
          onPressed: () {},
          density: ButtonDensity.compact,
          child: const Text('Home'),
        ),
        const MoreDots(),
        TextButton(
          onPressed: () {},
          density: ButtonDensity.compact,
          child: const Text('Components'),
        ),
        const Text('Breadcrumb'),
      ],
    );
  }
}

class K8sWelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('data'));
  }
}

