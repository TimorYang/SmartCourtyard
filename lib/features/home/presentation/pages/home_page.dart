import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../features/account/presentation/pages/account_profile_page.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../add_device/presentation/pages/add_new_doors_page.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../application/providers.dart';
import '../../domain/entities/home_scene.dart';
import '../widgets/device_customize_dialog.dart';
import '../widgets/device_delete_dialog.dart';
import '../widgets/device_name_dialog.dart';
import '../widgets/scene_name_dialog.dart';
import '../../../device_control/presentation/pages/device_command_page.dart';
import 'choose_scene_page.dart';
import 'device_share_page.dart';
import 'scene_page.dart';

class HomeAssetPaths {
  const HomeAssetPaths._();

  static const avatarPlaceholder =
      'assets/icons/home/home_avatar_placeholder.png';
  static const emptyDoorsPlaceholder =
      'assets/icons/home/home_empty_doors_placeholder.png';
  static const headerMenuIcon = 'assets/icons/home/home_header_menu_icon.png';
  static const headerGridPlaceholder =
      'assets/icons/home/home_header_grid_placeholder.png';
  static const headerSceneIcon = 'assets/icons/home/home_header_scene_icon.png';
  static const headerAddIcon = 'assets/icons/home/home_header_add_icon.png';
  static const addScenePlaceholder =
      'assets/icons/home/home_add_scene_placeholder.png';
  static const addDoorPlaceholder =
      'assets/icons/home/home_add_door_placeholder.png';
  static const smartDevicePlaceholder =
      'assets/icons/home/home_smart_device_placeholder.png';
  static const garageDoorIcon =
      'assets/icons/add_device/add_new_doors_garage_door.png';
  static const rollerDoorIcon =
      'assets/icons/add_device/add_new_doors_roller_door.png';
  static const deviceEditTopIcon =
      'assets/icons/home/home_device_edit_top_icon.png';
  static const deviceEditShareIcon =
      'assets/icons/home/home_device_edit_share_icon.png';
  static const deviceEditMoveSceneIcon =
      'assets/icons/home/home_device_edit_move_scene_icon.png';
  static const deviceEditNameIcon =
      'assets/icons/home/home_device_edit_name_icon.png';
  static const deviceEditDeleteIcon =
      'assets/icons/home/home_device_edit_delete_icon.png';
  static const deviceEditCustomizeIcon =
      'assets/icons/home/home_device_edit_customize_icon.png';
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
  var _isSingleColumnDeviceList = false;

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(homeDevicesProvider);
    final scenes = ref.watch(homeScenesProvider);
    final homeDevices = devices.when(
      data: (items) => items,
      loading: () => const <DeviceSummary>[],
      error: (error, stackTrace) => const <DeviceSummary>[],
    );
    final homes = scenes.when(
      data: (items) => _buildHomeGroups(items, homeDevices),
      loading: () => <_HomeGroup>[
        _HomeGroup(
          label: 'Home',
          doorCount: homeDevices.length,
          devices: homeDevices,
        ),
      ],
      error: (error, stackTrace) => <_HomeGroup>[
        _HomeGroup(
          label: 'Home',
          doorCount: homeDevices.length,
          devices: homeDevices,
        ),
      ],
    );
    final isLoading = devices.isLoading || scenes.isLoading;
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
                        ? const _HomeErrorState()
                        : isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : TabBarView(
                            children: [
                              for (final home in homes)
                                _HomeDevicePanel(
                                  home: home,
                                  isSingleColumn: _isSingleColumnDeviceList,
                                ),
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

  List<_HomeGroup> _buildHomeGroups(
    List<HomeScene> scenes,
    List<DeviceSummary> devices,
  ) {
    if (scenes.isEmpty) {
      return [
        _HomeGroup(label: 'Home', doorCount: devices.length, devices: devices),
      ];
    }

    final defaultSceneIndex = scenes.indexWhere((scene) => scene.isDefault);
    final fallbackSceneId =
        scenes[defaultSceneIndex == -1 ? 0 : defaultSceneIndex].id;

    return [
      for (var index = 0; index < scenes.length; index++)
        _HomeGroup(
          label: scenes[index].name.trim().isEmpty
              ? 'Home'
              : scenes[index].name.trim(),
          doorCount: devices
              .where(
                (device) =>
                    (device.sceneId ?? fallbackSceneId) == scenes[index].id,
              )
              .length,
          devices: devices
              .where(
                (device) =>
                    (device.sceneId ?? fallbackSceneId) == scenes[index].id,
              )
              .toList(growable: false),
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
  const _HomeHeader({
    required this.isSingleColumnDeviceList,
    required this.onToggleDeviceLayout,
    required this.onAddPressed,
  });

  final bool isSingleColumnDeviceList;
  final VoidCallback onToggleDeviceLayout;
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
                tooltip: l10n.accountProfileTitle,
                onPressed: () => context.push(AccountProfilePage.routePath),
              ),
              const Spacer(),
              _HeaderIconButton(
                tooltip: l10n.homeMenuTooltip,
                assetPath: isSingleColumnDeviceList
                    ? HomeAssetPaths.headerGridPlaceholder
                    : HomeAssetPaths.headerMenuIcon,
                fallbackIcon: isSingleColumnDeviceList
                    ? Icons.grid_view_rounded
                    : Icons.menu_rounded,
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
          Text(l10n.homeGreeting, style: AppTextTokens.homeGreeting(textTheme)),
          const SizedBox(height: 2),
          Text(l10n.homeWelcome, style: AppTextTokens.homeWelcome(textTheme)),
        ],
      ),
    );
  }
}

class _HomeGroup {
  const _HomeGroup({
    required this.label,
    required this.doorCount,
    required this.devices,
  });

