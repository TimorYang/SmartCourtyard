import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';

class WifiConfigurationPage extends ConsumerStatefulWidget {
  const WifiConfigurationPage({super.key});

  static const routeName = 'wifi-configuration';
  static const routePath = '/add-device/wifi';

  @override
  ConsumerState<WifiConfigurationPage> createState() =>
      _WifiConfigurationPageState();
}

class _WifiConfigurationPageState extends ConsumerState<WifiConfigurationPage> {
  late final TextEditingController _ssidController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(addDeviceControllerProvider);
    _ssidController = TextEditingController(text: initialState.wifiSsid);
    _passwordController = TextEditingController(
      text: initialState.wifiPassword,
    );
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addDeviceControllerProvider);
    final controller = ref.read(addDeviceControllerProvider.notifier);
    final selectedDevice = state.selectedDevice;

    if (_ssidController.text != state.wifiSsid) {
      _ssidController.value = _ssidController.value.copyWith(
        text: state.wifiSsid,
        selection: TextSelection.collapsed(offset: state.wifiSsid.length),
      );
    }
    if (_passwordController.text != state.wifiPassword) {
      _passwordController.value = _passwordController.value.copyWith(
        text: state.wifiPassword,
        selection: TextSelection.collapsed(offset: state.wifiPassword.length),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Wi‑Fi 配置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (selectedDevice == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('当前没有已连接设备，请返回蓝牙扫描页重新连接。'),
              ),
            )
          else ...[
            Text('已连接设备：${selectedDevice.name ?? selectedDevice.id}'),
            Text('设备 ID：${selectedDevice.id}'),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: state.isScanningWifi
                  ? null
                  : () => _openWifiPicker(context),
              icon: const Icon(Icons.wifi_find_outlined),
              label: const Text('扫描附近 Wi‑Fi'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ssidController,
              onChanged: controller.updateWifiSsid,
              decoration: const InputDecoration(
                labelText: 'SSID',
                hintText: '选择或输入 Wi‑Fi 名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              onChanged: controller.updateWifiPassword,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Wi‑Fi 密码',
                hintText: '请输入 Wi‑Fi 密码',
                border: OutlineInputBorder(),
              ),
            ),
            if (state.infoMessage != null) ...[
              const SizedBox(height: 16),
              _WifiMessage(
                message: state.infoMessage!,
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade900,
              ),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              _WifiMessage(
                message: state.errorMessage!,
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade900,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: state.isProvisioningWifi
                  ? null
                  : () async {
                      final success = await controller.configureWifi();
                      if (!context.mounted || !success) {
                        return;
                      }
                      context.go('/');
                    },
              child: Text(state.isProvisioningWifi ? '连接中...' : '开始连接'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openWifiPicker(BuildContext context) async {
    final controller = ref.read(addDeviceControllerProvider.notifier);
    final networks = await controller.scanWifiNetworks();
    if (!context.mounted || networks.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: networks.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final network = networks[index];
              return ListTile(
                leading: const Icon(Icons.wifi),
                title: Text(network.ssid),
                onTap: () {
                  controller.selectWifiNetwork(network.ssid);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _WifiMessage extends StatelessWidget {
  const _WifiMessage({
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
