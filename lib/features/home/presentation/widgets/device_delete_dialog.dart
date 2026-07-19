import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../application/providers.dart';

Future<void> showDeviceDeleteDialog(
  BuildContext context, {
  required DeviceSummary device,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.overlaySoft,
    builder: (context) =>
        DeviceDeleteDialog(device: device, parentContext: context),
  );
}

class DeviceDeleteDialog extends ConsumerStatefulWidget {
  const DeviceDeleteDialog({
    super.key,
    required this.device,
    required this.parentContext,
  });

  final DeviceSummary device;
  final BuildContext parentContext;

  @override
  ConsumerState<DeviceDeleteDialog> createState() => _DeviceDeleteDialogState();
}

class _DeviceDeleteDialogState extends ConsumerState<DeviceDeleteDialog> {
  var _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.backgroundPrimary,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.deviceDeleteConfirmMessage,
                textAlign: TextAlign.center,
                style: AppTextTokens.deviceDeleteConfirmMessage(textTheme),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sceneDialogCancelButton,
                          foregroundColor: AppColors.textPrimary,
                          shape: const StadiumBorder(),
                          textStyle: AppTextTokens.sceneDialogButton(textTheme),
                        ),
                        child: Text(l10n.deviceDeleteCancelAction),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _unbindDevice,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sceneDeleteAction,
                          foregroundColor: AppColors.backgroundPrimary,
                          shape: const StadiumBorder(),
                          textStyle: AppTextTokens.sceneDialogButton(textTheme),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.backgroundPrimary,
                                ),
                              )
                            : Text(l10n.deviceDeleteConfirmAction),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unbindDevice() async {
    final doorId = int.tryParse(widget.device.id);
    if (doorId == null) {
      _showFailure();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    final requestId =
        'home-unbind-door-$doorId-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await ref.read(unbindHomeDoorUseCaseProvider)(
        doorId: doorId,
        requestId: requestId,
      );
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
          _isSubmitting = false;
        });
      }
    }
  }

  void _showFailure() {
    AppToast.error(widget.parentContext, 'Failed to unbind device');
  }
}