  final String label;
  final int doorCount;
  final List<DeviceSummary> devices;
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.assetPath,
    required this.fallbackIcon,
    required this.onPressed,
  });

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
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      onPressed: onPressed,
      icon: Image.asset(
        assetPath,
        width: 16,
        height: 16,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(fallbackIcon, color: AppColors.iconHomeAction, size: 16);
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
  const _HomeDevicePanel({required this.home, required this.isSingleColumn});

  final _HomeGroup home;
  final bool isSingleColumn;

  @override
  Widget build(BuildContext context) {
    if (home.devices.isEmpty) {
      return _EmptyHomeState(doorCount: home.doorCount);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      children: [
        _DoorCount(count: home.doorCount),
        const SizedBox(height: 16),
        if (isSingleColumn)
          for (final device in home.devices) ...[
            SizedBox(height: 160, child: _DeviceCard(device: device)),
            const SizedBox(height: 18),
          ]
        else
          GridView.builder(
            itemCount: home.devices.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 22,
              childAspectRatio: 0.96,
            ),
            itemBuilder: (context, index) {
              return _DeviceCard(device: home.devices[index]);
            },
          ),
      ],
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
                onPressed: () => context.push(AddNewDoorsPage.routePath),
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
  const _AvatarPlaceholder({
    required this.assetPath,
    required this.size,
    this.tooltip,
    this.onPressed,
  });

  final String assetPath;
  final double size;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
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
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () {
        final doorId = Uri.encodeQueryComponent(device.id);
        context.push(
          '${DeviceCommandPage.routePath}?doorId=$doorId&deviceId=$doorId',
        );
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
              top: 10,
              right: 10,
              child: _DeviceStatusDot(onlineState: device.onlineState),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 18, 10, 14),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _DeviceDoorIcon(deviceName: device.name),
                      const SizedBox(height: 20),
                      Text(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextTokens.homeDeviceCardTitle(
                          Theme.of(context).textTheme,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _doorStateLabel(l10n, device.doorState),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextTokens.homeDeviceCardState(
                          Theme.of(context).textTheme,
                        ),
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

  Future<void> _showDeviceEditingSheet(
    BuildContext context,
    DeviceSummary device,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _DeviceEditingSheet(device: device, parentContext: context),
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

class _DeviceEditingSheet extends StatelessWidget {
  const _DeviceEditingSheet({
    required this.device,
    required this.parentContext,
  });

  final DeviceSummary device;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final items = [
      _DeviceEditingAction(
        label: l10n.homeDeviceEditTopAction,
        assetPath: HomeAssetPaths.deviceEditTopIcon,
        fallbackIcon: Icons.vertical_align_top_rounded,
      ),
      _DeviceEditingAction(
        label: l10n.homeDeviceEditShareAction,
        assetPath: HomeAssetPaths.deviceEditShareIcon,
        fallbackIcon: Icons.person_add_alt_1_outlined,
        onPressed: () {
          final router = GoRouter.of(context);
          Navigator.of(context).pop();
          router.push(DeviceSharePage.routePath);
        },
      ),
      _DeviceEditingAction(
        label: l10n.homeDeviceEditMoveSceneAction,
        assetPath: HomeAssetPaths.deviceEditMoveSceneIcon,
        fallbackIcon: Icons.exit_to_app_rounded,
        onPressed: () {
          final router = GoRouter.of(context);
          Navigator.of(context).pop();
          router.push(ChooseScenePage.routePath);
        },
      ),
      _DeviceEditingAction(
        label: l10n.homeDeviceEditNameAction,
        assetPath: HomeAssetPaths.deviceEditNameIcon,
        fallbackIcon: Icons.drive_file_rename_outline_rounded,
        onPressed: () {
          Navigator.of(context).pop();
          showDeviceNameDialog(parentContext);
        },
      ),
      _DeviceEditingAction(
        label: l10n.homeDeviceEditDeleteAction,
        assetPath: HomeAssetPaths.deviceEditDeleteIcon,
        fallbackIcon: Icons.delete_outline_rounded,
        onPressed: () {
          Navigator.of(context).pop();
          showDeviceDeleteDialog(parentContext);
        },
      ),
      _DeviceEditingAction(
        label: l10n.homeDeviceEditCustomizeAction,
        assetPath: HomeAssetPaths.deviceEditCustomizeIcon,
        fallbackIcon: Icons.image_outlined,
        onPressed: () {
          Navigator.of(context).pop();
          showDeviceCustomizeDialog(parentContext);
        },
      ),
    ];

    return SafeArea(
      top: false,
      child: Material(
        color: AppColors.backgroundPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 34, 28, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _DeviceDoorIcon(deviceName: device.name),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.homeDeviceEditingTitle,
                          style: AppTextTokens.homeDeviceEditingTitle(
                            textTheme,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.name,
                          style: AppTextTokens.homeDeviceEditingSubtitle(
                            textTheme,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              for (var index = 0; index < items.length; index++) ...[
                _DeviceEditingActionTile(action: items[index]),
                if (index != items.length - 1)
                  const Divider(height: 1, color: AppColors.borderHomeDivider),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceEditingAction {
  const _DeviceEditingAction({
    required this.label,
    required this.assetPath,
    required this.fallbackIcon,
    this.onPressed,
  });

  final String label;
  final String assetPath;
  final IconData fallbackIcon;
  final VoidCallback? onPressed;
}

class _DeviceEditingActionTile extends StatelessWidget {
  const _DeviceEditingActionTile({required this.action});

  final _DeviceEditingAction action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onPressed,
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            _DeviceEditingActionIcon(action: action),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.label,
                style: AppTextTokens.homeDeviceEditingAction(
                  Theme.of(context).textTheme,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textPrimary,
              size: 25,
            ),
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
  const _DeviceStatusDot({required this.onlineState});

  final DeviceOnlineState onlineState;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onlineState == DeviceOnlineState.online
            ? AppColors.authSuccess
            : AppColors.iconHomeAction,
      ),
    );
  }
}

class _DeviceDoorIcon extends StatelessWidget {
  const _DeviceDoorIcon({required this.deviceName});

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final isRoller = deviceName.toLowerCase().contains('roller');
    final assetPath = isRoller
        ? HomeAssetPaths.rollerDoorIcon
        : HomeAssetPaths.garageDoorIcon;

    return Image.asset(
      assetPath,
      width: 45,
      height: 45,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          isRoller ? Icons.window_outlined : Icons.garage_outlined,
          color: AppColors.iconHomeAction,
          size: 45,
        );
      },
    );
  }
}
