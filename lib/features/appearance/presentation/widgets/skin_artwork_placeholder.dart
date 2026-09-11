import 'package:flutter/material.dart';
import '../../../../app/theme/app_appearance_tokens.dart';
import '../../../../app/theme/app_skin_catalog.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/skin_asset_image.dart';
import '../../domain/entities/app_skin_id.dart';

class SkinArtworkPlaceholder extends StatelessWidget {
  const SkinArtworkPlaceholder({
    required this.skinId,
    required this.height,
    this.compact = false,
    super.key,
  });
  final AppSkinId skinId;
  final double height;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final skin = AppSkinCatalog.forId(skinId);
    final path = AppSkinAssets(skinId).themePreview;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppAppearanceLayoutTokens.cardRadius),
      child: SkinAssetImage(
        key: ValueKey(path),
        assetPath: path,
        height: height,
        width: double.infinity,
        fit: BoxFit.contain,
        semanticLabel: AppLocalizations.of(context).appearanceArtworkPending,
        fallback: ColoredBox(
          color: skin.pageBackground,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(
                AppAppearanceLayoutTokens.cardPadding,
              ),
              child: Text(
                AppLocalizations.of(context).appearanceArtworkPending,
                textAlign: TextAlign.center,
                style: AppAppearanceTextTokens.placeholder(
                  Theme.of(context).textTheme,
                  skin,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
