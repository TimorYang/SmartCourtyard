import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../app/router/app_route_observer.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../features/account/application/providers.dart';
import '../../../../features/account/domain/entities/account_profile.dart';
import '../../../../features/account/presentation/pages/account_profile_page.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/design_system/door_type_visuals.dart';
import '../../../add_device/presentation/pages/add_new_doors_page.dart';
import '../../../add_device/application/providers.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../hardware_debug/presentation/pages/ble_debug_page.dart';
import '../../../notification/presentation/pages/notification_list_page.dart';
import '../../application/providers.dart';
import '../../domain/entities/home_scene.dart';
import '../widgets/device_customize_dialog.dart';
import '../widgets/device_delete_dialog.dart';
import '../widgets/device_name_dialog.dart';
import '../widgets/scene_name_dialog.dart';
import '../../../device_control/presentation/pages/device_command_page.dart';
import '../../../device_control/application/device_command_controller.dart';
import 'choose_scene_page.dart';
import 'device_share_page.dart';
import 'scene_page.dart';

class HomeAssetPaths {
  const HomeAssetPaths._();

  static const avatarPlaceholder = 'assets/icons/home/home_avatar_placeholder.png';
  static const emptyDoorsPlaceholder = 'assets/icons/home/home_empty_doors_placeholder.png';
  static const headerMenuIcon = 'assets/icons/home/home_header_menu_icon.png';
  static const headerGridPlaceholder = 'assets/icons/home/home_header_grid_placeholder.png';
  static const headerSceneIcon = 'assets/icons/home/home_header_scene_icon.png';
  static const headerMessageIcon = 'assets/icons/home/home_header_message_icon.png';
  static const headerAddIcon = 'assets/icons/home/home_header_add_icon.png';
  static const addScenePlaceholder = 'assets/icons/home/home_add_scene_placeholder.png';
  static const addDoorPlaceholder = 'assets/icons/home/home_add_door_placeholder.png';
  static const smartDevicePlaceholder = 'assets/icons/home/home_smart_device_placeholder.png';
  static const garageDoorIcon = 'assets/icons/add_device/add_new_doors_garage_door.png';
  static const rollerDoorIcon = 'assets/icons/add_device/add_new_doors_roller_door.png';
  static const deviceEditTopIcon = 'assets/icons/home/home_device_edit_top_icon.png';
  static const deviceEditShareIcon = 'assets/icons/home/home_device_edit_share_icon.png';
  static const deviceEditMoveSceneIcon = 'assets/icons/home/home_device_edit_move_scene_icon.png';
  static const deviceEditNameIcon = 'assets/icons/home/home_device_edit_name_icon.png';
  static const deviceEditDeleteIcon = 'assets/icons/home/home_device_edit_delete_icon.png';
  static const deviceEditCustomizeIcon = 'assets/icons/home/home_device_edit_customize_icon.png';
  static const deviceCardSharingBadge = 'assets/icons/home/home_device_card_sharing_badge.png';
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  static const routeName = 'home';
  static const routePath = '/home';

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with WidgetsBindingObserver, RouteAware {
  var _isAddMenuVisible = false;
  var _isSingleColumnDeviceList = false;
  ModalRoute<dynamic>? _route;
  var _isDisconnectingBle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_disconnectConnectedBleDevices());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route == route) {
      return;
    }
    if (_route != null) {
      appRouteObserver.unsubscribe(this);
    }
    _route = route;
    if (route != null) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    unawaited(_disconnectConnectedBleDevices());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_disconnectConnectedBleDevices());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _disconnectConnectedBleDevices() async {
    if (_isDisconnectingBle) {
      return;
    }
    _isDisconnectingBle = true;
    try {
      final allDisconnected = await ref.read(addDeviceControllerProvider.notifier).disconnectConnectedBleDevices();
      if (!mounted || allDisconnected) {
        return;
      }
      AppToast.error(context, AppLocalizations.of(context).smartOpenerDisconnectFailedMessage);
    } finally {
      _isDisconnectingBle = false;
    }
  }

  Future<void> _refreshHome([int? sceneId]) async {
    if (sceneId == null) return;
    try {
      ref.invalidate(homeDoorsBySceneProvider(sceneId));
      ref.invalidate(homeDevicesProvider);
      await ref.read(homeDevicesProvider.future);
    } catch (_) {
      // Provider error states render the existing home error UI.
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(homeDevicesProvider);
    final scenes = ref.watch(homeScenesProvider);
    final accountProfile = ref.watch(accountControllerProvider).asData?.value;
    final homeDevices = devices.when(data: (items) => items, loading: () => const <DeviceSummary>[], error: (error, stackTrace) => const <DeviceSummary>[]);
    final homes = scenes.when(
      data: (items) => _buildHomeGroups(items, homeDevices),
      loading: () => <_HomeGroup>[_HomeGroup(label: 'Home', doorCount: homeDevices.length, devices: homeDevices, sceneId: null)],
      error: (error, stackTrace) => <_HomeGroup>[_HomeGroup(label: 'Home', doorCount: homeDevices.length, devices: homeDevices, sceneId: null)],
    );
    final hasError = devices.hasError || scenes.hasError;

    return DefaultTabController(
      key: ValueKey(homes.map((home) => home.label).join('|')),
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
                    profile: accountProfile,
                    isSingleColumnDeviceList: _isSingleColumnDeviceList,
                    onToggleDeviceLayout: () {
                      setState(() {
                        _isSingleColumnDeviceList = !_isSingleColumnDeviceList;
                      });
                    },
                    onAddPressed: () {
                      setState(() {
                        _isAddMenuVisible = true;
                      });
                    },
                  ),
                  _HomeTabs(homes: homes),
                  const Divider(height: 1, color: AppColors.borderHomeDivider),
                  Expanded(
                    child: hasError
                        ? _HomeRefreshableState(onRefresh: _refreshHome, child: const _HomeErrorState())
                        : TabBarView(
                            children: [
                              for (final home in homes)
                                _HomeDevicePanel(home: home, isSingleColumn: _isSingleColumnDeviceList, onRefresh: () => _refreshHome(home.sceneId)),
                            ],
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

  List<_HomeGroup> _buildHomeGroups(List<HomeScene> scenes, List<DeviceSummary> devices) {
    if (scenes.isEmpty) {
      return [_HomeGroup(label: 'Home', doorCount: devices.length, devices: devices, sceneId: null)];
    }

    final defaultSceneIndex = scenes.indexWhere((scene) => scene.isDefault);
    final fallbackSceneId = scenes[defaultSceneIndex == -1 ? 0 : defaultSceneIndex].id;

    return [
      for (var index = 0; index < scenes.length; index++)
        _HomeGroup(
          label: scenes[index].name.trim().isEmpty ? 'Home' : scenes[index].name.trim(),
          doorCount: devices.where((device) => (device.sceneId ?? fallbackSceneId) == scenes[index].id).length,
          devices: devices.where((device) => (device.sceneId ?? fallbackSceneId) == scenes[index].id).toList(growable: false),
          sceneId: scenes[index].id,
        ),
    ];
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
  const _HomeAddMenuItemData({required this.label, required this.assetPath, required this.fallbackIcon, required this.onPressed});

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
            _HomeAddMenuIcon(assetPath: item.assetPath, fallbackIcon: item.fallbackIcon),
            const SizedBox(width: 10),
            Expanded(child: Text(item.label, style: AppTextTokens.homeAddMenuItem(Theme.of(context).textTheme))),
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
  const _HomeHeader({required this.profile, required this.isSingleColumnDeviceList, required this.onToggleDeviceLayout, required this.onAddPressed});

  final AccountProfile? profile;
  final bool isSingleColumnDeviceList;
  final VoidCallback onToggleDeviceLayout;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarPlaceholder(
                assetPath: HomeAssetPaths.avatarPlaceholder,
                imageUrl: profile?.avatarUrl,
                size: 58,
                tooltip: l10n.accountProfileTitle,
                onPressed: () => context.push(AccountProfilePage.routePath),
              ),
              const Spacer(),
              _HeaderIconButton(
                tooltip: "",
                assetPath: HomeAssetPaths.headerMessageIcon,
                fallbackIcon: Icons.message,
                onPressed: () => context.push(NotificationListPage.routePath),
              ),
              _HeaderIconButton(
                tooltip: l10n.homeMenuTooltip,
                assetPath: isSingleColumnDeviceList ? HomeAssetPaths.headerGridPlaceholder : HomeAssetPaths.headerMenuIcon,
                fallbackIcon: isSingleColumnDeviceList ? Icons.grid_view_rounded : Icons.menu_rounded,
                onPressed: onToggleDeviceLayout,
              ),
              _HeaderIconButton(
                tooltip: l10n.sceneHomeShortcutTooltip,
                assetPath: HomeAssetPaths.headerSceneIcon,
                fallbackIcon: Icons.edit_outlined,
                onPressed: () => context.push(ScenePage.routePath),
              ),
              _HeaderIconButton(
                tooltip: l10n.homeAddDoorTooltip,
                assetPath: HomeAssetPaths.headerAddIcon,
                fallbackIcon: Icons.add_rounded,
                onPressed: onAddPressed,
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            child: Text(profile?.nickname.isNotEmpty == true ? 'Hi ${profile!.nickname}' : l10n.homeGreeting, style: AppTextTokens.homeGreeting(textTheme)),
            onTap: () => context.push(BleDebugPage.routePath),
          ),
          const SizedBox(height: 2),
          Text(l10n.homeWelcome, style: AppTextTokens.homeWelcome(textTheme)),
        ],
      ),
    );
  }
}

