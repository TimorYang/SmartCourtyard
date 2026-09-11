import 'package:flinx/shared/widgets/flinx_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_links.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../application/providers.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import 'register_code_page.dart';
import '../widgets/auth_alerts.dart';
import '../widgets/auth_flow_widgets.dart';

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

    ref.listen(registerFormControllerProvider, (previous, next) {
      if ((next.errorMessageKey != null || next.errorMessage != null) &&
          (next.errorMessageKey != previous?.errorMessageKey ||
              next.errorMessage != previous?.errorMessage)) {
        AppToast.error(
          context,
          registrationErrorMessage(
            context,
            next.errorMessageKey,
            userMessage: next.errorMessage,
          ),
        );
      }
    });

    return Scaffold(
      appBar: FlinxNavigationBar(title: '', showBottomDivider: false),
      backgroundColor: context.colors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.registerTitle,
                style: context.appText.registerTitle(theme.textTheme),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.registerDescription,
                style: context.appText.registerDescription(theme.textTheme),
              ),
              const SizedBox(height: 48),
              AuthTextField(
                hintText: l10n.registerEmailPlaceholder,
                icon: AuthAssetIcon(
                  assetPath: AuthAssetPaths.emailFieldIcon,
                  width: 22,
                  height: 22,
                  fallback: Icon(
                    Icons.mail_outline_rounded,
                    color: context.colors.textIcon,
                    size: 22,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                onChanged: controller.updateEmail,
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _PrivacyAgreementToggle(
                    selected: state.agreedToPrivacyPolicy,
                    onTap: controller.togglePrivacyAgreement,
                  ),
                  const SizedBox(width: 0),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: context.appText.registerAgreement(
                          theme.textTheme,
                        ),
                        children: [
                          TextSpan(text: l10n.registerAgreementPrefix),
                          TextSpan(
                            text: l10n.privacyPolicyLabel,
                            style: TextStyle(
                              color: context.colors.textAgreementLink,
                              decoration: TextDecoration.underline,
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
              const SizedBox(height: 30),
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
                          final sent = await controller.sendCode();
                          if (sent && context.mounted) {
                            context.push(
                              RegisterCodePage.locationFor(state.trimmedEmail),
                            );
                          }
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.brandPrimaryLight,
                    disabledBackgroundColor:
                        context.colors.brandPrimaryDisabled,
                    foregroundColor:
                        context.colors.authPrimaryButtonDisabledForeground,
                    disabledForegroundColor:
                        context.colors.authPrimaryButtonDisabledForeground,
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                    textStyle: context.appText.loginPrimaryButton(
                      theme.textTheme,
                    ),
                  ),
                  child: state.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.sendCodeAction),
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

  static const privacyCheckedIcon =
      'assets/icons/auth/register_privacy_checked_icon.png';
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
                      ? context.colors.toggleSelected
                      : context.colors.borderMuted,
                ),
                color: selected
                    ? context.colors.toggleSelected
                    : context.colors.authPrimaryButtonDisabledForeground,
              ),
              child: selected
                  ? AuthAssetIcon(
                      assetPath: _RegisterPageAssetPaths.privacyCheckedIcon,
                      width: 14,
                      height: 14,
                      fallback: Icon(
                        Icons.check,
                        size: 14,
                        color:
                            context.colors.authPrimaryButtonDisabledForeground,
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
