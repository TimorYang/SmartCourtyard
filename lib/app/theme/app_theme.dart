import 'package:flutter/material.dart';

import 'app_design_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.brandPrimary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navigationBackground,
        foregroundColor: AppColors.navigationForeground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextTokens.navigationTitle(
          ThemeData.light().textTheme,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.navigationForeground,
          size: 22,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.navigationForeground,
          size: 22,
        ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.navigationDivider),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8BB7FF),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextTokens.navigationTitle(
          ThemeData.dark().textTheme,
        ).copyWith(color: colorScheme.onSurface),
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 22),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface, size: 22),
        shape: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
    );
  }
}
