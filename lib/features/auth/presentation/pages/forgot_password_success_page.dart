import 'package:flinx/shared/widgets/flinx_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../account/application/providers.dart';
import '../../application/providers.dart';
import '../widgets/auth_flow_widgets.dart';
import 'login_page.dart';

class ForgotPasswordSuccessPage extends ConsumerStatefulWidget {
  const ForgotPasswordSuccessPage({super.key});

  static const routeName = 'forgot-password-success';
  static const routePath = '/forgot-password/success';

  @override
  ConsumerState<ForgotPasswordSuccessPage> createState() =>
      _ForgotPasswordSuccessPageState();
}

class _ForgotPasswordSuccessPageState
    extends ConsumerState<ForgotPasswordSuccessPage> {
  var _isReturningToLogin = false;

  Future<void> _returnToLogin() async {
    if (_isReturningToLogin) return;
    _isReturningToLogin = true;

    await ref.read(accountControllerProvider.notifier).clearAccount();
    ref.read(activeAuthSessionProvider.notifier).clear();
    if (mounted) context.go(LoginPage.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _returnToLogin();
      },
      child: Scaffold(
        appBar: FlinxNavigationBar(
          title: '',
          showBottomDivider: false,
          onBackPressed: _returnToLogin,
        ),
        backgroundColor: AppColors.backgroundPrimary,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 10, 32, 24),
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
                  onPressed: _returnToLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordSuccessPageAssetPaths {
  const _ForgotPasswordSuccessPageAssetPaths._();

  static const passwordResetSuccessIcon =
      'assets/icons/auth/forgot_password_success_icon.png';
}
