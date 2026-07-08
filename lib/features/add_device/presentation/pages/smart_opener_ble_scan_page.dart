import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/add_device_controller.dart';
import '../../application/providers.dart';
import 'smart_opener_device_not_found_page.dart';
import 'smart_opener_scan_results_page.dart';
import 'smart_opener_scan_guide_page.dart';

class SmartOpenerBleScanPage extends ConsumerStatefulWidget {
  const SmartOpenerBleScanPage({
    super.key,
    this.scanDuration = const Duration(seconds: 30),
  });

  static const routeName = 'smart-opener-ble-scan';
  static const routePath = '/add-device/smart-opener/ble-scan';

  final Duration scanDuration;

  @override
  ConsumerState<SmartOpenerBleScanPage> createState() =>
      _SmartOpenerBleScanPageState();
}

class _SmartOpenerBleScanPageState extends ConsumerState<SmartOpenerBleScanPage>
    with WidgetsBindingObserver {
  late final AddDeviceController _controller;
  Timer? _scanTimer;
  var _hasCompletedScan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ref.read(addDeviceControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _startTimedScan();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimedScan();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopTimedScan();
      return;
    }
    if (state == AppLifecycleState.resumed && !_hasCompletedScan) {
      _startTimedScan(clearResults: false);
    }
  }

  void _startTimedScan({bool clearResults = true}) {
    _scanTimer?.cancel();
    if (clearResults) {
      _controller.clearScanResults();
    }
    unawaited(_controller.startScan());
    _scanTimer = Timer(widget.scanDuration, () {
      unawaited(_completeScan());
    });
  }

  void _stopTimedScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
    unawaited(_controller.stopScan());
  }

  Future<void> _completeScan() async {
    if (_hasCompletedScan || !mounted) {
      return;
    }
    _hasCompletedScan = true;
    _scanTimer?.cancel();
    _scanTimer = null;
    await _controller.stopScan();
    if (!mounted) {
      return;
    }
    final devices = ref.read(addDeviceControllerProvider).sortedDevices();
    context.go(
      devices.isEmpty
          ? SmartOpenerDeviceNotFoundPage.routePath
          : SmartOpenerScanResultsPage.routePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final animationSize = (constraints.maxHeight * 0.42)
              .clamp(220.0, 328.0)
              .toDouble();

          return SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(43, 46, 43, 24),
              children: [
                Text(
                  l10n.smartOpenerBleScanningTitle,
                  style: AppTextTokens.smartOpenerScanningTitle(textTheme),
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.smartOpenerBleScanningDescription,
                  style: AppTextTokens.smartOpenerScanningDescription(
                    textTheme,
                  ),
                ),
                SizedBox(height: constraints.maxHeight < 620 ? 24 : 54),
                Center(child: _BleScanArtwork(size: animationSize)),
                SizedBox(height: constraints.maxHeight < 620 ? 24 : 41),
                Center(
                  child: Text(
                    l10n.smartOpenerBleScanningStatus,
                    textAlign: TextAlign.center,
                    style: AppTextTokens.smartOpenerScanningStatus(textTheme),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BleScanArtwork extends StatelessWidget {
  const _BleScanArtwork({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Lottie.asset(
            SmartOpenerScanAssetPaths.scanningAnimation,
            width: size,
            height: size,
            fit: BoxFit.contain,
            repeat: true,
            imageProviderFactory: (asset) {
              return AssetImage(
                '${SmartOpenerScanAssetPaths.scanningImageDirectory}/${asset.fileName}',
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
