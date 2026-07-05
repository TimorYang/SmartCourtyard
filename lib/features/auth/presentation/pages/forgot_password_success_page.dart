import 'package:flinx/shared/widgets/flinx_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../widgets/auth_flow_widgets.dart';
import 'login_page.dart';

class ForgotPasswordSuccessPage extends StatelessWidget {
  const ForgotPasswordSuccessPage({super.key});

  static const routeName = 'forgot-password-success';
  static const routePath = '/forgot-password/success';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: FlinxNavigationBar(title: '', showBottomDivider: false),
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 10, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 160),
              Center(
                child: Column(
                  children: [
                    const AuthAssetIcon(
                      key: ValueKey('forgot_password_success_icon'),
                      assetPath: _ForgotPasswordSuccessPageAssetPaths
                          .passwordResetSuccessIcon,
                      width: 108,
                      height: 108,
                      fallback: SizedBox(width: 96, height: 96),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.passwordResetSucceededTitle,
                      textAlign: TextAlign.center,
                      style: AppTextTokens.authSuccessTitle(theme.textTheme),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.passwordResetSucceededDescription,
                      textAlign: TextAlign.center,
                      style: AppTextTokens.authSuccessDescription(
                        theme.textTheme,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 44),
              AuthPrimaryButton(
                label: l10n.backToLoginAction,
                onPressed: () => _popBackToLogin(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _popBackToLogin(BuildContext context) {
    final router = GoRouter.of(context);
    var foundLoginRoute = false;

    Navigator.of(context).popUntil((route) {
      foundLoginRoute = route.settings.name == LoginPage.routeName;
      return foundLoginRoute || route.isFirst;
    });

    if (!foundLoginRoute) {
      router.go(LoginPage.routePath);
    }
  }
}

class _ForgotPasswordSuccessPageAssetPaths {
  const _ForgotPasswordSuccessPageAssetPaths._();

  static const passwordResetSuccessIcon =
      'assets/icons/auth/forgot_password_success_icon.png';
}
