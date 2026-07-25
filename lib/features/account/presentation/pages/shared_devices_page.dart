import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/design_system/door_type_visuals.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../home/presentation/pages/device_share_page.dart';
import 'shared_device_member_management_page.dart';

class SharedDevicesPage extends StatelessWidget {
  const SharedDevicesPage({super.key});

  static const routeName = 'shared-devices';
  static const routePath = '/account/shared-devices';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final devices = [
      _SharedDevice(
        name: l10n.addNewDoorsGarageDoor,
        doorType: DoorType.garage,
      ),
      _SharedDevice(
        name: l10n.addNewDoorsIndustrialDoor,
        doorType: DoorType.industrial,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
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
                    AppSpacingTokens.sharedDevicesPageHorizontal,
                    AppSpacingTokens.sharedDevicesTitleTop,
                    AppSpacingTokens.sharedDevicesPageHorizontal,
                    0,
                  ),
                  child: Text(
                    l10n.sharedDevicesTitle,
                    style: AppTextTokens.sharedDevicesTitle(textTheme),
                  ),
                ),
                const SizedBox(
                  height: AppSpacingTokens.sharedDevicesTitleToList,
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacingTokens.sharedDevicesPageHorizontal,
                    ),
                    itemCount: devices.length,
                    separatorBuilder: (_, _) => const SizedBox(
                      height: AppSpacingTokens.sharedDevicesCardGap,
                    ),
                    itemBuilder: (context, index) => _SharedDeviceCard(
                      key: SharedDevicesKeys.deviceCard(index),
                      device: devices[index],
                      shareDescription: l10n.sharedDevicesShareToPeople(3),
                      onTap: () => context.pushNamed(SharedDeviceMemberManagementPage.routeName),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacingTokens.sharedDevicesAddButtonBottom,
                  ),
                  child: Center(
                    child: Semantics(
                      button: true,
                      label: l10n.sharedDevicesAddLabel,
                      child: GestureDetector(
                        onTap: () => context.pushNamed(
                            DeviceSharePage.routeName,
                        ),
                        child: const _AddSharedDeviceButton(),
                      ),
                    ),
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

class SharedDevicesKeys {
  const SharedDevicesKeys._();

  static const addButton = ValueKey('shared-devices-add-button');

  static ValueKey<String> deviceCard(int index) =>
      ValueKey('shared-devices-device-card-$index');
}

class _SharedDevice {
  const _SharedDevice({required this.name, required this.doorType});

  final String name;
  final DoorType doorType;
}

class _SharedDeviceCard extends StatelessWidget {
  const _SharedDeviceCard({
    super.key,
    required this.device,
    required this.shareDescription,
    required this.onTap,
  });

  final _SharedDevice device;
  final String shareDescription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visual = DoorTypeVisuals.forType(device.doorType);

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppSpacingTokens.sharedDevicesCardHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacingTokens.sharedDevicesCardHorizontal,
          ),
          decoration: const BoxDecoration(
            color: AppColors.sharedDevicesCard,
            borderRadius: BorderRadius.all(
              Radius.circular(AppShapeTokens.sharedDevicesCardRadius),
            ),
          ),
          child: Row(
            children: [
              Image.asset(
                visual.assetPath,
                width: AppSpacingTokens.sharedDevicesIconSize,
                height: AppSpacingTokens.sharedDevicesIconSize,
                errorBuilder: (context, error, stackTrace) => Icon(
                  visual.fallbackIcon,
                  color: AppColors.textPrimary,
                  size: AppSpacingTokens.sharedDevicesIconSize,
                ),
              ),
              const SizedBox(width: AppSpacingTokens.sharedDevicesIconToText),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextTokens.sharedDevicesCardTitle(textTheme),
                    ),
                    const SizedBox(
                      height: AppSpacingTokens.sharedDevicesCardTitleToSubtitle,
                    ),
                    Text(
                      shareDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextTokens.sharedDevicesCardSubtitle(textTheme),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSharedDeviceButton extends StatelessWidget {
  const _AddSharedDeviceButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: SharedDevicesKeys.addButton,
      width: AppSpacingTokens.sharedDevicesAddButtonSize,
      height: AppSpacingTokens.sharedDevicesAddButtonSize,
      decoration: const BoxDecoration(
        color: AppColors.sharedDevicesAddButton,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: AppSpacingTokens.sharedDevicesAddIconSize,
      ),
    );
  }
}
