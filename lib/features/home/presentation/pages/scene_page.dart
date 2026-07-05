import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../widgets/scene_name_dialog.dart';

class SceneAssetPaths {
  const SceneAssetPaths._();

  static const warehousePlaceholder =
      'assets/icons/home/scene_warehouse_placeholder.png';
  static const editDonePlaceholder =
      'assets/icons/home/scene_edit_done_placeholder.png';
}

class ScenePage extends StatefulWidget {
  const ScenePage({super.key});

  static const routeName = 'scene';
  static const routePath = '/scene';

  @override
  State<ScenePage> createState() => _ScenePageState();
}

class _ScenePageState extends State<ScenePage> {
  static const _sceneCount = 5;
  static const _scenes = <_SceneItem>[
    _SceneItem(
      name: 'Warehouse A',
      deviceCount: 5,
      iconAssetPath: SceneAssetPaths.warehousePlaceholder,
      fallbackIcon: Icons.home_outlined,
    ),
    _SceneItem(
      name: 'Home Garage A',
      deviceCount: 2,
      iconAssetPath: SceneAssetPaths.warehousePlaceholder,
      fallbackIcon: Icons.home_outlined,
    ),
    _SceneItem(
      name: 'Home Garage B',
      deviceCount: 2,
      iconAssetPath: SceneAssetPaths.warehousePlaceholder,
      fallbackIcon: Icons.home_outlined,
    ),
  ];

  var _isEditing = false;

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
            tooltip: _isEditing
                ? l10n.sceneDoneEditingTooltip
                : l10n.sceneEditTooltip,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            icon: _isEditing
                ? const _EditDoneIcon()
                : const Icon(
                    Icons.edit_outlined,
                    color: AppColors.iconHomeAction,
                    size: 25,
                  ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 10, 0, 10),
            child: Text(
              _isEditing ? l10n.sceneEditingTitle : l10n.sceneTitle,
              style: AppTextTokens.sceneTitle(textTheme),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Text(
              l10n.sceneCount(_sceneCount),
              style: AppTextTokens.sceneBreadcrumb(textTheme),
            ),
          ),
          const SizedBox(height: 46),
          for (final scene in _scenes) ...[
            _SceneCard(scene: scene, isEditing: _isEditing),
            const SizedBox(height: 16),
          ],
          if (!_isEditing) ...[
            const SizedBox(height: 2),
            _NewSceneCard(onPressed: () => showSceneNameDialog(context)),
          ],
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
  });

  final String name;
  final int deviceCount;
  final String iconAssetPath;
  final IconData fallbackIcon;
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.scene, required this.isEditing});

  final _SceneItem scene;
  final bool isEditing;

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
          if (isEditing) ...[
            const _DeleteSceneButton(),
            const SizedBox(width: 15),
          ],
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
                  l10n.sceneDeviceCount(scene.deviceCount),
                  style: AppTextTokens.sceneCardMeta(textTheme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditDoneIcon extends StatelessWidget {
  const _EditDoneIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      SceneAssetPaths.editDonePlaceholder,
      width: 25,
      height: 25,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.check_rounded,
          color: AppColors.iconHomeAction,
          size: 25,
        );
      },
    );
  }
}

class _DeleteSceneButton extends StatelessWidget {
  const _DeleteSceneButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: AppColors.sceneDeleteAction,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.remove_rounded,
        color: AppColors.backgroundPrimary,
        size: 24,
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

class _NewSceneCard extends StatelessWidget {
  const _NewSceneCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: l10n.sceneNewSceneAction,
      child: Material(
        color: AppColors.surfaceSceneCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(
            height: 88,
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
                  l10n.sceneNewSceneAction,
                  style: AppTextTokens.sceneNewScene(
                    Theme.of(context).textTheme,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
