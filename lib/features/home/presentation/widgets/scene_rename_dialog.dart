import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../application/providers.dart';
import '../../domain/entities/home_scene.dart';

Future<void> showSceneRenameDialog(
  BuildContext context, {
  required HomeScene scene,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.overlaySoft,
    builder: (context) => SceneRenameDialog(scene: scene),
  );
}

class SceneRenameDialog extends ConsumerStatefulWidget {
  const SceneRenameDialog({required this.scene, super.key});

  final HomeScene scene;

  @override
  ConsumerState<SceneRenameDialog> createState() => _SceneRenameDialogState();
}

class _SceneRenameDialogState extends ConsumerState<SceneRenameDialog> {
  late final TextEditingController _controller;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _sceneName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _sceneName {
    final name = widget.scene.name.trim();
    return name.isEmpty ? 'Home' : name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: viewInsets,
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
                    'Scene Rename',
                    style: AppTextTokens.sceneDialogTitle(textTheme),
                  ),
                  const SizedBox(height: 30),
                  _SceneRenameTextField(controller: _controller),
                  const SizedBox(height: 80),
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
                                : Text(l10n.smartOpenerConfirmAction),
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
      AppToast.error(context, 'input scene name');
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    final requestId =
        'home-rename-scene-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await ref.read(renameHomeSceneUseCaseProvider)(
        sceneId: widget.scene.id,
        name: name,
        requestId: requestId,
      );
      ref.invalidate(homeScenesProvider);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Failed to rename scene');
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

class _SceneRenameTextField extends StatelessWidget {
  const _SceneRenameTextField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.sceneDialogInputBorder),
      ),
      padding: const EdgeInsets.only(left: 24, right: 10),
      child: Row(
        children: [
          const Icon(
            Icons.view_in_ar_outlined,
            color: AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextTokens.sceneDialogInput(textTheme),
              decoration: const InputDecoration.collapsed(hintText: ''),
            ),
          ),
          IconButton(
            tooltip: 'Clear',
            visualDensity: VisualDensity.compact,
            onPressed: controller.clear,
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textHint,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
