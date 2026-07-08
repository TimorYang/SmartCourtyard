import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import 'smart_opener_qr_scan_page.dart';

class SmartOpenerScanAssetPaths {
  const SmartOpenerScanAssetPaths._();

  static const qrLabel = 'assets/icons/add_device/smart_opener_qr_label.png';
  static const scanningAnimation =
      'assets/animations/add_device/js_scan_device.json';
  static const scanningImageDirectory =
      'assets/icons/add_device/lottie_js_scan_device';
}

class SmartOpenerScanGuidePage extends StatelessWidget {
  const SmartOpenerScanGuidePage({super.key});

  static const routeName = 'smart-opener-scan-guide';
  static const routePath = '/add-device/smart-opener/scan-guide';

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 48, 30, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.smartOpenerScanTitle,
                style: AppTextTokens.smartOpenerScanTitle(textTheme),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.smartOpenerScanDescription,
                style: AppTextTokens.smartOpenerScanDescription(textTheme),
              ),
              const Spacer(flex: 2),
              Center(
                child: Image.asset(
                  SmartOpenerScanAssetPaths.qrLabel,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: FilledButton(
                  onPressed: () =>
                      context.push(SmartOpenerQrScanPage.routePath),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    textStyle: AppTextTokens.smartOpenerPrimaryButton(
                      textTheme,
                    ),
                  ),
                  child: Text(l10n.smartOpenerScanAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
