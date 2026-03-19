import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../service/config_service.dart';

class NacosSettingsPage extends StatefulWidget {
  @override
  State<NacosSettingsPage> createState() => _NacosSettingsPage();
}

class _NacosSettingsPage extends State<NacosSettingsPage> {
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
          await saveNacosConfig(
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
                  label: const Text('Nacos服务器地址'),
                  validator: const HttpValidator(),
                  child: const TextField(initialValue: ''),
                ),
                FormField<String>(
                  key: _nameKey,
                  label: const Text('Nacos服务器用户名'),
                  validator: const NonNullValidator(),
                  child: const TextField(initialValue: ''),
                ),
                FormField<String>(
                  key: _passwordKey,
                  label: const Text('Nacos服务器密码'),
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

class HttpValidator extends Validator<String> {
  final String? message;

  const HttpValidator({this.message});

  @override
  FutureOr<ValidationResult?> validate(
    BuildContext context,
    String? value,
    FormValidationMode state,
  ) async {
    if (value == null) {
      return InvalidResult('不能为空', state: state);
    }
    try {
      var r = await Dio().head(value);
      if (r.statusCode != 200) {
        return InvalidResult('链接状态异常', state: state);
      }
    } catch (e) {
      return InvalidResult('链接状态异常', state: state);
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    return false;
  }
}
