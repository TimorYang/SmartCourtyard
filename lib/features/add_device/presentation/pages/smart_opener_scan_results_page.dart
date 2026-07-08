import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import 'smart_opener_choose_wifi_page.dart';

class SmartOpenerScanResultsPage extends ConsumerStatefulWidget {
  const SmartOpenerScanResultsPage({super.key});

  static const routeName = 'smart-opener-scan-results';
  static const routePath = '/add-device/smart-opener/scan-results';

  @override
  ConsumerState<SmartOpenerScanResultsPage> createState() =>
      _SmartOpenerScanResultsPageState();
}

class _SmartOpenerScanResultsPageState
    extends ConsumerState<SmartOpenerScanResultsPage> {
  String? _pendingDeviceId;

  Future<void> _addDevice(BleDevice device) async {
    setState(() {
      _pendingDeviceId = device.id;
    });
    final controller = ref.read(addDeviceControllerProvider.notifier);
    final connected = await controller.connectAndAuthenticate(device);
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingDeviceId = null;
    });
    if (connected) {
      context.push(SmartOpenerChooseWifiPage.routePath);
      return;
    }

    final state = ref.read(addDeviceControllerProvider);
    final message = state.errorMessage ?? 'Unable to connect device.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final devices = ref.watch(addDeviceControllerProvider).sortedDevices();

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
          itemCount: devices.length + 1,
          separatorBuilder: (context, index) => index == 0
              ? const SizedBox(height: 17)
              : const SizedBox(height: 18),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.smartOpenerScanResultsTitle,
                    style: AppTextTokens.smartOpenerFlowTitle(textTheme),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.smartOpenerScanResultsCount(devices.length),
                    style: AppTextTokens.smartOpenerFlowSubtitle(textTheme),
                  ),
                ],
              );
            }

            final device = devices[index - 1];
            return _ScanResultCard(
              device: device,
              isPending: _pendingDeviceId == device.id,
              onAddPressed: _pendingDeviceId == null
                  ? () => _addDevice(device)
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  const _ScanResultCard({
    required this.device,
    required this.isPending,
    required this.onAddPressed,
  });

  final BleDevice device;
  final bool isPending;
  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final name = device.name?.trim().isNotEmpty == true
        ? device.name!.trim()
        : 'Smart Door';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 95),
      padding: const EdgeInsets.fromLTRB(15, 23, 15, 23),
      decoration: BoxDecoration(
        color: AppColors.smartOpenerCardSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.door_front_door_outlined,
            size: 48,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.smartOpenerResultCardTitle(textTheme),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.smartOpenerDefaultDeviceSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.smartOpenerResultCardSubtitle(textTheme),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            height: 32,
            child: FilledButton(
              onPressed: onAddPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.smartOpenerAddButton,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.textHint,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: isPending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.smartOpenerAddAction,
                      style: AppTextTokens.smartOpenerSmallButton(textTheme),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
