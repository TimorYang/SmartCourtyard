import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error_message.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../../domain/entities/home_scene.dart';
import '../widgets/scene_name_dialog.dart';
import '../widgets/scene_rename_dialog.dart';

class SceneAssetPaths {
  const SceneAssetPaths._();

  static const warehousePlaceholder =
      'assets/icons/home/scene_warehouse_placeholder.png';
  static const warehousePlaceholderOther =
      'assets/icons/home/scene_warehouse_placeholder_other.png';
  static const editPlaceholder = 'assets/icons/home/scene_edit_placeholder.png';
  static const editDonePlaceholder =
      'assets/icons/home/scene_edit_done_placeholder.png';
}

class ScenePage extends ConsumerStatefulWidget {
  const ScenePage({super.key});

  static const routeName = 'scene';
  static const routePath = '/scene';

  @override
  ConsumerState<ScenePage> createState() => _ScenePageState();
}

class _ScenePageState extends ConsumerState<ScenePage> {
  var _isEditing = false;
  final _deletingSceneIds = <int>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scenesState = ref.watch(homeScenesProvider);
    final sceneCount = scenesState.asData?.value.length ?? 0;

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
            icon: _SceneEditActionIcon(
              assetPath: _isEditing
                  ? SceneAssetPaths.editDonePlaceholder
                  : SceneAssetPaths.editPlaceholder,
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
              l10n.sceneCount(sceneCount),
              style: AppTextTokens.sceneBreadcrumb(textTheme),
            ),
          ),
          const SizedBox(height: 46),
          scenesState.when(
            data: (scenes) => _SceneList(
              scenes: scenes,
              isEditing: _isEditing,
              deletingSceneIds: _deletingSceneIds,
              onCreateScene: () => unawaited(_showCreateSceneDialog()),
              onDeleteScene: (scene) => unawaited(_deleteScene(scene)),
              onRenameScene: (scene) =>
                  unawaited(_showRenameSceneDialog(scene)),
            ),
            loading: () => const _SceneLoadingState(),
            error: (error, stackTrace) => _SceneErrorState(
              onRetry: () => ref.invalidate(homeScenesProvider),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateSceneDialog() async {
    await showSceneNameDialog(context);
    if (mounted) {
      ref.invalidate(homeScenesProvider);
    }
  }

  Future<void> _showRenameSceneDialog(HomeScene scene) async {
    await showSceneRenameDialog(context, scene: scene);
    if (mounted) {
      ref.invalidate(homeScenesProvider);
    }
  }

  Future<void> _deleteScene(HomeScene scene) async {
    if (_deletingSceneIds.contains(scene.id)) {
      return;
    }
    setState(() {
      _deletingSceneIds.add(scene.id);
    });
    final requestId =
        'home-delete-scene-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    try {
      await ref.read(deleteHomeSceneUseCaseProvider)(
        sceneId: scene.id,
        requestId: requestId,
      );
      ref.invalidate(homeScenesProvider);
    } catch (error) {
      if (mounted) {
        AppToast.error(
          context,
          appErrorMessage(
            error,
            AppLocalizations.of(context).sceneDeleteFailed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingSceneIds.remove(scene.id);
        });
      }
    }
  }
}

class _SceneList extends StatelessWidget {
  const _SceneList({
    required this.scenes,
    required this.isEditing,
    required this.deletingSceneIds,
    required this.onCreateScene,
    required this.onDeleteScene,
    required this.onRenameScene,
  });

  final List<HomeScene> scenes;
  final bool isEditing;
  final Set<int> deletingSceneIds;
  final VoidCallback onCreateScene;
  final ValueChanged<HomeScene> onDeleteScene;
  final ValueChanged<HomeScene> onRenameScene;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, scene) in scenes.indexed) ...[
          _SceneCard(
            scene: scene,
            showDeleteAction: isEditing && index > 0,
            isDeleting: deletingSceneIds.contains(scene.id),
            onDelete: () => onDeleteScene(scene),
            onRename: () => onRenameScene(scene),
            indexNumber: index,
          ),
          const SizedBox(height: 16),
        ],
        if (!isEditing) ...[
          const SizedBox(height: 2),
          _NewSceneCard(onPressed: onCreateScene),
        ],
      ],
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.scene,
    required this.showDeleteAction,
    required this.isDeleting,
    required this.onDelete,
    required this.onRename,
    required this.indexNumber,
  });

  final HomeScene scene;
  final bool showDeleteAction;
  final bool isDeleting;
  final int indexNumber;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onRename,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.surfaceItemSceneCard,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          children: [
            if (showDeleteAction) ...[
              _DeleteSceneButton(isDeleting: isDeleting, onPressed: onDelete),
              const SizedBox(width: 15),
            ],
            _SceneIcon(
              assetPath: indexNumber == 0
                  ? SceneAssetPaths.warehousePlaceholder
                  : SceneAssetPaths.warehousePlaceholderOther,
              icon: Icons.home_outlined,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scene.name.trim().isEmpty ? 'Home' : scene.name.trim(),
                    style: AppTextTokens.sceneCardTitle(textTheme),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.sceneDeviceCount(scene.doorCount),
                    style: AppTextTokens.sceneCardMeta(textTheme),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneLoadingState extends StatelessWidget {
  const _SceneLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 88,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SceneErrorState extends StatelessWidget {
  const _SceneErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 120,
      child: Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(
            'Failed to load scenes',
            style: AppTextTokens.sceneCardMeta(textTheme),
          ),
        ),
      ),
    );
  }
}

class _SceneEditActionIcon extends StatelessWidget {
  const _SceneEditActionIcon({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}

class _DeleteSceneButton extends StatelessWidget {
  const _DeleteSceneButton({required this.isDeleting, required this.onPressed});

  final bool isDeleting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isDeleting ? null : onPressed,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.sceneDeleteAction,
          shape: BoxShape.circle,
        ),
        child: isDeleting
            ? const Padding(
                padding: EdgeInsets.all(5),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.backgroundPrimary,
                ),
              )
            : const Icon(
                Icons.remove_rounded,
                color: AppColors.backgroundPrimary,
                size: 24,
              ),
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
