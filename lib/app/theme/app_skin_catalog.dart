import 'skins/technology_skin.dart';
import 'skins/minimalist_skin.dart';
import 'skins/dark_skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/appearance/domain/entities/app_skin_id.dart';

enum AppSkinColorSemantic {
  keepOriginal,
  pageBackground,
  surface,
  surfaceMuted,
  textPrimary,
  textSecondary,
  textMuted,
  border,
  brand,
  brandMuted,
  onBrand,
  navigationForeground,
  commandAction,
  commandActionForeground,
  switchActive,
  accent,
  success,
  successMuted,
  disabled,
  danger,
  dangerMuted,
  warning,
  scrim,
  shadow,
}

enum AppSkinColorRole {
  brandAlexa(AppSkinColorSemantic.keepOriginal),
  brandAlexaDark(AppSkinColorSemantic.keepOriginal),
  brandGoogleBlue(AppSkinColorSemantic.keepOriginal),
  accentWifi(AppSkinColorSemantic.brand),
  glowPrimary(AppSkinColorSemantic.brand),
  glowSecondary(AppSkinColorSemantic.brand),
  backgroundInverse(AppSkinColorSemantic.pageBackground),
  afterSalesHint(AppSkinColorSemantic.textMuted),
  fBoxConnectionManualHint(AppSkinColorSemantic.textMuted),
  fBoxWiringTestControlSurface(AppSkinColorSemantic.commandAction),
  fBoxWiringTestControlForeground(AppSkinColorSemantic.commandActionForeground),
  deviceControlPanelPressed(AppSkinColorSemantic.surfaceMuted),
  deviceControlWireless(AppSkinColorSemantic.brand),
  deviceControlMetricMuted(AppSkinColorSemantic.textMuted),
  deviceSettingsValue(AppSkinColorSemantic.brand),
  deviceSettingsSectionLabel(AppSkinColorSemantic.textMuted),
  deviceDetailNavigationSelected(AppSkinColorSemantic.brand),
  deviceDetailNavigationUnselected(AppSkinColorSemantic.disabled),
  securityCenterDialogWarning(AppSkinColorSemantic.warning),
  warningDialogScrim(AppSkinColorSemantic.scrim),
  warningDialogSurface(AppSkinColorSemantic.surface),
  warningDialogIcon(AppSkinColorSemantic.warning),
  warningDialogPrimaryAction(AppSkinColorSemantic.brand),
  warningDialogPrimaryActionForeground(AppSkinColorSemantic.onBrand),
  securityReportHeroBlue(AppSkinColorSemantic.pageBackground),
  securityReportHeroFade(AppSkinColorSemantic.pageBackground),
  securityReportSuggestion(AppSkinColorSemantic.danger),
  safetyBatterySolutionHighlightBorder(AppSkinColorSemantic.border),
  backgroundDarkTop(AppSkinColorSemantic.pageBackground),
  backgroundDarkBottom(AppSkinColorSemantic.pageBackground),
  surfaceGarage(AppSkinColorSemantic.keepOriginal),
  surfaceGarageTrim(AppSkinColorSemantic.keepOriginal),
  surfacePlantDark(AppSkinColorSemantic.keepOriginal),
  surfacePlantMid(AppSkinColorSemantic.keepOriginal),
  surfacePlantLight(AppSkinColorSemantic.keepOriginal),
  textMuted1A232C(AppSkinColorSemantic.textPrimary),
  textMuted656565(AppSkinColorSemantic.textMuted),
  textAccountHeader(AppSkinColorSemantic.textPrimary),
  textAccountHeaderMeta(AppSkinColorSemantic.textSecondary),
  textAccountMenuValue(AppSkinColorSemantic.textSecondary),
  textAccountDetailsValue(AppSkinColorSemantic.textMuted),
  textAccountLanguageOption(AppSkinColorSemantic.textSecondary),
  textAccountLanguageSelected(AppSkinColorSemantic.textPrimary),
  textAgreement(AppSkinColorSemantic.textSecondary),
  textAuthBody(AppSkinColorSemantic.textSecondary),
  textRegisterAgreement(AppSkinColorSemantic.textSecondary),
  textRegisterLink(AppSkinColorSemantic.brand),
  textRegisterLink0066FF(AppSkinColorSemantic.brand),
  textProviderDark(AppSkinColorSemantic.textSecondary),
  iconAccountMenu(AppSkinColorSemantic.textSecondary),
  sharedDevicesAddButton(AppSkinColorSemantic.brand),
  manageDevicesIcon(AppSkinColorSemantic.textSecondary),
  upgradeCheckOnlineSurface(AppSkinColorSemantic.successMuted),
  upgradeCheckOnlineText(AppSkinColorSemantic.success),
  upgradeCheckOfflineSurface(AppSkinColorSemantic.dangerMuted),
  upgradeCheckOfflineText(AppSkinColorSemantic.danger),
  scannerControlBackground(AppSkinColorSemantic.keepOriginal),
  smartOpenerWifiError(AppSkinColorSemantic.danger),
  deviceShareFieldShadow(AppSkinColorSemantic.shadow),
  borderProvider(AppSkinColorSemantic.border),
  loginProviderForeground(AppSkinColorSemantic.textPrimary),
  navigationBackground(AppSkinColorSemantic.pageBackground),
  navigationDivider(AppSkinColorSemantic.border),
  shadowStrong(AppSkinColorSemantic.shadow),
  accountDetailsAvatarForeground(AppSkinColorSemantic.onBrand),
  accountDetailsAvatarOptionBorder(AppSkinColorSemantic.border),
  accountDetailsAvatarSurface(AppSkinColorSemantic.surface),
  accountDetailsDeletionConfirmForeground(AppSkinColorSemantic.onBrand),
  accountDetailsDeletionConfirmSurface(AppSkinColorSemantic.danger),
  accountDetailsLogoutSurface(AppSkinColorSemantic.surface),
  accountDetailsSheetActionSurface(AppSkinColorSemantic.surfaceMuted),
  accountDetailsSheetInputBorder(AppSkinColorSemantic.border),
  accountDetailsSheetInputFocusedBorder(AppSkinColorSemantic.brand),
  accountDetailsSheetInputIcon(AppSkinColorSemantic.textMuted),
  accountDetailsSheetSurface(AppSkinColorSemantic.surface),
  accountLanguageDialogCancelSurface(AppSkinColorSemantic.surfaceMuted),
  accountLanguageDialogDivider(AppSkinColorSemantic.border),
  accountLanguageDialogScrim(AppSkinColorSemantic.scrim),
  accountLanguageDialogSurface(AppSkinColorSemantic.surface),
  accountProfileBackground(AppSkinColorSemantic.pageBackground),
  accountProfileLogoutSurface(AppSkinColorSemantic.surface),
  afterSalesConfirmedSurface(AppSkinColorSemantic.surface),
  afterSalesFieldBorder(AppSkinColorSemantic.border),
  afterSalesPhotoIcon(AppSkinColorSemantic.textSecondary),
  afterSalesPhotoPlaceholder(AppSkinColorSemantic.surfaceMuted),
  afterSalesSecondaryBorder(AppSkinColorSemantic.border),
  afterSalesSummarySurface(AppSkinColorSemantic.surface),
  authInputErrorBorder(AppSkinColorSemantic.danger),
  authPrimaryButtonDisabledForeground(AppSkinColorSemantic.onBrand),
  authSuccess(AppSkinColorSemantic.success),
  backgroundDarkMiddle(AppSkinColorSemantic.surfaceMuted),
  backgroundPrimary(AppSkinColorSemantic.pageBackground),
  borderAccountDivider(AppSkinColorSemantic.border),
  borderCodeCell(AppSkinColorSemantic.border),
  borderHomeDivider(AppSkinColorSemantic.border),
  borderHomePlaceholder(AppSkinColorSemantic.disabled),
  borderMuted(AppSkinColorSemantic.border),
  borderRegionDivider(AppSkinColorSemantic.border),
  borderSelectedSceneCard(AppSkinColorSemantic.brand),
  borderSubtle(AppSkinColorSemantic.border),
  brandPrimary(AppSkinColorSemantic.brand),
  brandPrimaryDisabled(AppSkinColorSemantic.disabled),
  brandPrimaryLight(AppSkinColorSemantic.brand),
  deviceControlDivider(AppSkinColorSemantic.border),
  deviceControlInactive(AppSkinColorSemantic.disabled),
  deviceControlPanel(AppSkinColorSemantic.surface),
  deviceControlPrimaryAction(AppSkinColorSemantic.commandAction),
  deviceControlPrimaryActionForeground(
    AppSkinColorSemantic.commandActionForeground,
  ),
  deviceDetailNavigationBackground(AppSkinColorSemantic.surface),
  deviceDetailNavigationDivider(AppSkinColorSemantic.border),
  deviceSettingsCancelAction(AppSkinColorSemantic.surfaceMuted),
  deviceSettingsDivider(AppSkinColorSemantic.border),
  deviceSettingsForceMarginConfirm(AppSkinColorSemantic.brand),
  deviceSettingsForceMarginWarningText(AppSkinColorSemantic.warning),
  deviceSettingsSheetCancel(AppSkinColorSemantic.surfaceMuted),
  deviceSettingsSheetScrim(AppSkinColorSemantic.scrim),
  deviceSettingsSliderGuide(AppSkinColorSemantic.border),
  deviceShareCancelButton(AppSkinColorSemantic.surfaceMuted),
  deviceShareCheckbox(AppSkinColorSemantic.brand),
  deviceShareDialogOverlay(AppSkinColorSemantic.scrim),
  deviceShareEditSummaryBackground(AppSkinColorSemantic.pageBackground),
  deviceShareFieldBorder(AppSkinColorSemantic.border),
  deviceShareFieldDisabled(AppSkinColorSemantic.surfaceMuted),
  deviceShareFieldError(AppSkinColorSemantic.danger),
  deviceShareHourSelected(AppSkinColorSemantic.brand),
  deviceShareUnavailable(AppSkinColorSemantic.disabled),
  fBoxWiringTestPrimaryAction(AppSkinColorSemantic.brand),
  fBoxWiringTestPrimaryActionForeground(AppSkinColorSemantic.onBrand),
  fBoxWiringTestSegmentBorder(AppSkinColorSemantic.border),
  fBoxWiringTestSegmentSelectedSurface(AppSkinColorSemantic.surface),
  fBoxWiringTestSegmentSurface(AppSkinColorSemantic.surfaceMuted),
  fBoxWiringTestStatusPending(AppSkinColorSemantic.disabled),
  homeBackground(AppSkinColorSemantic.pageBackground),
  homeDeviceOnlineStatus(AppSkinColorSemantic.success),
  homeDeviceUnavailableStatus(AppSkinColorSemantic.textPrimary),
  homeNotificationUnreadBadge(AppSkinColorSemantic.keepOriginal),
  iconAccountChevron(AppSkinColorSemantic.textSecondary),
  iconHomeAction(AppSkinColorSemantic.brand),
  iconHomePlaceholder(AppSkinColorSemantic.disabled),
  loginProviderDivider(AppSkinColorSemantic.border),
  loginProviderSurface(AppSkinColorSemantic.surface),
  loginToggleSurface(AppSkinColorSemantic.surface),
  manageDevicesCard(AppSkinColorSemantic.surface),
  manageDevicesRemoveDialogCancelSurface(AppSkinColorSemantic.surfaceMuted),
  manageDevicesRemoveDialogConfirmSurface(AppSkinColorSemantic.brand),
  manageDevicesRemoveDialogScrim(AppSkinColorSemantic.scrim),
  manageDevicesRemoveDialogSurface(AppSkinColorSemantic.surface),
  navigationForeground(AppSkinColorSemantic.navigationForeground),
  notificationBackground(AppSkinColorSemantic.pageBackground),
  notificationCard(AppSkinColorSemantic.surface),
  notificationEquipmentTag(AppSkinColorSemantic.dangerMuted),
  notificationEquipmentText(AppSkinColorSemantic.danger),
  notificationIcon(AppSkinColorSemantic.textSecondary),
  notificationIconSurface(AppSkinColorSemantic.surfaceMuted),
  notificationServiceTag(AppSkinColorSemantic.brandMuted),
  notificationServiceText(AppSkinColorSemantic.brand),
  notificationUnread(AppSkinColorSemantic.keepOriginal),
  notificationUpgradeTag(AppSkinColorSemantic.successMuted),
  notificationUpgradeText(AppSkinColorSemantic.success),
  onBrand(AppSkinColorSemantic.onBrand),
  operationRecordAvatarSurface(AppSkinColorSemantic.surface),
  operationRecordDivider(AppSkinColorSemantic.border),
  operationRecordTimeline(AppSkinColorSemantic.border),
  operationRecordTimelineLine(AppSkinColorSemantic.border),
  overlayMedium(AppSkinColorSemantic.scrim),
  overlaySoft(AppSkinColorSemantic.scrim),
  overlayStrong(AppSkinColorSemantic.scrim),
  receivingDevicesCard(AppSkinColorSemantic.surface),
  receivingDevicesDeleteAction(AppSkinColorSemantic.danger),
  regionSelection(AppSkinColorSemantic.brand),
  registerToggleSurface(AppSkinColorSemantic.surface),
  safetyBatterySolutionPlaceholderSurface(AppSkinColorSemantic.surfaceMuted),
  safetySensorAction(AppSkinColorSemantic.brand),
  safetySensorDisconnected(AppSkinColorSemantic.disabled),
  safetySensorItemSurface(AppSkinColorSemantic.surface),
  safetySensorManagementBackground(AppSkinColorSemantic.pageBackground),
  safetySensorManagementCancel(AppSkinColorSemantic.surfaceMuted),
  safetySensorManagementCancelForeground(AppSkinColorSemantic.textPrimary),
  safetySensorManagementCard(AppSkinColorSemantic.surface),
  safetySensorManagementConfirm(AppSkinColorSemantic.brand),
  safetySensorManagementDelete(AppSkinColorSemantic.danger),
  safetySensorManagementDialogScrim(AppSkinColorSemantic.scrim),
  safetySensorManagementDialogSurface(AppSkinColorSemantic.surface),
  safetySensorManagementIcon(AppSkinColorSemantic.textSecondary),
  safetySensorManagementWarning(AppSkinColorSemantic.warning),
  safetySensorMetricIcon(AppSkinColorSemantic.textSecondary),
  safetySensorMetricIconSurface(AppSkinColorSemantic.surfaceMuted),
  safetySensorPairingBackground(AppSkinColorSemantic.pageBackground),
  safetySensorPairingFailure(AppSkinColorSemantic.danger),
  safetySensorPairingPlaceholderForeground(AppSkinColorSemantic.textMuted),
  safetySensorPairingPlaceholderSurface(AppSkinColorSemantic.surfaceMuted),
  safetySensorPairingPrimaryAction(AppSkinColorSemantic.brand),
  safetySensorPairingPrimaryActionForeground(AppSkinColorSemantic.onBrand),
  safetySensorPairingResultForeground(AppSkinColorSemantic.onBrand),
  safetySensorPairingSecondaryAction(AppSkinColorSemantic.surfaceMuted),
  safetySensorPairingSecondaryForeground(AppSkinColorSemantic.textPrimary),
  safetySensorPairingSuccess(AppSkinColorSemantic.success),
  safetySensorPlaceholder(AppSkinColorSemantic.surfaceMuted),
  safetySensorPositionMarkerShadow(AppSkinColorSemantic.shadow),
  scanRadarTint(AppSkinColorSemantic.keepOriginal),
  scannerBackground(AppSkinColorSemantic.keepOriginal),
  scannerChipBackground(AppSkinColorSemantic.keepOriginal),
  scannerOverlayScrim(AppSkinColorSemantic.keepOriginal),
  scannerWindowCorner(AppSkinColorSemantic.keepOriginal),
  scannerWindowFill(AppSkinColorSemantic.keepOriginal),
  sceneDeleteAction(AppSkinColorSemantic.danger),
  sceneDialogCancelButton(AppSkinColorSemantic.surfaceMuted),
  sceneDialogInputBorder(AppSkinColorSemantic.border),
  securityCenterBackground(AppSkinColorSemantic.pageBackground),
  securityCenterCard(AppSkinColorSemantic.surface),
  securityCenterDialogPrimaryAction(AppSkinColorSemantic.brand),
  securityCenterDialogScrim(AppSkinColorSemantic.scrim),
  securityCenterDialogSurface(AppSkinColorSemantic.surface),
  securityCenterError(AppSkinColorSemantic.danger),
  securityCenterLink(AppSkinColorSemantic.brand),
  securityCenterSensorIcon(AppSkinColorSemantic.textSecondary),
  securityCenterSensorSurface(AppSkinColorSemantic.surface),
  securityCenterSensorUnavailable(AppSkinColorSemantic.disabled),
  securityCenterShield(AppSkinColorSemantic.brand),
  securityCenterSuccess(AppSkinColorSemantic.success),
  securityCenterSuccess2B2D2C(AppSkinColorSemantic.textPrimary),
  securityCenterTag(AppSkinColorSemantic.surfaceMuted),
  securityReportAbnormal(AppSkinColorSemantic.danger),
  securityReportActionSurface(AppSkinColorSemantic.surfaceMuted),
  securityReportBottomBar(AppSkinColorSemantic.surface),
  securityReportBottomBarDivider(AppSkinColorSemantic.border),
  securityReportChartBar(AppSkinColorSemantic.warning),
  securityReportChartGrid(AppSkinColorSemantic.border),
  securityReportChartTooltip(AppSkinColorSemantic.surfaceMuted),
  securityReportDisconnected(AppSkinColorSemantic.warning),
  securityReportDivider(AppSkinColorSemantic.border),
  securityReportNormal(AppSkinColorSemantic.success),
  securityReportSegmentSelected(AppSkinColorSemantic.brand),
  securityReportSegmentTrack(AppSkinColorSemantic.surfaceMuted),
  securityReportTableBorder(AppSkinColorSemantic.border),
  securityReportWarning(AppSkinColorSemantic.warning),
  sharedDeviceMemberActionIcon(AppSkinColorSemantic.brand),
  sharedDeviceMemberAvatarPlaceholder(AppSkinColorSemantic.surfaceMuted),
  sharedDeviceMemberAvatarPlaceholderIcon(AppSkinColorSemantic.textMuted),
  sharedDeviceMemberCard(AppSkinColorSemantic.surface),
  sharedDevicesCard(AppSkinColorSemantic.surface),
  smartOpenerAddButton(AppSkinColorSemantic.brand),
  smartOpenerAddedDeviceCardSurface(AppSkinColorSemantic.surface),
  smartOpenerCardSurface(AppSkinColorSemantic.surface),
  smartOpenerDivider(AppSkinColorSemantic.border),
  smartOpenerProgressTrack(AppSkinColorSemantic.surfaceMuted),
  smartOpenerSecondaryButton(AppSkinColorSemantic.surfaceMuted),
  smartOpenerSuccess(AppSkinColorSemantic.success),
  smartOpenerWarning(AppSkinColorSemantic.warning),
  surfaceAccountHeaderFallback(AppSkinColorSemantic.surfaceMuted),
  surfaceAccountHeaderFallbackLight(AppSkinColorSemantic.surfaceMuted),
  surfaceAccountMenu(AppSkinColorSemantic.surface),
  surfaceHomeAvatar(AppSkinColorSemantic.surface),
  surfaceHomeIcon(AppSkinColorSemantic.surfaceMuted),
  surfaceItemSceneCard(AppSkinColorSemantic.surface),
  surfaceMuted(AppSkinColorSemantic.surfaceMuted),
  surfacePlantDarker(AppSkinColorSemantic.keepOriginal),
  surfaceSceneCard(AppSkinColorSemantic.surface),
  systemPermissionsCard(AppSkinColorSemantic.surface),
  systemPermissionsDenied(AppSkinColorSemantic.danger),
  systemPermissionsGranted(AppSkinColorSemantic.success),
  textAgreementLink(AppSkinColorSemantic.brand),
  textCodeResend(AppSkinColorSemantic.brand),
  textCodeResendDisabled(AppSkinColorSemantic.disabled),
  textHint(AppSkinColorSemantic.textMuted),
  textIcon(AppSkinColorSemantic.textSecondary),
  textMuted(AppSkinColorSemantic.textMuted),
  textPrimary(AppSkinColorSemantic.textPrimary),
  textSecondary(AppSkinColorSemantic.textSecondary),
  toastError(AppSkinColorSemantic.danger),
  toastForeground(AppSkinColorSemantic.onBrand),
  toastInfo(AppSkinColorSemantic.brand),
  toastSuccess(AppSkinColorSemantic.success),
  toggleSelected(AppSkinColorSemantic.switchActive),
  transmitterManagementActionSurface(AppSkinColorSemantic.surfaceMuted),
  transmitterManagementPrimaryAction(AppSkinColorSemantic.brand),
  transmitterManagementSheetInputBorder(AppSkinColorSemantic.border),
  upgradeCheckBackground(AppSkinColorSemantic.pageBackground),
  upgradeCheckCard(AppSkinColorSemantic.surface),
  upgradeCheckCheckboxBorder(AppSkinColorSemantic.border),
  upgradeCheckCheckboxSelected(AppSkinColorSemantic.brand),
  upgradeCheckDialogScrim(AppSkinColorSemantic.scrim),
  upgradeCheckDialogSurface(AppSkinColorSemantic.surface),
  upgradeCheckDisabledAction(AppSkinColorSemantic.disabled),
  upgradeCheckDivider(AppSkinColorSemantic.border),
  upgradeCheckProgress(AppSkinColorSemantic.brand),
  upgradeCheckProgressTrack(AppSkinColorSemantic.surfaceMuted);

