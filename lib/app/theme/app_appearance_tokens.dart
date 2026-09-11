import 'package:flutter/material.dart';

import 'app_skin_catalog.dart';

class AppAppearanceLayoutTokens {
  const AppAppearanceLayoutTokens._();

  static const pageHorizontalPadding = 20.0;
  static const pageVerticalPadding = 8.0;
  static const sectionSpacing = 16.0;
  static const cardRadius = 16.0;
  static const cardPadding = 14.0;
  static const cardPreviewHeight = 210.0;
  static const detailPreviewHeight = 520.0;
  static const controlHeight = 52.0;
  static const touchTarget = 48.0;
  static const pageIndicatorSize = 16.0;
  static const previewActionRadius = 8.0;
  static const tagRadius = 7.0;
}

class AppAppearanceColorTokens {
  const AppAppearanceColorTokens(this.skin);
  final AppSkinTokens skin;
  Color get pageBackground => skin.resolveSemantic(
    AppSkinColorSemantic.pageBackground,
    fallback: const Color(0xFFF5F7FC),
  );
  Color get cardSurface => skin.resolveSemantic(
    AppSkinColorSemantic.surface,
    fallback: const Color(0xFFFFFFFF),
  );
  Color get previewActionSurface => skin.resolveSemantic(
    AppSkinColorSemantic.surfaceMuted,
    fallback: const Color(0xFFE5F0FF),
  );
  Color get previewActionForeground => skin.resolveSemantic(
    AppSkinColorSemantic.brand,
    fallback: const Color(0xFF1477F9),
  );
  Color get tagSurface => skin.resolveSemantic(
    AppSkinColorSemantic.surfaceMuted,
    fallback: const Color(0xFFF1F1F2),
  );
  Color get tagForeground => skin.resolveSemantic(
    AppSkinColorSemantic.textSecondary,
    fallback: const Color(0xFF737478),
  );
  Color get applyAction => skin.resolveSemantic(
    AppSkinColorSemantic.brand,
    fallback: const Color(0xFF0D6EFD),
  );
  Color get pageIndicatorInactive => skin.resolveSemantic(
    AppSkinColorSemantic.disabled,
    fallback: const Color(0xFFD7D8DA),
  );
}

class AppAppearanceTextTokens {
  const AppAppearanceTextTokens._();

  static TextStyle intro(TextTheme textTheme, AppSkinTokens skin) =>
      (textTheme.bodyLarge ?? const TextStyle()).copyWith(
        color: skin.textSecondary,
        height: 1.5,
      );

  static TextStyle cardTitle(TextTheme textTheme, AppSkinTokens skin) =>
      (textTheme.titleLarge ?? const TextStyle()).copyWith(
        color: skin.textPrimary,
        fontWeight: FontWeight.w700,
      );

  static TextStyle cardDescription(TextTheme textTheme, AppSkinTokens skin) =>
      (textTheme.bodyMedium ?? const TextStyle()).copyWith(
        color: skin.textSecondary,
        height: 1.45,
      );

  static TextStyle pageTitle(TextTheme textTheme, AppSkinTokens skin) =>
      (textTheme.headlineMedium ?? const TextStyle()).copyWith(
        color: skin.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      );

  static TextStyle gallerySubtitle(TextTheme textTheme, AppSkinTokens skin) =>
      (textTheme.titleMedium ?? const TextStyle()).copyWith(
        color: skin.textSecondary,
        fontWeight: FontWeight.w400,
      );

  static TextStyle placeholder(TextTheme textTheme, AppSkinTokens skin) =>
      (textTheme.labelLarge ?? const TextStyle()).copyWith(
        color: skin.textMuted,
        fontWeight: FontWeight.w600,
      );
}

extension AppAppearanceContext on BuildContext {
  AppAppearanceColorTokens get appearanceColors =>
      AppAppearanceColorTokens(skin);
}
