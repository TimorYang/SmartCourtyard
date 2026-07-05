import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';

Future<void> showDeviceDeleteDialog(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.overlaySoft,
    builder: (context) => const DeviceDeleteDialog(),
  );
}

class DeviceDeleteDialog extends StatelessWidget {
  const DeviceDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Material(
        color: AppColors.backgroundPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        clipBehavior: Clip.antiAlias,
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
                        onPressed: () => Navigator.pop(context),
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
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sceneDeleteAction,
                          foregroundColor: AppColors.backgroundPrimary,
                          shape: const StadiumBorder(),
                          textStyle: AppTextTokens.sceneDialogButton(textTheme),
                        ),
                        child: Text(l10n.deviceDeleteConfirmAction),
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
}
