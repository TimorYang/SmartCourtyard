import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/platform/gallery_image_saver.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/general_evaluation_controller.dart';
import '../../application/safety_sensors_evaluation_controller.dart';
import '../../domain/entities/full_report.dart';
import '../../domain/entities/general_evaluation_report.dart';
import '../../domain/entities/safety_sensors_evaluation.dart';
import '../widgets/security_report_widgets.dart';

typedef ReportImageSaver = Future<void> Function(Uint8List bytes);
typedef ReportImageCapture =
    Future<Uint8List> Function(GlobalKey boundaryKey, BuildContext context);
typedef ReportImageSharer = Future<void> Function(Uint8List bytes);

const _safetySuggestions = [
  FullReportSafetySuggestionCode.cycleMaintenance,
  FullReportSafetySuggestionCode.safetyEdgeLowBattery,
  FullReportSafetySuggestionCode.contactInstaller,
  FullReportSafetySuggestionCode.openingCurrentExceeded,
];

class FullReportPage extends ConsumerStatefulWidget {
  const FullReportPage({
    required this.deviceId,
    required this.doorId,
    this.captureReportImage = captureReportPngBytes,
    this.saveReportImage = GalleryImageSaver.savePngBytes,
    this.shareReportImage = shareReportPngBytes,
    super.key,
  });

  static const routeName = 'full-report';
  static const routePath = '/full-report';

  final String deviceId;
  final String doorId;
  final ReportImageCapture captureReportImage;
  final ReportImageSaver saveReportImage;
  final ReportImageSharer shareReportImage;

  @override
  ConsumerState<FullReportPage> createState() => _FullReportPageState();
}

