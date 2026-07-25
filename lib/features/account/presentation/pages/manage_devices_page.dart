import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../domain/entities/managed_login_device.dart';

class ManageDevicesPage extends StatelessWidget {
  const ManageDevicesPage({super.key});

  static const routeName = 'manage-devices';
  static const routePath = '/account/manage-devices';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final devices = _ManageDevicesMockData.create(l10n);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: FlinxNavigationBar(
        title: '',
        showBottomDivider: false,
        actions: [
          Semantics(
            label: l10n.manageDevicesEditLabel,
            child: Image.asset(
              ManageDevicesAssetPaths.edit,
              width: AppSpacingTokens.manageDevicesActionIconSize,
              height: AppSpacingTokens.manageDevicesActionIconSize,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: AppSpacingTokens.manageDevicesActionEndPadding),
        ],
      ),
      body: _ManageDevicesContent(
        devices: devices,
        title: l10n.manageDevicesTitle,
        subtitle: l10n.manageDevicesSubtitle,
        textTheme: textTheme,
      ),
    );
  }
}

class ManageDevicesAssetPaths {
  const ManageDevicesAssetPaths._();

  static const edit = 'assets/icons/account/manage_devices_edit.png';
  static const phone = 'assets/icons/account/manage_devices_phone.png';
  static const tablet = 'assets/icons/account/manage_devices_tablet.png';
  static const logout = 'assets/icons/account/manage_devices_logout.png';
}

class _ManageDevicesMockData {
  const _ManageDevicesMockData._();

  static List<ManagedLoginDevice> create(AppLocalizations l10n) {
    return [
      ManagedLoginDevice(
        id: 'iphone-16-pro-max',
        name: l10n.manageDevicesPhoneName,
        type: ManagedLoginDeviceType.phone,
        loggedInAt: DateTime(2025, 8, 2, 11, 2),
        isCurrentDevice: true,
      ),
      ManagedLoginDevice(
        id: 'ipad-air',
        name: l10n.manageDevicesTabletName,
        type: ManagedLoginDeviceType.tablet,
        loggedInAt: DateTime(2025, 8, 2, 11, 2),
        isCurrentDevice: false,
      ),
    ];
  }
}

class _ManageDevicesContent extends StatelessWidget {
  const _ManageDevicesContent({
    required this.devices,
    required this.title,
    required this.subtitle,
    required this.textTheme,
  });

  final List<ManagedLoginDevice> devices;
  final String title;
  final String subtitle;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacingTokens.manageDevicesPageHorizontal,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacingTokens.manageDevicesTitleTop),
                Text(title, style: AppTextTokens.sharedDevicesTitle(textTheme)),
                const SizedBox(
                  height: AppSpacingTokens.manageDevicesTitleToSubtitle,
                ),
                Text(
                  subtitle,
                  style: AppTextTokens.manageDevicesSubtitle(textTheme),
                ),
                const SizedBox(
                  height: AppSpacingTokens.manageDevicesSubtitleToList,
                ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: devices.length,
                    separatorBuilder: (_, _) => const SizedBox(
                      height: AppSpacingTokens.manageDevicesCardGap,
                    ),
                    itemBuilder: (context, index) =>
                        _ManagedDeviceCard(device: devices[index]),
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

class ManageDevicesKeys {
  const ManageDevicesKeys._();

  static const phoneCard = ValueKey('manage-devices-phone-card');
  static const tabletCard = ValueKey('manage-devices-tablet-card');
}

class _ManagedDeviceCard extends StatelessWidget {
  const _ManagedDeviceCard({required this.device});

  final ManagedLoginDevice device;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cardKey = device.type == ManagedLoginDeviceType.phone
        ? ManageDevicesKeys.phoneCard
        : ManageDevicesKeys.tabletCard;
    final l10n = AppLocalizations.of(context);

    return Container(
      key: cardKey,
      height: AppSpacingTokens.manageDevicesCardHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.manageDevicesCardHorizontal,
      ),
      decoration: const BoxDecoration(
        color: AppColors.manageDevicesCard,
        borderRadius: BorderRadius.all(
          Radius.circular(AppShapeTokens.sharedDevicesCardRadius),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            device.type == ManagedLoginDeviceType.phone
                ? ManageDevicesAssetPaths.phone
                : ManageDevicesAssetPaths.tablet,
            width: AppSpacingTokens.manageDevicesIconSize,
            height: AppSpacingTokens.manageDevicesIconSize,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          const SizedBox(width: AppSpacingTokens.manageDevicesIconToText),
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
                  height: AppSpacingTokens.manageDevicesCardTitleToTimestamp,
                ),
                Text(
                  l10n.manageDevicesLoginTimestamp(
                    device.loggedInAt.year,
                    device.loggedInAt.month.toString().padLeft(2, '0'),
                    device.loggedInAt.day.toString().padLeft(2, '0'),
                    device.loggedInAt.hour.toString().padLeft(2, '0'),
                    device.loggedInAt.minute.toString().padLeft(2, '0'),
                  ),
                  style: AppTextTokens.manageDevicesCardTimestamp(textTheme),
                ),
              ],
            ),
          ),
          Semantics(
            label: l10n.manageDevicesLogoutLabel,
            child: Image.asset(
              ManageDevicesAssetPaths.logout,
              width: AppSpacingTokens.manageDevicesActionIconSize,
              height: AppSpacingTokens.manageDevicesActionIconSize,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
