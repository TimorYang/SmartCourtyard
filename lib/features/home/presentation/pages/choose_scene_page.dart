import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';

class ChooseSceneAssetPaths {
  const ChooseSceneAssetPaths._();

  static const warehousePlaceholder =
      'assets/icons/home/scene_warehouse_placeholder.png';
  static const garagePlaceholder =
      'assets/icons/home/scene_garage_placeholder.png';
}

class ChooseScenePage extends StatelessWidget {
  const ChooseScenePage({super.key});

  static const routeName = 'choose-scene';
  static const routePath = '/choose-scene';

  static const _breadcrumb = 'Home/Smart Door';
  static const _scenes = <_SceneItem>[
    _SceneItem(
      name: 'Warehouse A',
      deviceCount: 5,
      iconAssetPath: ChooseSceneAssetPaths.warehousePlaceholder,
      fallbackIcon: Icons.home_work_outlined,
      selected: true,
    ),
    _SceneItem(
      name: 'Home Garage A',
      deviceCount: 2,
      iconAssetPath: ChooseSceneAssetPaths.garagePlaceholder,
      fallbackIcon: Icons.home_outlined,
    ),
    _SceneItem(
      name: 'Home Garage B',
      deviceCount: 2,
      iconAssetPath: ChooseSceneAssetPaths.garagePlaceholder,
      fallbackIcon: Icons.home_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: FlinxNavigationBar(
        title: '',
        showBottomDivider: false,
        actions: [
          IconButton(
            tooltip: l10n.chooseSceneEditTooltip,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            onPressed: () {},
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.iconHomeAction,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 10, 0, 0),
            child: Text(
              l10n.chooseSceneTitle,
              style: AppTextTokens.sceneTitle(textTheme),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 0, 0),
            child: Text(
              _breadcrumb,
              style: AppTextTokens.sceneBreadcrumb(textTheme),
            ),
          ),
          const SizedBox(height: 46),
          for (final scene in _scenes) ...[
            _SceneCard(scene: scene),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 2),
          const _NewSceneCard(),
        ],
      ),
    );
  }
}

class _SceneItem {
  const _SceneItem({
    required this.name,
    required this.deviceCount,
    required this.iconAssetPath,
    required this.fallbackIcon,
    this.selected = false,
  });

  final String name;
  final int deviceCount;
  final String iconAssetPath;
  final IconData fallbackIcon;
  final bool selected;
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.scene});

  final _SceneItem scene;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.surfaceItemSceneCard,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          _SceneIcon(assetPath: scene.iconAssetPath, icon: scene.fallbackIcon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scene.name,
                  style: AppTextTokens.sceneCardTitle(textTheme),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.chooseSceneDeviceCount(scene.deviceCount),
                  style: AppTextTokens.sceneCardMeta(textTheme),
                ),
              ],
            ),
          ),
          if (scene.selected) const _SelectedSceneIndicator(),
        ],
      ),
    );
  }
}

class _SceneIcon extends StatelessWidget {
  const _SceneIcon({required this.assetPath, required this.icon});

  final String assetPath;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: 48,
      height: 48,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(icon, color: AppColors.iconHomeAction, size: 48);
      },
    );
  }
}

class _SelectedSceneIndicator extends StatelessWidget {
  const _SelectedSceneIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: AppColors.authSuccess,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AppColors.backgroundPrimary,
        size: 15,
      ),
    );
  }
}

class _NewSceneCard extends StatelessWidget {
  const _NewSceneCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.surfaceItemSceneCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.authSuccess,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.backgroundPrimary,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.chooseSceneNewSceneAction,
            style: AppTextTokens.sceneNewScene(Theme.of(context).textTheme),
          ),
        ],
      ),
    );
  }
}
