import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/add_device_controller.dart';
import '../../application/device_type_ble_filter.dart';
import '../../application/providers.dart';
import '../add_device_error_message.dart';
import '../../application/smart_opener_qr_payload_parser.dart';
import 'add_device_page.dart';
import 'smart_opener_ble_scan_page.dart';
import 'smart_opener_choose_wifi_page.dart';

class SmartOpenerQrScanAssetPaths {
  const SmartOpenerQrScanAssetPaths._();

  static const galleryIcon =
      'assets/icons/add_device/smart_opener_qr_gallery_icon.png';
  static const flashlightOffIcon =
      'assets/icons/add_device/smart_opener_qr_flashlight_off_icon.png';
  static const flashlightOnIcon =
      'assets/icons/add_device/smart_opener_qr_flashlight_on_icon.png';
}

class SmartOpenerQrScanPageKeys {
  const SmartOpenerQrScanPageKeys._();

  static const cameraPermissionDialog = ValueKey<String>(
    'smart-opener-qr-camera-permission-dialog',
  );
  static const cameraPermissionDialogCancelAction = ValueKey<String>(
    'smart-opener-qr-camera-permission-dialog-cancel',
  );
  static const cameraPermissionDialogSettingsAction = ValueKey<String>(
    'smart-opener-qr-camera-permission-dialog-settings',
  );
  static const cameraPermissionErrorSettingsAction = ValueKey<String>(
    'smart-opener-qr-camera-permission-error-settings',
  );
}

class SmartOpenerQrScanPage extends ConsumerStatefulWidget {
  const SmartOpenerQrScanPage({
    super.key,
    this.enableCamera = true,
    this.deviceType = defaultDoorDeviceType,
  });

  static const routeName = 'smart-opener-qr-scan';
  static const routePath = '/add-device/smart-opener/qr-scan';

  final bool enableCamera;
  final String deviceType;

  @override
  ConsumerState<SmartOpenerQrScanPage> createState() =>
      _SmartOpenerQrScanPageState();
}

