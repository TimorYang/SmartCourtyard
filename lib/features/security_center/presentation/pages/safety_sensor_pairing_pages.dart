import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import 'safety_sensors_evaluation_page.dart';

class SafetySensorPairingGuidePage extends StatelessWidget {
  const SafetySensorPairingGuidePage({
    required this.doorId,
    required this.deviceId,
    super.key,
  });

  static const routeName = 'safety-sensor-pairing-guide';
  static const routePath = '/safety-sensors/pairing/guide';
  static const guideAsset =
      'assets/icons/security_center/safety_sensor_pairing_bluetooth_guide.png';

  final String doorId;
  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _PairingScaffold(
      title: l10n.safetySensorPairingTitle,
      onBackPressed: () =>
          _returnToEvaluation(context, doorId: doorId, deviceId: deviceId),
      body: _PairingContent(
        illustration: _PairingIllustration(assetPath: guideAsset),
        status: l10n.safetySensorPairingBluetoothEnabled,
        description: l10n.safetySensorPairingGuideDescription,
      ),
      action: _PairingActionButton(
        key: const ValueKey<String>('safety-sensor-pairing-start'),
        label: l10n.safetySensorPairingStart,
        onPressed: () => context.pushReplacement(
          safetySensorPairingMatchingLocation(
            doorId: doorId,
            deviceId: deviceId,
          ),
        ),
      ),
    );
  }
}

class SafetySensorPairingMatchingPage extends StatefulWidget {
  const SafetySensorPairingMatchingPage({
    required this.doorId,
    required this.deviceId,
    super.key,
  });

  static const routeName = 'safety-sensor-pairing-matching';
  static const routePath = '/safety-sensors/pairing/matching';
  static const matchingAsset =
      'assets/icons/security_center/safety_sensor_pairing_hold_button.png';

  final String doorId;
  final String deviceId;

  @override
  State<SafetySensorPairingMatchingPage> createState() =>
      _SafetySensorPairingMatchingPageState();
}

class _SafetySensorPairingMatchingPageState
    extends State<SafetySensorPairingMatchingPage> {
  Timer? _completionTimer;

  @override
  void initState() {
    super.initState();
    _completionTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      context.pushReplacement(
        safetySensorPairingSuccessLocation(
          doorId: widget.doorId,
          deviceId: widget.deviceId,
        ),
      );
    });
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    super.dispose();
  }

  void _exitPairing() {
    _returnToEvaluation(
      context,
      doorId: widget.doorId,
      deviceId: widget.deviceId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _exitPairing();
        }
      },
      child: _PairingScaffold(
        title: l10n.safetySensorPairingTitle,
        onBackPressed: _exitPairing,
        body: _PairingContent(
          illustration: _PairingIllustration(
            assetPath: SafetySensorPairingMatchingPage.matchingAsset,
          ),
          status: l10n.safetySensorPairingInProgress,
          description: l10n.safetySensorPairingMatchingDescription,
        ),
        action: _PairingActionButton(
          key: const ValueKey<String>('safety-sensor-pairing-cancel'),
          label: l10n.safetySensorPairingCancel,
          primary: false,
          onPressed: _exitPairing,
        ),
      ),
    );
  }
}

class SafetySensorPairingSuccessPage extends StatelessWidget {
  const SafetySensorPairingSuccessPage({
    required this.doorId,
    required this.deviceId,
    super.key,
  });

  static const routeName = 'safety-sensor-pairing-success';
  static const routePath = '/safety-sensors/pairing/success';

  final String doorId;
  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void complete() =>
        _returnToEvaluation(context, doorId: doorId, deviceId: deviceId);
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          complete();
        }
      },
      child: _PairingScaffold(
        title: l10n.safetySensorPairingTitle,
        onBackPressed: complete,
        body: _PairingContent(
          illustration: const _PairingSuccessIndicator(),
          status: l10n.safetySensorPairingSuccess,
        ),
        action: _PairingActionButton(
          key: const ValueKey<String>('safety-sensor-pairing-complete'),
          label: l10n.safetySensorPairingComplete,
          onPressed: complete,
        ),
      ),
    );
  }
}

class _PairingScaffold extends StatelessWidget {
  const _PairingScaffold({
    required this.title,
    required this.onBackPressed,
    required this.body,
    required this.action,
  });

