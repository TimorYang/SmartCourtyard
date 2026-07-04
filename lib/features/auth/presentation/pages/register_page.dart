import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_links.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../application/providers.dart';
import '../../../../shared/l10n/app_localizations.dart';
import 'register_code_page.dart';
import '../widgets/auth_alerts.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  static const routeName = 'register';
  static const routePath = '/register';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(registerFormControllerProvider);
    final controller = ref.read(registerFormControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 10, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                icon: const _RegisterAssetIcon(
                  assetPath: _RegisterPageAssetPaths.backArrowIcon,
                  width: 22,
                  height: 22,
                  fallback: Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                ),
              ),
              const SizedBox(height: 106),
              Text(
                l10n.registerTitle,
                style: AppTextTokens.registerTitle(theme.textTheme),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.registerDescription,
                style: AppTextTokens.registerDescription(theme.textTheme),
              ),
              const SizedBox(height: 56),
              _RegisterEmailField(
                hintText: l10n.registerEmailPlaceholder,
                onChanged: controller.updateEmail,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _PrivacyAgreementToggle(
                    selected: state.agreedToPrivacyPolicy,
                    onTap: controller.togglePrivacyAgreement,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: AppTextTokens.registerAgreement(theme.textTheme),
                        children: [
                          TextSpan(text: l10n.registerAgreementPrefix),
                          TextSpan(
                            text: l10n.privacyPolicyLabel,
                            style: const TextStyle(
                              color: AppColors.textRegisterLink,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.textRegisterLink,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => context.push(
                                AppLinks.webViewLocation(
                                  destination: AppLinkDestination.privacyPolicy,
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
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.canSendCode
                      ? () async {
                          if (!controller.validateEmailForSubmit()) {
                            await showAuthEmailInvalidDialog(context);
                            return;
                          }
                          context.push(
                            RegisterCodePage.locationFor(state.trimmedEmail),
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    disabledBackgroundColor: AppColors.brandPrimaryDisabled,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(72),
                    shape: const StadiumBorder(),
                    textStyle: AppTextTokens.registerPrimaryButton(
                      theme.textTheme,
                    ),
                  ),
                  child: Text(l10n.sendCodeAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterPageAssetPaths {
  const _RegisterPageAssetPaths._();

  static const backArrowIcon = 'assets/icons/auth/register_back_arrow.png';
  static const emailFieldIcon = 'assets/icons/auth/register_email_icon.png';
  static const privacyCheckedIcon =
      'assets/icons/auth/register_privacy_checked_icon.png';
}

class _RegisterEmailField extends StatelessWidget {
  const _RegisterEmailField({required this.hintText, required this.onChanged});

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 28,
            height: 34,
            child: Center(
              child: _RegisterAssetIcon(
                assetPath: _RegisterPageAssetPaths.emailFieldIcon,
                width: 24,
                height: 24,
                fallback: Icon(
                  Icons.mail_outline_rounded,
                  color: AppColors.textIcon,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: AppTextTokens.registerInputHint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyAgreementToggle extends StatelessWidget {
  const _PrivacyAgreementToggle({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: selected,
      child: GestureDetector(
        key: const ValueKey('register_privacy_agreement_toggle'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.authSuccess
                      : AppColors.borderMuted,
                ),
                color: selected ? AppColors.authSuccess : Colors.white,
              ),
              child: selected
                  ? const _RegisterAssetIcon(
                      assetPath: _RegisterPageAssetPaths.privacyCheckedIcon,
                      width: 18,
                      height: 18,
                      fallback: Icon(
                        Icons.check,
                        size: 20,
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

class _RegisterAssetIcon extends StatelessWidget {
  const _RegisterAssetIcon({
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
