import 'dart:async';

import 'package:dio/dio.dart';
import 'package:new_front/base/validator/http_validator.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../service/config_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _addressKey = const TextFieldKey('address');
  final _nameKey = const TextFieldKey('name');
  final _passwordKey = const TextFieldKey('password');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: .all(20),
      child: Form(
        onSubmit: (context, values) async {
          var address = _addressKey[values]!;
          var name = _nameKey[values]!;
          var password = _passwordKey[values]!;
          await saveK8sConfig(
            address: address,
            username: name,
            password: password,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormField<String>(
                  key: _addressKey,
                  label: const Text('K8S服务器地址'),
                  validator: const HttpValidator(),
                  child: const TextField(initialValue: ''),
                ),
                FormField<String>(
                  key: _nameKey,
                  label: const Text('K8S服务器用户名'),
                  validator: const NonNullValidator(),
                  child: const TextField(initialValue: ''),
                ),
                FormField<String>(
                  key: _passwordKey,
                  label: const Text('K8S服务器密码'),
                  validator: const NonNullValidator(),
                  child: const TextField(initialValue: ''),
                ),
              ],
            ).gap(4),
            const Gap(4),
            FormErrorBuilder(
              builder: (context, errors, child) {
                return PrimaryButton(
                  onPressed: errors.isEmpty ? () => context.submitForm() : null,
                  child: const Text('保存'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}