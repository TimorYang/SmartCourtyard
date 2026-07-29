import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../../domain/entities/managed_login_device.dart';

class ManageDevicesPage extends ConsumerStatefulWidget {
  const ManageDevicesPage({super.key});

  static const routeName = 'manage-devices';
  static const routePath = '/account/manage-devices';

  @override
  ConsumerState<ManageDevicesPage> createState() => _ManageDevicesPageState();
}

class _ManageDevicesPageState extends ConsumerState<ManageDevicesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(managedDevicesControllerProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final devices = ref.watch(managedDevicesControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: FlinxNavigationBar(title: '', showBottomDivider: false),
      body: devices.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ManageDevicesErrorState(
          message: l10n.manageDevicesLoadFailed,
          retryLabel: l10n.manageDevicesRetry,
          onRetry: () =>
              ref.read(managedDevicesControllerProvider.notifier).refresh(),
        ),
        data: (items) => items.isEmpty
            ? Center(
                child: Text(
                  l10n.manageDevicesEmpty,
                  style: AppTextTokens.manageDevicesSubtitle(textTheme),
                ),
              )
            : _ManageDevicesContent(
                devices: items,
                title: l10n.manageDevicesTitle,
                subtitle: l10n.manageDevicesSubtitle,
                textTheme: textTheme,
                onRemoveRequested: (device) => _showManagedDeviceRemovalDialog(
                  context,
                  onConfirm: () async {
                    try {
                      await ref
                          .read(managedDevicesControllerProvider.notifier)
                          .removeDevice(device.sessionId);
                    } catch (_) {
                      if (context.mounted) {
                        AppToast.error(context, l10n.manageDevicesRemoveFailed);
                      }
                      rethrow;
                    }
                  },
                ),
              ),
      ),
    );
  }
}

class ManageDevicesAssetPaths {
  const ManageDevicesAssetPaths._();

  static const phone = 'assets/icons/account/manage_devices_phone.png';
  static const logout = 'assets/icons/account/manage_devices_logout.png';
}

class _ManageDevicesContent extends StatelessWidget {
  const _ManageDevicesContent({
    required this.devices,
    required this.title,
    required this.subtitle,
    required this.textTheme,
    required this.onRemoveRequested,
  });

