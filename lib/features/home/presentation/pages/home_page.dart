import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../add_device/presentation/pages/add_new_doors_page.dart';
import '../../../add_device/presentation/pages/add_device_page.dart';
import '../../../../features/hardware_debug/presentation/pages/ble_debug_page.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../application/providers.dart';
import '../widgets/scene_name_dialog.dart';
import 'scene_page.dart';

class HomeAssetPaths {
  const HomeAssetPaths._();

  static const avatarPlaceholder =
      'assets/icons/home/home_avatar_placeholder.png';
  static const emptyDoorsPlaceholder =
      'assets/icons/home/home_empty_doors_placeholder.png';
  static const addScenePlaceholder =
      'assets/icons/home/home_add_scene_placeholder.png';
  static const addDoorPlaceholder =
      'assets/icons/home/home_add_door_placeholder.png';
  static const smartDevicePlaceholder =
      'assets/icons/home/home_smart_device_placeholder.png';
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  static const routeName = 'home';
  static const routePath = '/home';

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  var _isAddMenuVisible = false;

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(homeDevicesProvider);
    final homeDevices = devices.when(
      data: (items) => items,
      loading: () => const <DeviceSummary>[],
      error: (error, stackTrace) => const <DeviceSummary>[],
    );
    final homes = <_HomeGroup>[
      _HomeGroup(label: 'Home', devices: homeDevices),
      const _HomeGroup(label: 'home2', devices: <DeviceSummary>[]),
      const _HomeGroup(label: 'home3', devices: <DeviceSummary>[]),
    ];

    return DefaultTabController(
      length: homes.length,
      child: Scaffold(
        backgroundColor: AppColors.homeBackground,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HomeHeader(
                    onAddPressed: () {
                      setState(() {
                        _isAddMenuVisible = true;
                      });
                    },
                  ),
                  _HomeTabs(homes: homes),
                  const Divider(height: 1, color: AppColors.borderHomeDivider),
                  Expanded(
                    child: devices.when(
                      data: (_) => TabBarView(
                        children: [
                          for (final home in homes)
                            _HomeDevicePanel(home: home),
                        ],
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) => const _HomeErrorState(),
                    ),
                  ),
                ],
              ),
            ),
            if (_isAddMenuVisible)
              _HomeAddMenuOverlay(
                onDismissed: () {
                  setState(() {
                    _isAddMenuVisible = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeAddMenuOverlay extends StatelessWidget {
  const _HomeAddMenuOverlay({required this.onDismissed});

  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismissed,
            child: Container(color: AppColors.overlaySoft),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 62, right: 30),
                child: _HomeAddMenu(
                  items: [
                    _HomeAddMenuItemData(
                      label: l10n.homeAddSceneMenuAction,
                      assetPath: HomeAssetPaths.addScenePlaceholder,
                      fallbackIcon: Icons.view_in_ar_outlined,
                      onPressed: () {
                        onDismissed();
                        showSceneNameDialog(context);
                      },
                    ),
                    _HomeAddMenuItemData(
                      label: l10n.homeAddDoorMenuAction,
                      assetPath: HomeAssetPaths.addDoorPlaceholder,
                      fallbackIcon: Icons.dns_outlined,
                      onPressed: () {
                        onDismissed();
                        context.push(AddNewDoorsPage.routePath);
                      },
                    ),
                    _HomeAddMenuItemData(
                      label: l10n.homeSmartDeviceMenuAction,
                      assetPath: HomeAssetPaths.smartDevicePlaceholder,
                      fallbackIcon: Icons.wifi_tethering_outlined,
                      onPressed: onDismissed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAddMenu extends StatelessWidget {
  const _HomeAddMenu({required this.items});

  final List<_HomeAddMenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundPrimary,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 160,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _HomeAddMenuItem(item: items[index]),
              if (index != items.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: Divider(height: 1, color: AppColors.borderHomeDivider),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeAddMenuItemData {
  const _HomeAddMenuItemData({
    required this.label,
    required this.assetPath,
    required this.fallbackIcon,
    required this.onPressed,
  });

  final String label;
  final String assetPath;
  final IconData fallbackIcon;
  final VoidCallback onPressed;
}

class _HomeAddMenuItem extends StatelessWidget {
  const _HomeAddMenuItem({required this.item});

  final _HomeAddMenuItemData item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onPressed,
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            const SizedBox(width: 22),
            _HomeAddMenuIcon(
              assetPath: item.assetPath,
              fallbackIcon: item.fallbackIcon,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: AppTextTokens.homeAddMenuItem(
                  Theme.of(context).textTheme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeAddMenuIcon extends StatelessWidget {
  const _HomeAddMenuIcon({required this.assetPath, required this.fallbackIcon});

  final String assetPath;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: 20,
      height: 20,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, color: AppColors.iconHomeAction, size: 20);
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarPlaceholder(
                assetPath: HomeAssetPaths.avatarPlaceholder,
                size: 58,
              ),
              const Spacer(),
              _HeaderIconButton(
                tooltip: l10n.homeMenuTooltip,
                icon: Icons.menu_rounded,
                onPressed: () => context.push(BleDebugPage.routePath),
              ),
              _HeaderIconButton(
                tooltip: l10n.sceneHomeShortcutTooltip,
                icon: Icons.edit_outlined,
                onPressed: () => context.push(ScenePage.routePath),
              ),
              _HeaderIconButton(
                tooltip: l10n.homeAddDoorTooltip,
                icon: Icons.add_rounded,
                onPressed: onAddPressed,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(l10n.homeGreeting, style: AppTextTokens.homeGreeting(textTheme)),
          const SizedBox(height: 4),
          Text(l10n.homeWelcome, style: AppTextTokens.homeWelcome(textTheme)),
        ],
      ),
    );
  }
}

class _HomeGroup {
  const _HomeGroup({required this.label, required this.devices});

  final String label;
  final List<DeviceSummary> devices;
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.iconHomeAction, size: 24),
    );
  }
}

class _HomeTabs extends StatelessWidget {
  const _HomeTabs({required this.homes});

  final List<_HomeGroup> homes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 48,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        labelColor: Colors.black,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextTokens.homeTabLabel(textTheme),
        unselectedLabelStyle: AppTextTokens.homeTabLabel(textTheme),
        indicatorColor: AppColors.brandPrimary,
        indicatorWeight: 2,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.only(right: 28),
        tabs: [for (final home in homes) Tab(text: home.label)],
      ),
    );
  }
}

class _HomeDevicePanel extends StatelessWidget {
  const _HomeDevicePanel({required this.home});

  final _HomeGroup home;

  @override
  Widget build(BuildContext context) {
    if (home.devices.isEmpty) {
      return _EmptyHomeState(doorCount: home.devices.length);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _DoorCount(count: home.devices.length);
        }
        return _DeviceCard(device: home.devices[index - 1]);
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: home.devices.length + 1,
    );
  }
}

class _DoorCount extends StatelessWidget {
  const _DoorCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context).homeDoorCount(count),
      style: AppTextTokens.homeDoorCount(Theme.of(context).textTheme),
    );
  }
}

