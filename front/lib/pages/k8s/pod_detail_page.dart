import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart' show ElevatedButton;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../services/api_service.dart';

// 客户端日志管理器 - 用于诊断
class ClientLogger {
  static File? _logFile;
  static final List<String> _buffer = [];
  static Timer? _flushTimer;
  static bool _initialized = false;

  // 日志文件路径
  static const String _logFileName = 'client.log';

  // 初始化日志系统
  static Future<void> init() async {
    if (_initialized) return;

    try {
      _logFile = File(_logFileName);

      // 如果文件已存在，备份旧日志
      if (await _logFile!.exists()) {
        final backupName =
            'client_${DateTime.now().millisecondsSinceEpoch}.log';
        await _logFile!.rename(backupName);
      }

      // 创建新日志文件
      await _logFile!.create();

      // 启动定时刷新
      _flushTimer = Timer.periodic(const Duration(seconds: 5), (_) => _flush());

      _initialized = true;
      info('ClientLogger', '客户端日志系统初始化成功');
    } catch (e) {
      print('初始化客户端日志失败: $e');
    }
  }

  // 写入日志
  static void _log(String level, String tag, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logLine = '[$timestamp] [$level] [$tag] $message';

    // 同时输出到控制台
    print(logLine);

    if (!_initialized) {
      _buffer.add(logLine);
      return;
    }

    _buffer.add(logLine);

    // 如果缓冲区太大，立即刷新
    if (_buffer.length >= 50) {
      _flush();
    }
  }

  // 刷新缓冲区到文件
  static void _flush() {
    if (_logFile == null || _buffer.isEmpty) return;

    final linesToWrite = List<String>.from(_buffer);
    _buffer.clear();

    final content = linesToWrite.join('\n') + '\n';
    _logFile!
        .writeAsString(content, mode: FileMode.append)
        .then((_) {
          // 写入成功
        })
        .catchError((e) {
          print('写入客户端日志失败: $e');
        });
  }

  // 不同级别的日志
  static void debug(String tag, String message) => _log('DEBUG', tag, message);
  static void info(String tag, String message) => _log('INFO', tag, message);
  static void warn(String tag, String message) => _log('WARN', tag, message);
  static void error(String tag, String message) => _log('ERROR', tag, message);

  // 关闭日志系统
  static void close() {
    _flush();
    _flushTimer?.cancel();
    _initialized = false;
  }
}

// 日志流管理器 - 在后台创建文件并写入 WebSocket 数据（带缓冲区优化）
class LogStreamManager {
  static final Map<String, WebSocketChannel> _channels = {};
  static final Map<String, File> _logFiles = {};
  static final Map<String, List<String>> _buffers = {};
  static final Map<String, Timer> _flushTimers = {};

  // 缓冲区大小阈值（条数）
  static const int _bufferSizeThreshold = 100;
  // 刷新间隔（毫秒）
  static const int _flushIntervalMs = 500;