  final List<ManagedLoginDevice> devices;
  final String title;
  final String subtitle;
  final TextTheme textTheme;
  final ValueChanged<ManagedLoginDevice> onRemoveRequested;

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
                    itemBuilder: (context, index) => _ManagedDeviceCard(
                      device: devices[index],
                      onRemoveRequested: () =>
                          onRemoveRequested(devices[index]),
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

class ManageDevicesKeys {
  const ManageDevicesKeys._();

  static const removeDialog = ValueKey('manage-devices-remove-dialog');
  static const removeCancelButton = ValueKey('manage-devices-remove-cancel');
  static const removeConfirmButton = ValueKey('manage-devices-remove-confirm');

  static ValueKey<String> deviceCard(String sessionId) =>
      ValueKey('manage-devices-card-$sessionId');
  static ValueKey<String> logoutButton(String sessionId) =>
      ValueKey('manage-devices-logout-$sessionId');
}

class _ManagedDeviceCard extends StatelessWidget {
  const _ManagedDeviceCard({
    required this.device,
    required this.onRemoveRequested,
  });

  final ManagedLoginDevice device;
  final VoidCallback onRemoveRequested;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      key: ManageDevicesKeys.deviceCard(device.sessionId),
      height: AppSpacingTokens.manageDevicesCardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: const BoxDecoration(
        color: AppColors.manageDevicesCard,
        borderRadius: BorderRadius.all(
          Radius.circular(AppShapeTokens.sharedDevicesCardRadius),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            ManageDevicesAssetPaths.phone,
            width: AppSpacingTokens.manageDevicesIconSize,
            height: AppSpacingTokens.manageDevicesIconSize,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.phone_android,
                color: AppColors.textMuted,
                size: 46,
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _deviceName(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.sharedDevicesCardTitle(textTheme),
                ),
                const SizedBox(height: 12),
                Text(
                  _loginTimestamp(l10n),
                  style: AppTextTokens.manageDevicesCardTimestamp(textTheme),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: l10n.manageDevicesLogoutLabel,
            child: GestureDetector(
              key: ManageDevicesKeys.logoutButton(device.sessionId),
              behavior: HitTestBehavior.opaque,
              onTap: onRemoveRequested,
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: Image.asset(
                  ManageDevicesAssetPaths.logout,
                  width: AppSpacingTokens.manageDevicesActionIconSize,
                  height: AppSpacingTokens.manageDevicesActionIconSize,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.logout,
                      color: AppColors.textMuted,
                      size: 20,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _deviceName(AppLocalizations l10n) {
    final model = device.deviceModel?.trim();
    if (model != null && model.isNotEmpty) {
      return model;
    }
    return switch (device.platform) {
      ManagedLoginDevicePlatform.ios => l10n.manageDevicesIosName,
      ManagedLoginDevicePlatform.android => l10n.manageDevicesAndroidName,
      ManagedLoginDevicePlatform.unknown => l10n.manageDevicesUnknownDevice,
    };
  }

  String _loginTimestamp(AppLocalizations l10n) {
    final timestamp = device.lastLoginTime;
    if (timestamp == null) return l10n.manageDevicesUnknownLoginTime;
    return l10n.manageDevicesLoginTimestamp(
      timestamp.year,
      timestamp.month.toString().padLeft(2, '0'),
      timestamp.day.toString().padLeft(2, '0'),
      timestamp.hour.toString().padLeft(2, '0'),
      timestamp.minute.toString().padLeft(2, '0'),
    );
  }
}

class _ManageDevicesErrorState extends StatelessWidget {
  const _ManageDevicesErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 12),
        TextButton(onPressed: onRetry, child: Text(retryLabel)),
      ],
    ),
  );
}

Future<void> _showManagedDeviceRemovalDialog(
  BuildContext context, {
  required Future<void> Function() onConfirm,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: AppColors.manageDevicesRemoveDialogScrim,
    builder: (context) => _ManagedDeviceRemovalDialog(onConfirm: onConfirm),
  );
}

class _ManagedDeviceRemovalDialog extends StatelessWidget {
  const _ManagedDeviceRemovalDialog({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    var isRemoving = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          key: ManageDevicesKeys.removeDialog,
          insetPadding: const EdgeInsets.symmetric(
            horizontal:
                AppSpacingTokens.manageDevicesRemoveDialogHorizontalInset,
          ),
          backgroundColor: AppColors.manageDevicesRemoveDialogSurface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(AppShapeTokens.manageDevicesRemoveDialogRadius),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacingTokens.manageDevicesRemoveDialogMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacingTokens.manageDevicesRemoveDialogContentHorizontal,
                AppSpacingTokens.manageDevicesRemoveDialogContentTop,
                AppSpacingTokens.manageDevicesRemoveDialogContentHorizontal,
                AppSpacingTokens.manageDevicesRemoveDialogContentBottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.manageDevicesRemoveConfirmationMessage,
                    textAlign: TextAlign.center,
                    style: AppTextTokens.manageDevicesRemoveDialogMessage(
                      textTheme,
                    ),
                  ),
                  const SizedBox(
                    height:
                        AppSpacingTokens.manageDevicesRemoveDialogActionsTop,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _ManagedDeviceRemovalDialogAction(
                          key: ManageDevicesKeys.removeCancelButton,
                          label: l10n.manageDevicesRemoveCancelAction,
                          isPrimary: false,
                          onPressed: isRemoving
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(
                        width:
                            AppSpacingTokens.manageDevicesRemoveDialogActionGap,
                      ),
                      Expanded(
                        child: _ManagedDeviceRemovalDialogAction(
                          key: ManageDevicesKeys.removeConfirmButton,
                          label: l10n.manageDevicesRemoveConfirmAction,
                          isPrimary: true,
                          onPressed: isRemoving
                              ? null
                              : () async {
                                  setState(() => isRemoving = true);
                                  try {
                                    await onConfirm();
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  } catch (_) {
                                    if (context.mounted) {
                                      setState(() => isRemoving = false);
                                    }
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ManagedDeviceRemovalDialogAction extends StatelessWidget {
  const _ManagedDeviceRemovalDialogAction({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isPrimary
                ? AppColors.manageDevicesRemoveDialogConfirmSurface
                : AppColors.manageDevicesRemoveDialogCancelSurface,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
          ),
          child: SizedBox(
            height: AppSpacingTokens.manageDevicesRemoveDialogActionHeight,
            child: Center(
              child: Text(
                label,
                style: AppTextTokens.manageDevicesRemoveDialogAction(
                  Theme.of(context).textTheme,
                  isPrimary: isPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
