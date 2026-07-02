import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../../shared/l10n/app_localizations.dart';
import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const routeName = 'welcome';
  static const routePath = '/';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _WelcomeBackground(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.overlayStrong,
                  AppColors.overlayMedium,
                  AppColors.overlaySoft,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  const _FlinxLogo(),
                  const SizedBox(height: 40),
                  Text(
                    l10n.welcomeHeadline,
                    style: AppTextTokens.welcomeHeadline(theme.textTheme),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.welcomeSubtitle,
                    style: AppTextTokens.welcomeSubtitle(theme.textTheme),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.push(HomePage.routePath),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: AppColors.backgroundPrimary,
                        minimumSize: const Size.fromHeight(62),
                        shape: const StadiumBorder(),
                        textStyle: AppTextTokens.welcomePrimaryButton(
                          theme.textTheme,
                        ),
                      ),
                      child: Text(l10n.homeShortcutAction),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.push(LoginPage.routePath),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: AppColors.backgroundPrimary,
                        minimumSize: const Size.fromHeight(62),
                        shape: const StadiumBorder(),
                        textStyle: AppTextTokens.welcomePrimaryButton(
                          theme.textTheme,
                        ),
                      ),
                      child: Text(l10n.loginAction),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.push(RegisterPage.routePath),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.backgroundPrimary,
                        foregroundColor: AppColors.textMuted,
                        minimumSize: const Size.fromHeight(62),
                        shape: const StadiumBorder(),
                        textStyle: AppTextTokens.welcomeSecondaryButton(
                          theme.textTheme,
                        ),
                      ),
                      child: Text(l10n.registerAction),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBackground extends StatelessWidget {
  const _WelcomeBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundDarkTop,
            AppColors.backgroundDarkMiddle,
            AppColors.backgroundDarkBottom,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -90,
            right: -30,
            child: _GlowOrb(
              size: 240,
              color: AppColors.glowPrimary,
              opacity: 0.24,
            ),
          ),
          Positioned(
            top: 110,
            left: -50,
            child: _GlowOrb(
              size: 160,
              color: AppColors.glowSecondary,
              opacity: 0.18,
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.42),
            child: Container(
              width: double.infinity,
              height: 320,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: AppColors.surfaceGarage,
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowStrong,
                    blurRadius: 30,
                    offset: Offset(0, 24),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.16),
            child: Container(
              width: double.infinity,
              height: 82,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                color: AppColors.surfaceGarageTrim,
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 92,
              height: 230,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surfacePlantDark,
                    AppColors.surfacePlantDarker,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 54,
            bottom: 156,
            child: Container(
              width: 18,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfacePlantMid,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned(
            left: 40,
            bottom: 176,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfacePlantLight,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _FlinxLogo extends StatelessWidget {
  const _FlinxLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RichText(
            text: TextSpan(
              style: AppTextTokens.flinxLogo(Theme.of(context).textTheme),
              children: const [
                TextSpan(text: 'f'),
                TextSpan(text: '.'),
                TextSpan(text: 'lin'),
                TextSpan(text: 'X'),
              ],
            ),
          ),
          Positioned(
            left: 48,
            top: -8,
            child: Transform.rotate(
              angle: -0.15,
              child: const Icon(
                Icons.wifi_rounded,
                color: AppColors.accentWifi,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
