import 'package:new_front/base/validator/http_validator.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../service/config_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _addressKey = const TextFieldKey('address');
  final _nameKey = const TextFieldKey('name');
  final _passwordKey = const TextFieldKey('password');

  final _addressController = TextEditingController();
  final _k8sUsernameController = TextEditingController();
  final _k8sPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    var r = await getConfigs();
    _addressController.text = r.data?.k8s?.address ?? '';
    _k8sUsernameController.text = r.data?.k8s?.username ?? '';
    _k8sPasswordController.text = r.data?.k8s?.password ?? '';
  }

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
                  child: TextField(controller: _addressController),
                ),
                FormField<String>(
                  key: _nameKey,
                  label: const Text('K8S服务器用户名'),
                  validator: const NonNullValidator(),
                  child: TextField(controller: _k8sUsernameController),
                ),
                FormField<String>(
                  key: _passwordKey,
                  label: const Text('K8S服务器密码'),
                  validator: const NonNullValidator(),
                  child: TextField(controller: _k8sPasswordController),
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
