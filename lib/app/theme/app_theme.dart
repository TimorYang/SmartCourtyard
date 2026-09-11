import 'package:flutter/material.dart';

import '../../features/appearance/domain/entities/app_skin_id.dart';
import 'app_design_tokens.dart';
import 'app_skin_catalog.dart';

class AppTheme {
  const AppTheme._();

  /// The pre-skinning app theme. Keep this visually identical to the
  /// `b3dfd9e` baseline; the extension is metadata and does not alter styling.
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
        systemOverlayStyle: AppSkinCatalog.minimalist.systemOverlayStyle,
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
      extensions: const [AppSkinCatalog.minimalist],
    );
  }

  static ThemeData forSkin(AppSkinId skinId) {
    if (skinId == AppSkinId.minimalist) return light();

    final skin = AppSkinCatalog.forId(skinId);
    final brightness = skinId == AppSkinId.dark
        ? Brightness.dark
        : Brightness.light;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: skin.brand,
          brightness: brightness,
        ).copyWith(
          primary: skin.brand,
          onPrimary: skin.onBrand,
          secondary: skin.accent,
          surface: skin.surface,
          onSurface: skin.textPrimary,
          onSurfaceVariant: skin.textSecondary,
          surfaceContainerLowest: skin.pageBackground,
          surfaceContainerLow: skin.surface,
          surfaceContainer: skin.surface,
          surfaceContainerHigh: skin.surfaceMuted,
          surfaceContainerHighest: skin.surfaceMuted,
          outlineVariant: skin.border,
          outline: skin.border,
          error: skin.danger,
          onError: skin.onBrand,
        );
    final textTheme = ThemeData(brightness: brightness).textTheme.apply(
      bodyColor: skin.textPrimary,
      displayColor: skin.textPrimary,
    );
    final overlayStyle = skin.systemOverlayStyle;

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      scaffoldBackgroundColor: skin.pageBackground,
      cardColor: skin.surface,
      cardTheme: CardThemeData(
        color: skin.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: skin.border,
      disabledColor: skin.disabled,
      iconTheme: IconThemeData(color: skin.textSecondary),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? skin.switchActive
              : skin.switchInactive,
        ),
        thumbColor: WidgetStatePropertyAll(skin.switchThumb),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: skin.navigationBackground,
        indicatorColor: skin.brand.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? skin.navigationSelected
                : skin.navigationUnselected,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? skin.navigationSelected
                : skin.navigationUnselected,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: skin.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: skin.surface,
        modalBackgroundColor: skin.surface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: skin.surfaceMuted,
        hintStyle: TextStyle(color: skin.textMuted),
        labelStyle: TextStyle(color: skin.textSecondary),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: skin.brand,
        selectionColor: skin.brand.withValues(alpha: 0.25),
        selectionHandleColor: skin.brand,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: skin.brand,
        linearTrackColor: skin.surfaceMuted,
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStatePropertyAll(skin.onBrand),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: skin.surfaceMuted,
        contentTextStyle: TextStyle(color: skin.textPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: skin.brand,
          foregroundColor: skin.onBrand,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: skin.navigationBackground,
        foregroundColor: skin.navigationForeground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppResolvedTextTokens(
          AppResolvedColors(skin),
        ).navigationTitle(textTheme).copyWith(color: skin.navigationForeground),
        iconTheme: IconThemeData(color: skin.navigationForeground, size: 22),
        actionsIconTheme: IconThemeData(
          color: skin.navigationForeground,
          size: 22,
        ),
        systemOverlayStyle: overlayStyle,
        shape: Border(bottom: BorderSide(color: skin.border)),
      ),
      extensions: [skin],
    );
  }
}
