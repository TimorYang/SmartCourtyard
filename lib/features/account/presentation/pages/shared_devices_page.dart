import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/design_system/door_type_visuals.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../../domain/entities/shared_door.dart';
import 'shared_device_member_management_page.dart';

class SharedDevicesPage extends ConsumerStatefulWidget {
  const SharedDevicesPage({super.key});

  static const routeName = 'shared-devices';
  static const routePath = '/account/shared-devices';

  @override
  ConsumerState<SharedDevicesPage> createState() => _SharedDevicesPageState();
}

class _SharedDevicesPageState extends ConsumerState<SharedDevicesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(sharedDevicesControllerProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final sharedDevices = ref.watch(sharedDevicesControllerProvider);

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
                  child: sharedDevices.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => _SharedDevicesErrorState(
                      message: l10n.sharedDevicesLoadFailed,
                      retryLabel: l10n.sharedDevicesRetry,
                      onRetry: () => ref
                          .read(sharedDevicesControllerProvider.notifier)
                          .refresh(),
                    ),
                    data: (devices) {
                      if (devices.isEmpty) {
                        return Center(child: Text(l10n.sharedDevicesEmpty));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal:
                              AppSpacingTokens.sharedDevicesPageHorizontal,
                        ),
                        itemCount: devices.length,
                        separatorBuilder: (_, _) => const SizedBox(
                          height: AppSpacingTokens.sharedDevicesCardGap,
                        ),
                        itemBuilder: (context, index) => _SharedDeviceCard(
                          key: SharedDevicesKeys.deviceCard(index),
                          device: devices[index],
                          shareDescription: l10n.sharedDevicesShareToPeople(
                            devices[index].sharedUserCount,
                          ),
                          onTap: () => context.pushNamed(
                            SharedDeviceMemberManagementPage.routeName,
                            extra: devices[index],
                          ),
                        ),
                      );
                    },
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
  static const retryButton = ValueKey('shared-devices-retry-button');

  static ValueKey<String> deviceCard(int index) =>
      ValueKey('shared-devices-device-card-$index');
}

class _SharedDeviceCard extends StatelessWidget {
  const _SharedDeviceCard({
    super.key,
    required this.device,
    required this.shareDescription,
    required this.onTap,
  });

  final SharedDoor device;
  final String shareDescription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visual = DoorTypeVisuals.forType(DoorType.garage);

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

class _SharedDevicesErrorState extends StatelessWidget {
  const _SharedDevicesErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          TextButton(
            key: SharedDevicesKeys.retryButton,
            onPressed: onRetry,
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}
