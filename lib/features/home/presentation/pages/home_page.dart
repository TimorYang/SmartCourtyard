import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../add_device/presentation/pages/add_device_page.dart';
import '../../../../features/hardware_debug/presentation/pages/ble_debug_page.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../application/providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const routeName = 'home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(homeDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FLINX'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(AddDevicePage.routePath),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Device'),
          ),
          TextButton.icon(
            onPressed: () => context.push(BleDebugPage.routePath),
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('BLE Debug'),
          ),
        ],
      ),
      body: devices.when(
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyHomeState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              return _DeviceCard(device: items[index]);
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: items.length,
          );
        },
        error: (error, stackTrace) {
          return const Center(child: Text('Unable to load devices.'));
        },
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _EmptyHomeState extends StatelessWidget {
  const _EmptyHomeState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No devices yet.'));
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final DeviceSummary device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Door: ${device.doorState.name}'),
            Text('Connection: ${device.bleState.name}'),
            Text('Life remaining: ${device.remainingLifePercent}%'),
          ],
        ),
      ),
    );
  }
}
