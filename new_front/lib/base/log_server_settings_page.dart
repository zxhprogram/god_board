import 'package:new_front/base/validator/http_validator.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../service/config_service.dart';
import '../service/node_server_api.dart';

class LogServerSettingsPage extends StatefulWidget {
  @override
  State<LogServerSettingsPage> createState() => _LogServerSettingsPage();
}

class _LogServerSettingsPage extends State<LogServerSettingsPage> {
  final _addressKey = const TextFieldKey('address');
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    var r = await getConfigs();
    _addressController.text = r.data?.nacos?.address ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: .all(20),
      child: Form(
        onSubmit: (context, values) async {
          var address = _addressKey[values]!;
          await saveNodeServerConfig(address: address);
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
                  label: const Text('日志服务器地址'),
                  // validator: const HttpValidator(),
                  child: TextField(
                    controller: _addressController,
                    initialValue: '',
                  ),
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
