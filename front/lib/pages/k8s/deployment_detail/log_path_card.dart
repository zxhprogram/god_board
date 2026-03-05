import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'deployment_state.dart';

/// 日志路径配置卡片
class LogPathConfigCard extends StatelessWidget {
  final DeploymentState state;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  const LogPathConfigCard({
    super.key,
    required this.state,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '日志路径配置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (state.isLoadingLogPath)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (state.logPathConfig != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '已配置',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // 已配置的日志路径显示
            if (state.logPathConfig != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.folder,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '当前日志路径',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      state.logPathConfig!['log_path'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    if (state.logPathConfig!['description'] != null &&
                        state.logPathConfig!['description']
                            .toString()
                            .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '描述: ${state.logPathConfig!['description']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.gray.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // 日志路径输入框
            TextField(
              controller: state.logPathController,
              placeholder: const Text('日志路径'),
              hintText: '请输入日志文件路径，例如: /var/log/app/app.log',
            ),
            const SizedBox(height: 12),
            // 描述输入框
            TextField(
              controller: state.logPathDescController,
              placeholder: const Text('描述（可选）'),
              hintText: '请输入日志路径的描述信息',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            // 操作按钮
            Row(
              children: [
                PrimaryButton(
                  onPressed: onSave,
                  child: Text(state.logPathConfig != null ? '更新配置' : '保存配置'),
                ),
                const SizedBox(width: 12),
                if (state.logPathConfig != null)
                  SecondaryButton(
                    onPressed: () => _showDeleteConfirm(context),
                    child: const Text('删除配置'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Card(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '确认删除',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('确定要删除日志路径配置吗？'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SecondaryButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  PrimaryButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDelete();
                    },
                    child: const Text('删除'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
