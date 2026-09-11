import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error_message.dart';
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
    barrierColor: context.colors.overlaySoft,
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
      color: context.colors.backgroundPrimary,
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
                style: context.appText.deviceDeleteConfirmMessage(textTheme),
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
                          backgroundColor:
                              context.colors.sceneDialogCancelButton,
                          foregroundColor: context.colors.textPrimary,
                          shape: const StadiumBorder(),
                          textStyle: context.appText.sceneDialogButton(
                            textTheme,
                          ),
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
                          backgroundColor: context.colors.sceneDeleteAction,
                          foregroundColor: context
                              .colors
                              .authPrimaryButtonDisabledForeground,
                          shape: const StadiumBorder(),
                          textStyle: context.appText.sceneDialogButton(
                            textTheme,
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context
                                      .colors
                                      .authPrimaryButtonDisabledForeground,
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
      ref.read(homeDeviceListsInvalidatorProvider)();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        _showFailure(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showFailure([Object? error]) {
    AppToast.error(
      widget.parentContext,
      appErrorMessage(
        error,
        AppLocalizations.of(widget.parentContext).deviceUnbindFailed,
      ),
    );
  }
}