class _HomeGroup {
  const _HomeGroup({required this.label, required this.doorCount, required this.devices, required this.sceneId});

  final String label;
  final int doorCount;
  final List<DeviceSummary> devices;
  final int? sceneId;
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.tooltip, required this.assetPath, required this.fallbackIcon, required this.onPressed});

  final String tooltip;
  final String assetPath;
  final IconData fallbackIcon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(fallbackIcon, color: AppColors.iconHomeAction);
        },
      ),
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
      height: 38,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        labelColor: Colors.black,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextTokens.homeTabLabel(textTheme),
        unselectedLabelStyle: AppTextTokens.homeUnselectedTabLabel(textTheme),
        indicatorColor: AppColors.brandPrimary,
        indicatorWeight: 1,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.only(right: 28),
        tabs: [for (final home in homes) Tab(text: home.label)],
      ),
    );
  }
}

class _HomeDevicePanel extends StatelessWidget {
  const _HomeDevicePanel({required this.home, required this.isSingleColumn, required this.onRefresh});

  final _HomeGroup home;
  final bool isSingleColumn;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: home.devices.isEmpty
          ? _EmptyHomeState(doorCount: home.doorCount)
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              children: [
                _DoorCount(count: home.doorCount),
                const SizedBox(height: 16),
                if (isSingleColumn)
                  for (final device in home.devices) ...[SizedBox(height: 162, child: _DeviceCard(device: device)), const SizedBox(height: 18)]
                else
                  GridView.builder(
                    itemCount: home.devices.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      return _DeviceCard(device: home.devices[index]);
                    },
                  ),
              ],
            ),
    );
  }
}