  const AppSkinColorRole(this.semantic);

  final AppSkinColorSemantic semantic;
}

@immutable
class AppSkinTokens extends ThemeExtension<AppSkinTokens> {
  const AppSkinTokens({
    required this.id,
    this.transition,
    required this.pageBackground,
    required this.backgroundGradient,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.brand,
    required this.onBrand,
    required this.accent,
    required this.success,
    required this.disabled,
    required this.danger,
    required this.warning,
    required this.scrim,
    required this.shadow,
    required this.systemBarBackground,
    required this.commandAction,
    required this.commandActionForeground,
    required this.commandActionPressedOverlay,
    required this.switchActive,
    required this.switchInactive,
    required this.switchThumb,
    required this.navigationBackground,
    required this.navigationForeground,
    required this.navigationSelected,
    required this.navigationUnselected,
  });

  final AppSkinId id;
  final AppSkinTransition? transition;
  final Color pageBackground;
  final List<Color> backgroundGradient;
  final Color surface;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color brand;
  final Color onBrand;
  final Color accent;
  final Color success;
  final Color disabled;
  final Color danger;
  final Color warning;
  final Color scrim;
  final Color shadow;
  final Color systemBarBackground;
  final Color commandAction;
  final Color commandActionForeground;
  final Color commandActionPressedOverlay;
  final Color switchActive;
  final Color switchInactive;
  final Color switchThumb;
  final Color navigationBackground;
  final Color navigationForeground;
  final Color navigationSelected;
  final Color navigationUnselected;