class _FullReportPageState extends ConsumerState<FullReportPage> {
  final _reportBoundaryKey = GlobalKey();
  var _isSaving = false;
  var _isSharing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadReportData);
  }

  void _loadReportData() {
    ref
        .read(generalEvaluationControllerProvider.notifier)
        .load(doorId: widget.doorId);
    ref
        .read(safetySensorsEvaluationControllerProvider(widget.doorId).notifier)
        .load(doorId: widget.doorId);
  }

  Future<void> _saveReportImage() async {
    if (_isSaving || _isSharing) return;

    _isSaving = true;
    try {
      final bytes = await widget.captureReportImage(
        _reportBoundaryKey,
        context,
      );
      if (mounted) {
        setState(() {});
      }
      await widget.saveReportImage(bytes);
      if (!mounted) return;
      AppToast.success(
        context,
        AppLocalizations.of(context).securityReportSaveSuccess,
      );
    } on GalleryImageSaveException catch (error) {
      if (!mounted) return;
      AppToast.error(context, _saveErrorMessage(context, error));
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
        context,
        AppLocalizations.of(context).securityReportCaptureFailed,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareReportImage() async {
    if (_isSaving || _isSharing) return;

    setState(() => _isSharing = true);
    try {
      final bytes = await widget.captureReportImage(
        _reportBoundaryKey,
        context,
      );
      await widget.shareReportImage(bytes);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
        context,
        AppLocalizations.of(context).securityReportShareFailed,
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(generalEvaluationControllerProvider);
    final sensorsState = ref.watch(
      safetySensorsEvaluationControllerProvider(widget.doorId),
    );
    if (reportState.isLoading || sensorsState.isLoading) {
      return _stateScaffold(const Center(child: CircularProgressIndicator()));
    }
    if (reportState.hasError || sensorsState.hasError) {
      return _stateScaffold(
        Center(
          child: TextButton(
            onPressed: _loadReportData,
            child: Text(
              AppLocalizations.of(context).generalEvaluationLoadFailed,
            ),
          ),
        ),
      );
    }
    return _buildReport(
      context,
      reportState.requireValue,
      sensorsState.requireValue,
    );
  }

  Widget _buildReport(
    BuildContext context,
    GeneralEvaluationReport report,
    SafetySensorsEvaluation sensorEvaluation,
  ) {
    return Scaffold(
      backgroundColor: AppColors.securityCenterBackground,
      appBar: FlinxNavigationBar(
        title: AppLocalizations.of(context).securityReportTitle,
        showBottomDivider: false,
      ),
      body: SingleChildScrollView(
        key: const ValueKey<String>('full-report-scroll'),
        child: RepaintBoundary(
          key: _reportBoundaryKey,
          child: ColoredBox(
            color: AppColors.securityCenterBackground,
            child: Stack(
              children: [
                const Positioned(
                  top: 150,
                  left: 0,
                  right: 0,
                  child: SecurityReportBlueBackdrop(),
                ),
                Column(
                  children: [
                    SecurityReportHero(
                      motorName: report.motorName,
                      needsMaintenance: report.cycleSummary.needsMaintenance,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          CycleSummaryCard(summary: report.cycleSummary),
                          const SizedBox(height: 16),
                          BalanceEvaluationCard(
                            selection: BalanceEvaluation.open,
                            evaluation: report.openBalanceEvaluation,
                          ),
                          const SizedBox(height: 22),
                          BalanceEvaluationCard(
                            selection: BalanceEvaluation.close,
                            evaluation: report.closeBalanceEvaluation,
                          ),
                          const SizedBox(height: 22),
                          OperationChartCard(
                            range: RecordRange.last7Days,
                            record: report.last7DaysRecord,
                          ),
                          const SizedBox(height: 22),
                          OperationChartCard(
                            range: RecordRange.last24Hours,
                            record: report.last24HoursRecord,
                          ),
                          const SizedBox(height: 16),
                          MotorFunctionStatusCard(
                            status: report.motorFunctionStatus,
                          ),
                          const SizedBox(height: 16),
                          SensorDiagnosisSection.wired(
                            diagnosis: _diagnosis(
                              sensorEvaluation.wiredSensorGroup,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SensorDiagnosisSection.wireless(
                            diagnosis: _diagnosis(
                              sensorEvaluation.wirelessSensorGroup,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SafetySuggestionCard(suggestions: _safetySuggestions),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SecurityReportActionBar(
        isSaving: _isSaving,
        isSharing: _isSharing,
        onSave: _saveReportImage,
        onShare: _shareReportImage,
      ),
    );
  }

  Widget _stateScaffold(Widget body) => Scaffold(
    backgroundColor: AppColors.securityCenterBackground,
    appBar: FlinxNavigationBar(
      title: AppLocalizations.of(context).securityReportTitle,
      showBottomDivider: false,
    ),
    body: body,
  );

  String _saveErrorMessage(
    BuildContext context,
    GalleryImageSaveException error,
  ) {
    final l10n = AppLocalizations.of(context);
    return switch (error.failure) {
      GalleryImageSaveFailure.accessDenied =>
        l10n.securityReportSaveAccessDenied,
      GalleryImageSaveFailure.notEnoughSpace => l10n.securityReportSaveNoSpace,
      GalleryImageSaveFailure.unsupported => l10n.securityReportSaveUnsupported,
      GalleryImageSaveFailure.failed => l10n.securityReportSaveFailed,
    };
  }

  FullReportSensorDiagnosis _diagnosis(SafetySensorGroup group) {
    final sensors = group.sensors
        .map(
          (sensor) => FullReportSensor(
            id: sensor.id,
            type: _sensorType(sensor.sensorCode),
            states: const [],
            status: sensor.status,
            batteryStatus: sensor.batteryStatus,
            statusLabel: sensor.statusLabel,
          ),
        )
        .toList(growable: false);
    return FullReportSensorDiagnosis(
      summary: FullReportSensorSummary(
        normalCount: group.sensors
            .where(
              (sensor) =>
                  sensor.status == SafetySensorStatus.notTriggered ||
                  sensor.status == SafetySensorStatus.unlocked,
            )
            .length,
        disconnectedCount: group.sensors
            .where((sensor) => sensor.status == SafetySensorStatus.disconnected)
            .length,
        abnormalCount: group.sensors
            .where(
              (sensor) =>
                  sensor.status == SafetySensorStatus.triggered ||
                  sensor.status == SafetySensorStatus.locked,
            )
            .length,
      ),
      sensors: sensors,
    );
  }

  FullReportSensorType _sensorType(String sensorCode) => switch (sensorCode) {
    'WIRED_PHOTO_BEAM' => FullReportSensorType.wiredPhotoBeam,
    'WIRED_ELECTRONIC_LOCK' => FullReportSensorType.wiredELock,
    'WIRELESS_PHOTO_BEAM' => FullReportSensorType.wirelessPhotoBeam,
    'WIRELESS_WICKET_DOOR' => FullReportSensorType.wirelessWicketDoor,
    'WIRELESS_SAFETY_EDGE' => FullReportSensorType.wirelessSafetyEdge,
    'WIRELESS_SLACK_ROPE' => FullReportSensorType.wirelessSlackRope,
    'WIRELESS_ELECTRONIC_LOCK' => FullReportSensorType.wirelessELock,
    _ => FullReportSensorType.wirelessPositionSensor,
  };
}

Future<Uint8List> captureReportPngBytes(
  GlobalKey boundaryKey,
  BuildContext context,
) async {
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    throw StateError('Report image boundary is unavailable.');
  }

  final pixelRatio = _reportCapturePixelRatio(
    MediaQuery.devicePixelRatioOf(context),
    boundary.size.height,
  );
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  if (byteData == null) {
    throw StateError('Report image bytes could not be created.');
  }

  return byteData.buffer.asUint8List();
}

Future<void> shareReportPngBytes(Uint8List bytes) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'image/png')],
      fileNameOverrides: ['flinx-safety-report.png'],
    ),
  );
}

double _reportCapturePixelRatio(double devicePixelRatio, double contentHeight) {
  const maxLongImagePixels = 12000.0;
  final heightLimitedRatio = maxLongImagePixels / contentHeight;
  final cappedDeviceRatio = devicePixelRatio.clamp(0.5, 2.0).toDouble();
  final cappedHeightRatio = heightLimitedRatio.clamp(0.5, 2.0).toDouble();
  return cappedDeviceRatio.clamp(0.5, cappedHeightRatio).toDouble();
}

class SecurityReportActionBar extends StatelessWidget {
  const SecurityReportActionBar({
    required this.isSaving,
    required this.isSharing,
    required this.onSave,
    required this.onShare,
    super.key,
  });

  final bool isSaving;
  final bool isSharing;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.securityReportBottomBar,
        border: Border(
          top: BorderSide(color: AppColors.securityReportBottomBarDivider),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: SecurityReportActionButton(
                  key: const ValueKey<String>('full-report-save-action'),
                  icon: Icons.save_outlined,
                  label: isSaving
                      ? AppLocalizations.of(context).securityReportSavingAction
                      : AppLocalizations.of(context).securityReportSaveAction,
                  onTap: isSaving || isSharing ? null : onSave,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: SecurityReportActionButton(
                  key: const ValueKey<String>('full-report-share-action'),
                  icon: Icons.open_in_new,
                  label: isSharing
                      ? AppLocalizations.of(context).securityReportSharingAction
                      : AppLocalizations.of(context).securityReportShareAction,
                  onTap: isSaving || isSharing ? null : onShare,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