class _DoorCount extends StatelessWidget {
  const _DoorCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(AppLocalizations.of(context).homeDoorCount(count), style: AppTextTokens.homeDoorCount(Theme.of(context).textTheme));
  }
}

class _EmptyHomeState extends StatelessWidget {
  const _EmptyHomeState({required this.doorCount});

  final int doorCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DoorCount(count: doorCount),
                const Spacer(flex: 2),
                Center(child: _EmptyDoorsAsset(assetPath: HomeAssetPaths.emptyDoorsPlaceholder, size: 116)),
                const SizedBox(height: 28),
                Text(l10n.homeNoDoorsTitle, textAlign: TextAlign.center, style: AppTextTokens.homeEmptyTitle(textTheme)),
                const SizedBox(height: 8),
                Text(l10n.homeNoDoorsSubtitle, textAlign: TextAlign.center, style: AppTextTokens.homeEmptySubtitle(textTheme)),
                const SizedBox(height: 42),
                Center(
                  child: SizedBox(
                    width: 152,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => context.push(AddNewDoorsPage.routePath),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: AppColors.backgroundPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
          ),
        ),
      ],
    );
  }
}

class _HomeRefreshableState extends StatelessWidget {
  const _HomeRefreshableState({required this.onRefresh, required this.child});

