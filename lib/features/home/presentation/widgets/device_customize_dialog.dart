import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../application/providers.dart';
import '../../domain/entities/home_door_cover_image.dart';

typedef DeviceCoverImagePicker = Future<XFile?> Function();

Future<XFile?> _pickDeviceCoverImage() {
  return ImagePicker().pickImage(source: ImageSource.gallery);
}

Future<void> showDeviceCustomizeDialog(
  BuildContext context, {
  required DeviceSummary device,
  DeviceCoverImagePicker pickImage = _pickDeviceCoverImage,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.overlaySoft,
    builder: (context) => DeviceCustomizeDialog(
      device: device,
      parentContext: context,
      pickImage: pickImage,
    ),
  );
}

class DeviceCustomizeDialog extends ConsumerStatefulWidget {
  const DeviceCustomizeDialog({
    super.key,
    required this.device,
    required this.parentContext,
    required this.pickImage,
  });

  final DeviceSummary device;
  final BuildContext parentContext;
  final DeviceCoverImagePicker pickImage;

  @override
  ConsumerState<DeviceCustomizeDialog> createState() =>
      _DeviceCustomizeDialogState();
}

class _DeviceCustomizeDialogState extends ConsumerState<DeviceCustomizeDialog> {
  var _isResetting = false;
  var _isUpdatingCover = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: Material(
          color: AppColors.backgroundPrimary,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(44, 22, 44, 78),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.deviceCustomizeTitle,
                  style: AppTextTokens.deviceCustomizeTitle(textTheme),
                ),
                const SizedBox(height: 22),
                _CustomizeActionRow(
                  label: l10n.deviceCustomizeChangePictureAction,
                  showChevron: true,
                  onPressed: _isResetting || _isUpdatingCover
                      ? null
                      : _changePicture,
                  trailing: _isUpdatingCover
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
                const Divider(height: 1, color: AppColors.borderHomeDivider),
                _CustomizeActionRow(
                  label: l10n.deviceCustomizeDefaultPictureAction,
                  onPressed: _isResetting || _isUpdatingCover
                      ? null
                      : _resetToDefaultPicture,
                  trailing: _isResetting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
                const Divider(height: 1, color: AppColors.borderHomeDivider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetToDefaultPicture() async {
    if (_isResetting) {
      return;
    }
    final doorId = int.tryParse(widget.device.id);
    if (doorId == null) {
      _showFailure();
      return;
    }

    setState(() {
      _isResetting = true;
    });
    final requestId =
        'home-reset-door-cover-$doorId-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await ref.read(resetHomeDoorCoverUseCaseProvider)(
        doorId: doorId,
        requestId: requestId,
      );
      if (widget.device.sceneId case final int sceneId) {
        ref.invalidate(homeDoorsBySceneProvider(sceneId));
      }
      ref.invalidate(homeDevicesProvider);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        _showFailure();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  Future<void> _changePicture() async {
    final selectedImage = await widget.pickImage();
    if (selectedImage == null || !mounted || _isUpdatingCover) {
      return;
    }
    final doorId = int.tryParse(widget.device.id);
    if (doorId == null) {
      _showUpdateFailure();
      return;
    }

    setState(() {
      _isUpdatingCover = true;
    });
    final requestId =
        'home-update-door-cover-$doorId-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      final bytes = await selectedImage.readAsBytes();
      final fileName = selectedImage.name.trim();
      await ref.read(updateHomeDoorCoverUseCaseProvider)(
        doorId: doorId,
        image: HomeDoorCoverImage(
          bytes: bytes,
          fileName: fileName.isEmpty ? 'door-cover.jpg' : fileName,
        ),
        requestId: requestId,
      );
      if (widget.device.sceneId case final int sceneId) {
        ref.invalidate(homeDoorsBySceneProvider(sceneId));
      }
      ref.invalidate(homeDevicesProvider);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        _showUpdateFailure();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingCover = false;
        });
      }
    }
  }

  void _showFailure() {
    AppToast.error(
      widget.parentContext,
      AppLocalizations.of(
        widget.parentContext,
      ).deviceCustomizeResetPictureFailed,
    );
  }

  void _showUpdateFailure() {
    AppToast.error(
      widget.parentContext,
      AppLocalizations.of(
        widget.parentContext,
      ).deviceCustomizeChangePictureFailed,
    );
  }
}

class _CustomizeActionRow extends StatelessWidget {
  const _CustomizeActionRow({
    required this.label,
    this.showChevron = false,
    this.onPressed,
    this.trailing,
  });

  final String label;
  final bool showChevron;
  final VoidCallback? onPressed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextTokens.deviceCustomizeAction(
                  Theme.of(context).textTheme,
                ),
              ),
            ),
            if (trailing case final Widget trailing) trailing,
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textPrimary,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
