import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/design_system/door_type_option.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../../domain/entities/receiving_door.dart';

class ReceivingDevicesPage extends ConsumerStatefulWidget {
  const ReceivingDevicesPage({super.key});

  static const routeName = 'receiving-devices';
  static const routePath = '/account/receiving-devices';

  @override
  ConsumerState<ReceivingDevicesPage> createState() =>
      _ReceivingDevicesPageState();
}

class _ReceivingDevicesPageState extends ConsumerState<ReceivingDevicesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(receivingDevicesControllerProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final receivingDevices = ref.watch(receivingDevicesControllerProvider);

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
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Image.asset(
                'assets/icons/account/shared_device_member_edit_placeholder.png',
              ),
            ),
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
                  child: Text(
                    l10n.receivingDevicesTitle,
                    style: AppTextTokens.receivingDevicesTitle(
                      Theme.of(context).textTheme,
                    ),
                  ),
                ),
                const SizedBox(
                  height: AppSpacingTokens.receivingDevicesTitleToList,
                ),
                Expanded(
                  child: receivingDevices.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => _ReceivingDevicesErrorState(
                      message: l10n.receivingDevicesLoadFailed,
                      retryLabel: l10n.receivingDevicesRetry,
                      onRetry: () => ref
                          .read(receivingDevicesControllerProvider.notifier)
                          .refresh(),
                    ),
                    data: (devices) {
                      if (devices.isEmpty) {
                        return Center(child: Text(l10n.receivingDevicesEmpty));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal:
                              AppSpacingTokens.receivingDevicesPageHorizontal,
                        ),
                        itemCount: devices.length,
                        separatorBuilder: (_, _) => const SizedBox(
                          height: AppSpacingTokens.receivingDevicesCardGap,
                        ),
                        itemBuilder: (context, index) => _ReceivingDeviceCard(
                          key: ReceivingDevicesKeys.deviceCard(index),
                          device: devices[index],
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

class ReceivingDevicesKeys {
  const ReceivingDevicesKeys._();

  static const editButton = ValueKey('receiving-devices-edit-button');
  static const retryButton = ValueKey('receiving-devices-retry-button');

  static ValueKey<String> deviceCard(int index) =>
      ValueKey('receiving-devices-card-$index');
}

class _ReceivingDeviceCard extends StatelessWidget {
  const _ReceivingDeviceCard({super.key, required this.device});

  final ReceivingDoor device;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final visual = DoorTypeOption.fromDoorType(DoorType.garage);

    return Container(
      height: AppSpacingTokens.receivingDevicesCardHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.receivingDevicesCardHorizontal,
      ),
      decoration: const BoxDecoration(
        color: AppColors.receivingDevicesCard,
        borderRadius: BorderRadius.all(
          Radius.circular(AppShapeTokens.receivingDevicesCardRadius),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            visual.assetPath,
            width: AppSpacingTokens.receivingDevicesIconSize,
            height: AppSpacingTokens.receivingDevicesIconSize,
            errorBuilder: (context, error, stackTrace) => Icon(
              visual.fallbackIcon,
              color: AppColors.textPrimary,
              size: AppSpacingTokens.receivingDevicesIconSize,
            ),
          ),
          const SizedBox(width: AppSpacingTokens.receivingDevicesIconToText),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.receivingDevicesCardTitle(textTheme),
                ),
                const SizedBox(
                  height: AppSpacingTokens.receivingDevicesCardTitleToSubtitle,
                ),
                Text(
                  l10n.receivingDevicesOwnerEmail(device.ownerEmail),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.receivingDevicesCardSubtitle(textTheme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivingDevicesErrorState extends StatelessWidget {
  const _ReceivingDevicesErrorState({
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
            key: ReceivingDevicesKeys.retryButton,
            onPressed: onRetry,
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}