  final RefreshCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
      ),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppLocalizations.of(context).homeLoadDoorsFailed));
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.assetPath, required this.size, this.imageUrl, this.tooltip, this.onPressed});

  final String assetPath;
  final double size;
  final String? imageUrl;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = imageUrl?.trim();
    final avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? Image.asset(assetPath, fit: BoxFit.cover, errorBuilder: _buildFallback)
            : Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: _buildFallback),
      ),
    );

    if (onPressed == null) {
      return avatar;
    }

    return Tooltip(
      message: tooltip ?? '',
      child: Semantics(
        button: true,
        label: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: SizedBox(width: size, height: size, child: avatar),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context, Object error, StackTrace? stackTrace) {
    return Container(
      color: AppColors.surfaceHomeAvatar,
      alignment: Alignment.center,
      child: Icon(Icons.person, color: AppColors.iconHomePlaceholder, size: size * 0.64),
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
            border: Border.all(color: AppColors.borderHomePlaceholder, width: 1),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.dns_outlined, color: AppColors.iconHomePlaceholder, size: size * 0.48),
        );
      },
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final DeviceSummary device;

  static const _sharingBadgeKey = ValueKey<String>('home-device-sharing-badge');
  static const _statusDotKey = ValueKey<String>('home-device-status-dot');
  static const _sharingBadgeSize = 52.0;
  static const _cardInset = 10.0;
  static const _statusDotSpacing = 8.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSharing = device.shareStatus == 2;

    return GestureDetector(
      onTap: () {
        final doorId = Uri.encodeQueryComponent(device.id);
        context.push('${DeviceCommandPage.routePath}?doorId=$doorId&deviceId=$doorId');
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showDeviceEditingSheet(context, device);
      },
      child: Material(
        color: AppColors.surfaceItemSceneCard,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: isSharing ? _sharingBadgeSize + _statusDotSpacing : _cardInset,
              right: _cardInset,
              child: _DeviceStatusDot(key: _statusDotKey, onlineState: device.onlineState),
            ),
            if (isSharing)
              Positioned(
                top: -6,
                right: 0,
                child: Image.asset(
                  HomeAssetPaths.deviceCardSharingBadge,
                  key: _sharingBadgeKey,
                  width: _sharingBadgeSize,
                  height: _sharingBadgeSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 18, 10, 14),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _DeviceDoorIcon(device: device),
                      const SizedBox(height: 20),
                      Text(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextTokens.homeDeviceCardTitle(Theme.of(context).textTheme),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _doorStateLabel(l10n, device.doorState),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextTokens.homeDeviceCardState(Theme.of(context).textTheme),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeviceEditingSheet(BuildContext context, DeviceSummary device) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeviceEditingSheet(device: device, parentContext: context),
    );
  }

  String _doorStateLabel(AppLocalizations l10n, DoorState state) {
    return switch (state) {
      DoorState.open => l10n.homeDoorStateOpen,
      DoorState.opening => l10n.homeDoorStateOpening,
      DoorState.stopped => l10n.homeDoorStateStopped,
      DoorState.closing => l10n.homeDoorStateClosing,
      DoorState.closed => l10n.homeDoorStateClosed,
      DoorState.unknown => l10n.homeDoorStateUnknown,
    };
  }
}

class _DeviceEditingSheet extends ConsumerStatefulWidget {
  const _DeviceEditingSheet({required this.device, required this.parentContext});

  final DeviceSummary device;
  final BuildContext parentContext;

  @override
  ConsumerState<_DeviceEditingSheet> createState() => _DeviceEditingSheetState();
}

class _DeviceEditingSheetState extends ConsumerState<_DeviceEditingSheet> {
  var _isTopping = false;
  var _isCheckingShareDevice = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final items = <_DeviceEditingAction>[
      if (widget.device.shareStatus != 2) ...[
        _DeviceEditingAction(
          label: l10n.homeDeviceEditTopAction,
          assetPath: HomeAssetPaths.deviceEditTopIcon,
          fallbackIcon: Icons.vertical_align_top_rounded,
          isPending: _isTopping,
          onPressed: _isTopping ? null : _topDevice,
        ),
        _DeviceEditingAction(
          label: l10n.homeDeviceEditCustomizeAction,
          assetPath: HomeAssetPaths.deviceEditCustomizeIcon,
          fallbackIcon: Icons.image_outlined,
          onPressed: () {
            Navigator.of(context).pop();
            showDeviceCustomizeDialog(widget.parentContext, device: widget.device);
          },
        ),
        _DeviceEditingAction(
          label: l10n.homeDeviceEditShareAction,
          assetPath: HomeAssetPaths.deviceEditShareIcon,
          fallbackIcon: Icons.person_add_alt_1_outlined,
          isPending: _isCheckingShareDevice,
          onPressed: _isCheckingShareDevice ? null : _shareDevice,
        ),
      ],
      _DeviceEditingAction(
        label: l10n.homeDeviceEditMoveSceneAction,
        assetPath: HomeAssetPaths.deviceEditMoveSceneIcon,
        fallbackIcon: Icons.exit_to_app_rounded,
        onPressed: () {
          final router = GoRouter.of(context);
          Navigator.of(context).pop();
          router.push(ChooseScenePage.routePath, extra: widget.device);
        },
      ),
      _DeviceEditingAction(
        label: l10n.homeDeviceEditNameAction,
        assetPath: HomeAssetPaths.deviceEditNameIcon,
        fallbackIcon: Icons.drive_file_rename_outline_rounded,
        onPressed: () {
          Navigator.of(context).pop();
          showDeviceNameDialog(widget.parentContext, device: widget.device);
        },
      ),
      _DeviceEditingAction(
        label: l10n.homeDeviceEditDeleteAction,
        assetPath: HomeAssetPaths.deviceEditDeleteIcon,
        fallbackIcon: Icons.delete_outline_rounded,
        onPressed: () {
          Navigator.of(context).pop();
          showDeviceDeleteDialog(widget.parentContext, device: widget.device);
        },
      ),
    ];

