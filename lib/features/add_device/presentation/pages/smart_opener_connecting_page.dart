import '../../../../shared/widgets/skin_asset_image.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import 'smart_opener_scan_results_page.dart';
import 'smart_opener_connection_success_page.dart';

class SmartOpenerConnectingPage extends ConsumerStatefulWidget {
  const SmartOpenerConnectingPage({super.key, required this.isWifiSkipped});

  static const routeName = 'smart-opener-connecting';
  static const routePath = '/add-device/smart-opener/connecting';

  final bool isWifiSkipped;

  @override
  ConsumerState<SmartOpenerConnectingPage> createState() =>
      _SmartOpenerConnectingPageState();
}

class _SmartOpenerConnectingPageState
    extends ConsumerState<SmartOpenerConnectingPage>
    with SingleTickerProviderStateMixin {
  var _started = false;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_configureWifi());
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _configureWifi() async {
    if (_started) {
      return;
    }
    _started = true;
    final ok = await ref
        .read(addDeviceControllerProvider.notifier)
        .configureWifi(isWifiSkipped: widget.isWifiSkipped);
    if (!mounted) {
      return;
    }
    if (ok) {
      context.pushReplacement(SmartOpenerConnectionSuccessPage.routePath);
      return;
    }

    _progressController.stop();
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Text(l10n.smartOpenerConnectionFailedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.smartOpenerOkAction),
          ),
        ],
      ),
    );
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _confirmStop() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: context.colors.overlayMedium,
      builder: (context) => const _StopAdditionSheet(),
    );
    if (!mounted || confirmed != true) {
      return;
    }
    context.go(SmartOpenerScanResultsPage.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(_confirmStop());
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.backgroundPrimary,
        appBar: FlinxNavigationBar(
          title: '',
          showBottomDivider: false,
          actions: const [],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final artHeight = (constraints.maxHeight * 0.42)
                .clamp(250.0, 470.0)
                .toDouble();
            final artWidth = (constraints.maxWidth - 68).clamp(260.0, 395.0);

            return SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                children: [
                  Center(
                    child: SkinAssetImage.themed(
                      context,
                      _SmartOpenerConnectingAssets.art,
                      width: artWidth,
                      height: artHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _ConnectingFallbackArt(
                            width: artWidth,
                            height: artHeight,
                          ),
                    ),
                  ),
                  const SizedBox(height: 80),
                  Text(
                    l10n.smartOpenerConnectingTitle,
                    textAlign: TextAlign.center,
                    style: context.appText.smartOpenerConnectingTitle(
                      textTheme,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsetsGeometry.only(left: 50, right: 50),
                    child: _ConnectingProgressBar(
                      animation: _progressController,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                    child: Text(
                      l10n.smartOpenerConnectingTip,
                      textAlign: TextAlign.center,
                      style: context.appText.smartOpenerBodyCenter(textTheme),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SmartOpenerConnectingAssets {
  const _SmartOpenerConnectingAssets._();

  static const art = 'assets/icons/add_device/smart_opener_connecting_art.png';
}

class _ConnectingProgressBar extends StatelessWidget {
  const _ConnectingProgressBar({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 353,
          height: 10,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) => LinearProgressIndicator(
              value: animation.value * 0.95,
              backgroundColor: context.colors.smartOpenerProgressTrack,
              color: context.colors.brandPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectingFallbackArt extends StatelessWidget {
  const _ConnectingFallbackArt({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: height * 0.64,
            height: height * 0.64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.scanRadarTint,
            ),
          ),
          Icon(
            Icons.settings_remote_outlined,
            size: height * 0.32,
            color: context.colors.textPrimary,
          ),
          Positioned(
            right: width * 0.12,
            bottom: height * 0.15,
            child: Icon(
              Icons.phone_iphone_outlined,
              size: height * 0.25,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopAdditionSheet extends StatelessWidget {
  const _StopAdditionSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.backgroundPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(38, 48, 38, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.smartOpenerStopAdditionTitle,
                style: context.appText.smartOpenerSheetTitle(textTheme),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.smartOpenerStopAdditionDescription,
                style: context.appText
                    .smartOpenerBodyCenter(textTheme)
                    .copyWith(fontSize: 17),
              ),
              const SizedBox(height: 35),
              Row(
                children: [
                  Expanded(
                    child: _SheetActionButton(
                      label: l10n.smartOpenerCancelAction,
                      isPrimary: false,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _SheetActionButton(
                      label: l10n.smartOpenerConfirmAction,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
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
      height: 58,
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
            borderRadius: BorderRadius.circular(29),
          ),
        ),
        child: Text(
          label,
          style: isPrimary
              ? context.appText
                    .smartOpenerActionButton(textTheme)
                    .copyWith(fontSize: 18)
              : context.appText
                    .smartOpenerSecondaryActionButton(textTheme)
                    .copyWith(fontSize: 18),
        ),
      ),
    );
  }
}
