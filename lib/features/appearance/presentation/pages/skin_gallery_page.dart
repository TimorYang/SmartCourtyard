import '../../../../app/theme/app_skin_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_appearance_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../application/providers.dart';
import '../../domain/entities/app_skin_id.dart';
import '../widgets/skin_preview_card.dart';
import 'skin_detail_page.dart';

class SkinGalleryPage extends ConsumerWidget {
  const SkinGalleryPage({super.key});

  static const routeName = 'skin-gallery';
  static const routePath = '/account/appearance';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppAppearanceLayoutTokens.pageHorizontalPadding,
          0,
          AppAppearanceLayoutTokens.pageHorizontalPadding,
          28,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.appearanceGalleryTitle,
                      maxLines: 1,
                      style: AppAppearanceTextTokens.pageTitle(
                        Theme.of(context).textTheme,
                        context.skin,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.appearanceGallerySubtitle,
                      maxLines: 1,
                      style: AppAppearanceTextTokens.gallerySubtitle(
                        Theme.of(context).textTheme,
                        context.skin,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final skinId in AppSkinId.values) ...[
            SkinPreviewCard(
              skinId: skinId,
              selected: skinId == selected,
              onPreview: () =>
                  context.push(SkinDetailPage.routePathFor(skinId)),
            ),
            if (skinId != AppSkinId.values.last)
              const SizedBox(height: AppAppearanceLayoutTokens.sectionSpacing),
          ],
        ],
      ),
    );
  }
}