  // 启动日志流：调用 /start-log-stream，创建文件，连接 WebSocket
  static Future<Map<String, dynamic>> startLogStream({
    required String namespace,
    required String deployment,
    required String pod,
    required String logPath,
  }) async {
    ClientLogger.info(
      'LogStreamManager',
      '启动日志流: namespace=$namespace, pod=$pod, logPath=$logPath',
    );

    // 1. 调用 /start-log-stream 接口
    ClientLogger.debug('LogStreamManager', '调用 /start-log-stream 接口...');
    final response = await ApiService.startLogStream(
      namespace: namespace,
      podName: pod,
      logPath: logPath,
      container: deployment,
    );

    if (response['success'] != true) {
      ClientLogger.error('LogStreamManager', '启动日志流失败: ${response['message']}');
      return response;
    }

    final String? wsUrl = response['wsUrl'] as String?;
    if (wsUrl == null) {
      ClientLogger.error('LogStreamManager', '未获取到 WebSocket URL');
      return {'success': false, 'message': '未获取到 WebSocket URL'};
    }
    ClientLogger.info('LogStreamManager', '获取到 WebSocket URL: $wsUrl');

    // 2. 在当前目录创建与 podName 一样的 log 文件
    try {
      final fileName = '$pod.log';
      ClientLogger.info('LogStreamManager', '创建日志文件: $fileName');
      final file = File(fileName);

      // 如果文件已存在，先删除
      if (await file.exists()) {
        ClientLogger.warn('LogStreamManager', '日志文件已存在，删除旧文件');
        await file.delete();
      }

      // 创建新文件
      await file.create();
      ClientLogger.info('LogStreamManager', '日志文件创建成功');

      // 保存文件引用
      _logFiles[pod] = file;

      // 初始化缓冲区
      _buffers[pod] = [];

      // 3. 连接 WebSocket 并将数据追加到文件
      ClientLogger.info('LogStreamManager', '开始连接 WebSocket...');
      _connectWebSocket(pod, wsUrl, file);

      ClientLogger.info(
        'LogStreamManager',
        '日志流启动成功: processId=${response['processId']}',
      );
      return {
        'success': true,
        'message': '日志流已启动，文件: $fileName',
        'processId': response['processId'],
        'fileName': fileName,
      };
    } catch (e, stackTrace) {
      ClientLogger.error('LogStreamManager', '创建日志文件失败: $e\n$stackTrace');
      return {'success': false, 'message': '创建日志文件失败: $e'};
    }
  }

  // 连接 WebSocket 并写入文件（使用缓冲区优化）
  static void _connectWebSocket(String pod, String wsUrl, File file) {
    try {
      ClientLogger.info('LogStreamManager', '正在连接 WebSocket: $wsUrl');
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channels[pod] = channel;
      ClientLogger.info('LogStreamManager', 'WebSocket 连接已建立: $pod');

      // 创建定时刷新器
      _flushTimers[pod] = Timer.periodic(
        const Duration(milliseconds: _flushIntervalMs),
        (_) => _flushBuffer(pod, file),
      );
      ClientLogger.debug('LogStreamManager', '定时刷新器已创建: ${_flushIntervalMs}ms');

      channel.stream.listen(
        (message) {
          // 将消息添加到缓冲区（非阻塞）
          final buffer = _buffers[pod];
          if (buffer != null) {
            buffer.add(message.toString());

            // 如果缓冲区达到阈值，立即刷新
            if (buffer.length >= _bufferSizeThreshold) {
              ClientLogger.debug(
                'LogStreamManager',
                '缓冲区达到阈值，立即刷新: $pod, size=${buffer.length}',
              );
              _flushBuffer(pod, file);
            }
          }
        },
        onError: (error) {
          ClientLogger.error('LogStreamManager', 'WebSocket 错误: $error');
          _cleanup(pod);
        },
        onDone: () {
          ClientLogger.info('LogStreamManager', 'WebSocket 连接已关闭: $pod');
          // 最后刷新一次缓冲区
          _flushBuffer(pod, file);
          _cleanup(pod);
        },
      );
    } catch (e, stackTrace) {
      ClientLogger.error(
        'LogStreamManager',
        '连接 WebSocket 失败: $e\n$stackTrace',
      );
      _cleanup(pod);
    }
  }

  // 刷新缓冲区到文件
  static void _flushBuffer(String pod, File file) {
    final buffer = _buffers[pod];
    if (buffer == null || buffer.isEmpty) return;

    final lineCount = buffer.length;
    ClientLogger.debug('LogStreamManager', '刷新缓冲区: $pod, lines=$lineCount');

    // 取出当前缓冲区的数据
    final linesToWrite = List<String>.from(buffer);
    buffer.clear();

    // 异步写入文件
    final content = linesToWrite.join('\n') + '\n';
    file
        .writeAsString(content, mode: FileMode.append)
        .then((_) {
          ClientLogger.debug(
            'LogStreamManager',
            '写入日志文件成功: $pod, lines=$lineCount',
          );
        })
        .catchError((e) {
          ClientLogger.error('LogStreamManager', '写入日志文件失败: $e');
          // 如果写入失败，将数据放回缓冲区
          buffer.insertAll(0, linesToWrite);
        });
  }

