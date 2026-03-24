import 'package:new_front/service/redis_service.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';

class RedisSettingsPage extends StatefulWidget {
  const RedisSettingsPage({super.key});

  @override
  State<RedisSettingsPage> createState() => _RedisSettingsPageState();
}

class _RedisSettingsPageState extends State<RedisSettingsPage> {
  final _addressKey = const TextFieldKey('address');
  final _portKey = const TextFieldKey('port');
  final _passwordKey = const TextFieldKey('password');

  final _redisIpController = TextEditingController();
  final _redisPortController = TextEditingController();
  final _redisPasswordController = TextEditingController();
  final _isClusterState = Signal<CheckboxState>(.unchecked);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    var r = await getRedisConfig();
    if (r.data != null) {
      _redisIpController.text = r.data!.host;
      _redisPortController.text = '${r.data!.port}';
      _redisPasswordController.text = r.data!.password;
      _isClusterState.value = r.data!.isCluster ? .checked : .unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    var checkBoxState = _isClusterState.watch(context);
    return Container(
      width: 480,
      padding: .all(20),
      child: Form(
        onSubmit: (context, values) async {
          var address = _addressKey[values]!;
          var port = _portKey[values]!;
          var isCluster = _isClusterState.value;
          var password = _passwordKey[values]!;
          await saveRedisConfig(
            host: address,
            port: int.parse(port),
            isCluster: isCluster == .checked,
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
                  label: const Text('redis服务器地址'),
                  validator: const NonNullValidator(),
                  child: TextField(
                    placeholder: Text('集群使用英文逗号进行分割'),
                    controller: _redisIpController,
                  ),
                ),
                FormField<String>(
                  key: _portKey,
                  label: const Text('redis服务器端口'),
                  validator: const NonNullValidator(),
                  child: TextField(controller: _redisPortController),
                ),
                FormField<String>(
                  key: _passwordKey,
                  label: const Text('redis服务器密码'),
                  validator: const NonNullValidator(),
                  child: TextField(controller: _redisPasswordController),
                ),
                Row(
                  children: [
                    Checkbox(
                      state: checkBoxState,
                      onChanged: (v) {
                        _isClusterState.value = v;
                      },
                    ),
                    Text('集群'),
                  ],
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
