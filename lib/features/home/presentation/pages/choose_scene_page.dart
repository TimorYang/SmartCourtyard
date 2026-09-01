import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_error_message.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../../domain/entities/home_scene.dart';

class ChooseSceneAssetPaths {
  const ChooseSceneAssetPaths._();

  static const garagePlaceholder =
      'assets/icons/home/scene_garage_placeholder.png';
}

class ChooseScenePage extends ConsumerStatefulWidget {
  const ChooseScenePage({super.key, required this.door});

  final DeviceSummary? door;

  static const routeName = 'choose-scene';
  static const routePath = '/choose-scene';

  @override
  ConsumerState<ChooseScenePage> createState() => _ChooseScenePageState();
}

class _ChooseScenePageState extends ConsumerState<ChooseScenePage> {
  var _isMoving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scenesState = ref.watch(homeScenesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      body: _isMoving
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                children: [
                  Text(
                    l10n.chooseSceneTitle,
                    style: AppTextTokens.sceneTitle(textTheme),
                  ),
                  const SizedBox(height: 38),
                  if (widget.door == null || widget.door!.sceneId == null)
                    const _ChooseSceneMoveUnavailableState()
                  else
                    scenesState.when(
                      loading: () => const _ChooseSceneLoadingState(),
                      error: (_, _) => _ChooseSceneErrorState(
                        onRetry: () => ref.invalidate(homeScenesProvider),
                      ),
                      data: (scenes) => scenes.isEmpty
                          ? const _ChooseSceneEmptyState()
                          : _ChooseSceneList(
                              scenes: scenes,
                              currentSceneId: widget.door!.sceneId!,
                              onSceneSelected: _moveDoorToScene,
                            ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _moveDoorToScene(HomeScene scene) async {
    if (_isMoving) return;
    final door = widget.door;
    final doorId = door == null ? null : int.tryParse(door.id);
    final sourceSceneId = door?.sceneId;
    if (doorId == null || sourceSceneId == null || sourceSceneId == scene.id) {
      AppToast.error(
        context,
        AppLocalizations.of(context).chooseSceneMoveFailed,
      );
      return;
    }

    setState(() => _isMoving = true);
    final requestId =
        'home-move-door-$doorId-to-${scene.id}-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await ref.read(moveHomeDoorToSceneUseCaseProvider)(
        doorId: doorId,
        sceneId: scene.id,
        requestId: requestId,
      );
      ref.invalidate(homeDoorsBySceneProvider(sourceSceneId));
      ref.invalidate(homeDoorsBySceneProvider(scene.id));
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        final fallback =
            error is AppError && error.code == AppErrorCode.networkUnavailable
            ? AppLocalizations.of(context).chooseSceneMoveNetworkUnavailable
            : AppLocalizations.of(context).chooseSceneMoveFailed;
        final message = appErrorMessage(error, fallback);
        AppToast.error(context, message);
      }
    } finally {
      if (mounted) setState(() => _isMoving = false);
    }
  }
}

class _ChooseSceneList extends StatelessWidget {
  const _ChooseSceneList({
    required this.scenes,
    required this.currentSceneId,
    required this.onSceneSelected,
  });

  final List<HomeScene> scenes;
  final int currentSceneId;
  final ValueChanged<HomeScene> onSceneSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < scenes.length; index++) ...[
          _SceneCard(
            scene: scenes[index],
            selected: scenes[index].id == currentSceneId,
            onPressed: scenes[index].id == currentSceneId
                ? null
                : () => onSceneSelected(scenes[index]),
          ),
          if (index != scenes.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Divider(height: 18, color: AppColors.borderHomeDivider),
            ),
        ],
      ],
    );
  }
}

class _ChooseSceneMoveUnavailableState extends StatelessWidget {
  const _ChooseSceneMoveUnavailableState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: Center(
        child: Text(
          AppLocalizations.of(context).chooseSceneMoveUnavailable,
          style: AppTextTokens.sceneCardMeta(Theme.of(context).textTheme),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ChooseSceneLoadingState extends StatelessWidget {
  const _ChooseSceneLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 108,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ChooseSceneEmptyState extends StatelessWidget {
  const _ChooseSceneEmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: Center(
        child: Text(
          AppLocalizations.of(context).chooseSceneEmpty,
          style: AppTextTokens.sceneCardMeta(Theme.of(context).textTheme),
        ),
      ),
    );
  }
}

class _ChooseSceneErrorState extends StatelessWidget {
  const _ChooseSceneErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(
            AppLocalizations.of(context).chooseSceneLoadFailed,
            style: AppTextTokens.sceneCardMeta(Theme.of(context).textTheme),
          ),
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
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: onPressed != null,
      selected: selected,
      child: Material(
        color: AppColors.surfaceItemSceneCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: selected
                  ? Border.all(
                      color: AppColors.borderSelectedSceneCard,
                      width: 1,
                    )
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              children: [
                const _SceneIcon(),
                const SizedBox(width: 16),
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
                      const SizedBox(height: 12),
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
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.home_outlined,
          color: AppColors.iconHomeAction,
          size: 38,
        );
      },
    );
  }
}
