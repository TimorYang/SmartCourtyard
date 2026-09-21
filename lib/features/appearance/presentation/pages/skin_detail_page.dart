import '../../../../app/theme/app_skin_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_appearance_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../application/providers.dart';
import '../../domain/entities/app_skin_id.dart';
import '../widgets/skin_artwork_placeholder.dart';

class SkinDetailPage extends ConsumerStatefulWidget {
  const SkinDetailPage({required this.skinId, super.key});

  static const routeName = 'skin-detail';
  static const routePath = '/account/appearance/:skinId';

  final AppSkinId skinId;

  static String routePathFor(AppSkinId skinId) =>
      '/account/appearance/${skinId.storageValue}';

  @override
  ConsumerState<SkinDetailPage> createState() => _SkinDetailPageState();
}

class _SkinDetailPageState extends ConsumerState<SkinDetailPage> {
  var _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected =
        ref.watch(appSkinControllerProvider).value ?? AppSkinId.minimalist;
    return Scaffold(
      backgroundColor: context.appearanceColors.pageBackground,
      appBar: AppBar(
        backgroundColor: context.appearanceColors.pageBackground,
        foregroundColor: context.skin.textPrimary,
        title: const SizedBox.shrink(),
        shape: const Border(),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppAppearanceLayoutTokens.pageHorizontalPadding,
            0,
            AppAppearanceLayoutTokens.pageHorizontalPadding,
            24,
          ),
          children: [
            Text(
              _title(l10n),
              style: AppAppearanceTextTokens.pageTitle(
                Theme.of(context).textTheme,
                context.skin,
              ),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.appearanceColors.cardSurface,
                borderRadius: BorderRadius.circular(
                  AppAppearanceLayoutTokens.cardRadius,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: SkinArtworkPlaceholder(
                  skinId: widget.skinId,
                  height: AppAppearanceLayoutTokens.detailPreviewHeight,
                  detail: true,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Semantics(
              label: l10n.appearanceSelectedLabel,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final skinId in AppSkinId.values) ...[
                    Container(
                      width: AppAppearanceLayoutTokens.pageIndicatorSize,
                      height: AppAppearanceLayoutTokens.pageIndicatorSize,
                      decoration: BoxDecoration(
                        color: skinId == widget.skinId
                            ? context.appearanceColors.applyAction
                            : context.appearanceColors.pageIndicatorInactive,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (skinId != AppSkinId.values.last)
                      const SizedBox(width: 18),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: AppAppearanceLayoutTokens.controlHeight,
              child: FilledButton(
                key: const ValueKey('skin-apply-button'),
                onPressed: _saving || selected == widget.skinId ? null : _apply,
                style: FilledButton.styleFrom(
                  backgroundColor: context.appearanceColors.applyAction,
                  foregroundColor: context.skin.onBrand,
                  disabledBackgroundColor: context.appearanceColors.applyAction
                      .withValues(alpha: 0.55),
                  shape: const StadiumBorder(),
                ),
                child: _saving
                    ? SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.skin.onBrand,
                        ),
                      )
                    : Text(
                        selected == widget.skinId
                            ? l10n.appearanceAppliedAction
                            : l10n.appearanceApplyAction,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apply() async {
    setState(() => _saving = true);
    final saved = await ref
        .read(appSkinControllerProvider.notifier)
        .applySkin(widget.skinId);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!saved) {
      AppToast.error(
        context,
        AppLocalizations.of(context).appearanceApplyFailed,
      );
    }
  }

  String _title(AppLocalizations l10n) => switch (widget.skinId) {
    AppSkinId.dark => l10n.appearanceDarkTitle,
    AppSkinId.minimalist => l10n.appearanceMinimalistTitle,
    AppSkinId.technologyWind => l10n.appearanceTechnologyWindTitle,
  };
}
