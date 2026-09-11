import '../../../../shared/widgets/skin_asset_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import 'add_device_page.dart';
import 'smart_opener_scan_guide_page.dart';

class FBoxConnectionGuideAssetPaths {
  const FBoxConnectionGuideAssetPaths._();

  static const connectionGuide =
      'assets/icons/add_device/f_box_connection_guide.png';
}

class FBoxConnectionGuidePage extends StatelessWidget {
  const FBoxConnectionGuidePage({super.key});

  static const routeName = 'f-box-connection-guide';
  static const routePath = '/add-device/f-box/connection-guide';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      appBar: FlinxNavigationBar(
        title: '',
        showBottomDivider: false,
        automaticallyImplyLeading: context.canPop(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 35, 20, 24),
                children: [
                  Text(
                    l10n.fBoxConnectionGuideTitle,
                    style: context.appText.smartOpenerScanTitle(textTheme),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    l10n.fBoxConnectionGuideInstructions,
                    style: context.appText.fBoxConnectionInstructions(
                      textTheme,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.fBoxConnectionGuideManualHint,
                    style: context.appText.fBoxConnectionManualHint(textTheme),
                  ),
                  const SizedBox(height: 110),
                  SkinAssetImage.themed(
                    context,
                    FBoxConnectionGuideAssetPaths.connectionGuide,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_not_supported_outlined,
                      color: context.colors.iconHomeAction,
                      size: 96,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => context.pushNamed(
                    SmartOpenerScanGuidePage.routeName,
                    queryParameters: {
                      AddDevicePage.deviceTypeQueryParameter: 'fbox',
                    },
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.brandPrimary,
                    foregroundColor:
                        context.colors.authPrimaryButtonDisabledForeground,
                    shape: const StadiumBorder(),
                    textStyle: context.appText.smartOpenerPrimaryButton(
                      textTheme,
                    ),
                  ),
                  child: Text(l10n.fBoxConnectionGuideNextAction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
