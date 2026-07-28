import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../../domain/entities/app_locale_preference.dart';
import '../../domain/entities/account_profile.dart';
import '../../domain/entities/account_overview.dart';
import '../../../auth/application/providers.dart';
import '../../../auth/presentation/pages/welcome_page.dart';
import '../../../home/application/providers.dart';
import 'account_details_page.dart';
import 'check_upgraded_version_page.dart';
import 'hardware_diagnostics_page.dart';
import 'manage_devices_page.dart';
import 'receiving_devices_page.dart';
import 'region_page.dart';
import 'shared_devices_page.dart';
import 'system_permissions_page.dart';

class AccountProfileAssetPaths {
  const AccountProfileAssetPaths._();

  static const headerBackground =
      'assets/images/account/account_profile_header_bg.png';
  static const avatarPlaceholder =
      'assets/icons/home/home_avatar_placeholder.png';
  static const menuSharedDevices =
      'assets/icons/account/account_profile_menu_shared_devices.png';
  static const menuReceivingDevices =
      'assets/icons/account/account_profile_menu_receiving_devices.png';
  static const menuManageDevices =
      'assets/icons/account/account_profile_menu_manage_devices.png';
  static const menuAfterSalesService =
      'assets/icons/account/account_profile_menu_after_sales_service.png';
  static const menuRegion =
      'assets/icons/account/account_profile_menu_region.png';
  static const menuLanguage =
      'assets/icons/account/account_profile_menu_language.png';
  static const menuSystemPermissions =
      'assets/icons/account/account_profile_menu_system_permissions.png';
  static const menuManualGuide =
      'assets/icons/account/account_profile_menu_manual_guide.png';
  static const menuCheckForUpdates =
      'assets/icons/account/account_profile_menu_check_for_updates.png';
  static const menuAbout =
      'assets/icons/account/account_profile_menu_about.png';
}

class AccountProfileKeys {
  const AccountProfileKeys._();

  static const avatarButton = ValueKey('account-profile-avatar-button');
  static const sharedDevicesMenuItem = ValueKey(
    'account-profile-shared-devices-menu-item',
  );
  static const receivingDevicesMenuItem = ValueKey(
    'account-profile-receiving-devices-menu-item',
  );
  static const languageMenuItem = ValueKey(
    'account-profile-language-menu-item',
  );
  static const languageDialog = ValueKey('account-language-dialog');
  static const languagePicker = ValueKey('account-language-picker');
  static const languageCancelButton = ValueKey(
    'account-language-cancel-button',
  );
  static const languageConfirmButton = ValueKey(
    'account-language-confirm-button',
  );
  static const regionMenuItem = ValueKey('account-profile-region-menu-item');
  static const manageDevicesMenuItem = ValueKey(
    'account-profile-manage-devices-menu-item',
  );
  static const systemPermissionsMenuItem = ValueKey(
    'account-profile-system-permissions-menu-item',
  );
  static const checkForUpdatesMenuItem = ValueKey(
    'account-profile-check-for-updates-menu-item',
  );
  static const afterSalesMenuItem = ValueKey(
    'account-profile-after-sales-menu-item',
  );
  static const manualGuideMenuItem = ValueKey(
    'account-profile-manual-guide-menu-item',
  );
  static const logoutButton = ValueKey('account-profile-logout-button');
}

class AccountProfilePage extends ConsumerStatefulWidget {
  const AccountProfilePage({super.key});

  static const routeName = 'account-profile';
  static const routePath = '/account/profile';

