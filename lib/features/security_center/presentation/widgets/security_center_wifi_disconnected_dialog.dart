import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';

class SecurityCenterWifiDisconnectedDialog extends StatelessWidget {
  const SecurityCenterWifiDisconnectedDialog({super.key});

  static const _wifiDisconnectedAsset = 'assets/icons/security_center/security_center_wifi_disconnected.png';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: DecoratedBox(
          decoration: BoxDecoration(color: AppColors.securityCenterDialogSurface, borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 41, 24, 35),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(_wifiDisconnectedAsset, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox(width: 92, height: 68)),
                const SizedBox(height: 31),
                Text(l10n.securityCenterWifiDisconnectedMessage, textAlign: TextAlign.left, style: AppTextTokens.securityCenterDialogMessage(textTheme)),
                const SizedBox(height: 33),
                SizedBox(
                  width: 182,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.securityCenterDialogPrimaryAction, shape: const StadiumBorder()),
                    child: Text(l10n.securityCenterWifiDisconnectedBackAction, style: AppTextTokens.securityCenterDialogAction(textTheme)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
