import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_links.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../account/application/providers.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../application/login_form_controller.dart';
import '../../application/apple_login_controller.dart';
import '../../application/providers.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import '../widgets/auth_alerts.dart';
import '../widgets/auth_flow_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  static const routeName = 'login';
  static const routePath = '/login';

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isSubmitting = false;
  bool _isPasswordObscured = true;
  final _accountTextController = TextEditingController(
    text: defaultLoginAccount,
  );
  final _passwordTextController = TextEditingController(
    text: defaultLoginPassword,
  );

  @override
  void dispose() {
    _accountTextController.dispose();
    _passwordTextController.dispose();
    super.dispose();
  }

  Future<void> _submitAppleLogin({required bool agreedToTerms}) async {
    final submission = await ref
        .read(appleLoginControllerProvider.notifier)
        .submit(agreedToTerms: agreedToTerms);
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    switch (submission.type) {
      case AppleLoginSubmissionType.success:
        final result = submission.result!;
        ref
            .read(accountControllerProvider.notifier)
            .setSessionProfile(result.profile);
        ref
            .read(activeAuthSessionProvider.notifier)
            .markAuthenticated(userId: result.profile.userId);
        context.go(HomePage.routePath);
      case AppleLoginSubmissionType.agreementRequired:
        AppToast.info(context, l10n.appleLoginAgreementRequired);
      case AppleLoginSubmissionType.unavailable:
        AppToast.info(context, l10n.appleLoginUnavailable);
      case AppleLoginSubmissionType.failed:
        AppToast.error(context, l10n.appleLoginFailed);
      case AppleLoginSubmissionType.canceled:
      case AppleLoginSubmissionType.busy:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(loginFormControllerProvider);
    final controller = ref.read(loginFormControllerProvider.notifier);
    final appleLoginState = ref.watch(appleLoginControllerProvider);
    final showAppleLogin = ref.watch(appleLoginPlatformSupportedProvider);

    return Scaffold(
      appBar: FlinxNavigationBar(title: '', showBottomDivider: false),
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: MediaQuery.removeViewInsets(
        removeBottom: true,
        context: context,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              SafeArea(
                top: false,
                left: false,
                right: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.loginTitle,
                        style: AppTextTokens.loginTitle(theme.textTheme),
                      ),
                      const SizedBox(height: 55),
                      AuthTextField(
                        controller: _accountTextController,
                        hintText: l10n.loginAccountPlaceholder,
                        icon: const AuthAssetIcon(
                          assetPath: AuthAssetPaths.accountFieldIcon,
                          width: 22,
                          height: 22,
                          fallback: SizedBox.shrink(),
                        ),
                        compact: true,
                        ultraCompact: true,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        onChanged: controller.updateAccount,
                        rightView: AuthTextFieldAction(
                          label: l10n.loginClearAccountAction,
                          icon: Icons.close_rounded,
                          onTap: () {
                            _accountTextController.clear();
                            controller.updateAccount('');
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      AuthTextField(
                        controller: _passwordTextController,
                        hintText: l10n.loginPasswordPlaceholder,
                        icon: const AuthAssetIcon(
                          assetPath: AuthAssetPaths.passwordFieldIcon,
                          width: 22,
                          height: 22,
                          fallback: SizedBox.shrink(),
                        ),
                        compact: true,
                        ultraCompact: true,
                        obscureText: _isPasswordObscured,
                        textInputAction: TextInputAction.done,
                        onChanged: controller.updatePassword,
                        rightView: AuthTextFieldAction(
                          label: _isPasswordObscured
                              ? l10n.loginShowPasswordAction
                              : l10n.loginHidePasswordAction,
                          icon: _isPasswordObscured
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          onTap: () => setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _AgreementToggle(
                            selected: state.agreedToTerms,
                            onTap: controller.toggleAgreement,
                          ),
                          const SizedBox(width: 0),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: AppTextTokens.loginAgreement(
                                  theme.textTheme,
                                ),
                                children: [
                                  TextSpan(text: l10n.loginAgreementPrefix),
                                  TextSpan(
                                    text: l10n.userAgreementLabel,
                                    style: const TextStyle(
                                      color: AppColors.textAgreementLink,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => context.push(
                                        AppLinks.webViewLocation(
                                          destination:
                                              AppLinkDestination.userAgreement,
                                          title: l10n.userAgreementLabel,
                                        ),
                                      ),
                                  ),
                                  TextSpan(text: l10n.loginAgreementMiddle),
                                  TextSpan(
                                    text: l10n.privacyPolicyLabel,
                                    style: const TextStyle(
                                      color: AppColors.textAgreementLink,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => context.push(
                                        AppLinks.webViewLocation(
                                          destination:
                                              AppLinkDestination.privacyPolicy,
                                          title: l10n.privacyPolicyLabel,
                                        ),
                                      ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed:
                              state.canSubmit &&
                                  !_isSubmitting &&
                                  !appleLoginState.isSubmitting
                              ? () async {
                                  if (!controller.validateEmailForSubmit()) {
                                    await showAuthEmailInvalidDialog(context);
                                    return;
                                  }
                                  setState(() {
                                    _isSubmitting = true;
                                  });
                                  try {
                                    final result =
                                        await ref.read(loginUseCaseProvider)(
                                          email: state.trimmedEmail,
                                          password: state.password,
                                        );
                                    ref
                                        .read(
                                          accountControllerProvider.notifier,
                                        )
                                        .setSessionProfile(result.profile);
                                    ref
                                        .read(
                                          activeAuthSessionProvider.notifier,
                                        )
                                        .markAuthenticated(
                                          userId: result.profile.userId,
                                        );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    context.go(HomePage.routePath);
                                  } catch (_) {
                                    if (!context.mounted) {
                                      return;
                                    }
                                    AppToast.error(context, l10n.loginFailed);
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isSubmitting = false;
                                      });
                                    }
                                  }
                                }
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandPrimaryLight,
                            disabledBackgroundColor:
                                AppColors.brandPrimaryDisabled,
                            foregroundColor: Colors.white,
                            disabledForegroundColor:
                                AppColors.authPrimaryButtonDisabledForeground,
                            minimumSize: const Size.fromHeight(48),
                            shape: const StadiumBorder(),
                            textStyle: AppTextTokens.loginPrimaryButton(
                              theme.textTheme,
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(l10n.signInAction),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () =>
                                context.push(RegisterPage.routePath),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              padding: EdgeInsets.zero,
                              textStyle: AppTextTokens.loginTextButton(
                                theme.textTheme,
                              ),
                            ),
                            child: Text(l10n.registerAction),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () =>
                                context.push(ForgotPasswordPage.routePath),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              padding: EdgeInsets.zero,
                              textStyle: AppTextTokens.loginTextButton(
                                theme.textTheme,
                              ),
                            ),
                            child: Text(l10n.forgotPasswordAction),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 30,
                right: 30,
                bottom: 60,
                child: _ThirdPartyLoginSection(
                  showAppleLogin: showAppleLogin,
                  isAppleSubmitting: appleLoginState.isSubmitting,
                  onAppleLogin: _isSubmitting
                      ? null
                      : () => _submitAppleLogin(
                          agreedToTerms: state.agreedToTerms,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginPageAssetPaths {
  const _LoginPageAssetPaths._();

  static const appleProviderMark = 'assets/icons/auth/provider_apple_mark.png';
  static const googleProviderMark =
      'assets/icons/auth/provider_google_mark.png';
  static const facebookProviderMark =
      'assets/icons/auth/provider_meta_mark.png';
  static const agreementCheckedIcon =
      'assets/icons/auth/login_agreement_checked_icon.png';
}

class _ThirdPartyLoginSection extends StatelessWidget {
  const _ThirdPartyLoginSection({
    required this.showAppleLogin,
    required this.isAppleSubmitting,
    required this.onAppleLogin,
  });

  final bool showAppleLogin;
  final bool isAppleSubmitting;
  final VoidCallback? onAppleLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProviderSectionHeader(label: l10n.otherWaysToLogin),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CompactProviderButton(
              label: l10n.continueWithGoogle,
              icon: const _ProviderAssetIcon(
                assetPath: _LoginPageAssetPaths.googleProviderMark,
                size: 36,
                fallback: SizedBox.shrink(),
              ),
              onTap: () => AppToast.info(context, l10n.continueWithGoogle),
            ),
            if (showAppleLogin) ...[
              const SizedBox(width: 18),
              _CompactProviderButton(
                key: const ValueKey('apple_login_button'),
                label: l10n.continueWithApple,
                icon: isAppleSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.brandPrimaryLight,
                        ),
                      )
                    : const _ProviderAssetIcon(
                        assetPath: _LoginPageAssetPaths.appleProviderMark,
                        size: 36,
                        fallback: SizedBox.shrink(),
                      ),
                onTap: isAppleSubmitting ? null : onAppleLogin,
              ),
            ],
            const SizedBox(width: 18),
            _CompactProviderButton(
              label: l10n.continueWithFacebook,
              icon: const _ProviderAssetIcon(
                assetPath: _LoginPageAssetPaths.facebookProviderMark,
                size: 36,
                fallback: SizedBox.shrink(),
              ),
              onTap: () => AppToast.info(context, l10n.continueWithFacebook),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProviderSectionHeader extends StatelessWidget {
  const _ProviderSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _ProviderDivider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: AppTextTokens.loginProviderSectionLabel(
              Theme.of(context).textTheme,
            ),
          ),
        ),
        const Expanded(child: _ProviderDivider()),
      ],
    );
  }
}

class _AgreementToggle extends StatelessWidget {
  const _AgreementToggle({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: selected,
      child: GestureDetector(
        key: const ValueKey('login_agreement_toggle'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.toggleSelected
                      : AppColors.borderMuted,
                ),
                color: selected ? AppColors.toggleSelected : Colors.white,
              ),
              child: selected
                  ? const AuthAssetIcon(
                      assetPath: _LoginPageAssetPaths.agreementCheckedIcon,
                      width: 14,
                      height: 14,
                      fallback: Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderDivider extends StatelessWidget {
  const _ProviderDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.loginProviderDivider,
    );
  }
}

class _CompactProviderButton extends StatelessWidget {
  const _CompactProviderButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.loginProviderSurface,
                shape: BoxShape.circle,
              ),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderAssetIcon extends StatelessWidget {
  const _ProviderAssetIcon({
    required this.assetPath,
    required this.size,
    required this.fallback,
  });

  final String assetPath;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
