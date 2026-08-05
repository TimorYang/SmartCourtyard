import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import 'smart_opener_scan_guide_page.dart';

class UsbDongleGuideAssetPaths {
  const UsbDongleGuideAssetPaths._();

  static const standardInsert =
      'assets/icons/add_device/usb_dongle_guide_standard_insert.png';
  static const standardIndicator =
      'assets/icons/add_device/usb_dongle_guide_standard_indicator.png';
  static const industrialInsert =
      'assets/icons/add_device/usb_dongle_guide_industrial_insert.png';
  static const industrialIndicator =
      'assets/icons/add_device/usb_dongle_guide_industrial_indicator.png';

  static String insertFor(DoorType doorType) {
    return doorType == DoorType.industrial ? industrialInsert : standardInsert;
  }

  static String indicatorFor(DoorType doorType) {
    return doorType == DoorType.industrial
        ? industrialIndicator
        : standardIndicator;
  }
}

class UsbDongleGuidePage extends StatelessWidget {
  const UsbDongleGuidePage({super.key, required this.doorType});

  static const routeName = 'usb-dongle-guide';
  static const routePath = '/add-device/usb-dongle/guide';

  final DoorType doorType;

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
                  _GuideStep(
                    title: l10n.usbDongleGuideInsertTitle,
                    description: l10n.usbDongleGuideInsertDescription,
                    assetPath: UsbDongleGuideAssetPaths.insertFor(doorType),
                  ),
                  const SizedBox(height: 36),
                  _GuideStep(
                    title: l10n.usbDongleGuideIndicatorTitle,
                    description: l10n.usbDongleGuideIndicatorDescription,
                    assetPath: UsbDongleGuideAssetPaths.indicatorFor(doorType),
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
                  child: Text(l10n.usbDongleGuideSearchDeviceAction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.title,
    required this.description,
    required this.assetPath,
  });

  final String title;
  final String description;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextTokens.smartOpenerScanTitle(textTheme)),
        const SizedBox(height: 11),
        Text(
          description,
          style: AppTextTokens.smartOpenerScanDescription(textTheme),
        ),
        const SizedBox(height: 28),
        Center(
          child: Image.asset(
            assetPath,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.iconHomeAction,
              size: 96,
            ),
          ),
        ),
      ],
    );
  }
}
