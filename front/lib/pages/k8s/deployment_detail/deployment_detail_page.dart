import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../../services/api_service.dart';
import 'deployment_state.dart';
import 'info_cards.dart';
import 'nacos_cards.dart';
import 'log_path_card.dart';
import 'drawers.dart';

/// Deployment 详情页面
class DeploymentDetailPage extends StatefulWidget {
  final String namespace;
  final String deployment;

  const DeploymentDetailPage({
    super.key,
    required this.namespace,
    required this.deployment,
  });

  @override
  State<DeploymentDetailPage> createState() => _DeploymentDetailPageState();
}

class _DeploymentDetailPageState extends State<DeploymentDetailPage> {
  late DeploymentState _state;

  @override
  void initState() {
    super.initState();
    _state = DeploymentState(
      namespace: widget.namespace,
      deployment: widget.deployment,
      context: context,
    );
    _state.addListener(_onStateChanged);
    _state.loadAllData();
  }

  @override
  void didUpdateWidget(DeploymentDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.namespace != widget.namespace ||
        oldWidget.deployment != widget.deployment) {
      _state.namespace = widget.namespace;
      _state.deployment = widget.deployment;
      _state.loadAllData();
    }
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _state.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final ctx = context;
    Future.microtask(() {
      if (ctx.mounted) {
        showToast(
          context: ctx,
          builder: (context, overlay) => Card(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isError ? Icons.error : Icons.info,
                    color: isError ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Text(message),
                  const SizedBox(width: 8),
                  IconButton.ghost(
                    onPressed: overlay.close,
                    icon: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
          ),
          location: ToastLocation.topRight,
          showDuration: const Duration(seconds: 3),
        );
      }
    });
  }

  void _showNacosMappingDrawer() {
    openDrawerOverlay(
      context: context,
      position: OverlayPosition.right,
      builder: (context) => NacosMappingDrawerContent(
        deployment: widget.deployment,
        namespace: widget.namespace,
        onSave: (nacosNamespace, nacosConfigId) async {
          final response = await ApiService.saveK8sNacosMapping(
            k8sNamespace: widget.namespace,
            k8sDeployment: widget.deployment,
            nacosNamespace: nacosNamespace,
            nacosConfigId: nacosConfigId,
          );
          if (response['code'] == 200) {
            await _state.loadExistingMapping();
          }
          return response;
        },
        onShowToast: _showToast,
      ),
    );
  }

  void _showNacosServiceMappingDrawer() {
    openDrawerOverlay(
      context: context,
      position: OverlayPosition.right,
      builder: (context) => NacosServiceMappingDrawerContent(
        deployment: widget.deployment,
        namespace: widget.namespace,
        onSave: (nacosNamespace, nacosServiceName, nacosGroupName) async {
          final response = await ApiService.saveK8sNacosServiceMapping(
            k8sNamespace: widget.namespace,
            k8sDeployment: widget.deployment,
            nacosNamespace: nacosNamespace,
            nacosServiceName: nacosServiceName,
            nacosGroupName: nacosGroupName,
          );
          if (response['code'] == 200) {
            await _state.loadExistingServiceMapping();
          }
          return response;
        },
        onShowToast: _showToast,
      ),
    );
  }

  Future<void> _saveLogPathConfig() async {
    if (_state.logPathController.text.isEmpty) {
      _showToast('请输入日志路径', isError: true);
      return;
    }

    final success = await _state.saveLogPathConfig();
    if (success) {
      _showToast('保存成功');
    } else {
      _showToast('保存失败', isError: true);
    }
  }

  Future<void> _deleteLogPathConfig() async {
    final success = await _state.deleteLogPathConfig();
    if (success) {
      _showToast('删除成功');
    } else {
      _showToast('删除失败', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(child: _buildBody());
  }

  Widget _buildBody() {
    if (_state.isLoading) {
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

    if (_state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _state.errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.gray),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              onPressed: _state.loadAllData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_state.deploymentData == null) {
      return const Center(child: Text('暂无数据'));
    }

    final labels =
        _state.deploymentData!['labels'] as Map<String, dynamic>? ?? {};
    final annotations =
        _state.deploymentData!['annotations'] as Map<String, dynamic>? ?? {};
    final containers =
        _state.deploymentData!['containers'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              const Icon(Icons.apps, size: 32, color: Colors.blue),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.deployment,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // 状态标签
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_state.deploymentData!['readyReplicas'] ?? 0}/${_state.deploymentData!['replicas'] ?? 0} Ready',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Namespace: ${widget.namespace}',
                style: const TextStyle(fontSize: 14, color: Colors.gray),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Button.primary(
                child: Icon(Icons.play_arrow),
                onPressed: () async {
                  final response = await ApiService.getK8sPods(
                    widget.namespace,
                    widget.deployment,
                  );

                  if (response['code'] == 200 && response['data'] != null) {
                    final data = response['data'];
                    final items = data['items'] as List<dynamic>? ?? [];
                    print(items);
                    if (items.isEmpty) {
                      return;
                    }

                  }
                },
              ),
              Text('一键拉取所有日志到本地'),
            ],
          ),
          const SizedBox(height: 4),
          // 基本信息卡片
          BasicInfoCard(state: _state),
          const SizedBox(height: 4),
          // Labels 卡片
          LabelsCard(labels: labels),
          if (labels.isNotEmpty) const SizedBox(height: 4),
          // Annotations 卡片
          AnnotationsCard(annotations: annotations),
          if (annotations.isNotEmpty) const SizedBox(height: 4),
          // Containers 卡片
          if (containers.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(4),
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
                    const SizedBox(height: 4),
                    ...containers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final container = entry.value as Map<String, dynamic>;
                      return ContainerCard(index: index, container: container);
                    }),
                  ],
                ),
              ),
            ),
          if (containers.isNotEmpty) const SizedBox(height: 4),
          // Services 卡片
          ServicesCard(state: _state),
          const SizedBox(height: 4),
          // Nacos 配置关联卡片
          NacosConfigCard(state: _state, onAssociate: _showNacosMappingDrawer),
          const SizedBox(height: 4),
          // Nacos 服务关联卡片
          NacosServiceCard(
            state: _state,
            onAssociate: _showNacosServiceMappingDrawer,
          ),
          const SizedBox(height: 4),
          // 日志路径配置卡片
          LogPathConfigCard(
            state: _state,
            onSave: _saveLogPathConfig,
            onDelete: _deleteLogPathConfig,
          ),
        ],
      ),
    );
  }
}
