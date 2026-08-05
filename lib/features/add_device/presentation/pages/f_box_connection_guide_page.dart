import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
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
      backgroundColor: AppColors.backgroundPrimary,
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
                    style: AppTextTokens.smartOpenerScanTitle(textTheme),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    l10n.fBoxConnectionGuideInstructions,
                    style: AppTextTokens.fBoxConnectionInstructions(textTheme),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.fBoxConnectionGuideManualHint,
                    style: AppTextTokens.fBoxConnectionManualHint(textTheme),
                  ),
                  const SizedBox(height: 110),
                  Image.asset(
                    FBoxConnectionGuideAssetPaths.connectionGuide,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.iconHomeAction,
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
                  onPressed: () =>
                      context.push(SmartOpenerScanGuidePage.routePath),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    textStyle: AppTextTokens.smartOpenerPrimaryButton(
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
