import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../../domain/entities/account_profile.dart';
import 'account_details_page.dart';
import '../../../notification/presentation/pages/notification_list_page.dart';

class AccountProfileAssetPaths {
  const AccountProfileAssetPaths._();

  static const headerBackground =
      'assets/images/account/account_profile_header_bg.png';
  static const avatarPlaceholder =
      'assets/icons/home/home_avatar_placeholder.png';
}

class AccountProfileKeys {
  const AccountProfileKeys._();

  static const avatarButton = ValueKey('account-profile-avatar-button');
}

class AccountProfilePage extends ConsumerWidget {
  const AccountProfilePage({super.key});

  static const routeName = 'account-profile';
  static const routePath = '/account/profile';

  static final _fallbackRegisteredAt = DateTime(2023, 5, 4, 14, 34, 48);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref
        .watch(accountControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

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
                maxHeight: constraints.maxHeight,
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
    required this.maxHeight,
  });

  final AccountProfile? profile;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final registeredAt =
        profile?.registeredAt ?? AccountProfilePage._fallbackRegisteredAt;
    final menuItems = [
      _AccountMenuItem(
        label: l10n.accountSharedDevices,
        trailingText: '12',
        icon: Icons.grid_view_rounded,
      ),
      _AccountMenuItem(
        label: l10n.accountReceivingDevices,
        trailingText: '2',
        icon: Icons.dashboard_customize_outlined,
      ),
      _AccountMenuItem(
        label: l10n.accountManageDevices,
        trailingText: '2',
        icon: Icons.subject_rounded,
      ),
      _AccountMenuItem(
        label: l10n.accountMessage,
        icon: Icons.inbox_rounded,
        onTap: () => context.pushNamed(NotificationListPage.routeName),
      ),
      _AccountMenuItem(
        label: l10n.accountRegion,
        trailingText: profile?.country ?? l10n.accountDefaultRegion,
        icon: Icons.location_on_outlined,
      ),
      _AccountMenuItem(
        label: l10n.accountLanguage,
        trailingText: l10n.accountDefaultLanguage,
        icon: Icons.language_rounded,
      ),
      _AccountMenuItem(
        label: l10n.accountSystemPermissions,
        icon: Icons.playlist_add_check_rounded,
      ),
      _AccountMenuItem(
        label: l10n.accountCheckForUpdates,
        trailingText: '2',
        icon: Icons.published_with_changes_rounded,
      ),
      _AccountMenuItem(
        label: l10n.accountAbout,
        icon: Icons.info_outline_rounded,
      ),
    ];

    return SafeArea(
      top: false,
      child: SizedBox(
        height: maxHeight,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _AccountHeader(
              email: profile?.email ?? l10n.accountFallbackEmail,
              registeredAt: _formatTimestamp(registeredAt),
            ),
            _AccountMenu(items: menuItems),
            const SizedBox(height: 40),
          ],
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
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.email, required this.registeredAt});

  static const _headerImageWidth = 1125.0;
  static const _headerImageHeight = 600.0;

  final String email;
  final String registeredAt;

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
                right: 20,
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
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextTokens.accountProfileEmail(textTheme),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            registeredAt,
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
            if (index == 4 || index == 7)
              const Divider(height: 36, thickness: 36, color: Colors.white),
            _AccountMenuRow(item: items[index]),
          ],
        ],
      ),
    );
  }
}

class _AccountMenuItem {
  const _AccountMenuItem({
    required this.label,
    required this.icon,
    this.trailingText,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final String? trailingText;
  final VoidCallback? onTap;
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
        onTap:
            item.onTap ??
            () {
              AppToast.info(context, l10n.accountMenuComingSoon(item.label));
            },
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 38),
              SizedBox(
                width: 20,
                child: Icon(
                  item.icon,
                  color: AppColors.iconAccountMenu,
                  size: 20,
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
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
