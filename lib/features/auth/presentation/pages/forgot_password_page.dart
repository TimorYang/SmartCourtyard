import 'package:flinx/shared/widgets/flinx_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../application/providers.dart';
import 'forgot_password_code_page.dart';
import '../widgets/auth_alerts.dart';
import '../widgets/auth_flow_widgets.dart';

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
      appBar: FlinxNavigationBar(title: '', showBottomDivider: false),
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        key: const ValueKey('forgot_password_keyboard_dismiss_area'),
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 10, 30, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
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
                const SizedBox(height: 40),
                AuthTextField(
                  fieldKey: const ValueKey('forgot_password_email_input'),
                  hintText: l10n.registerEmailPlaceholder,
                  icon: const AuthAssetIcon(
                    assetPath: AuthAssetPaths.emailFieldIcon,
                    width: 22,
                    height: 22,
                    fallback: Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.textIcon,
                      size: 22,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  autofocus: true,
                  onChanged: controller.updateEmail,
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ),
                const SizedBox(height: 80),
                SizedBox(
                  width: double.infinity,
                  height: 52,
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
                      backgroundColor: AppColors.brandPrimaryLight,
                      disabledBackgroundColor: AppColors.brandPrimaryDisabled,
                      foregroundColor: Colors.white,
                      disabledForegroundColor:
                          AppColors.authPrimaryButtonDisabledForeground,
                      minimumSize: const Size.fromHeight(48),
                      shape: const StadiumBorder(),
                      textStyle: AppTextTokens.loginPrimaryButton(
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
