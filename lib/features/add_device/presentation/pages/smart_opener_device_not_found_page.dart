import '../../../../shared/widgets/skin_asset_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../home/presentation/pages/home_page.dart';
import 'smart_opener_ble_scan_page.dart';

class SmartOpenerDeviceNotFoundPage extends StatelessWidget {
  const SmartOpenerDeviceNotFoundPage({super.key});

  static const routeName = 'smart-opener-device-not-found';
  static const routePath = '/add-device/smart-opener/device-not-found';
  static const artAssetPath =
      'assets/icons/add_device/smart_opener_device_not_found_art.png';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(43, 54, 43, 48),
              children: [
                Center(
                  child: SkinAssetImage.themed(
                    context,
                    artAssetPath,
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        _MissingDeviceFallbackArt(size: 300),
                  ),
                ),
                const SizedBox(height: 38),
                Text(
                  l10n.smartOpenerDeviceNotFoundTitle,
                  textAlign: TextAlign.center,
                  style: context.appText.smartOpenerConnectingTitle(textTheme),
                ),
                const SizedBox(height: 9),
                Text(
                  l10n.smartOpenerDeviceNotFoundDescription,
                  textAlign: TextAlign.center,
                  style: context.appText.smartOpenerBodyCenter(textTheme),
                ),
                SizedBox(height: constraints.maxHeight < 660 ? 48 : 78),
                _SmartOpenerWideButton(
                  label: l10n.smartOpenerRescanAction,
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop(true);
                      return;
                    }
                    context.go(SmartOpenerBleScanPage.routePath);
                  },
                ),
                const SizedBox(height: 19),
                _SmartOpenerWideButton(
                  label: l10n.smartOpenerBackHomeAction,
                  isPrimary: false,
                  onPressed: () => context.go(HomePage.routePath),
                ),
                const SizedBox(height: 36),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MissingDeviceFallbackArt extends StatelessWidget {
  const _MissingDeviceFallbackArt({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 6; i += 1)
            Container(
              width: (size * 0.26) + (i * size * 0.13),
              height: (size * 0.26) + (i * size * 0.13),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.borderSubtle),
              ),
            ),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: context.colors.smartOpenerWarning,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              color: context.colors.authPrimaryButtonDisabledForeground,
              size: 54,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartOpenerWideButton extends StatelessWidget {
  const _SmartOpenerWideButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isPrimary
              ? context.colors.brandPrimary
              : context.colors.smartOpenerSecondaryButton,
          foregroundColor: isPrimary
              ? context.colors.authPrimaryButtonDisabledForeground
              : context.colors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(34),
          ),
        ),
        child: Text(
          label,
          style: isPrimary
              ? context.appText.smartOpenerActionButton(textTheme)
              : context.appText.smartOpenerSecondaryActionButton(textTheme),
        ),
      ),
    );
  }
}