class _EmptyHomeState extends StatelessWidget {
  const _EmptyHomeState({required this.doorCount});

  final int doorCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DoorCount(count: doorCount),
          const Spacer(flex: 2),
          Center(
            child: _EmptyDoorsAsset(
              assetPath: HomeAssetPaths.emptyDoorsPlaceholder,
              size: 116,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.homeNoDoorsTitle,
            textAlign: TextAlign.center,
            style: AppTextTokens.homeEmptyTitle(textTheme),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.homeNoDoorsSubtitle,
            textAlign: TextAlign.center,
            style: AppTextTokens.homeEmptySubtitle(textTheme),
          ),
          const SizedBox(height: 42),
          Center(
            child: SizedBox(
              width: 152,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => context.push(AddDevicePage.routePath),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: AppColors.backgroundPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  textStyle: AppTextTokens.homePrimaryButton(textTheme),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.homeAddDoorAction),
              ),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(AppLocalizations.of(context).homeLoadDoorsFailed),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.assetPath, required this.size});

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color: AppColors.surfaceHomeAvatar,
            alignment: Alignment.center,
            child: Icon(
              Icons.person,
              color: AppColors.iconHomePlaceholder,
              size: size * 0.64,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyDoorsAsset extends StatelessWidget {
  const _EmptyDoorsAsset({required this.assetPath, required this.size});

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surfaceHomeIcon,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.borderHomePlaceholder,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.dns_outlined,
            color: AppColors.iconHomePlaceholder,
            size: size * 0.48,
          ),
        );
      },
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final DeviceSummary device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      color: AppColors.backgroundPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('${l10n.homeDoorStateLabel}: ${device.doorState.name}'),
            Text('${l10n.homeConnectionStateLabel}: ${device.bleState.name}'),
            Text(
              '${l10n.homeLifeRemainingLabel}: '
              '${device.remainingLifePercent}%',
            ),
          ],
        ),
      ),
    );
  }
}