  LinearGradient? accountHeaderGradient({
    required AlignmentGeometry begin,
    required AlignmentGeometry end,
    required List<Color> colors,
  }) => id == AppSkinId.minimalist
      ? LinearGradient(begin: begin, end: end, colors: colors)
      : null;

  Brightness get brightness =>
      id == AppSkinId.dark ? Brightness.dark : Brightness.light;

  LinearGradient? get deviceControlBackgroundGradient =>
      id == AppSkinId.technologyWind
      ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: backgroundGradient,
          stops: const [0, 0.35, 1],
        )
      : null;

  SystemUiOverlayStyle get systemOverlayStyle => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: brightness,
    statusBarIconBrightness: brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark,
    systemNavigationBarColor: systemBarBackground,
    systemNavigationBarIconBrightness: brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark,
  );

  SystemUiOverlayStyle systemOverlayStyleForForeground(Color foreground) {
    final lightIcons =
        ThemeData.estimateBrightnessForColor(foreground) == Brightness.light;
    return systemOverlayStyle.copyWith(
      statusBarIconBrightness: lightIcons ? Brightness.light : Brightness.dark,
      statusBarBrightness: lightIcons ? Brightness.dark : Brightness.light,
    );
  }

  Color resolve(AppSkinColorRole role, {required Color fallback}) =>
      resolveSemantic(role.semantic, fallback: fallback);

  Color resolveSemantic(
    AppSkinColorSemantic semantic, {
    required Color fallback,
  }) {
    final blend = transition;
    if (blend != null) {
      return Color.lerp(
        blend.from.resolveSemantic(semantic, fallback: fallback),
        blend.to.resolveSemantic(semantic, fallback: fallback),
        blend.progress,
      )!;
    }
    if (id == AppSkinId.minimalist) return fallback;
    return switch (semantic) {
      AppSkinColorSemantic.keepOriginal => fallback,
      AppSkinColorSemantic.pageBackground => pageBackground,
      AppSkinColorSemantic.surface => surface,
      AppSkinColorSemantic.surfaceMuted => surfaceMuted,
      AppSkinColorSemantic.textPrimary => textPrimary,
      AppSkinColorSemantic.textSecondary => textSecondary,
      AppSkinColorSemantic.textMuted => textMuted,
      AppSkinColorSemantic.border => border,
      AppSkinColorSemantic.brand => brand,
      AppSkinColorSemantic.brandMuted => brand.withValues(alpha: 0.12),
      AppSkinColorSemantic.onBrand => onBrand,
      AppSkinColorSemantic.navigationForeground => navigationForeground,
      AppSkinColorSemantic.commandAction => commandAction,
      AppSkinColorSemantic.commandActionForeground => commandActionForeground,
      AppSkinColorSemantic.switchActive => switchActive,
      AppSkinColorSemantic.accent => accent,
      AppSkinColorSemantic.success => success,
      AppSkinColorSemantic.successMuted => success.withValues(alpha: 0.14),
      AppSkinColorSemantic.disabled => disabled,
      AppSkinColorSemantic.danger => danger,
      AppSkinColorSemantic.dangerMuted => danger.withValues(alpha: 0.12),
      AppSkinColorSemantic.warning => warning,
      AppSkinColorSemantic.scrim => scrim,
      AppSkinColorSemantic.shadow => shadow,
    };
  }

  @override
  AppSkinTokens copyWith({
    Color? pageBackground,
    List<Color>? backgroundGradient,
    Color? surface,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? brand,
    Color? onBrand,
    Color? accent,
    Color? success,
    Color? disabled,
    Color? danger,
    Color? warning,
    Color? scrim,
    Color? shadow,
    Color? systemBarBackground,
    Color? commandAction,
    Color? commandActionForeground,
    Color? commandActionPressedOverlay,
    Color? switchActive,
    Color? switchInactive,
    Color? switchThumb,
    Color? navigationBackground,
    Color? navigationForeground,
    Color? navigationSelected,
    Color? navigationUnselected,
  }) {
    return AppSkinTokens(
      id: id,
      transition: transition,
      pageBackground: pageBackground ?? this.pageBackground,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      disabled: disabled ?? this.disabled,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      scrim: scrim ?? this.scrim,
      shadow: shadow ?? this.shadow,
      systemBarBackground: systemBarBackground ?? this.systemBarBackground,
      commandAction: commandAction ?? this.commandAction,
      commandActionForeground:
          commandActionForeground ?? this.commandActionForeground,
      commandActionPressedOverlay:
          commandActionPressedOverlay ?? this.commandActionPressedOverlay,
      switchActive: switchActive ?? this.switchActive,
      switchInactive: switchInactive ?? this.switchInactive,
      switchThumb: switchThumb ?? this.switchThumb,
      navigationBackground: navigationBackground ?? this.navigationBackground,
      navigationForeground: navigationForeground ?? this.navigationForeground,
      navigationSelected: navigationSelected ?? this.navigationSelected,
      navigationUnselected: navigationUnselected ?? this.navigationUnselected,
    );
  }

  @override
  AppSkinTokens lerp(covariant AppSkinTokens? other, double t) {
    if (other == null || t == 0) return this;
    if (t == 1) return other;
    Color blend(Color first, Color second) =>
        Color.lerp(first, second, t) ?? second;
    return AppSkinTokens(
      id: t < 0.5 ? id : other.id,
      transition: AppSkinTransition(from: this, to: other, progress: t),
      pageBackground: blend(pageBackground, other.pageBackground),
      backgroundGradient: t < 0.5
          ? backgroundGradient
          : other.backgroundGradient,
      surface: blend(surface, other.surface),
      surfaceMuted: blend(surfaceMuted, other.surfaceMuted),
      textPrimary: blend(textPrimary, other.textPrimary),
      textSecondary: blend(textSecondary, other.textSecondary),
      textMuted: blend(textMuted, other.textMuted),
      border: blend(border, other.border),
      brand: blend(brand, other.brand),
      onBrand: blend(onBrand, other.onBrand),
      accent: blend(accent, other.accent),
      success: blend(success, other.success),
      disabled: blend(disabled, other.disabled),
      danger: blend(danger, other.danger),
      warning: blend(warning, other.warning),
      scrim: blend(scrim, other.scrim),
      shadow: blend(shadow, other.shadow),
      systemBarBackground: blend(
        systemBarBackground,
        other.systemBarBackground,
      ),
      commandAction: blend(commandAction, other.commandAction),
      commandActionForeground: blend(
        commandActionForeground,
        other.commandActionForeground,
      ),
      commandActionPressedOverlay: blend(
        commandActionPressedOverlay,
        other.commandActionPressedOverlay,
      ),
      switchActive: blend(switchActive, other.switchActive),
      switchInactive: blend(switchInactive, other.switchInactive),
      switchThumb: blend(switchThumb, other.switchThumb),
      navigationBackground: blend(
        navigationBackground,
        other.navigationBackground,
      ),
      navigationForeground: blend(
        navigationForeground,
        other.navigationForeground,
      ),
      navigationSelected: blend(navigationSelected, other.navigationSelected),
      navigationUnselected: blend(
        navigationUnselected,
        other.navigationUnselected,
      ),
    );
  }
}

