import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import 'f_box_connection_guide_page.dart';
import 'smart_opener_qr_scan_page.dart';
import 'usb_dongle_guide_page.dart';

class AddDeviceAssetPaths {
  const AddDeviceAssetPaths._();

  static const fBox = 'assets/icons/add_device/add_device_f_box.png';
  static const usbWifiModule = 'assets/icons/add_device/add_device_usb_wifi_module.png';
  static const smartOpener = 'assets/icons/add_device/add_device_smart_opener.png';
  static const solarEnergySystem = 'assets/icons/add_device/add_device_solar_energy_system.png';
  static const camera = 'assets/icons/add_device/add_device_camera.png';
}

class AddDevicePage extends ConsumerStatefulWidget {
  const AddDevicePage({super.key, required this.doorType, this.doorId});

  static const routeName = 'add-device';
  static const routePath = '/add-device';
  static const doorTypeQueryParameter = 'doorType';
  static const doorIdQueryParameter = 'doorId';

  final DoorType doorType;
  final String? doorId;

  @override
  ConsumerState<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends ConsumerState<AddDevicePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(addDeviceControllerProvider.notifier).beginOnboardingFlow(doorId: widget.doorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 18, 46),
        children: [
          Text(l10n.addDeviceTitle, style: AppTextTokens.addDeviceTitle(textTheme)),
          const SizedBox(height: 2),
          Text(l10n.addDeviceSubtitle, style: AppTextTokens.addDeviceSubtitle(textTheme)),
          const SizedBox(height: 42),
          _DeviceSectionTitle(label: l10n.addDeviceFBoxSection),
          const SizedBox(height: 10),
          _DeviceOptionCard(
            label: l10n.addDeviceFBox,
            assetPath: AddDeviceAssetPaths.fBox,
            fallbackIcon: Icons.developer_board_outlined,
            onTap: () => context.push(FBoxConnectionGuidePage.routePath),
          ),
          const SizedBox(height: 29),
          _DeviceSectionTitle(label: l10n.addDeviceSmartControllerSection),
          const SizedBox(height: 14),
          _DeviceOptionCard(
            label: l10n.addDeviceUsbWifiModule,
            assetPath: AddDeviceAssetPaths.usbWifiModule,
            fallbackIcon: Icons.usb_outlined,
            onTap: () =>
                context.pushNamed(UsbDongleGuidePage.routeName, queryParameters: {AddDevicePage.doorTypeQueryParameter: widget.doorType.wireValue.toString()}),
          ),
          const SizedBox(height: 14),
          _DeviceOptionCard(
            label: l10n.addDeviceSmartOpener,
            assetPath: AddDeviceAssetPaths.smartOpener,
            fallbackIcon: Icons.wifi_tethering_outlined,
            onTap: () => context.push(SmartOpenerQrScanPage.routePath),
          ),
          const SizedBox(height: 14),
          _DeviceOptionCard(label: l10n.addDeviceSolarEnergySystem, assetPath: AddDeviceAssetPaths.solarEnergySystem, fallbackIcon: Icons.solar_power_outlined),
          const SizedBox(height: 26),
          _DeviceSectionTitle(label: l10n.addDeviceSmartAccessorySection),
          const SizedBox(height: 14),
          _DeviceOptionCard(label: l10n.addDeviceCamera, assetPath: AddDeviceAssetPaths.camera, fallbackIcon: Icons.videocam_outlined),
        ],
      ),
    );
  }
}

class _DeviceSectionTitle extends StatelessWidget {
  const _DeviceSectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextTokens.addDeviceSectionTitle(Theme.of(context).textTheme));
  }
}

class _DeviceOptionCard extends StatelessWidget {
  const _DeviceOptionCard({required this.label, required this.assetPath, required this.fallbackIcon, this.onTap});

  final String label;
  final String assetPath;
  final IconData fallbackIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceItemSceneCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 96,
          child: Row(
            children: [
              const SizedBox(width: 18),
              _DeviceOptionIcon(assetPath: assetPath, fallbackIcon: fallbackIcon),
              const SizedBox(width: 25),
              Expanded(child: Text(label, style: AppTextTokens.addDeviceCardTitle(Theme.of(context).textTheme))),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceOptionIcon extends StatelessWidget {
  const _DeviceOptionIcon({required this.assetPath, required this.fallbackIcon});

  final String assetPath;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: 64,
      height: 64,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, color: AppColors.iconHomeAction, size: 64);
      },
    );
  }
}
