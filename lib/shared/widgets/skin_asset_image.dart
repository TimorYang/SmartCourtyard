import 'package:flutter/material.dart';
import '../../app/theme/app_skin_catalog.dart';
import '../l10n/app_localizations.dart';

class SkinAssetImage extends StatelessWidget {
  const SkinAssetImage({
    required this.assetPath,
    required this.fallback,
    this.semanticLabel,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.excludeFromSemantics = false,
    super.key,
  });

  static Image themed(
    BuildContext context,
    String path, {
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
    bool gaplessPlayback = false,
    bool excludeFromSemantics = false,
    String? semanticLabel,
    ImageErrorWidgetBuilder? errorBuilder,
    ImageFrameBuilder? frameBuilder,
    FilterQuality filterQuality = FilterQuality.medium,
    bool matchTextDirection = false,
  }) {
    final resolved = AppSkinAssets(context.skin.id).resolve(path);
    return Image.asset(
      resolved,
      key: key,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      gaplessPlayback: gaplessPlayback,
      excludeFromSemantics: excludeFromSemantics,
      semanticLabel: semanticLabel,
      frameBuilder: frameBuilder,
      filterQuality: filterQuality,
      matchTextDirection: matchTextDirection,
      errorBuilder: (context, error, stackTrace) {
        if (resolved == path && errorBuilder != null) {
          return errorBuilder(context, error, stackTrace);
        }
        return Semantics(
          label: AppLocalizations.of(context).appearanceAssetPending,
          child: SizedBox(
            width: width,
            height: height,
            child: ColoredBox(
              color: context.skin.surfaceMuted,
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  color: context.skin.textMuted,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  final String assetPath;
  final Widget fallback;
  final String? semanticLabel;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) =>
          SizedBox(width: width, height: height, child: fallback),
    );
  }
}
