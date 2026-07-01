import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/device_command_controller.dart';
import '../../../../platform_bridge/hardware_models.dart';

class DeviceCommandPage extends ConsumerWidget {
  const DeviceCommandPage({required this.deviceId, super.key});

  static const routeName = 'device-command';
  static const routePath = '/device-command';

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deviceCommandControllerProvider);
    final controller = ref.read(deviceCommandControllerProvider.notifier);
    final actions = DeviceCommandAction.values;
    final isBusy =
        state.pendingAction != null ||
        state.pendingRemotePairingAction != null ||
        state.pendingRemoteManagementAction != null;
    final isQuerying = state.pendingRemoteManagementAction == 'query';
    final isDeletingAll = state.pendingRemoteManagementAction == 'delete-all';

    return Scaffold(
      appBar: AppBar(title: const Text('设备控制')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('当前设备', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          SelectableText(deviceId.isEmpty ? '未选择设备' : deviceId),
          if (state.infoMessage != null) ...[
            const SizedBox(height: 16),
            _DeviceCommandMessage(
              message: state.infoMessage!,
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue.shade900,
            ),
          ],
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            _DeviceCommandMessage(
              message: state.errorMessage!,
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade900,
            ),
          ],
          const SizedBox(height: 12),
          Text('控制命令：Cmd 0x0005，Data 为 2 字节 Controls。'),
          const SizedBox(height: 16),
          AbsorbPointer(
            absorbing: isBusy,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                mainAxisExtent: 56,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                final isPending = state.pendingAction == action;
                return FilledButton(
                  onPressed: () =>
                      controller.runAction(deviceId: deviceId, action: action),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isPending ? '发送中...' : action.label),
                      const SizedBox(height: 2),
                      Text(
                        action.controlCodeLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text('遥控器对码', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('对码命令：Cmd 0x0007，Data 为 2 字节 Controls。'),
          const SizedBox(height: 12),
          AbsorbPointer(
            absorbing: isBusy,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => controller.runRemotePairingAction(
                      deviceId: deviceId,
                      action: RemotePairingAction.start,
                    ),
                    child: _RemotePairingButtonLabel(
                      label: '开始对码',
                      controlCodeLabel: '0x1008',
                      pending:
                          state.pendingRemotePairingAction ==
                          RemotePairingAction.start,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.runRemotePairingAction(
                      deviceId: deviceId,
                      action: RemotePairingAction.cancel,
                    ),
                    child: _RemotePairingButtonLabel(
                      label: '取消对码',
                      controlCodeLabel: '0x1009',
                      pending:
                          state.pendingRemotePairingAction ==
                          RemotePairingAction.cancel,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('遥控器管理', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('查询 0x0008，删除 0x0009，改名 0x000A。'),
          const SizedBox(height: 12),
          AbsorbPointer(
            absorbing: isBusy,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        controller.queryRemotes(deviceId: deviceId),
                    icon: const Icon(Icons.refresh),
                    label: Text(isQuerying ? '查询中...' : '查询遥控器'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        controller.deleteRemote(deviceId: deviceId),
                    icon: const Icon(Icons.delete_sweep),
                    label: Text(isDeletingAll ? '删除中...' : '全部删除'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _RemoteControlList(
            remotes: state.remotes,
            totalCount: state.remoteTotalCount,
            totalPages: state.remoteTotalPages,
            currentPage: state.remoteCurrentPage,
            hasMore: state.remoteHasMore,
            pendingAction: state.pendingRemoteManagementAction,
            busy: isBusy,
            onDelete: (remote) => controller.deleteRemote(
              deviceId: deviceId,
              serialNumber: remote.serialNumber,
            ),
            onRename: (remote) async {
              final name = await _requestRemoteName(context, remote.name);
              if (name == null) {
                return;
              }
              await controller.renameRemote(
                deviceId: deviceId,
                serialNumber: remote.serialNumber,
                name: name,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RemoteControlList extends StatelessWidget {
  const _RemoteControlList({
    required this.remotes,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    required this.hasMore,
    required this.pendingAction,
    required this.busy,
    required this.onDelete,
    required this.onRename,
  });

  final List<RemoteControl> remotes;
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final bool hasMore;
  final String? pendingAction;
  final bool busy;
  final ValueChanged<RemoteControl> onDelete;
  final ValueChanged<RemoteControl> onRename;

  @override
  Widget build(BuildContext context) {
    if (remotes.isEmpty) {
      return Text(
        '暂无遥控器数据，请先查询。',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final pageLabel = totalPages > 0 ? '第 $currentPage/$totalPages 页' : '未分页';
    final moreLabel = hasMore ? '，还有后续包' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('已显示 ${remotes.length}/$totalCount 个，$pageLabel$moreLabel。'),
        const SizedBox(height: 8),
        for (final remote in remotes)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(remote.name.isEmpty ? '未命名遥控器' : remote.name),
            subtitle: Text(remote.serialNumberLabel),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '改名',
                  onPressed: busy ? null : () => onRename(remote),
                  icon: Icon(
                    pendingAction ==
                            'rename-${remote.serialNumber.toRadixString(16)}'
                        ? Icons.hourglass_top
                        : Icons.edit,
                  ),
                ),
                IconButton(
                  tooltip: '删除',
                  onPressed: busy ? null : () => onDelete(remote),
                  icon: Icon(
                    pendingAction ==
                            'delete-${remote.serialNumber.toRadixString(16)}'
                        ? Icons.hourglass_top
                        : Icons.delete_outline,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RemotePairingButtonLabel extends StatelessWidget {
  const _RemotePairingButtonLabel({
    required this.label,
    required this.controlCodeLabel,
    required this.pending,
  });

  final String label;
  final String controlCodeLabel;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = IconTheme.of(context).color;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(pending ? '对码中...' : label),
        const SizedBox(height: 2),
        Text(
          controlCodeLabel,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: foregroundColor),
        ),
      ],
    );
  }
}

Future<String?> _requestRemoteName(BuildContext context, String initialName) {
  return showDialog<String>(
    context: context,
    builder: (context) => _RemoteNameDialog(initialName: initialName),
  );
}

class _RemoteNameDialog extends StatefulWidget {
  const _RemoteNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_RemoteNameDialog> createState() => _RemoteNameDialogState();
}

class _RemoteNameDialogState extends State<_RemoteNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('遥控器改名'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 8,
        decoration: const InputDecoration(labelText: '名称'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _DeviceCommandMessage extends StatelessWidget {
  const _DeviceCommandMessage({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String message;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message, style: TextStyle(color: foregroundColor)),
      ),
    );
  }
}
