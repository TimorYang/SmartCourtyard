import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: l10n.chooseSceneBackTooltip,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 34,
                    height: 34,
                  ),
                  onPressed: context.pop,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.iconHomeAction,
                    size: 28,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: l10n.chooseSceneEditTooltip,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 34,
                    height: 34,
                  ),
                  onPressed: () {},
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.iconHomeAction,
                    size: 30,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 72),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chooseSceneTitle,
                    style: AppTextTokens.sceneTitle(textTheme),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _breadcrumb,
                    style: AppTextTokens.sceneBreadcrumb(textTheme),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 74),
            for (final scene in _scenes) ...[
              _SceneCard(scene: scene),
              const SizedBox(height: 20),
            ],
            const _NewSceneCard(),
          ],
        ),
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
      height: 146,
      decoration: BoxDecoration(
        color: AppColors.surfaceSceneCard,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: Row(
        children: [
          _SceneIcon(assetPath: scene.iconAssetPath, icon: scene.fallbackIcon),
          const SizedBox(width: 38),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scene.name,
                  style: AppTextTokens.sceneCardTitle(textTheme),
                ),
                const SizedBox(height: 20),
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
      width: 58,
      height: 58,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(icon, color: AppColors.iconHomeAction, size: 58);
      },
    );
  }
}

class _SelectedSceneIndicator extends StatelessWidget {
  const _SelectedSceneIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        color: AppColors.authSuccess,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AppColors.backgroundPrimary,
        size: 26,
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
      height: 146,
      decoration: BoxDecoration(
        color: AppColors.surfaceSceneCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.authSuccess,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.backgroundPrimary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.chooseSceneNewSceneAction,
            style: AppTextTokens.sceneNewScene(Theme.of(context).textTheme),
          ),
        ],
      ),
    );
  }
}
