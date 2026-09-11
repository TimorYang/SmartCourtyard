import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../device_control/presentation/pages/device_command_page.dart';

class WifiConfigurationPage extends ConsumerStatefulWidget {
  const WifiConfigurationPage({super.key, this.qrPayload});

  static const routeName = 'wifi-configuration';
  static const routePath = '/add-device/wifi';

  final String? qrPayload;

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
    final l10n = AppLocalizations.of(context);
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
      appBar: FlinxNavigationBar(title: l10n.wifiConfigurationTitle),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.qrPayload != null && widget.qrPayload!.trim().isNotEmpty)
            _WifiMessage(
              message: l10n.smartOpenerQrPayloadReceived,
              backgroundColor: context.colors.surfaceSceneCard,
              foregroundColor: context.colors.textMuted,
            ),
          if (widget.qrPayload != null && widget.qrPayload!.trim().isNotEmpty)
            const SizedBox(height: 12),
          if (selectedDevice == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.wifiConfigurationNoDevice),
              ),
            )
          else ...[
            Text(
              l10n.wifiConfigurationConnectedDevice(
                selectedDevice.name ?? selectedDevice.id,
              ),
            ),
            Text(l10n.wifiConfigurationDeviceId(selectedDevice.id)),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: state.isScanningWifi
                  ? null
                  : () => controller.scanWifiNetworks(),
              icon: const Icon(Icons.wifi_find_outlined),
              label: Text(
                state.isScanningWifi
                    ? l10n.wifiConfigurationScanning
                    : l10n.wifiConfigurationScan,
              ),
            ),
            if (state.wifiNetworks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.wifiConfigurationNetworks,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final network in state.wifiNetworks)
                      ListTile(
                        leading: const Icon(Icons.wifi),
                        title: Text(network.ssid),
                        trailing: state.wifiSsid == network.ssid
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () => controller.selectWifiNetwork(network.ssid),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _ssidController,
              onChanged: controller.updateWifiSsid,
              decoration: InputDecoration(
                labelText: l10n.wifiConfigurationSsid,
                hintText: l10n.wifiConfigurationSsidHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              onChanged: controller.updateWifiPassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.wifiConfigurationPassword,
                hintText: l10n.wifiConfigurationPasswordHint,
                border: const OutlineInputBorder(),
              ),
            ),
            if (state.infoMessage != null) ...[
              const SizedBox(height: 16),
              _WifiMessage(
                message: state.infoMessage!,
                backgroundColor: context.colors.wifiInfoSurface,
                foregroundColor: context.colors.wifiInfoForeground,
              ),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              _WifiMessage(
                message: state.errorMessage!,
                backgroundColor: context.colors.wifiErrorSurface,
                foregroundColor: context.colors.wifiErrorForeground,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed:
                  state.isProvisioningWifi ||
                      state.wifiSsid.trim().isEmpty ||
                      state.wifiPassword.isEmpty
                  ? null
                  : () async {
                      final success = await controller.configureWifi();
                      if (!context.mounted || !success) {
                        return;
                      }
                      final deviceId = Uri.encodeQueryComponent(
                        selectedDevice.id,
                      );
                      context.go(
                        '${DeviceCommandPage.routePath}'
                        '?doorId=$deviceId&deviceId=$deviceId',
                      );
                    },
              child: Text(
                state.isProvisioningWifi
                    ? l10n.wifiConfigurationConnecting
                    : l10n.wifiConfigurationConnect,
              ),
            ),
          ],
        ],
      ),
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
        borderRadius: BorderRadius.circular(AppSpacingTokens.wifiMessageRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message, style: TextStyle(color: foregroundColor)),
      ),
    );
  }
}
