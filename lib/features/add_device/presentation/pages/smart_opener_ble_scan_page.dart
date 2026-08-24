import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/add_device_controller.dart';
import '../../application/device_type_ble_filter.dart';
import '../../application/providers.dart';
import '../add_device_error_message.dart';
import 'smart_opener_choose_wifi_page.dart';
import 'smart_opener_device_not_found_page.dart';
import 'smart_opener_scan_results_page.dart';
import 'smart_opener_scan_guide_page.dart';

class SmartOpenerBleScanPage extends ConsumerStatefulWidget {
  const SmartOpenerBleScanPage({
    super.key,
    this.scanDuration = const Duration(seconds: 30),
    this.targetSn,
    this.deviceType = defaultDoorDeviceType,
  });

  static const routeName = 'smart-opener-ble-scan';
  static const routePath = '/add-device/smart-opener/ble-scan';

  final Duration scanDuration;
  final String? targetSn;
  final String deviceType;

  @override
  ConsumerState<SmartOpenerBleScanPage> createState() =>
      _SmartOpenerBleScanPageState();
}

class _SmartOpenerBleScanPageState extends ConsumerState<SmartOpenerBleScanPage>
    with WidgetsBindingObserver {
  late final AddDeviceController _controller;
  Timer? _scanTimer;
  var _hasCompletedScan = false;
  var _isConnectingTarget = false;
  String? _pendingDeviceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ref.read(addDeviceControllerProvider.notifier);
    if (_targetSn != null) {
      ref.listenManual(addDeviceControllerProvider, (previous, next) {
        BleDevice? targetDevice;
        for (final device in next.devices.values) {
          if (device.sn?.trim() == _targetSn) {
            targetDevice = device;
            break;
          }
        }
        if (targetDevice != null) {
          unawaited(_connectTargetDevice(targetDevice));
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_prepareAndStartTimedScan());
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
      unawaited(_prepareAndStartTimedScan(clearResults: false));
    }
  }

  Future<void> _prepareAndStartTimedScan({bool clearResults = true}) async {
    final allDisconnected = await _controller.disconnectConnectedBleDevices();
    if (!mounted) {
      return;
    }
    if (!allDisconnected) {
      AppToast.error(
        context,
        AppLocalizations.of(context).smartOpenerDisconnectFailedMessage,
      );
    }
    await _startTimedScan(clearResults: clearResults);
  }

  Future<void> _startTimedScan({bool clearResults = true}) async {
    _scanTimer?.cancel();
    if (clearResults) {
      _controller.clearScanResults();
    }
    final didStartScan = await _controller.startScan(
      deviceType: widget.deviceType,
      targetSn: _targetSn,
    );
    if (!didStartScan || !mounted) {
      return;
    }
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
    if (devices.isEmpty) {
      final shouldRescan = await context.push<bool>(
        SmartOpenerDeviceNotFoundPage.routePath,
      );
      if (shouldRescan == true && mounted) {
        setState(() {
          _hasCompletedScan = false;
          _isConnectingTarget = false;
        });
        await _prepareAndStartTimedScan();
      }
      return;
    }
    context.push(SmartOpenerScanResultsPage.routePath);
  }

  Future<void> _addDevice(BleDevice device) async {
    setState(() {
      _pendingDeviceId = device.id;
    });
    _scanTimer?.cancel();
    _scanTimer = null;
    await _controller.stopScan();
    final connected = await _controller.connectAndAuthenticate(device);
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingDeviceId = null;
    });
    if (connected) {
      context.push(SmartOpenerChooseWifiPage.routePath);
      return;
    }

    final state = ref.read(addDeviceControllerProvider);
    final message = localizedAddDeviceErrorMessage(
      context,
      state,
      fallback: AppLocalizations.of(context).smartOpenerScannerConnectionFailed,
    );
    AppToast.error(context, message);
  }

  Future<void> _connectTargetDevice(BleDevice device) async {
    if (_isConnectingTarget || _hasCompletedScan || !mounted) {
      return;
    }
    _isConnectingTarget = true;
    _scanTimer?.cancel();
    _scanTimer = null;
    await _controller.stopScan();
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingDeviceId = device.id;
    });
    final connected = await _controller.connectAndAuthenticate(device);
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingDeviceId = null;
    });
    if (connected) {
      context.push(SmartOpenerChooseWifiPage.routePath);
      return;
    }
    final state = ref.read(addDeviceControllerProvider);
    AppToast.error(
      context,
      localizedAddDeviceErrorMessage(
        context,
        state,
        fallback: AppLocalizations.of(
          context,
        ).smartOpenerScannerConnectionFailed,
      ),
    );
  }

  String? get _targetSn {
    final value = widget.targetSn?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final devices = ref.watch(addDeviceControllerProvider).sortedDevices();

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
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
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
                if (devices.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _ScanningDevicePreviewList(
                    devices: devices,
                    pendingDeviceId: _pendingDeviceId,
                    onAddDevice: _pendingDeviceId == null ? _addDevice : null,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScanningDevicePreviewList extends StatelessWidget {
  const _ScanningDevicePreviewList({
    required this.devices,
    required this.pendingDeviceId,
    required this.onAddDevice,
  });

  final List<BleDevice> devices;
  final String? pendingDeviceId;
  final ValueChanged<BleDevice>? onAddDevice;

  @override
  Widget build(BuildContext context) {
    final itemExtent = 84.0;
    final listHeight = (devices.length * itemExtent).clamp(0.0, 252.0);

    return SizedBox(
      height: listHeight,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: devices.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final device = devices[index];
          return _ScanningDevicePreviewCard(
            device: device,
            isPending: pendingDeviceId == device.id,
            onAddPressed: onAddDevice == null
                ? null
                : () => onAddDevice!(device),
          );
        },
      ),
    );
  }
}

class _ScanningDevicePreviewCard extends StatelessWidget {
  const _ScanningDevicePreviewCard({
    required this.device,
    required this.isPending,
    required this.onAddPressed,
  });

  final BleDevice device;
  final bool isPending;
  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final name = device.name?.trim().isNotEmpty == true
        ? device.name!.trim()
        : 'Smart Door';

    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.smartOpenerCardSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.door_front_door_outlined,
            size: 34,
            color: AppColors.textIcon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.smartOpenerResultCardTitle(
                    textTheme,
                  ).copyWith(fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.smartOpenerDefaultDeviceSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.smartOpenerResultCardSubtitle(
                    textTheme,
                  ).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            height: 32,
            child: FilledButton(
              onPressed: onAddPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.smartOpenerAddButton,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.textHint,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: isPending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.smartOpenerAddAction,
                      style: AppTextTokens.smartOpenerSmallButton(textTheme),
                    ),
            ),
          ),
        ],
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
