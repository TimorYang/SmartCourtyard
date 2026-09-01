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
  var _scanSessionGeneration = 0;
  var _isScanSessionRunning = false;
  Completer<void>? _scanSessionCancellation;
  var _hasCompletedScan = false;
  var _isCompletingScan = false;
  var _isAddingDevice = false;
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
      _prepareAndStartScanSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cancelScanSession());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_cancelScanSession());
      return;
    }
    if (state == AppLifecycleState.resumed &&
        !_hasCompletedScan &&
        !_isAddingDevice &&
        !_isConnectingTarget) {
      _prepareAndStartScanSession(clearResults: false);
    }
  }

  void _prepareAndStartScanSession({bool clearResults = true}) {
    if (!mounted ||
        _isScanSessionRunning ||
        _isAddingDevice ||
        _isConnectingTarget) {
      return;
    }

    final sessionId = ++_scanSessionGeneration;
    final cancellation = Completer<void>();
    _scanSessionCancellation = cancellation;
    _isScanSessionRunning = true;
    _hasCompletedScan = false;
    unawaited(
      _runScanSession(
        sessionId,
        cancellation: cancellation,
        clearResults: clearResults,
      ),
    );
  }

  Future<void> _runScanSession(
    int sessionId, {
    required Completer<void> cancellation,
    required bool clearResults,
  }) async {
    try {
      final allDisconnected = await _controller.disconnectConnectedBleDevices();
      if (!mounted || sessionId != _scanSessionGeneration) {
        return;
      }
      if (!allDisconnected) {
        AppToast.error(
          context,
          AppLocalizations.of(context).smartOpenerDisconnectFailedMessage,
        );
      }
      if (clearResults) {
        _controller.clearScanResults();
      }

      // The scan window starts before awaiting native scan startup. Native
      // startup latency must not extend the user's 30-second scan task.
      final scanWindow = Completer<void>();
      final scanDeadline = Timer(widget.scanDuration, () {
        if (!scanWindow.isCompleted) {
          scanWindow.complete();
        }
      });
      final scanStarted = _controller.startScan(
        deviceType: widget.deviceType,
        targetSn: _targetSn,
      );
      unawaited(_handleScanStart(sessionId, scanStarted));

      try {
        await Future.any<void>([scanWindow.future, cancellation.future]);
        if (!_isActiveScanSession(sessionId) || cancellation.isCompleted) {
          return;
        }
        await _completeScan(sessionId);
      } finally {
        scanDeadline.cancel();
      }
    } catch (_) {
      if (_isActiveScanSession(sessionId)) {
        await _completeScan(sessionId, forceNoDevices: true);
      }
    } finally {
      if (identical(_scanSessionCancellation, cancellation)) {
        _scanSessionCancellation = null;
      }
      if (sessionId == _scanSessionGeneration) {
        _isScanSessionRunning = false;
      }
    }
  }

  Future<void> _handleScanStart(int sessionId, Future<bool> scanStarted) async {
    bool didStartScan;
    try {
      didStartScan = await scanStarted;
    } catch (_) {
      didStartScan = false;
    }

    if (!didStartScan) {
      if (_isActiveScanSession(sessionId)) {
        await _completeScan(sessionId, forceNoDevices: true);
      }
      return;
    }

    // If the task was cancelled while native startup was still pending, a
    // late successful start must be stopped immediately and must not revive
    // the old scan session.
    if (!_isActiveScanSession(sessionId) && !_isScanSessionRunning) {
      await _controller.stopScan();
    }
  }

  Future<void> _cancelScanSession({bool markCompleted = false}) async {
    final cancellation = _scanSessionCancellation;
    if (cancellation != null && !cancellation.isCompleted) {
      cancellation.complete();
    }
    ++_scanSessionGeneration;
    _isScanSessionRunning = false;
    if (markCompleted) {
      _hasCompletedScan = true;
    }
    await _controller.stopScan();
  }

  Future<void> _completeScan(
    int sessionId, {
    bool forceNoDevices = false,
  }) async {
    if (!_isActiveScanSession(sessionId) || _isCompletingScan) {
      return;
    }
    _hasCompletedScan = true;
    _isScanSessionRunning = false;
    _isCompletingScan = true;
    final cancellation = _scanSessionCancellation;
    if (cancellation != null && !cancellation.isCompleted) {
      cancellation.complete();
    }
    await _controller.stopScan();
    if (!mounted || sessionId != _scanSessionGeneration) {
      _isCompletingScan = false;
      return;
    }

    final devices = forceNoDevices
        ? const <BleDevice>[]
        : ref.read(addDeviceControllerProvider).sortedDevices();
    if (devices.isEmpty) {
      final shouldRescan = await context.push<bool>(
        SmartOpenerDeviceNotFoundPage.routePath,
      );
      if (shouldRescan == true && mounted) {
        setState(() {
          _hasCompletedScan = false;
          _isCompletingScan = false;
          _isConnectingTarget = false;
          _isAddingDevice = false;
        });
        _prepareAndStartScanSession();
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _isCompletingScan = false;
      });
      return;
    }
    if (!mounted) {
      return;
    }
    await context.push(SmartOpenerScanResultsPage.routePath);
    if (mounted && sessionId == _scanSessionGeneration) {
      setState(() {
        _isCompletingScan = false;
      });
    }
  }

  bool _isCurrentScanSession(int sessionId) {
    return mounted && sessionId == _scanSessionGeneration;
  }

  bool _isActiveScanSession(int sessionId) {
    return _isCurrentScanSession(sessionId) &&
        _isScanSessionRunning &&
        !_hasCompletedScan;
  }

  Future<void> _addDevice(BleDevice device) async {
    if (!mounted ||
        _isAddingDevice ||
        _isConnectingTarget ||
        _isCompletingScan) {
      return;
    }
    _isAddingDevice = true;
    _hasCompletedScan = true;
    setState(() {
      _pendingDeviceId = device.id;
    });

    await _cancelScanSession();
    if (!mounted) {
      return;
    }
    final connected = await _controller.connectAndAuthenticate(device);
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingDeviceId = null;
      _isAddingDevice = false;
    });
    if (connected) {
      await _controller.stopScan();
      if (!mounted) {
        return;
      }
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
    if (_isConnectingTarget ||
        _isAddingDevice ||
        _isCompletingScan ||
        _hasCompletedScan ||
        !mounted) {
      return;
    }
    _isConnectingTarget = true;
    _isAddingDevice = true;
    _hasCompletedScan = true;
    setState(() {
      _pendingDeviceId = device.id;
    });

    await _cancelScanSession();
    if (!mounted) {
      return;
    }
    final connected = await _controller.connectAndAuthenticate(device);
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingDeviceId = null;
      _isAddingDevice = false;
      _isConnectingTarget = false;
    });
    if (connected) {
      await _controller.stopScan();
      if (!mounted) {
        return;
      }
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
                    onAddDevice:
                        _pendingDeviceId == null &&
                            !_isAddingDevice &&
                            !_isCompletingScan
                        ? _addDevice
                        : null,
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
