import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const brandPrimary = Color(0xFF176CFF);
  static const brandPrimaryLight = Color(0xFF90CAF8);
  static const brandPrimaryDisabled = Color(0xFFB5D8F5);
  static const authPrimaryButtonDisabledForeground = Color(0xFFFFFFFF);
  static const authSuccess = Color(0xFF12C76B);
  static const toggleSelected = Color(0xFF12C76B);
  static const brandAlexa = Color(0xFF2EB5E9);
  static const brandAlexaDark = Color(0xFF1F96C5);
  static const brandGoogleBlue = Color(0xFF4285F4);
  static const accentWifi = Color(0xFFD9E100);
  static const glowPrimary = Color(0xFF2055D8);
  static const glowSecondary = Color(0xFF1A3C7A);

  static const backgroundPrimary = Colors.white;
  static const backgroundInverse = Colors.black;
  static const homeBackground = Color(0xFFF8F8F9);
  static const backgroundDarkTop = Color(0xFF0D1B30);
  static const backgroundDarkMiddle = Color(0xFF14253D);
  static const backgroundDarkBottom = Color(0xFF1B1D24);

  static const surfaceGarage = Color(0xFF15171E);
  static const surfaceGarageTrim = Color(0xFF2A2D35);
  static const surfacePlantDark = Color(0xFF263327);
  static const surfacePlantDarker = Color(0xFF121813);
  static const surfacePlantMid = Color(0xFF384A37);
  static const surfacePlantLight = Color(0xFF4E6550);

  static const textPrimary = Color(0xFF26292F);
  static const textSecondary = Color(0xFF202020);
  static const textMuted = Color(0xFF5B5B60);
  static const textHint = Color(0xFF7A7A7A);
  static const textIcon = Color(0xFF5A5D64);
  static const textAgreement = Color(0xFFC0C0C3);
  static const textAgreementLink = Color(0xFF4C4B4A);
  static const textAuthBody = Color(0xFF555A62);
  static const textRegisterAgreement = Color(0xFF707070);
  static const textRegisterLink = Color(0xFF0D6EFF);
  static const textProviderDark = Color(0xFF2D2D2D);
  static const textCodeResend = Color(0xFF7DAEFF);

  static const iconHomeAction = Color(0xFF3F424A);
  static const iconHomePlaceholder = Color(0xFFD5D9E0);
  static const surfaceHomeAvatar = Color(0xFFECEFF4);
  static const surfaceHomeIcon = Color(0xFFF8F9FB);
  static const surfaceSceneCard = Color(0xFFF4F5F7);
  static const surfaceItemSceneCard = Color(0xFFF1F3F5);

  static const borderSubtle = Color(0xFFDBDBDB);
  static const borderMuted = Color(0xFFC8C8C8);
  static const borderProvider = Color(0xFFADADAD);
  static const borderCodeCell = Color(0xFFE1E1E1);
  static const navigationBackground = Colors.white;
  static const navigationForeground = Color(0xFF26292F);
  static const navigationDivider = Color(0xFFE6E7EB);
  static const borderHomeDivider = Color(0xFFE7E8EB);
  static const borderHomePlaceholder = Color(0xFFDDE1E7);

  static const shadowStrong = Color(0x99000000);
  static const overlayStrong = Color(0x7A000000);
  static const overlayMedium = Color(0xA3000000);
  static const overlaySoft = Color(0x57000000);
}

class AppTextTokens {
  const AppTextTokens._();

