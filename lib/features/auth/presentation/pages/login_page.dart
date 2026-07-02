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
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 22,
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
                      icon: Icons.person_outline_rounded,
                      compact: true,
                      ultraCompact: true,
                      onChanged: controller.updateAccount,
                    ),
                    const SizedBox(height: 12),
                    _LoginField(
                      hintText: l10n.loginPasswordPlaceholder,
                      icon: Icons.lock_outline_rounded,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                      icon: const Icon(
                        Icons.apple,
                        color: Colors.white,
                        size: 24,
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
                      icon: const _LetterBadge(
                        text: 'G',
                        foregroundColor: AppColors.brandGoogleBlue,
                        backgroundColor: Colors.white,
                        compact: true,
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
                      icon: const _LetterBadge(
                        text: 'a',
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.brandAlexaDark,
                        compact: true,
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
  final IconData icon;
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
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.borderMuted,
                style: BorderStyle.solid,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.textIcon,
              size: compact ? 22 : 25,
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
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.brandPrimaryLight : AppColors.borderMuted,
        ),
        color: selected ? AppColors.brandPrimaryLight : Colors.white,
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
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
