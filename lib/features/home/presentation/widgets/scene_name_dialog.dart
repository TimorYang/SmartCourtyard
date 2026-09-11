import '../../../../shared/widgets/skin_asset_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error_message.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../application/providers.dart';

class SceneNameDialogAssetPaths {
  const SceneNameDialogAssetPaths._();

  static const nameInputPlaceholder =
      'assets/icons/home/device_name_input_placeholder.png';
}

Future<void> showSceneNameDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: context.colors.overlaySoft,
    builder: (context) => const SceneNameDialog(),
  );
}

class SceneNameDialog extends ConsumerStatefulWidget {
  const SceneNameDialog({super.key});

  @override
  ConsumerState<SceneNameDialog> createState() => _SceneNameDialogState();
}

class _SceneNameDialogState extends ConsumerState<SceneNameDialog> {
  late final TextEditingController _controller;
  var _isSubmitting = false;
  var _hasName = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onNameChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final hasName = _controller.text.trim().isNotEmpty;
    if (_hasName != hasName) {
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
                    l10n.sceneNameDialogTitle,
                    style: context.appText.sceneDialogTitle(textTheme),
                  ),
                  const SizedBox(height: 16),
                  _SceneNameTextField(controller: _controller),
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
                            onPressed: _isSubmitting || !_hasName
                                ? null
                                : _submit,
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
    final name = _controller.text.trim();
    if (name.isEmpty) {
      AppToast.error(
        context,
        AppLocalizations.of(context).sceneNameInputPlaceholder,
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    final requestId =
        'home-create-scene-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await ref.read(createHomeSceneUseCaseProvider)(
        name: name,
        requestId: requestId,
      );
      ref.invalidate(homeScenesProvider);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(
          context,
          appErrorMessage(
            error,
            AppLocalizations.of(context).sceneCreateFailed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

class _SceneNameTextField extends StatelessWidget {
  const _SceneNameTextField({required this.controller});

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
          const _SceneNameInputIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: context.appText.sceneDialogInput(textTheme),
              decoration: InputDecoration.collapsed(
                hintText: l10n.sceneNameInputPlaceholder,
                hintStyle: context.appText.sceneDialogInputHint(textTheme),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneNameInputIcon extends StatelessWidget {
  const _SceneNameInputIcon();

  @override
  Widget build(BuildContext context) {
    return SkinAssetImage.themed(
      context,
      SceneNameDialogAssetPaths.nameInputPlaceholder,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
