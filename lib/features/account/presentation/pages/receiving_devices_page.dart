import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/design_system/door_type_visuals.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';

class ReceivingDevicesPage extends StatelessWidget {
  const ReceivingDevicesPage({super.key});

  static const routeName = 'receiving-devices';
  static const routePath = '/account/receiving-devices';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final devices = [
      _ReceivingDevice(name: l10n.receivingDevicesSmartDoorA, sharingStatus: l10n.receivingDevicesSharedWithPeople(2), icon: _ReceivingDeviceIcon.garageDoor),
      _ReceivingDevice(name: l10n.receivingDevicesSmartDoorB, sharingStatus: l10n.receivingDevicesNotShared, icon: _ReceivingDeviceIcon.garageDoor),
      _ReceivingDevice(name: l10n.receivingDevicesSmartDoorB, sharingStatus: l10n.receivingDevicesNotShared, icon: _ReceivingDeviceIcon.camera),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: FlinxNavigationBar(
        title: '',
        showBottomDivider: false,
        actions: [
          Semantics(
            key: ReceivingDevicesKeys.editButton,
            button: true,
            enabled: false,
            label: l10n.receivingDevicesEditLabel,
            child: Padding(padding: EdgeInsets.only(right: 20), child: Image.asset("assets/icons/account/shared_device_member_edit_placeholder.png")),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacingTokens.receivingDevicesPageHorizontal,
                    AppSpacingTokens.receivingDevicesTitleTop,
                    AppSpacingTokens.receivingDevicesPageHorizontal,
                    0,
                  ),
                  child: Text(l10n.receivingDevicesTitle, style: AppTextTokens.receivingDevicesTitle(Theme.of(context).textTheme)),
                ),
                const SizedBox(height: AppSpacingTokens.receivingDevicesTitleToList),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacingTokens.receivingDevicesPageHorizontal),
                    itemCount: devices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacingTokens.receivingDevicesCardGap),
                    itemBuilder: (context, index) => _ReceivingDeviceCard(device: devices[index], index: index),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReceivingDevicesKeys {
  const ReceivingDevicesKeys._();

  static const editButton = ValueKey('receiving-devices-edit-button');

  static ValueKey<String> deviceCard(int index) => ValueKey('receiving-devices-card-$index');
}

enum _ReceivingDeviceIcon { garageDoor, camera }

class _ReceivingDevice {
  const _ReceivingDevice({required this.name, required this.sharingStatus, required this.icon});

  final String name;
  final String sharingStatus;
  final _ReceivingDeviceIcon icon;
}

class _ReceivingDeviceCard extends StatelessWidget {
  const _ReceivingDeviceCard({required this.device, required this.index});

  final _ReceivingDevice device;
  final int index;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: ReceivingDevicesKeys.deviceCard(index),
      height: AppSpacingTokens.receivingDevicesCardHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacingTokens.receivingDevicesCardHorizontal),
      decoration: const BoxDecoration(
        color: AppColors.receivingDevicesCard,
        borderRadius: BorderRadius.all(Radius.circular(AppShapeTokens.receivingDevicesCardRadius)),
      ),
      child: Row(
        children: [
          _ReceivingDeviceIconView(icon: device.icon),
          const SizedBox(width: AppSpacingTokens.receivingDevicesIconToText),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextTokens.receivingDevicesCardTitle(textTheme)),
                const SizedBox(height: AppSpacingTokens.receivingDevicesCardTitleToSubtitle),
                Text(device.sharingStatus, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextTokens.receivingDevicesCardSubtitle(textTheme)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivingDeviceIconView extends StatelessWidget {
  const _ReceivingDeviceIconView({required this.icon});

  final _ReceivingDeviceIcon icon;

  @override
  Widget build(BuildContext context) {
    final visual = DoorTypeVisuals.forType(DoorType.garage);
    final assetPath = switch (icon) {
      _ReceivingDeviceIcon.garageDoor => visual.assetPath,
      _ReceivingDeviceIcon.camera => 'assets/icons/add_device/add_device_camera.png',
    };
    final fallbackIcon = switch (icon) {
      _ReceivingDeviceIcon.garageDoor => visual.fallbackIcon,
      _ReceivingDeviceIcon.camera => Icons.videocam_outlined,
    };

    return Image.asset(
      assetPath,
      width: AppSpacingTokens.receivingDevicesIconSize,
      height: AppSpacingTokens.receivingDevicesIconSize,
      errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: AppColors.textPrimary, size: AppSpacingTokens.receivingDevicesIconSize),
    );
  }
}