  // 清理资源
  static void _cleanup(String pod) {
    ClientLogger.info('LogStreamManager', '清理资源: $pod');

    // 取消定时器
    _flushTimers[pod]?.cancel();
    _flushTimers.remove(pod);

    // 最后刷新缓冲区
    final file = _logFiles[pod];
    if (file != null) {
      _flushBuffer(pod, file);
    }

    _channels.remove(pod);
    _logFiles.remove(pod);
    _buffers.remove(pod);

    ClientLogger.info('LogStreamManager', '资源清理完成: $pod');
  }

  // 停止日志流
  static Future<void> stopLogStream(String pod) async {
    ClientLogger.info('LogStreamManager', '停止日志流: $pod');

    // 关闭 WebSocket 连接
    final channel = _channels[pod];
    if (channel != null) {
      await channel.sink.close();
      ClientLogger.info('LogStreamManager', 'WebSocket 连接已关闭: $pod');
    }
    _cleanup(pod);
  }

  // 获取所有正在运行的日志流
  static List<String> getActiveStreams() {
    return _channels.keys.toList();
  }

  // 检查指定 pod 的日志流是否在运行
  static bool isStreamRunning(String pod) {
    return _channels.containsKey(pod);
  }
}

// 日志获取对话框
class LogStreamDialog extends StatefulWidget {
  final String namespace;
  final String deployment;
  final String pod;

  const LogStreamDialog({
    super.key,
    required this.namespace,
    required this.deployment,
    required this.pod,
  });

  @override
  State<LogStreamDialog> createState() => _LogStreamDialogState();
}

class _LogStreamDialogState extends State<LogStreamDialog> {
  final TextEditingController _logPathController = TextEditingController(
    text: '/app/logs/app.log',
  );
  bool _isStarting = false;
  String? _resultMessage;
  bool _isSuccess = false;
  bool _isRunning = false;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    // 初始化客户端日志
    ClientLogger.init();
    ClientLogger.info('LogStreamDialog', '对话框初始化: pod=${widget.pod}');

    _checkStatus();
    // 定时检查状态
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkStatus();
    });
  }

  @override
  void dispose() {
    _logPathController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  void _checkStatus() {
    final isRunning = LogStreamManager.isStreamRunning(widget.pod);
    if (isRunning != _isRunning) {
      setState(() {
        _isRunning = isRunning;
      });
    }
  }

  Future<void> _startLogStream() async {
    ClientLogger.info('LogStreamDialog', '用户点击启动日志流: pod=${widget.pod}');
    setState(() {
      _isStarting = true;
      _resultMessage = null;
    });

    // 使用 LogStreamManager 启动日志流（后台创建文件并写入 WebSocket 数据）
    final response = await LogStreamManager.startLogStream(
      namespace: widget.namespace,
      deployment: widget.deployment,
      pod: widget.pod,
      logPath: _logPathController.text,
    );

    setState(() {
      _isStarting = false;
      if (response['success'] == true) {
        _isSuccess = true;
        _isRunning = true;
        _resultMessage =
            '日志流启动成功！\n进程ID: ${response['processId'] ?? 'N/A'}\n文件: ${response['fileName']}';
        ClientLogger.info(
          'LogStreamDialog',
          '日志流启动成功: ${response['fileName']}',
        );
      } else {
        _isSuccess = false;
        _resultMessage = response['message'] ?? '启动失败';
        ClientLogger.error('LogStreamDialog', '日志流启动失败: ${_resultMessage}');
      }
    });
  }

  Future<void> _stopLogStream() async {
    ClientLogger.info('LogStreamDialog', '用户点击断开连接: pod=${widget.pod}');
    await LogStreamManager.stopLogStream(widget.pod);
    setState(() {
      _isRunning = false;
      _resultMessage = '日志流已断开';
      _isSuccess = true;
    });
    ClientLogger.info('LogStreamDialog', '日志流已断开: pod=${widget.pod}');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('获取 Pod 日志'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Namespace: ${widget.namespace}'),
            Text('Pod: ${widget.pod}'),
            Text('容器: ${widget.deployment}'),
            const SizedBox(height: 16),
            TextField(
              controller: _logPathController,
              placeholder: const Text('请输入日志文件路径'),
            ),
            const SizedBox(height: 8),
            const Text('日志路径').small.muted,
            if (_resultMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Text(
                  _resultMessage!,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        Button(
          style: const ButtonStyle.secondary(),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        if (_isRunning) ...[
          // 状态指示器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '运行中',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 断开连接按钮
          Button(
            style: const ButtonStyle.destructive(),
            onPressed: _stopLogStream,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stop, size: 16),
                SizedBox(width: 4),
                Text('断开连接'),
              ],
            ),
          ),
        ] else ...[
          PrimaryButton(
            onPressed: _isStarting ? null : _startLogStream,
            child: _isStarting
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('启动中...'),
                    ],
                  )
                : const Text('启动日志流'),
          ),
        ],
      ],
    );
  }
}

