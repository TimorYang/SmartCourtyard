import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../home/presentation/pages/home_page.dart';

class SmartOpenerConnectionSuccessPage extends StatelessWidget {
  const SmartOpenerConnectionSuccessPage({super.key});

  static const routeName = 'smart-opener-connection-success';
  static const routePath = '/add-device/smart-opener/success';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final topGap = constraints.maxHeight < 760 ? 34.0 : 70.0;
          final formGap = constraints.maxHeight < 760 ? 44.0 : 94.0;
          final actionGap = constraints.maxHeight < 760 ? 54.0 : 112.0;

          return SafeArea(
            top: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(58, topGap, 58, 34),
              children: [
                const Center(child: _SuccessCheck()),
                const SizedBox(height: 38),
                Text(
                  l10n.smartOpenerConnectionSuccessTitle,
                  textAlign: TextAlign.center,
                  style: AppTextTokens.smartOpenerConnectingTitle(textTheme),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.smartOpenerConnectionSuccessDescription,
                  textAlign: TextAlign.center,
                  style: AppTextTokens.smartOpenerBodyCenter(textTheme),
                ),
                SizedBox(height: formGap),
                _SuccessFormRow(
                  icon: Icons.door_front_door_outlined,
                  label: l10n.smartOpenerDeviceNamePlaceholder,
                ),
                _SuccessFormRow(
                  icon: Icons.view_in_ar_outlined,
                  label: l10n.smartOpenerSelectScenePlaceholder,
                  trailing: Icons.chevron_right,
                ),
                SizedBox(height: actionGap),
                Text(
                  l10n.smartOpenerInviteFamilyTip,
                  textAlign: TextAlign.center,
                  style: AppTextTokens.smartOpenerBodyCenter(textTheme),
                ),
                const SizedBox(height: 19),
                _SuccessActionButton(
                  label: l10n.smartOpenerShareAction,
                  isPrimary: false,
                  onPressed: () => context.go(HomePage.routePath),
                ),
                const SizedBox(height: 22),
                _SuccessActionButton(
                  label: l10n.smartOpenerTryAction,
                  onPressed: () => context.go(HomePage.routePath),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SuccessCheck extends StatelessWidget {
  const _SuccessCheck();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      height: 142,
      decoration: const BoxDecoration(
        color: AppColors.smartOpenerSuccess,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 78),
    );
  }
}

class _SuccessFormRow extends StatelessWidget {
  const _SuccessFormRow({
    required this.icon,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 90,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.smartOpenerDivider)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: AppColors.textIcon),
          const SizedBox(width: 22),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextTokens.smartOpenerFormText(textTheme),
            ),
          ),
          if (trailing != null)
            Icon(trailing, size: 34, color: AppColors.textPrimary),
        ],
      ),
    );
  }
}

class _SuccessActionButton extends StatelessWidget {
  const _SuccessActionButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 68,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isPrimary
              ? AppColors.brandPrimary
              : AppColors.smartOpenerSecondaryButton,
          foregroundColor: isPrimary ? Colors.white : AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(34),
          ),
        ),
        child: Text(
          label,
          style: isPrimary
              ? AppTextTokens.smartOpenerActionButton(textTheme)
              : AppTextTokens.smartOpenerSecondaryActionButton(textTheme),
        ),
      ),
    );
  }
}