  final String title;
  final VoidCallback onBackPressed;
  final Widget body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.safetySensorPairingBackground,
      appBar: FlinxNavigationBar(
        title: '',
        showBottomDivider: false,
        onBackPressed: onBackPressed,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: AppTextTokens.sharedDevicesTitle(textTheme),
                ),
              ),
            ),
            Expanded(child: body),
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: SizedBox(width: double.infinity, child: action),
            ),
          ],
        ),
      ),
    );
  }
}

class _PairingContent extends StatelessWidget {
  const _PairingContent({
    required this.illustration,
    required this.status,
    this.description,
  });

  final Widget illustration;
  final String status;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Column(
          children: [
            SizedBox(height: 230, child: Center(child: illustration)),
            const SizedBox(height: 45),
            Text(
              status,
              textAlign: TextAlign.center,
              style: AppTextTokens.safetySensorPairingStatus(textTheme),
            ),
            if (description != null) ...[
              const SizedBox(height: 22),
              Text(
                description!,
                textAlign: TextAlign.left,
                style: AppTextTokens.safetySensorPairingBody(textTheme),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PairingIllustration extends StatelessWidget {
  const _PairingIllustration({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      key: ValueKey<String>('safety-sensor-pairing-asset-$assetPath'),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          _PairingAssetPlaceholder(assetPath: assetPath),
    );
  }
}

class _PairingAssetPlaceholder extends StatelessWidget {
  const _PairingAssetPlaceholder({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.safetySensorPairingImagePlaceholder,
      child: Container(
        key: ValueKey<String>('safety-sensor-pairing-placeholder-$assetPath'),
        width: 220,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.safetySensorPairingPlaceholderSurface,
          borderRadius: BorderRadius.circular(
            AppShapeTokens.safetySensorPairingPlaceholderRadius,
          ),
        ),
        child: Icon(
          Icons.image_outlined,
          color: AppColors.safetySensorPairingPlaceholderForeground,
          size: 56,
        ),
      ),
    );
  }
}

class _PairingSuccessIndicator extends StatelessWidget {
  const _PairingSuccessIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: const BoxDecoration(
        color: AppColors.safetySensorPairingSuccess,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 78),
    );
  }
}

class _PairingActionButton extends StatelessWidget {
  const _PairingActionButton({
    required this.label,
    required this.onPressed,
    this.primary = true,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 48,
      child: Padding(
        padding: EdgeInsetsGeometry.only(left: 30, right: 30),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: primary
                ? AppColors.safetySensorPairingPrimaryAction
                : AppColors.safetySensorPairingSecondaryAction,
            foregroundColor: primary
                ? Colors.white
                : AppColors.safetySensorPairingSecondaryForeground,
            overlayColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppShapeTokens.safetySensorPairingActionRadius,
              ),
            ),
          ),
          child: Text(
            label,
            style: primary
                ? AppTextTokens.safetySensorPairingAction(textTheme)
                : AppTextTokens.safetySensorPairingSecondaryAction(textTheme),
          ),
        ),
      ),
    );
  }
}

String safetySensorPairingGuideLocation({
  required String doorId,
  required String deviceId,
}) =>
    _pairingLocation(SafetySensorPairingGuidePage.routePath, doorId, deviceId);

String safetySensorPairingMatchingLocation({
  required String doorId,
  required String deviceId,
}) => _pairingLocation(
  SafetySensorPairingMatchingPage.routePath,
  doorId,
  deviceId,
);

String safetySensorPairingSuccessLocation({
  required String doorId,
  required String deviceId,
}) => _pairingLocation(
  SafetySensorPairingSuccessPage.routePath,
  doorId,
  deviceId,
);

String _pairingLocation(String routePath, String doorId, String deviceId) =>
    '$routePath?doorId=${Uri.encodeQueryComponent(doorId)}'
    '&deviceId=${Uri.encodeQueryComponent(deviceId)}';

void _returnToEvaluation(
  BuildContext context, {
  required String doorId,
  required String deviceId,
}) {
  if (Navigator.of(context).canPop()) {
    context.pop();
    return;
  }
  context.go(
    _pairingLocation(SafetySensorsEvaluationPage.routePath, doorId, deviceId),
  );
}
