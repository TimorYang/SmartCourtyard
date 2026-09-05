import 'package:flutter/material.dart';

import '../../app/theme/app_design_tokens.dart';

Future<void> showFlinxWarningDialog(
  BuildContext context, {
  required String message,
  required String confirmLabel,
  required String iconAssetPath,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.warningDialogScrim,
    builder: (_) => FlinxWarningDialog(
      message: message,
      confirmLabel: confirmLabel,
      iconAssetPath: iconAssetPath,
    ),
  );
}

class FlinxWarningDialog extends StatelessWidget {
  const FlinxWarningDialog({
    required this.message,
    required this.confirmLabel,
    required this.iconAssetPath,
    super.key,
  });

  final String message;
  final String confirmLabel;
  final String iconAssetPath;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacingTokens.warningDialogHorizontalInset,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacingTokens.warningDialogMaxWidth,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.warningDialogSurface,
              borderRadius: BorderRadius.circular(
                AppShapeTokens.warningDialogRadius,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacingTokens.warningDialogContentHorizontal,
                AppSpacingTokens.warningDialogContentTop,
                AppSpacingTokens.warningDialogContentHorizontal,
                AppSpacingTokens.warningDialogContentBottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SizedBox.square(
                      dimension: AppSpacingTokens.warningDialogIconSize,
                      child: Image.asset(
                        iconAssetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.error_outline,
                          color: AppColors.warningDialogIcon,
                          size: AppSpacingTokens.warningDialogIconSize,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: AppSpacingTokens.warningDialogIconToMessage,
                  ),
                  Text(
                    message,
                    textAlign: TextAlign.left,
                    style: AppTextTokens.warningDialogMessage(textTheme),
                  ),
                  const SizedBox(
                    height: AppSpacingTokens.warningDialogMessageToAction,
                  ),
                  SizedBox(
                    height: AppSpacingTokens.warningDialogActionHeight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.warningDialogPrimaryAction,
                        foregroundColor:
                            AppColors.warningDialogPrimaryActionForeground,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        confirmLabel,
                        style: AppTextTokens.warningDialogAction(textTheme),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
