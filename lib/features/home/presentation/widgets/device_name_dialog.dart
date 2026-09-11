import '../../../../shared/widgets/skin_asset_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error_message.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../application/providers.dart';

class DeviceNameDialogAssetPaths {
  const DeviceNameDialogAssetPaths._();

  static const nameInputPlaceholder =
      'assets/icons/home/device_name_input_placeholder.png';
}

Future<void> showDeviceNameDialog(
  BuildContext context, {
  required DeviceSummary device,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: context.colors.overlaySoft,
    builder: (context) =>
        DeviceNameDialog(device: device, parentContext: context),
  );
}

class DeviceNameDialog extends ConsumerStatefulWidget {
  const DeviceNameDialog({
    super.key,
    required this.device,
    required this.parentContext,
  });

  final DeviceSummary device;
  final BuildContext parentContext;

  @override
  ConsumerState<DeviceNameDialog> createState() => _DeviceNameDialogState();
}

class _DeviceNameDialogState extends ConsumerState<DeviceNameDialog> {
  late final TextEditingController _controller;
  var _hasName = false;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.device.name)
      ..addListener(_onNameChanged);
    _hasName = _controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _controller.removeListener(_onNameChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final hasName = _controller.text.trim().isNotEmpty;
    if (hasName != _hasName) {
      setState(() {
        _hasName = hasName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: viewInsets + const EdgeInsets.symmetric(horizontal: 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Material(
            color: context.colors.backgroundPrimary,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.deviceNameDialogTitle,
                    style: context.appText.sceneDialogTitle(textTheme),
                  ),
                  const SizedBox(height: 16),
                  _DeviceNameTextField(controller: _controller),
                  const SizedBox(height: 26),
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
                            child: Text(l10n.sceneNameCancelAction),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _hasName && !_isSubmitting
                                ? _submit
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: context.colors.brandPrimary,
                              disabledBackgroundColor:
                                  context.colors.brandPrimaryDisabled,
                              foregroundColor: context
                                  .colors
                                  .authPrimaryButtonDisabledForeground,
                              disabledForegroundColor: context
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
                                : Text(l10n.sceneNameConfirmAction),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    final doorId = int.tryParse(widget.device.id);
    final name = _controller.text.trim();
    if (doorId == null || name.isEmpty) {
      _showFailure();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    final requestId =
        'home-rename-door-$doorId-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await ref.read(renameHomeDoorUseCaseProvider)(
        doorId: doorId,
        name: name,
        requestId: requestId,
      );
      final sceneId = widget.device.sceneId;
      if (sceneId != null) {
        ref.invalidate(homeDoorsBySceneProvider(sceneId));
        ref.invalidate(homeDevicesProvider);
      }
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
        AppLocalizations.of(widget.parentContext).deviceRenameFailed,
      ),
    );
  }
}

class _DeviceNameTextField extends StatelessWidget {
  const _DeviceNameTextField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.colors.sceneDialogInputBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const _DeviceNameInputIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: context.appText.sceneDialogInput(textTheme),
              decoration: InputDecoration.collapsed(
                hintText: l10n.deviceNameInputPlaceholder,
                hintStyle: context.appText.sceneDialogInputHint(textTheme),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceNameInputIcon extends StatelessWidget {
  const _DeviceNameInputIcon();

  @override
  Widget build(BuildContext context) {
    return SkinAssetImage.themed(
      context,
      DeviceNameDialogAssetPaths.nameInputPlaceholder,
      width: 15,
      height: 15,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.dns_outlined,
          color: context.colors.textHint,
          size: 15,
        );
      },
    );
  }
}