  @override
  ConsumerState<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends ConsumerState<AccountProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(accountOverviewAutoRefreshProvider)) {
        _refreshOverview();
      }
    });
  }

  Future<void> _refreshOverview() async {
    try {
      await ref.read(accountOverviewControllerProvider.notifier).refresh();
    } on Object {
      if (mounted) {
        AppToast.error(
          context,
          AppLocalizations.of(context).accountOverviewRefreshFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref
        .watch(accountControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final overview = ref
        .watch(accountOverviewControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final localePreference = ref
        .watch(appLocaleControllerProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => AppLocalePreference.english,
        );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const FlinxNavigationBar(
        title: '',
        showBottomDivider: false,
        isTransparent: true,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.accountProfileBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: _AccountProfileContent(
                profile: profile,
                overview: overview,
                localePreference: localePreference,
                maxHeight: constraints.maxHeight,
                onRefresh: _refreshOverview,
                onLocaleConfirmed: (locale) => ref
                    .read(appLocaleControllerProvider.notifier)
                    .selectLocale(locale),
                onLogout: () async {
                  final authSessionController = ref.read(
                    activeAuthSessionProvider.notifier,
                  );
                  final accountController = ref.read(
                    accountControllerProvider.notifier,
                  );

                  ref.invalidate(homeScenesProvider);
                  ref.invalidate(homeDevicesProvider);
                  ref.invalidate(cachedAccountProfileProvider);
                  ref.invalidate(authSessionProvider);

                  await accountController.clearAccount();
                  authSessionController.clear();
                  if (context.mounted) {
                    context.go(WelcomePage.routePath);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AccountProfileContent extends StatelessWidget {
  const _AccountProfileContent({
    required this.profile,
    required this.overview,
    required this.localePreference,
    required this.maxHeight,
    required this.onRefresh,
    required this.onLocaleConfirmed,
    required this.onLogout,
  });

  final AccountProfile? profile;
  final AccountOverview? overview;
  final AppLocalePreference localePreference;
  final double maxHeight;
  final Future<void> Function() onRefresh;
  final Future<void> Function(AppLocalePreference locale) onLocaleConfirmed;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nickname = overview?.nickname.isNotEmpty == true
        ? overview!.nickname
        : profile?.nickname ?? l10n.accountFallbackEmail;
    final refreshedAt = overview?.refreshedAt;
    final menuItems = [
      _AccountMenuItem(
        label: l10n.accountSharedDevices,
        trailingText: overview?.sharedDoorCount.toString() ?? '0',
        iconAssetPath: AccountProfileAssetPaths.menuSharedDevices,
        onTap: () => context.pushNamed(SharedDevicesPage.routeName),
        key: AccountProfileKeys.sharedDevicesMenuItem,
      ),
      _AccountMenuItem(
        label: l10n.accountReceivingDevices,
        trailingText: overview?.receivingDoorCount.toString() ?? '0',
        iconAssetPath: AccountProfileAssetPaths.menuReceivingDevices,
        onTap: () => context.pushNamed(ReceivingDevicesPage.routeName),
        key: AccountProfileKeys.receivingDevicesMenuItem,
      ),
      _AccountMenuItem(
        label: l10n.accountManageDevices,
        trailingText: overview?.ownedDoorCount.toString() ?? '0',
        iconAssetPath: AccountProfileAssetPaths.menuManageDevices,
        onTap: () => context.pushNamed(ManageDevicesPage.routeName),
        key: AccountProfileKeys.manageDevicesMenuItem,
      ),
      _AccountMenuItem(
        label: l10n.accountAfterSalesService,
        iconAssetPath: AccountProfileAssetPaths.menuAfterSalesService,
        key: AccountProfileKeys.afterSalesMenuItem,
      ),
      _AccountMenuItem(
        label: l10n.accountRegion,
        trailingText: profile?.country ?? l10n.accountDefaultRegion,
        iconAssetPath: AccountProfileAssetPaths.menuRegion,
        onTap: () => context.pushNamed(RegionPage.routeName),
        key: AccountProfileKeys.regionMenuItem,
      ),
      _AccountMenuItem(
        label: l10n.accountLanguage,
        trailingText: _languageLabel(l10n, localePreference),
        iconAssetPath: AccountProfileAssetPaths.menuLanguage,
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          barrierColor: AppColors.accountLanguageDialogScrim,
          backgroundColor: Colors.transparent,
          builder: (context) => _LanguageDialog(
            initialLocale: localePreference,
            onConfirm: onLocaleConfirmed,
          ),
        ),
        key: AccountProfileKeys.languageMenuItem,
      ),
      _AccountMenuItem(
        label: l10n.accountSystemPermissions,
        iconAssetPath: AccountProfileAssetPaths.menuSystemPermissions,
        key: AccountProfileKeys.systemPermissionsMenuItem,
        onTap: () => context.pushNamed(SystemPermissionsPage.routeName),
      ),
      _AccountMenuItem(
        label: l10n.accountManualGuide,
        iconAssetPath: AccountProfileAssetPaths.menuManualGuide,
        key: AccountProfileKeys.manualGuideMenuItem,
      ),
      _AccountMenuItem(
        label: l10n.accountCheckForUpdates,
        iconAssetPath: AccountProfileAssetPaths.menuCheckForUpdates,
        key: AccountProfileKeys.checkForUpdatesMenuItem,
        onTap: () => context.pushNamed(CheckUpgradedVersionPage.routeName),
      ),
      _AccountMenuItem(
        label: l10n.accountAbout,
        iconAssetPath: AccountProfileAssetPaths.menuAbout,
        onTap: () => context.pushNamed(HardwareDiagnosticsPage.routeName),
      ),
    ];

    return SafeArea(
      top: false,
      child: SizedBox(
        height: maxHeight,
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _AccountHeader(
                nickname: nickname,
                refreshedAt: refreshedAt == null
                    ? l10n.accountOverviewRefreshTimeUnavailable
                    : _formatTimestamp(refreshedAt),
              ),
              _AccountMenu(items: menuItems),
              _AccountProfileLogoutButton(onPressed: onLogout),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} '
        '${twoDigits(value.hour)}:${twoDigits(value.minute)}:'
        '${twoDigits(value.second)}';
  }

  String _languageLabel(AppLocalizations l10n, AppLocalePreference locale) {
    return switch (locale) {
      AppLocalePreference.english => l10n.accountLanguageOptionEnglish,
      AppLocalePreference.simplifiedChinese =>
        l10n.accountLanguageOptionSimplifiedChinese,
    };
  }
}

class _LanguageDialog extends StatefulWidget {
  const _LanguageDialog({required this.initialLocale, required this.onConfirm});

  final AppLocalePreference initialLocale;
  final Future<void> Function(AppLocalePreference locale) onConfirm;

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  late AppLocalePreference _selectedLocale;
  late final FixedExtentScrollController _languagePickerController;
  var _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _selectedLocale = widget.initialLocale;
    final selectedLocaleIndex = AppLocalePreference.values.indexOf(
      _selectedLocale,
    );
    _languagePickerController = FixedExtentScrollController(
      initialItem: selectedLocaleIndex,
    );
  }

  @override
  void dispose() {
    _languagePickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final languages = [
      _LanguageOptionData(
        label: l10n.accountLanguageOptionEnglish,
        locale: AppLocalePreference.english,
      ),
      _LanguageOptionData(
        label: l10n.accountLanguageOptionSimplifiedChinese,
        locale: AppLocalePreference.simplifiedChinese,
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Material(
          key: AccountProfileKeys.languageDialog,
          color: AppColors.accountLanguageDialogSurface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(AppShapeTokens.accountLanguageDialogRadius),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 522),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.accountLanguageDialogTitle,
                    style: AppTextTokens.accountLanguageDialogTitle(textTheme),
                  ),
                  const SizedBox(height: 18),
                  _LanguagePicker(
                    controller: _languagePickerController,
                    languages: languages,
                    selectedLocale: _selectedLocale,
                    onScrollEnd: () => _selectCenteredLocale(languages),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: _LanguageDialogButton(
                          key: AccountProfileKeys.languageCancelButton,
                          label: l10n.accountLanguageCancelAction,
                          isPrimary: false,
                          onPressed: _isConfirming
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: _LanguageDialogButton(
                          key: AccountProfileKeys.languageConfirmButton,
                          label: l10n.accountLanguageConfirmAction,
                          isPrimary: true,
                          onPressed: _isConfirming ? null : () => _confirm(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _isConfirming = true);
    await widget.onConfirm(_selectedLocale);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _selectCenteredLocale(List<_LanguageOptionData> languages) {
    final selectedIndex = _languagePickerController.selectedItem;
    final locale = languages[selectedIndex].locale;
    if (locale != _selectedLocale) {
      setState(() => _selectedLocale = locale);
    }
  }
}

class _LanguageOptionData {
  const _LanguageOptionData({required this.label, required this.locale});

  final String label;
  final AppLocalePreference locale;
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({
    required this.controller,
    required this.languages,
    required this.selectedLocale,
    required this.onScrollEnd,
  });

  final FixedExtentScrollController controller;
  final List<_LanguageOptionData> languages;
  final AppLocalePreference selectedLocale;
  final VoidCallback onScrollEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacingTokens.accountLanguageDialogWheelHeight,
      child: Stack(
        children: [
          NotificationListener<ScrollEndNotification>(
            onNotification: (notification) {
              if (notification.depth == 0) {
                onScrollEnd();
              }
              return false;
            },
            child: ListWheelScrollView.useDelegate(
              key: AccountProfileKeys.languagePicker,
              controller: controller,
              itemExtent: AppSpacingTokens.accountLanguageDialogWheelItemExtent,
              physics: const FixedExtentScrollPhysics(),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: languages.length,
                builder: (context, index) {
                  final language = languages[index];
                  return Semantics(
                    selected: language.locale == selectedLocale,
                    label: language.label,
                    child: Center(
                      child: Text(
                        language.label,
                        style: AppTextTokens.accountLanguageDialogOption(
                          Theme.of(context).textTheme,
                          isSelected: language.locale == selectedLocale,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                height: AppSpacingTokens.accountLanguageDialogWheelItemExtent,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.accountLanguageDialogDivider,
                      width: AppSpacingTokens
                          .accountLanguageDialogSelectionLineThickness,
                    ),
                    bottom: BorderSide(
                      color: AppColors.accountLanguageDialogDivider,
                      width: AppSpacingTokens
                          .accountLanguageDialogSelectionLineThickness,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageDialogButton extends StatelessWidget {
  const _LanguageDialogButton({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isPrimary
              ? AppColors.brandPrimaryLight
              : AppColors.accountLanguageDialogCancelSurface,
          foregroundColor: isPrimary ? Colors.white : AppColors.textPrimary,
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: AppTextTokens.accountLanguageDialogAction(
            Theme.of(context).textTheme,
            isPrimary: isPrimary,
          ),
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.nickname, required this.refreshedAt});

  static const _headerImageWidth = 1125.0;
  static const _headerImageHeight = 600.0;

  final String nickname;
  final String refreshedAt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final headerHeight =
            constraints.maxWidth * _headerImageHeight / _headerImageWidth;

        return SizedBox(
          height: headerHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                AccountProfileAssetPaths.headerBackground,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const _HeaderFallbackArt();
                },
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 18,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _AccountAvatar(
                      size: 66,
                      onTap: () =>
                          context.pushNamed(AccountDetailsPage.routeName),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextTokens.accountProfileEmail(textTheme),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            refreshedAt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextTokens.accountProfileRegisteredAt(
                              textTheme,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderFallbackArt extends StatelessWidget {
  const _HeaderFallbackArt();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceAccountHeaderFallback,
            AppColors.surfaceAccountHeaderFallbackLight,
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Icon(
          Icons.garage_outlined,
          color: AppColors.backgroundPrimary.withValues(alpha: 0.18),
          size: 160,
        ),
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.size, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: AppLocalizations.of(context).accountDetailsHeadPortrait,
      child: GestureDetector(
        key: AccountProfileKeys.avatarButton,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.backgroundPrimary.withValues(alpha: 0.46),
              width: 1,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              AccountProfileAssetPaths.avatarPlaceholder,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.surfaceHomeAvatar,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.person,
                    color: AppColors.iconHomePlaceholder,
                    size: size * 0.62,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.items});

  final List<_AccountMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAccountMenu,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _AccountMenuRow(item: items[index]),
            if (index < items.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 28,
                endIndent: 28,
                color: AppColors.borderAccountDivider,
              ),
          ],
        ],
      ),
    );
  }
}

class _AccountMenuItem {
  const _AccountMenuItem({
    required this.label,
    required this.iconAssetPath,
    this.trailingText,
    this.onTap,
    this.key,
  });

  final String label;
  final String iconAssetPath;
  final String? trailingText;
  final VoidCallback? onTap;
  final Key? key;
}

class _AccountMenuRow extends StatelessWidget {
  const _AccountMenuRow({required this.item});

  final _AccountMenuItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: item.label,
      child: InkWell(
        key: item.key,
        onTap:
            item.onTap ??
            () {
              AppToast.info(context, l10n.accountMenuComingSoon(item.label));
            },
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              const SizedBox(width: 28),
              SizedBox(
                width: 20,
                height: 20,
                child: Image.asset(
                  item.iconAssetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.expand(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.accountMenuLabel(textTheme),
                ),
              ),
              if (item.trailingText case final trailingText?) ...[
                Text(
                  trailingText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.accountMenuValue(textTheme),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.iconAccountChevron,
                size: 24,
              ),
              const SizedBox(width: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountProfileLogoutButton extends StatelessWidget {
  const _AccountProfileLogoutButton({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton(
          key: AccountProfileKeys.logoutButton,
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accountProfileLogoutSurface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(AppShapeTokens.accountProfileLogoutRadius),
              ),
            ),
          ),
          child: Text(
            AppLocalizations.of(context).accountDetailsLogout,
            style: AppTextTokens.accountProfileLogout(
              Theme.of(context).textTheme,
            ),
          ),
        ),
      ),
    );
  }
}
