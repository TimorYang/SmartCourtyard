import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_links.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../application/providers.dart';
import '../../../../shared/l10n/app_localizations.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  static const routeName = 'login';
  static const routePath = '/login';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(loginFormControllerProvider);
    final controller = ref.read(loginFormControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: MediaQuery.removeViewInsets(
        removeBottom: true,
        context: context,
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const _AssetIcon(
                        assetPath: _LoginPageAssetPaths.backArrowIcon,
                        width: 22,
                        height: 22,
                        fallback: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.loginTitle,
                      style: AppTextTokens.loginTitle(theme.textTheme),
                    ),
                    const SizedBox(height: 24),
                    _LoginField(
                      hintText: l10n.loginAccountPlaceholder,
                      icon: const _AssetIcon(
                        assetPath: _LoginPageAssetPaths.accountFieldIcon,
                        width: 22,
                        height: 22,
                        fallback: SizedBox.shrink(),
                      ),
                      compact: true,
                      ultraCompact: true,
                      onChanged: controller.updateAccount,
                    ),
                    const SizedBox(height: 12),
                    _LoginField(
                      hintText: l10n.loginPasswordPlaceholder,
                      icon: const _AssetIcon(
                        assetPath: _LoginPageAssetPaths.passwordFieldIcon,
                        width: 22,
                        height: 22,
                        fallback: SizedBox.shrink(),
                      ),
                      compact: true,
                      ultraCompact: true,
                      obscureText: true,
                      onChanged: controller.updatePassword,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: controller.toggleAgreement,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _AgreementToggle(selected: state.agreedToTerms),
                            const SizedBox(width: 10),
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
                                            destination: AppLinkDestination
                                                .userAgreement,
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
                                            destination: AppLinkDestination
                                                .privacyPolicy,
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
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: state.canSubmit
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.loginSubmitPending),
                                  ),
                                );
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandPrimaryLight,
                          disabledBackgroundColor:
                              AppColors.brandPrimaryDisabled,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: const StadiumBorder(),
                          textStyle: AppTextTokens.loginPrimaryButton(
                            theme.textTheme,
                          ),
                        ),
                        child: Text(l10n.signInAction),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => context.push(RegisterPage.routePath),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: EdgeInsets.zero,
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
              left: 24,
              right: 24,
              bottom: 28,
              child: SafeArea(
                top: false,
                maintainBottomViewPadding: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ProviderButton(
                      label: l10n.continueWithApple,
                      backgroundColor: AppColors.backgroundInverse,
                      foregroundColor: Colors.white,
                      borderColor: AppColors.backgroundInverse,
                      minHeight: 40,
                      compact: true,
                      icon: const _ProviderAssetIcon(
                        assetPath: _LoginPageAssetPaths.appleProviderMark,
                        size: 24,
                        fallback: Icon(
                          Icons.apple,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ProviderButton(
                      label: l10n.continueWithGoogle,
                      backgroundColor: AppColors.backgroundPrimary,
                      foregroundColor: AppColors.textProviderDark,
                      borderColor: AppColors.borderProvider,
                      minHeight: 40,
                      compact: true,
                      icon: const _ProviderAssetIcon(
                        assetPath: _LoginPageAssetPaths.googleProviderMark,
                        size: 28,
                        fallback: _LetterBadge(
                          text: 'G',
                          foregroundColor: AppColors.brandGoogleBlue,
                          backgroundColor: Colors.white,
                          compact: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ProviderButton(
                      label: l10n.continueWithAlexa,
                      backgroundColor: AppColors.brandAlexa,
                      foregroundColor: Colors.white,
                      borderColor: AppColors.brandAlexa,
                      minHeight: 40,
                      compact: true,
                      icon: const _ProviderAssetIcon(
                        assetPath:
                            _LoginPageAssetPaths.voiceAssistantProviderMark,
                        size: 28,
                        fallback: _LetterBadge(
                          text: 'a',
                          foregroundColor: Colors.white,
                          backgroundColor: AppColors.brandAlexaDark,
                          compact: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
  static const voiceAssistantProviderMark =
      'assets/icons/auth/provider_voice_assistant_mark.png';
  static const backArrowIcon = 'assets/icons/auth/login_back_arrow.png';
  static const accountFieldIcon = 'assets/icons/auth/login_account_icon.png';
  static const passwordFieldIcon = 'assets/icons/auth/login_password_icon.png';
  static const agreementCheckedIcon =
      'assets/icons/auth/login_agreement_checked_icon.png';
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.hintText,
    required this.icon,
    required this.onChanged,
    required this.compact,
    required this.ultraCompact,
    this.obscureText = false,
  });

  final String hintText;
  final Widget icon;
  final ValueChanged<String> onChanged;
  final bool compact;
  final bool ultraCompact;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 26 : 30,
            height: compact ? 26 : 30,
            alignment: Alignment.center,
            child: SizedBox(
              width: compact ? 22 : 25,
              height: compact ? 22 : 25,
              child: icon,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              obscureText: obscureText,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: AppTextTokens.loginInputHint.copyWith(
                  fontSize: ultraCompact ? 16 : 18,
                ),
                isDense: compact,
                contentPadding: EdgeInsets.symmetric(
                  vertical: ultraCompact ? 8 : 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgreementToggle extends StatelessWidget {
  const _AgreementToggle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.brandPrimaryLight : AppColors.borderMuted,
        ),
        color: selected ? AppColors.brandPrimaryLight : Colors.white,
      ),
      child: selected
          ? const _AssetIcon(
              assetPath: _LoginPageAssetPaths.agreementCheckedIcon,
              width: 14,
              height: 14,
              fallback: Icon(Icons.check, size: 14, color: Colors.white),
            )
          : null,
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.minHeight,
    required this.compact,
    required this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final double minHeight;
  final bool compact;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(label)));
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          minimumSize: Size.fromHeight(minHeight),
          side: BorderSide(color: borderColor, width: 1.6),
          shape: const StadiumBorder(),
          textStyle: AppTextTokens.providerButton(Theme.of(context).textTheme),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(width: compact ? 10 : 14),
            Flexible(child: Text(label)),
          ],
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

class _AssetIcon extends StatelessWidget {
  const _AssetIcon({
    required this.assetPath,
    required this.width,
    required this.height,
    required this.fallback,
  });

  final String assetPath;
  final double width;
  final double height;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

class _LetterBadge extends StatelessWidget {
  const _LetterBadge({
    required this.text,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.compact,
  });

  final String text;
  final Color foregroundColor;
  final Color backgroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 28 : 32,
      height: compact ? 28 : 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderMuted),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foregroundColor,
          fontSize: compact ? 18 : 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