class PodDetailPage extends StatefulWidget {
  final String namespace;
  final String deployment;
  final String pod;

  const PodDetailPage({
    super.key,
    required this.namespace,
    required this.deployment,
    required this.pod,
  });

  @override
  State<PodDetailPage> createState() => _PodDetailPageState();
}

class _PodDetailPageState extends State<PodDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _podData;

  @override
  void initState() {
    super.initState();
    _loadPodDetail();
  }

  Future<void> _loadPodDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 获取指定 deployment 下的所有 pod，然后找到当前 pod
    final response = await ApiService.getK8sPods(
      widget.namespace,
      widget.deployment,
    );

    if (response['code'] == 200 && response['data'] != null) {
      final data = response['data'];
      final items = data['items'] as List<dynamic>? ?? [];

      // 查找当前 pod
      final pod = items.firstWhere(
        (item) => item['name'] == widget.pod,
        orElse: () => null,
      );

      if (pod != null) {
        setState(() {
          _podData = pod;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '未找到 pod: ${widget.pod}';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = response['message'] ?? '获取 pod 详情失败';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'succeeded':
        return Colors.blue;
      default:
        return Colors.gray;
    }
  }

  void _showLogStreamDialog() {
    showDialog(
      context: context,
      builder: (context) => LogStreamDialog(
        namespace: widget.namespace,
        deployment: widget.deployment,
        pod: widget.pod,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载中...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.gray),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadPodDetail, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_podData == null) {
      return const Center(child: Text('暂无数据'));
    }

    final labels = _podData!['labels'] as Map<String, dynamic>? ?? {};
    final annotations = _podData!['annotations'] as Map<String, dynamic>? ?? {};
    final containers = _podData!['containers'] as List<dynamic>? ?? [];
    final conditions = _podData!['conditions'] as List<dynamic>? ?? [];
    final volumes = _podData!['volumes'] as List<dynamic>? ?? [];
    final status = _podData!['status'] as String? ?? 'Unknown';
    final statusColor = _getStatusColor(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(Icons.circle, size: 32, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.pod,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 获取日志按钮
              Button(
                style: const ButtonStyle.primary(),
                onPressed: _showLogStreamDialog,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description, size: 16),
                    SizedBox(width: 4),
                    Text('获取日志'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 状态标签
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Namespace: ${widget.namespace}',
                style: const TextStyle(fontSize: 14, color: Colors.gray),
              ),
              const SizedBox(width: 8),
              Text(
                'Deployment: ${widget.deployment}',
                style: const TextStyle(fontSize: 14, color: Colors.gray),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // 基本信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '基本信息',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('名称', _podData!['name'] ?? '-'),
                  _buildInfoRow('Namespace', widget.namespace),
                  _buildInfoRow('状态', status),
                  _buildInfoRow('Phase', _podData!['phase'] ?? '-'),
                  _buildInfoRow('Pod IP', _podData!['podIP'] ?? '-'),
                  _buildInfoRow('Host IP', _podData!['hostIP'] ?? '-'),
                  _buildInfoRow('Node', _podData!['nodeName'] ?? '-'),
                  _buildInfoRow('创建时间', _podData!['creationTimestamp'] ?? '-'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Conditions 卡片
          if (conditions.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conditions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...conditions.map((condition) {
                      final type = condition['type'] ?? 'Unknown';
                      final status = condition['status'] ?? 'Unknown';
                      final reason = condition['reason'];
                      final message = condition['message'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: status == 'True'
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: status == 'True'
                                ? Colors.green.shade200
                                : Colors.orange.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  status == 'True'
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  size: 16,
                                  color: status == 'True'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  type,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: status == 'True'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            if (reason != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Reason: $reason',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.gray,
                                ),
                              ),
                            ],
                            if (message != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                message,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Labels 卡片
          if (labels.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Labels',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: labels.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.gray.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${entry.key}: ${entry.value}'),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Annotations 卡片
          if (annotations.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Annotations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...annotations.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: const TextStyle(color: Colors.gray),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Containers 卡片
          if (containers.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Containers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...containers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final container = entry.value as Map<String, dynamic>;
                      return _buildContainerCard(index, container);
                    }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Volumes 卡片
          if (volumes.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Volumes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...volumes.map((volume) {
                      final name = volume['name'] ?? 'Unknown';
                      final type = volume['type'] ?? 'Unknown';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.storage,
                              size: 20,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Type: $type',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContainerCard(int index, Map<String, dynamic> container) {
    final resources = container['resources'] as Map<String, dynamic>? ?? {};
    final requests = resources['requests'] as Map<String, dynamic>? ?? {};
    final limits = resources['limits'] as Map<String, dynamic>? ?? {};
    final ports = container['ports'] as List<dynamic>? ?? [];
    final env = container['env'] as List<dynamic>? ?? [];
    final status = container['status'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) const Divider(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.gray.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.gray.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container 名称
              Row(
                children: [
                  const Icon(Icons.memory, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    container['name'] ?? 'Container ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (status['ready'] == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Ready',
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Image
              _buildInfoRow('Image', container['image'] ?? '-'),
              // Container ID
              if (status['containerID'] != null)
                _buildInfoRow(
                  'Container ID',
                  '${status['containerID'].toString().substring(0, 20)}...',
                ),
              // Restart Count
              if (status['restartCount'] != null)
                _buildInfoRow('Restart Count', '${status['restartCount']}'),
              // Command
              if (container['command'] != null)
                _buildInfoRow(
                  'Command',
                  (container['command'] as List).join(' '),
                ),
              // Args
              if (container['args'] != null)
                _buildInfoRow('Args', (container['args'] as List).join(' ')),
              const SizedBox(height: 12),
              // Resources
              if (requests.isNotEmpty || limits.isNotEmpty)
                const Text(
                  'Resources:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              if (requests.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Requests:',
                        style: TextStyle(fontSize: 12, color: Colors.gray),
                      ),
                      ...requests.entries.map(
                        (e) => Text('  ${e.key}: ${e.value}'),
                      ),
                    ],
                  ),
                ),
              if (limits.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Limits:',
                        style: TextStyle(fontSize: 12, color: Colors.gray),
                      ),
                      ...limits.entries.map(
                        (e) => Text('  ${e.key}: ${e.value}'),
                      ),
                    ],
                  ),
                ),
              // Ports
              if (ports.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Ports:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ports.map((port) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        '${port['containerPort']}/${port['protocol'] ?? 'TCP'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              // Environment Variables
              if (env.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Environment Variables:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                ...env.take(5).map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 2),
                    child: Text(
                      '${e['name']}: ${e['value'] ?? '***'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
                if (env.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      '... and ${env.length - 5} more',
                      style: const TextStyle(fontSize: 12, color: Colors.gray),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.gray),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
