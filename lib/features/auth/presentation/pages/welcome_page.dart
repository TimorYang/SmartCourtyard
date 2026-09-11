import '../../../../shared/widgets/flinx_system_ui.dart';
import '../../../../shared/widgets/skin_asset_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import 'login_page.dart';
import 'register_page.dart';

class _WelcomeAssets {
  const _WelcomeAssets._();

  static const background = 'assets/images/auth/welcome_background.png';
  static const logo = 'assets/images/auth/welcome_flinx_logo.png';
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const routeName = 'welcome';
  static const routePath = '/';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return FlinxSystemUi(
      foregroundColor: context.colors.welcomeForeground,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            SkinAssetImage.themed(
              context,
              _WelcomeAssets.background,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) =>
                  ColoredBox(color: context.colors.backgroundDarkMiddle),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 50),
                          SkinAssetImage.themed(
                            context,
                            _WelcomeAssets.logo,
                            height: 40,
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(height: 62),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            l10n.welcomeHeadline,
                            style: context.appText.welcomeHeadline(
                              theme.textTheme,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.welcomeSubtitle,
                            style: context.appText.welcomeSubtitle(
                              theme.textTheme,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => context.push(LoginPage.routePath),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.colors.brandPrimary,
                          foregroundColor: context
                              .colors
                              .authPrimaryButtonDisabledForeground,
                          minimumSize: const Size.fromHeight(50),
                          shape: const StadiumBorder(),
                          textStyle: context.appText.welcomePrimaryButton(
                            theme.textTheme,
                          ),
                        ),
                        child: Text(l10n.loginAction),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => context.push(RegisterPage.routePath),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.colors.backgroundPrimary,
                          foregroundColor: context.colors.textMuted,
                          minimumSize: const Size.fromHeight(50),
                          shape: const StadiumBorder(),
                          textStyle: context.appText.welcomeSecondaryButton(
                            theme.textTheme,
                          ),
                        ),
                        child: Text(l10n.registerAction),
                      ),
                    ),
                    const SizedBox(height: 110),
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