/// Retains each endpoint's semantic colors, including distinct legacy colors.
@immutable
class AppSkinTransition {
  const AppSkinTransition({
    required this.from,
    required this.to,
    required this.progress,
  });
  final AppSkinTokens from;
  final AppSkinTokens to;
  final double progress;
}

class AppSkinCatalog {
  const AppSkinCatalog._();

  static const dark = darkSkin;
  static const minimalist = minimalistSkin;
  static const technologyWind = technologyWindSkin;
  static AppSkinTokens forId(AppSkinId id) => switch (id) {
    AppSkinId.dark => dark,
    AppSkinId.minimalist => minimalist,
    AppSkinId.technologyWind => technologyWind,
  };
}

/// Centralizes logical asset names so final exports can replace placeholders
/// without changing feature widgets.
class AppSkinAssets {
  const AppSkinAssets(this.skinId);

  final AppSkinId skinId;

  /// Door frames, avatars and provider branding are shared original artwork.
  /// All other app cut assets have an explicit slot in each skin package.
  String resolve(String original) {
    if (skinId == AppSkinId.minimalist ||
        original.contains('/skins/') ||
        original.contains('door_') &&
            (original.contains('garage') ||
                original.contains('frame') ||
                original.contains('hero')) ||
        original.contains('/door_frames/') ||
        original.contains('/avatars/') ||
        original.contains('avatar') ||
        original.contains('google') ||
        original.contains('facebook') ||
        original.contains('provider_meta_mark') ||
        original.contains('apple') ||
        original.contains('/animations/')) {
      return original;
    }
    final match = RegExp(
      r'^assets/(images|icons)/(.+)\.(png|webp|jpg|jpeg)$',
    ).firstMatch(original);
    if (match == null) return original;
    return 'assets/${match[1]}/skins/${skinId.storageValue}/${match[2]}_placeholder.${match[3]}';
  }

  String get themePreview =>
      'assets/images/skins/${skinId.storageValue}/appearance/'
      'skin_${skinId.storageValue}_theme_preview_placeholder.png';

  String get themeDetail =>
      'assets/images/skins/${skinId.storageValue}/appearance/'
      'skin_${skinId.storageValue}_theme_detail_placeholder.png';
}

extension AppSkinBuildContext on BuildContext {
  AppSkinTokens get skin =>
      Theme.of(this).extension<AppSkinTokens>() ?? AppSkinCatalog.minimalist;
}