    return Material(
      color: AppColors.backgroundPrimary,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 34, 28, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _DeviceDoorIcon(device: widget.device),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.homeDeviceEditingTitle, style: AppTextTokens.homeDeviceEditingTitle(textTheme)),
                        const SizedBox(height: 4),
                        Text(widget.device.name, style: AppTextTokens.homeDeviceEditingSubtitle(textTheme)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              for (var index = 0; index < items.length; index++) ...[
                _DeviceEditingActionTile(action: items[index]),
                if (index != items.length - 1) const Divider(height: 1, color: AppColors.borderHomeDivider),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _topDevice() async {
    final doorId = int.tryParse(widget.device.id);
    if (doorId == null) {
      _showTopFailure();
      return;
    }

    setState(() {
      _isTopping = true;
    });
    final requestId = 'home-top-door-$doorId-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await ref.read(topHomeDoorUseCaseProvider)(doorId: doorId, requestId: requestId);
      ref.invalidate(homeDevicesProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        _showTopFailure();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTopping = false;
        });
      }
    }
  }

  Future<void> _shareDevice() async {
    final noDeviceMessage = AppLocalizations.of(widget.parentContext).homeNoDeviceMessage;
    setState(() {
      _isCheckingShareDevice = true;
    });

    try {
      final devices = await ref.read(fetchDoorDevicesUseCaseProvider)(
        doorId: widget.device.id,
        requestId: 'home-share-door-${widget.device.id}-${DateTime.now().toUtc().microsecondsSinceEpoch}',
      );
      if (!mounted) {
        return;
      }
      if (devices.isEmpty) {
        Navigator.of(context).pop();
        if (widget.parentContext.mounted) {
          AppToast.info(widget.parentContext, noDeviceMessage);
        }
        return;
      }

      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.push(DeviceSharePage.routePath, extra: widget.device);
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingShareDevice = false;
        });
      }
    }
  }

  void _showTopFailure() {
    AppToast.error(widget.parentContext, 'Failed to top device');
  }
}

class _DeviceEditingAction {
  const _DeviceEditingAction({required this.label, required this.assetPath, required this.fallbackIcon, this.isPending = false, this.onPressed});

  final String label;
  final String assetPath;
  final IconData fallbackIcon;
  final bool isPending;
  final VoidCallback? onPressed;
}

class _DeviceEditingActionTile extends StatelessWidget {
  const _DeviceEditingActionTile({required this.action});

  final _DeviceEditingAction action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.isPending ? null : action.onPressed,
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            _DeviceEditingActionIcon(action: action),
            const SizedBox(width: 12),
            Expanded(child: Text(action.label, style: AppTextTokens.homeDeviceEditingAction(Theme.of(context).textTheme))),
            action.isPending
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary, size: 25),
          ],
        ),
      ),
    );
  }
}

class _DeviceEditingActionIcon extends StatelessWidget {
  const _DeviceEditingActionIcon({required this.action});

  final _DeviceEditingAction action;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      action.assetPath,
      width: 22,
      height: 22,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(action.fallbackIcon, color: AppColors.textMuted, size: 22);
      },
    );
  }
}

class _DeviceStatusDot extends StatelessWidget {
  const _DeviceStatusDot({super.key, required this.onlineState});

  final DeviceOnlineState onlineState;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onlineState == DeviceOnlineState.online ? AppColors.homeDeviceOnlineStatus : AppColors.homeDeviceUnavailableStatus,
      ),
    );
  }
}

class _DeviceDoorIcon extends StatelessWidget {
  const _DeviceDoorIcon({required this.device});

  final DeviceSummary device;

  @override
  Widget build(BuildContext context) {
    final visual = DoorTypeVisuals.forType(device.doorType);

    return Image.asset(
      visual.assetPath,
      width: 64,
      height: 64,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(visual.fallbackIcon, color: AppColors.iconHomeAction, size: 64);
      },
    );
  }
}
