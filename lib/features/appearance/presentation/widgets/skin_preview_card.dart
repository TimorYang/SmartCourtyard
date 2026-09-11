import 'package:flutter/material.dart';

import '../../../../app/theme/app_appearance_tokens.dart';
import '../../../../app/theme/app_skin_catalog.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../domain/entities/app_skin_id.dart';
import 'skin_artwork_placeholder.dart';

class SkinPreviewCard extends StatelessWidget {
  const SkinPreviewCard({
    required this.skinId,
    required this.selected,
    required this.onPreview,
    super.key,
  });

  final AppSkinId skinId;
  final bool selected;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      label: _title(l10n),
      child: Material(
        color: context.appearanceColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppAppearanceLayoutTokens.cardRadius),
          ),
          side: BorderSide(
            color: selected
                ? context.appearanceColors.previewActionForeground
                : Colors.transparent,
            width: selected ? 1.5 : 0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('skin-card-${skinId.storageValue}'),
          onTap: onPreview,
          child: Padding(
            padding: const EdgeInsets.all(
              AppAppearanceLayoutTokens.cardPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkinArtworkPlaceholder(
                  skinId: skinId,
                  height: AppAppearanceLayoutTokens.cardPreviewHeight,
                  compact: true,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title(l10n),
                            style: AppAppearanceTextTokens.cardTitle(
                              textTheme,
                              context.skin,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _description(l10n),
                            style: AppAppearanceTextTokens.cardDescription(
                              textTheme,
                              context.skin,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onPreview,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(72, 44),
                        backgroundColor:
                            context.appearanceColors.previewActionSurface,
                        foregroundColor:
                            context.appearanceColors.previewActionForeground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppAppearanceLayoutTokens.previewActionRadius,
                          ),
                        ),
                      ),
                      child: Text(l10n.appearancePreviewAction),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _tags(
                    l10n,
                  ).map((tag) => _SkinTag(label: tag)).toList(growable: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n) => switch (skinId) {
    AppSkinId.dark => l10n.appearanceDarkTitle,
    AppSkinId.minimalist => l10n.appearanceMinimalistTitle,
    AppSkinId.technologyWind => l10n.appearanceTechnologyWindTitle,
  };

  String _description(AppLocalizations l10n) => switch (skinId) {
    AppSkinId.dark => l10n.appearanceDarkDescription,
    AppSkinId.minimalist => l10n.appearanceMinimalistDescription,
    AppSkinId.technologyWind => l10n.appearanceTechnologyWindDescription,
  };

  List<String> _tags(AppLocalizations l10n) => switch (skinId) {
    AppSkinId.dark => [
      l10n.appearanceDarkTagMood,
      l10n.appearanceDarkTagComfort,
    ],
    AppSkinId.minimalist => [
      l10n.appearanceMinimalistTagClean,
      l10n.appearanceMinimalistTagFocus,
    ],
    AppSkinId.technologyWind => [
      l10n.appearanceTechnologyTagShine,
      l10n.appearanceTechnologyTagData,
    ],
  };
}

class _SkinTag extends StatelessWidget {
  const _SkinTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appearanceColors.tagSurface,
        borderRadius: BorderRadius.circular(
          AppAppearanceLayoutTokens.tagRadius,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.appearanceColors.tagForeground,
          ),
        ),
      ),
    );
  }
}