class _SmartOpenerQrScanPageState extends ConsumerState<SmartOpenerQrScanPage>
    with WidgetsBindingObserver {
  static const _targetScanTimeout = Duration(seconds: 10);

  late final MobileScannerController _scannerController;
  late final AddDeviceController _addDeviceController;
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _targetScanTimer;
  String? _targetSn;
  var _isProcessing = false;
  var _isConnectingTarget = false;
  var _isShowingCameraPermissionDialog = false;
  var _isOpeningCameraPermissionSettings = false;
  var _resumeScanningAfterSettings = false;
  var _didLeaveAppForSettings = false;
  var _suppressNextPermissionDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
    );
    _scannerController.addListener(_handleScannerStateChanged);
    _addDeviceController = ref.read(addDeviceControllerProvider.notifier);
    ref.listenManual(addDeviceControllerProvider, (previous, next) {
      final targetSn = _targetSn;
      if (!_isProcessing || targetSn == null) {
        return;
      }
      for (final device in next.devices.values) {
        if (device.sn?.trim() == targetSn) {
          unawaited(_connectTargetDevice(device));
          return;
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _targetScanTimer?.cancel();
    unawaited(_addDeviceController.stopScan());
    _scannerController.removeListener(_handleScannerStateChanged);
    unawaited(_scannerController.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_resumeScanningAfterSettings) {
        _didLeaveAppForSettings = true;
      }
      return;
    }
    if (state == AppLifecycleState.resumed &&
        _resumeScanningAfterSettings &&
        _didLeaveAppForSettings) {
      _resumeScanningAfterSettings = false;
      _didLeaveAppForSettings = false;
      _suppressNextPermissionDialog = true;
      unawaited(_restartScannerAfterSettings());
    }
  }

  void _handleScannerStateChanged() {
    final scannerState = _scannerController.value;
    final error = scannerState.error;
    if (error?.errorCode != MobileScannerErrorCode.permissionDenied) {
      if (scannerState.isRunning) {
        _suppressNextPermissionDialog = false;
      }
      return;
    }
    if (_suppressNextPermissionDialog) {
      _suppressNextPermissionDialog = false;
      return;
    }
    if (_isShowingCameraPermissionDialog) {
      return;
    }
    _isShowingCameraPermissionDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _isShowingCameraPermissionDialog = false;
        return;
      }
      unawaited(_showCameraPermissionDeniedDialog());
    });
  }

  Future<void> _showCameraPermissionDeniedDialog() async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: SmartOpenerQrScanPageKeys.cameraPermissionDialog,
        title: Text(l10n.smartOpenerScannerPermissionDialogTitle),
        content: Text(l10n.smartOpenerScannerPermissionDialogMessage),
        actions: [
          TextButton(
            key: SmartOpenerQrScanPageKeys.cameraPermissionDialogCancelAction,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.smartOpenerCancelAction),
          ),
          TextButton(
            key: SmartOpenerQrScanPageKeys.cameraPermissionDialogSettingsAction,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              unawaited(_openCameraPermissionSettings());
            },
            child: Text(l10n.smartOpenerScannerPermissionSettingsAction),
          ),
        ],
      ),
    );
    _isShowingCameraPermissionDialog = false;
  }

  Future<void> _openCameraPermissionSettings() async {
    if (_isOpeningCameraPermissionSettings) {
      return;
    }
    _isOpeningCameraPermissionSettings = true;
    _resumeScanningAfterSettings = true;
    _didLeaveAppForSettings = false;
    final opened = await _addDeviceController.openCameraPermissionSettings();
    _isOpeningCameraPermissionSettings = false;
    if (opened || !mounted) {
      return;
    }
    _resumeScanningAfterSettings = false;
    _showMessage(
      AppLocalizations.of(context).smartOpenerScannerPermissionSettingsFailed,
    );
  }

  Future<void> _restartScannerAfterSettings() async {
    if (!widget.enableCamera || !mounted) {
      return;
    }
    try {
      await _scannerController.start();
    } catch (_) {
      if (mounted) {
        _showMessage(
          AppLocalizations.of(context).smartOpenerScannerUnknownError,
        );
      }
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(AppLocalizations.of(context).smartOpenerScannerUnknownError);
    }
  }

  Future<void> _pickFromGallery() async {
    final l10n = AppLocalizations.of(context);
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        return;
      }
      final capture = await _scannerController.analyzeImage(image.path);
      final rawValue = _firstQrPayload(capture);
      if (rawValue == null) {
        _showMessage(l10n.smartOpenerScannerNoCodeFound);
        return;
      }
      await _handleQrPayload(rawValue);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.smartOpenerScannerImageFailed);
    }
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    final rawValue = _firstQrPayload(capture);
    if (rawValue == null) {
      return;
    }
    await _handleQrPayload(rawValue);
  }

  Future<void> _handleQrPayload(String rawValue) async {
    if (_isProcessing || !mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final serialNumber = parseSmartOpenerSerialNumber(rawValue);
    if (serialNumber == null) {
      _showMessage(l10n.smartOpenerScannerInvalidCode);
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _isProcessing = true;
      _targetSn = serialNumber;
    });
    try {
      await _scannerController.stop();
    } catch (_) {
      await _resumeQrScanning(l10n.smartOpenerScannerUnknownError);
      return;
    }
    if (!mounted) {
      return;
    }
    await _startTargetScan(serialNumber);
  }

  Future<void> _startTargetScan(String serialNumber) async {
    final allDisconnected = await _addDeviceController
        .disconnectConnectedBleDevices();
    if (!mounted || !_isProcessing) {
      return;
    }
    if (!allDisconnected) {
      _showMessage(
        AppLocalizations.of(context).smartOpenerDisconnectFailedMessage,
      );
    }
    _addDeviceController.clearScanResults();
    _targetSn = serialNumber;
    _targetScanTimer = Timer(_targetScanTimeout, () {
      unawaited(_handleTargetScanTimeout());
    });
    await _addDeviceController.startScan(
      deviceType: widget.deviceType,
      targetSn: serialNumber,
    );
    if (!mounted || !_isProcessing) {
      return;
    }
    final scanState = ref.read(addDeviceControllerProvider);
    if (!scanState.isScanning && scanState.errorMessage != null) {
      await _resumeQrScanning(scanState.errorMessage!);
    }
  }

  Future<void> _connectTargetDevice(BleDevice device) async {
    if (_isConnectingTarget || !_isProcessing || !mounted) {
      return;
    }
    _isConnectingTarget = true;
    _targetScanTimer?.cancel();
    _targetScanTimer = null;
    await _addDeviceController.stopScan();
    final connected = await _addDeviceController.connectAndAuthenticate(device);
    if (!mounted) {
      return;
    }
    if (connected) {
      context.push(SmartOpenerChooseWifiPage.routePath);
      return;
    }
    final state = ref.read(addDeviceControllerProvider);
    await _resumeQrScanning(
      localizedAddDeviceErrorMessage(
        context,
        state,
        fallback: AppLocalizations.of(
          context,
        ).smartOpenerScannerConnectionFailed,
      ),
    );
  }

  Future<void> _handleTargetScanTimeout() async {
    if (!_isProcessing || !mounted) {
      return;
    }
    await _resumeQrScanning(
      AppLocalizations.of(context).smartOpenerScannerDeviceNotFound,
    );
  }

  Future<void> _resumeQrScanning(String message) async {
    _targetScanTimer?.cancel();
    _targetScanTimer = null;
    await _addDeviceController.stopScan();
    if (!mounted) {
      return;
    }
    setState(() {
      _isProcessing = false;
      _isConnectingTarget = false;
      _targetSn = null;
    });
    _showMessage(message);
    if (widget.enableCamera) {
      try {
        await _scannerController.start();
      } catch (_) {
        if (mounted) {
          _showMessage(
            AppLocalizations.of(context).smartOpenerScannerUnknownError,
          );
        }
      }
    }
  }

  String? _firstQrPayload(BarcodeCapture? capture) {
    if (capture == null) {
      return null;
    }
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  void _showMessage(String message) {
    AppToast.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.scannerBackground,
      extendBodyBehindAppBar: true,
      appBar: FlinxNavigationBar(
        title: '',
        automaticallyImplyLeading: context.canPop(),
        showBottomDivider: false,
        isTransparent: true,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: l10n.smartOpenerScannerBluetoothTooltip,
            onPressed: _isProcessing
                ? null
                : () => context.pushNamed(
                    SmartOpenerBleScanPage.routeName,
                    queryParameters: {
                      AddDevicePage.deviceTypeQueryParameter:
                          normalizeDoorDeviceType(widget.deviceType),
                    },
                  ),
            icon: const Icon(Icons.bluetooth),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scanWindowSize = constraints.maxWidth * 0.58;
          final scanWindow = Rect.fromCenter(
            center: Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.36,
            ),
            width: scanWindowSize,
            height: scanWindowSize,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              if (widget.enableCamera)
                MobileScanner(
                  controller: _scannerController,
                  fit: BoxFit.cover,
                  scanWindow: scanWindow,
                  onDetect: _handleDetection,
                  errorBuilder: (context, error) {
                    final hasPermissionError =
                        error.errorCode ==
                        MobileScannerErrorCode.permissionDenied;
                    return _ScannerError(
                      message: _scannerMessage(l10n, error),
                      actionLabel: hasPermissionError
                          ? l10n.smartOpenerScannerPermissionSettingsAction
                          : null,
                      onAction: hasPermissionError
                          ? () => unawaited(_openCameraPermissionSettings())
                          : null,
                    );
                  },
                  placeholderBuilder: (context) {
                    return const ColoredBox(color: AppColors.scannerBackground);
                  },
                )
              else
                const ColoredBox(color: AppColors.scannerBackground),
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScannerOverlayPainter(
                    scanWindow: scanWindow,
                    paintWindowFill: !widget.enableCamera,
                  ),
                ),
              ),
              Positioned(
                left: scanWindow.left,
                right: scanWindow.left,
                top: scanWindow.bottom + 26,
                child: Center(
                  child: _ScannerChip(
                    label: l10n.smartOpenerScannerManualAction,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 82,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ScannerActionButton(
                      label: l10n.smartOpenerScannerGalleryAction,
                      assetPath: SmartOpenerQrScanAssetPaths.galleryIcon,
                      fallbackIcon: Icons.image_outlined,
                      onPressed: _isProcessing ? null : _pickFromGallery,
                    ),
                    const SizedBox(width: 76),
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _scannerController,
                      builder: (context, scannerState, child) {
                        final isTorchOn =
                            scannerState.torchState == TorchState.on;
                        return _ScannerActionButton(
                          label: l10n.smartOpenerScannerFlashlightAction,
                          assetPath: isTorchOn
                              ? SmartOpenerQrScanAssetPaths.flashlightOnIcon
                              : SmartOpenerQrScanAssetPaths.flashlightOffIcon,
                          fallbackIcon: isTorchOn
                              ? Icons.flashlight_on_outlined
                              : Icons.flashlight_off_outlined,
                          onPressed: _isProcessing ? null : _toggleTorch,
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (_isProcessing)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x99000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _scannerMessage(
    AppLocalizations l10n,
    MobileScannerException exception,
  ) {
    if (exception.errorCode == MobileScannerErrorCode.permissionDenied) {
      return l10n.smartOpenerScannerPermissionError;
    }
    return l10n.smartOpenerScannerUnknownError;
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.scannerBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextTokens.scannerControlLabel(
                  Theme.of(context).textTheme,
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  key: SmartOpenerQrScanPageKeys
                      .cameraPermissionErrorSettingsAction,
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerChip extends StatelessWidget {
  const _ScannerChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: AppColors.scannerChipBackground,
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(
          label,
          style: AppTextTokens.scannerChip(Theme.of(context).textTheme),
        ),
      ),
    );
  }
}

class _ScannerActionButton extends StatelessWidget {
  const _ScannerActionButton({
    required this.label,
    required this.assetPath,
    required this.fallbackIcon,
    required this.onPressed,
  });

  final String label;
  final String assetPath;
  final IconData fallbackIcon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(fallbackIcon, size: 22);
                },
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextTokens.scannerControlLabel(
                  Theme.of(context).textTheme,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter({
    required this.scanWindow,
    required this.paintWindowFill,
  });

  final Rect scanWindow;
  final bool paintWindowFill;

  @override
  void paint(Canvas canvas, Size size) {
    if (paintWindowFill) {
      final fillPaint = Paint()..color = AppColors.scannerWindowFill;
      canvas.drawRect(scanWindow, fillPaint);
    }

    final cornerPaint = Paint()
      ..color = AppColors.scannerWindowCorner
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const cornerLength = 12.0;

    canvas
      ..drawLine(
        scanWindow.topLeft,
        scanWindow.topLeft + const Offset(cornerLength, 0),
        cornerPaint,
      )
      ..drawLine(
        scanWindow.topLeft,
        scanWindow.topLeft + const Offset(0, cornerLength),
        cornerPaint,
      )
      ..drawLine(
        scanWindow.topRight,
        scanWindow.topRight + const Offset(-cornerLength, 0),
        cornerPaint,
      )
      ..drawLine(
        scanWindow.topRight,
        scanWindow.topRight + const Offset(0, cornerLength),
        cornerPaint,
      )
      ..drawLine(
        scanWindow.bottomLeft,
        scanWindow.bottomLeft + const Offset(cornerLength, 0),
        cornerPaint,
      )
      ..drawLine(
        scanWindow.bottomLeft,
        scanWindow.bottomLeft + const Offset(0, -cornerLength),
        cornerPaint,
      )
      ..drawLine(
        scanWindow.bottomRight,
        scanWindow.bottomRight + const Offset(-cornerLength, 0),
        cornerPaint,
      )
      ..drawLine(
        scanWindow.bottomRight,
        scanWindow.bottomRight + const Offset(0, -cornerLength),
        cornerPaint,
      );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow ||
        oldDelegate.paintWindowFill != paintWindowFill;
  }
}
