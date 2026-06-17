import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/device_command_controller.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('设备控制')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('当前设备', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          SelectableText(deviceId.isEmpty ? '未选择设备' : deviceId),
          const SizedBox(height: 16),
          GridView.builder(
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
                onPressed: state.pendingAction == null
                    ? () => controller.runAction(
                        deviceId: deviceId,
                        action: action,
                      )
                    : null,
                child: Text(isPending ? '发送中...' : action.label),
              );
            },
          ),
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
        ],
      ),
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
