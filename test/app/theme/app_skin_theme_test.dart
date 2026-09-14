import 'package:flinx/app/theme/app_design_tokens.dart';
import 'package:flinx/app/theme/app_skin_catalog.dart';
import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/appearance/domain/entities/app_skin_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home headings and report labels remain readable across palettes', () {
    for (final id in [AppSkinId.dark, AppSkinId.technologyWind]) {
      final skin = AppSkinCatalog.forId(id);
      final text = AppResolvedTextTokens(AppResolvedColors(skin));
      final theme = AppTheme.forSkin(id);
      expect(text.homeGreeting(theme.textTheme).color, skin.textPrimary);
      expect(text.homeEmptyTitle(theme.textTheme).color, skin.textPrimary);
      expect(
        text.securityReportDeviceName(theme.textTheme).color,
        skin.textPrimary,
      );
      expect(theme.cardTheme.color, skin.surface);
      expect(
        AppResolvedColors(skin).scannerChipBackground,
        AppColors.scannerChipBackground,
      );
    }
  });

  test('legacy colors interpolate continuously in both directions', () {
    for (final target in [AppSkinCatalog.dark, AppSkinCatalog.technologyWind]) {
      for (final endpoints in [
        (AppSkinCatalog.minimalist, target),
        (target, AppSkinCatalog.minimalist),
      ]) {
        for (final t in [0.0, 0.1, 0.49, 0.5, 0.9, 1.0]) {
          final colors = AppResolvedColors(endpoints.$1.lerp(endpoints.$2, t));
          expect(
            colors.homeBackground,
            Color.lerp(
              AppResolvedColors(endpoints.$1).homeBackground,
              AppResolvedColors(endpoints.$2).homeBackground,
              t,
            ),
          );
          expect(
            colors.backgroundPrimary,
            Color.lerp(
              AppResolvedColors(endpoints.$1).backgroundPrimary,
              AppResolvedColors(endpoints.$2).backgroundPrimary,
              t,
            ),
          );
        }
      }
    }
  });

  test('preserves distinct minimalist component colors', () {
    const colors = AppResolvedColors(AppSkinCatalog.minimalist);
    expect(colors.homeBackground, AppColors.homeBackground);
    expect(colors.backgroundPrimary, AppColors.backgroundPrimary);
    expect(
      colors.accountDetailsLogoutSurface,
      AppColors.accountDetailsLogoutSurface,
    );
    expect(
      colors.deviceControlPrimaryAction,
      AppColors.deviceControlPrimaryAction,
    );
    expect(colors.homeBackground, isNot(colors.backgroundPrimary));
  });

  test(
    'only technology control background has a gradient; commands are solid',
    () {
      expect(AppSkinCatalog.dark.deviceControlBackgroundGradient, isNull);
      expect(AppSkinCatalog.minimalist.deviceControlBackgroundGradient, isNull);
      expect(
        AppSkinCatalog
            .technologyWind
            .deviceControlBackgroundGradient!
            .colors
            .length,
        3,
      );
      for (final id in AppSkinId.values) {
        final skin = AppSkinCatalog.forId(id);
        final colors = AppResolvedColors(skin);
        expect(colors.deviceControlPrimaryAction, skin.commandAction);
        final luminances = [
          skin.commandAction.computeLuminance(),
          skin.commandActionForeground.computeLuminance(),
        ]..sort();
        expect(
          (luminances.last + 0.05) / (luminances.first + 0.05),
          greaterThanOrEqualTo(3),
        );
      }
    },
  );

  test('system bars and material components use the active palette', () {
    for (final id in [AppSkinId.dark, AppSkinId.technologyWind]) {
      final skin = AppSkinCatalog.forId(id);
      final theme = AppTheme.forSkin(id);
      expect(theme.scaffoldBackgroundColor, skin.pageBackground);
      expect(theme.dialogTheme.backgroundColor, skin.surface);
      expect(theme.bottomSheetTheme.backgroundColor, skin.surface);
      expect(theme.appBarTheme.systemOverlayStyle, skin.systemOverlayStyle);
      expect(
        skin.systemOverlayStyle.statusBarIconBrightness,
        id == AppSkinId.dark ? Brightness.light : Brightness.dark,
      );
      expect(AppResolvedColors(skin).warningDialogSurface, skin.surface);
    }
  });

  test(
    'skin resources have stable distinct slots and door images stay original',
    () {
      const asset = 'assets/icons/home/home_header_add_icon.png';
      expect(const AppSkinAssets(AppSkinId.minimalist).resolve(asset), asset);
      expect(
        const AppSkinAssets(AppSkinId.dark).resolve(asset),
        'assets/icons/skins/dark/home/home_header_add_icon_placeholder.png',
      );
      expect(
        const AppSkinAssets(AppSkinId.technologyWind).resolve(asset),
        'assets/icons/skins/technology_wind/home/home_header_add_icon_placeholder.png',
      );
      const emptyDoors = 'assets/icons/home/home_empty_doors.png';
      expect(
        const AppSkinAssets(AppSkinId.minimalist).resolve(emptyDoors),
        emptyDoors,
      );
      expect(
        const AppSkinAssets(AppSkinId.dark).resolve(emptyDoors),
        'assets/icons/skins/dark/home/home_empty_doors_placeholder.png',
      );
      expect(
        const AppSkinAssets(AppSkinId.technologyWind).resolve(emptyDoors),
        'assets/icons/skins/technology_wind/home/home_empty_doors_placeholder.png',
      );
      const door = 'assets/images/device_control_garage_door_closed.png';
      for (final id in AppSkinId.values) {
        expect(AppSkinAssets(id).resolve(door), door);
      }
    },
  );
}
