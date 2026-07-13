import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../domain/entities/home_scene.dart';

class ChooseSceneAssetPaths {
  const ChooseSceneAssetPaths._();

  static const garagePlaceholder =
      'assets/icons/home/scene_garage_placeholder.png';
}

class ChooseScenePage extends StatelessWidget {
  const ChooseScenePage({super.key});

  static const routeName = 'choose-scene';
  static const routePath = '/choose-scene';

  static const _breadcrumb = '333/TestFoor';
  static const _currentSceneId = 333;
  static const _sceneResponses = <Map<String, Object>>[
    {'defaultScene': true, 'doorCount': 5, 'id': 1, 'name': 'Home'},
    {'defaultScene': false, 'doorCount': 0, 'id': 2222, 'name': '2222'},
    {'defaultScene': false, 'doorCount': 1, 'id': 333, 'name': '333'},
    {'defaultScene': false, 'doorCount': 1, 'id': 4444, 'name': '4444'},
    {'defaultScene': false, 'doorCount': 0, 'id': 555, 'name': '555'},
  ];

  static final _scenes = [
    for (final response in _sceneResponses)
      HomeScene(
        id: response['id'] as int,
        name: response['name'] as String,
        doorCount: response['doorCount'] as int,
        isDefault: response['defaultScene'] as bool,
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
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: l10n.chooseSceneBackTooltip,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.iconHomeAction,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 42),
            Text(
              l10n.chooseSceneTitle,
              style: AppTextTokens.sceneTitle(textTheme),
            ),
            const SizedBox(height: 2),
            Text(_breadcrumb, style: AppTextTokens.sceneBreadcrumb(textTheme)),
            const SizedBox(height: 38),
            for (var index = 0; index < _scenes.length; index++) ...[
              _SceneCard(
                scene: _scenes[index],
                selected: _scenes[index].id == _currentSceneId,
                onPressed: () => context.pop(_scenes[index]),
              ),
              if (index != _scenes.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Divider(
                    height: 18,
                    color: AppColors.borderHomeDivider,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.scene,
    required this.selected,
    required this.onPressed,
  });

  final HomeScene scene;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: AppColors.surfaceItemSceneCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Container(
            height: 108,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: selected
                  ? Border.all(
                      color: AppColors.borderSelectedSceneCard,
                      width: 1,
                    )
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 34),
            child: Row(
              children: [
                const _SceneIcon(),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scene.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextTokens.sceneCardTitle(textTheme),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.chooseSceneDeviceCount(scene.doorCount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextTokens.sceneCardMeta(textTheme),
                      ),
                    ],
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

class _SceneIcon extends StatelessWidget {
  const _SceneIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      ChooseSceneAssetPaths.garagePlaceholder,
      width: 42,
      height: 42,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.home_outlined,
          color: AppColors.iconHomeAction,
          size: 42,
        );
      },
    );
  }
}
