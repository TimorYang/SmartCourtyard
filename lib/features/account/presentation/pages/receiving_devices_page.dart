import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error_message.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/design_system/door_type_option.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../home/application/home_door_cover_image_source.dart';
import '../../../home/application/providers.dart';
import '../../application/providers.dart';
import '../../domain/entities/receiving_door.dart';

class ReceivingDevicesAssetPaths {
  const ReceivingDevicesAssetPaths._();

  static const edit =
      'assets/icons/account/shared_device_member_edit_placeholder.png';
  static const editDone = 'assets/icons/home/scene_edit_done_placeholder.png';
}

class ReceivingDevicesPage extends ConsumerStatefulWidget {
  const ReceivingDevicesPage({super.key});

  static const routeName = 'receiving-devices';
  static const routePath = '/account/receiving-devices';

  @override
  ConsumerState<ReceivingDevicesPage> createState() =>
      _ReceivingDevicesPageState();
}

class _ReceivingDevicesPageState extends ConsumerState<ReceivingDevicesPage> {
  var _isEditing = false;
  final _deletingShareIds = <int>{};

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
          IconButton(
            key: ReceivingDevicesKeys.editButton,
            tooltip: _isEditing
                ? l10n.receivingDevicesDoneEditingLabel
                : l10n.receivingDevicesEditLabel,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: AppSpacingTokens.receivingDevicesEditActionSize,
              height: AppSpacingTokens.receivingDevicesEditActionSize,
            ),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            icon: _ReceivingDevicesEditActionIcon(
              assetPath: _isEditing
                  ? ReceivingDevicesAssetPaths.editDone
                  : ReceivingDevicesAssetPaths.edit,
            ),
          ),
          const SizedBox(
            width: AppSpacingTokens.receivingDevicesEditActionRight,
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
                    _isEditing
                        ? l10n.receivingDevicesEditingTitle
                        : l10n.receivingDevicesTitle,
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
                          showDeleteAction: _isEditing,
                          isDeleting: _deletingShareIds.contains(
                            devices[index].shareId,
                          ),
                          onDelete: () =>
                              unawaited(_deleteReceivingDevice(devices[index])),
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

  Future<void> _deleteReceivingDevice(ReceivingDoor device) async {
    if (_deletingShareIds.contains(device.shareId)) return;

    setState(() {
      _deletingShareIds.add(device.shareId);
    });
    try {
      final error = await ref
          .read(receivingDevicesControllerProvider.notifier)
          .deleteShare(shareId: device.shareId);
      if (!mounted) return;

      if (error == null) {
        ref.read(homeDeviceListsInvalidatorProvider)();
        ref.invalidate(receivingDevicesControllerProvider);
      } else {
        AppToast.error(
          context,
          appErrorMessage(
            error,
            AppLocalizations.of(context).receivingDevicesDeleteFailed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingShareIds.remove(device.shareId);
        });
      }
    }
  }
}

class ReceivingDevicesKeys {
  const ReceivingDevicesKeys._();

  static const editButton = ValueKey('receiving-devices-edit-button');
  static const retryButton = ValueKey('receiving-devices-retry-button');

  static ValueKey<String> deviceCard(int index) =>
      ValueKey('receiving-devices-card-$index');

  static ValueKey<String> deleteButton(int shareId) =>
      ValueKey('receiving-devices-delete-$shareId');
}

class _ReceivingDeviceCard extends ConsumerWidget {
  const _ReceivingDeviceCard({
    super.key,
    required this.device,
    required this.showDeleteAction,
    required this.isDeleting,
    required this.onDelete,
  });

  final ReceivingDoor device;
  final bool showDeleteAction;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final visual = DoorTypeOption.fromDoorType(
      DoorType.fromWireValue(device.doorType),
    );
    final coverImage = ref.watch(
      homeDoorCoverImageSourceProvider(device.coverFileId),
    );

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
          if (showDeleteAction) ...[
            _DeleteReceivingDeviceButton(
              key: ReceivingDevicesKeys.deleteButton(device.shareId),
              label: l10n.receivingDevicesDeleteLabel,
              isDeleting: isDeleting,
              onPressed: onDelete,
            ),
            const SizedBox(
              width: AppSpacingTokens.receivingDevicesDeleteActionGap,
            ),
          ],
          _ReceivingDeviceCoverImage(
            coverImage: coverImage,
            visual: visual,
            doorId: device.doorId,
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

class _ReceivingDevicesEditActionIcon extends StatelessWidget {
  const _ReceivingDevicesEditActionIcon({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _DeleteReceivingDeviceButton extends StatelessWidget {
  const _DeleteReceivingDeviceButton({
    required super.key,
    required this.label,
    required this.isDeleting,
    required this.onPressed,
  });

  final String label;
  final bool isDeleting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isDeleting,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isDeleting ? null : onPressed,
        child: Container(
          width: AppSpacingTokens.receivingDevicesDeleteActionSize,
          height: AppSpacingTokens.receivingDevicesDeleteActionSize,
          decoration: const BoxDecoration(
            color: AppColors.receivingDevicesDeleteAction,
            shape: BoxShape.circle,
          ),
          child: isDeleting
              ? const Padding(
                  padding: EdgeInsets.all(
                    AppSpacingTokens.receivingDevicesDeleteProgressInset,
                  ),
                  child: CircularProgressIndicator(
                    strokeWidth: AppSpacingTokens
                        .receivingDevicesDeleteProgressStrokeWidth,
                    color: AppColors.backgroundPrimary,
                  ),
                )
              : const Icon(
                  Icons.remove_rounded,
                  color: AppColors.backgroundPrimary,
                  size: AppSpacingTokens.receivingDevicesDeleteActionSize,
                ),
        ),
      ),
    );
  }
}

class _ReceivingDeviceCoverImage extends StatelessWidget {
  const _ReceivingDeviceCoverImage({
    required this.coverImage,
    required this.visual,
    required this.doorId,
  });

  final HomeDoorCoverImageSource? coverImage;
  final DoorTypeOption visual;
  final int doorId;

  @override
  Widget build(BuildContext context) {
    if (coverImage != null) {
      return Image.network(
        coverImage!.url,
        key: ValueKey<String>('receiving-device-cover-$doorId'),
        headers: coverImage!.headers,
        width: AppSpacingTokens.receivingDevicesIconSize,
        height: AppSpacingTokens.receivingDevicesIconSize,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) =>
            loadingProgress == null
            ? child
            : const SizedBox(
                width: AppSpacingTokens.receivingDevicesIconSize,
                height: AppSpacingTokens.receivingDevicesIconSize,
              ),
        errorBuilder: (context, error, stackTrace) =>
            _ReceivingDeviceDefaultCover(visual: visual),
      );
    }
    return _ReceivingDeviceDefaultCover(visual: visual);
  }
}

class _ReceivingDeviceDefaultCover extends StatelessWidget {
  const _ReceivingDeviceDefaultCover({required this.visual});

  final DoorTypeOption visual;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      visual.assetPath,
      width: AppSpacingTokens.receivingDevicesIconSize,
      height: AppSpacingTokens.receivingDevicesIconSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        visual.fallbackIcon,
        color: AppColors.textPrimary,
        size: AppSpacingTokens.receivingDevicesIconSize,
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
