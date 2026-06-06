import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../../../platform_bridge/hardware_models.dart';
import 'wifi_configuration_page.dart';

class AddDevicePage extends ConsumerStatefulWidget {
  const AddDevicePage({super.key});

  static const routeName = 'add-device';
  static const routePath = '/add-device';

  @override
  ConsumerState<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends ConsumerState<AddDevicePage> {
  late final TextEditingController _authTokenController;

  @override
  void initState() {
    super.initState();
    final initialToken = ref.read(addDeviceControllerProvider).authToken;
    _authTokenController = TextEditingController(text: initialToken);
    Future<void>.microtask(
      () => ref.read(addDeviceControllerProvider.notifier).startScan(),
    );
  }

  @override
  void dispose() {
    ref.read(addDeviceControllerProvider.notifier).stopScan();
    _authTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addDeviceControllerProvider);
    final controller = ref.read(addDeviceControllerProvider.notifier);
    final devices = state.sortedDevices();

    return Scaffold(
      appBar: AppBar(title: const Text('添加设备')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('先扫描并连接蓝牙设备，鉴权成功后进入 Wi‑Fi 配置页面。'),
          const SizedBox(height: 16),
          TextField(
            controller: _authTokenController,
            onChanged: controller.updateAuthToken,
            decoration: const InputDecoration(
              labelText: '鉴权 Token（32 位 MD5）',
              hintText: '请输入设备鉴权 Token',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: state.isScanning ? null : controller.startScan,
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('开始扫描'),
              ),
              OutlinedButton.icon(
                onPressed: state.isScanning ? controller.stopScan : null,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('停止扫描'),
              ),
            ],
          ),
          if (state.infoMessage != null) ...[
            const SizedBox(height: 16),
            _MessageBanner(
              message: state.infoMessage!,
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue.shade900,
            ),
          ],
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            _MessageBanner(
              message: state.errorMessage!,
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade900,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            '蓝牙设备 (${devices.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (devices.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('暂未发现蓝牙设备，请确认设备已上电且在附近。'),
              ),
            ),
          for (final device in devices) ...[
            _BleDeviceCard(
              device: device,
              connectionState: state.connectionStateFor(device.id),
              busy: state.isConnecting || state.isAuthenticating,
              onConnect: () async {
                final success = await controller.connectAndAuthenticate(device);
                if (!context.mounted || !success) {
                  return;
                }
                context.push(WifiConfigurationPage.routePath);
              },
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _BleDeviceCard extends StatelessWidget {
  const _BleDeviceCard({
    required this.device,
    required this.connectionState,
    required this.busy,
    required this.onConnect,
  });

  final BleDevice device;
  final BleConnectionState connectionState;
  final bool busy;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.name ?? '未命名设备'),
            const SizedBox(height: 8),
            Text('设备 ID: ${device.id}'),
            Text('RSSI: ${device.rssi}'),
            Text('连接状态: ${connectionState.name}'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: busy ? null : onConnect,
                child: const Text('连接并鉴权'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message, style: TextStyle(color: foregroundColor)),
      ),
    );
  }
}
