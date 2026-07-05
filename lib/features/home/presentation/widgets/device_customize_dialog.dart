import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';

Future<void> showDeviceCustomizeDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.overlaySoft,
    builder: (context) => const DeviceCustomizeDialog(),
  );
}

class DeviceCustomizeDialog extends StatelessWidget {
  const DeviceCustomizeDialog({super.key});

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
                ),
                const Divider(height: 1, color: AppColors.borderHomeDivider),
                _CustomizeActionRow(
                  label: l10n.deviceCustomizeDefaultPictureAction,
                ),
                const Divider(height: 1, color: AppColors.borderHomeDivider),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomizeActionRow extends StatelessWidget {
  const _CustomizeActionRow({required this.label, this.showChevron = false});

  final String label;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
          if (showChevron)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textPrimary,
              size: 28,
            ),
        ],
      ),
    );
  }
}