  static TextStyle welcomeHeadline(TextTheme textTheme) {
    return (textTheme.displaySmall ?? const TextStyle()).copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      height: 1.06,
    );
  }

  static TextStyle welcomeSubtitle(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: Colors.white.withValues(alpha: 0.88),
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle navigationTitle(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: AppColors.navigationForeground,
      fontSize: 17,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle welcomePrimaryButton(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle welcomeSecondaryButton(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle loginTitle(TextTheme textTheme) {
    return (textTheme.displaySmall ?? const TextStyle()).copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle loginAgreement(TextTheme textTheme) {
    return (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: AppColors.textAgreement,
      height: 1.45,
    );
  }

  static const loginInputHint = TextStyle(
    color: AppColors.textHint,
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );

  static TextStyle loginPrimaryButton(TextTheme textTheme) {
    return (textTheme.headlineSmall ?? const TextStyle()).copyWith(
      fontSize: 17,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle loginTextButton(TextTheme textTheme) {
    return (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle registerTitle(TextTheme textTheme) {
    return (textTheme.displaySmall ?? const TextStyle()).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle registerDescription(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: AppColors.textAuthBody,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
  }

  static const registerInputHint = TextStyle(
    color: AppColors.textHint,
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );

  static TextStyle registerAgreement(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: AppColors.textRegisterAgreement,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
  }

  static TextStyle registerPrimaryButton(TextTheme textTheme) {
    return (textTheme.titleLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle forgotPasswordTitle(TextTheme textTheme) {
    return (textTheme.displaySmall ?? const TextStyle()).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle forgotPasswordDescription(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: AppColors.textAuthBody,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
  }

  static const forgotPasswordInputHint = TextStyle(
    color: AppColors.textHint,
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );

  static TextStyle forgotPasswordPrimaryButton(TextTheme textTheme) {
    return (textTheme.titleLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle authFlowTitle(TextTheme textTheme) {
    return (textTheme.displaySmall ?? const TextStyle()).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle authFlowDescription(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: AppColors.textAuthBody,
      fontWeight: FontWeight.w400,
      height: 1.35,
    );
  }

  static TextStyle verificationTitle(TextTheme textTheme) {
    return (textTheme.displaySmall ?? const TextStyle()).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle verificationDescription(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: AppColors.textAuthBody,
      fontWeight: FontWeight.w400,
      height: 1.35,
    );
  }

  static TextStyle verificationDigit(TextTheme textTheme) {
    return (textTheme.headlineSmall ?? const TextStyle()).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle verificationResend(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: AppColors.textCodeResend,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle registerPasswordTitle(TextTheme textTheme) {
    return (textTheme.displaySmall ?? const TextStyle()).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle registerPasswordDescription(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: AppColors.textAuthBody,
      fontWeight: FontWeight.w400,
      height: 1.35,
    );
  }

  static const registerPasswordInputHint = TextStyle(
    color: AppColors.textHint,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static const authPasswordInput = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static TextStyle registerPasswordPrimaryButton(TextTheme textTheme) {
    return (textTheme.titleLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle authSuccessTitle(TextTheme textTheme) {
    return (textTheme.headlineMedium ?? const TextStyle()).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle authSuccessDescription(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: AppColors.textAuthBody,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle providerButton(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle flinxLogo(TextTheme textTheme) {
    return (textTheme.headlineMedium ?? const TextStyle()).copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.4,
    );
  }

  static TextStyle homeGreeting(TextTheme textTheme) {
    return (textTheme.headlineSmall ?? const TextStyle()).copyWith(
      color: Colors.black,
      fontWeight: FontWeight.w800,
      height: 1.05,
    );
  }

  static TextStyle homeWelcome(TextTheme textTheme) {
    return (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle homeTabLabel(TextTheme textTheme) {
    return (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle homeDoorCount(TextTheme textTheme) {
    return (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle homeEmptyTitle(TextTheme textTheme) {
    return (textTheme.headlineSmall ?? const TextStyle()).copyWith(
      color: Colors.black,
      fontWeight: FontWeight.w800,
      height: 1.05,
    );
  }

  static TextStyle homeEmptySubtitle(TextTheme textTheme) {
    return (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: AppColors.textHint,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle homePrimaryButton(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle sceneTitle(TextTheme textTheme) {
    return (textTheme.displaySmall ?? const TextStyle()).copyWith(
      color: AppColors.textPrimary,
      fontSize: 25,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      height: 1.08,
    );
  }

  static TextStyle sceneBreadcrumb(TextTheme textTheme) {
    return (textTheme.titleLarge ?? const TextStyle()).copyWith(
      color: AppColors.textMuted,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.2,
    );
  }

  static TextStyle sceneCardTitle(TextTheme textTheme) {
    return (textTheme.titleLarge ?? const TextStyle()).copyWith(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
  }

  static TextStyle sceneCardMeta(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: AppColors.textHint,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.2,
    );
  }

  static TextStyle sceneNewScene(TextTheme textTheme) {
    return (textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: AppColors.textPrimary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.2,
    );
  }
}
