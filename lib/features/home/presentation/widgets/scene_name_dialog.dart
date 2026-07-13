import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../application/providers.dart';

class SceneNameDialogAssetPaths {
  const SceneNameDialogAssetPaths._();

  static const nameInputPlaceholder =
      'assets/icons/home/scene_name_input_placeholder.png';
}

Future<void> showSceneNameDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.overlaySoft,
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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            color: AppColors.backgroundPrimary,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.sceneNameDialogTitle,
                    style: AppTextTokens.sceneDialogTitle(textTheme),
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
                                  AppColors.sceneDialogCancelButton,
                              foregroundColor: AppColors.textPrimary,
                              shape: const StadiumBorder(),
                              textStyle: AppTextTokens.sceneDialogButton(
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
                            onPressed: _isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary,
                              foregroundColor: AppColors.backgroundPrimary,
                              shape: const StadiumBorder(),
                              textStyle: AppTextTokens.sceneDialogButton(
                                textTheme,
                              ),
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('input scene name')));
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Failed to create scene')),
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
        border: Border.all(color: AppColors.sceneDialogInputBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const _SceneNameInputIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextTokens.sceneDialogInput(textTheme),
              decoration: InputDecoration.collapsed(
                hintText: l10n.sceneNameInputPlaceholder,
                hintStyle: AppTextTokens.sceneDialogInputHint(textTheme),
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
    return Image.asset(
      SceneNameDialogAssetPaths.nameInputPlaceholder,
      width: 15,
      height: 15,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.view_in_ar_outlined,
          color: AppColors.textHint,
          size: 15,
        );
      },
    );
  }
}
