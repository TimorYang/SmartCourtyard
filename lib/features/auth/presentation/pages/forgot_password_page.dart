import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../application/providers.dart';
import 'forgot_password_code_page.dart';
import '../widgets/auth_alerts.dart';

class ForgotPasswordPage extends ConsumerWidget {
  const ForgotPasswordPage({super.key});

  static const routeName = 'forgot-password';
  static const routePath = '/forgot-password';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(forgotPasswordControllerProvider);
    final controller = ref.read(forgotPasswordControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        key: const ValueKey('forgot_password_keyboard_dismiss_area'),
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
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
                  icon: const _ForgotPasswordAssetIcon(
                    assetPath: _ForgotPasswordAssetPaths.backArrowIcon,
                    width: 22,
                    height: 22,
                    fallback: Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                  ),
                ),
                const SizedBox(height: 106),
                Text(
                  l10n.forgotPasswordTitle,
                  style: AppTextTokens.forgotPasswordTitle(theme.textTheme),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.forgotPasswordDescription,
                  style: AppTextTokens.forgotPasswordDescription(
                    theme.textTheme,
                  ),
                ),
                const SizedBox(height: 56),
                _ForgotPasswordEmailField(
                  hintText: l10n.registerEmailPlaceholder,
                  onChanged: controller.updateEmail,
                ),
                const SizedBox(height: 138),
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
                              ForgotPasswordCodePage.locationFor(
                                state.trimmedEmail,
                              ),
                            );
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      disabledBackgroundColor: AppColors.brandPrimaryDisabled,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(72),
                      shape: const StadiumBorder(),
                      textStyle: AppTextTokens.forgotPasswordPrimaryButton(
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
      ),
    );
  }
}

class _ForgotPasswordEmailField extends StatelessWidget {
  const _ForgotPasswordEmailField({
    required this.hintText,
    required this.onChanged,
  });

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
              child: _ForgotPasswordAssetIcon(
                assetPath: _ForgotPasswordAssetPaths.emailFieldIcon,
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
              key: const ValueKey('forgot_password_email_input'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              autofocus: true,
              onChanged: onChanged,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: AppTextTokens.forgotPasswordInputHint,
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

class _ForgotPasswordAssetIcon extends StatelessWidget {
  const _ForgotPasswordAssetIcon({
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

class _ForgotPasswordAssetPaths {
  const _ForgotPasswordAssetPaths._();

  static const backArrowIcon = 'assets/icons/auth/register_back_arrow.png';
  static const emailFieldIcon = 'assets/icons/auth/register_email_icon.png';
}
