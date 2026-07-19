import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/platform/gallery_image_saver.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../widgets/security_report_widgets.dart';

typedef ReportImageSaver = Future<void> Function(Uint8List bytes);
typedef ReportImageCapture =
    Future<Uint8List> Function(GlobalKey boundaryKey, BuildContext context);

class FullReportPage extends StatefulWidget {
  const FullReportPage({
    required this.deviceId,
    this.captureReportImage = captureReportPngBytes,
    this.saveReportImage = GalleryImageSaver.savePngBytes,
    super.key,
  });

  static const routeName = 'full-report';
  static const routePath = '/full-report';

  final String deviceId;
  final ReportImageCapture captureReportImage;
  final ReportImageSaver saveReportImage;

  @override
  State<FullReportPage> createState() => _FullReportPageState();
}

class _FullReportPageState extends State<FullReportPage> {
  final _reportBoundaryKey = GlobalKey();
  var _isSaving = false;

  Future<void> _saveReportImage() async {
    if (_isSaving) return;

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
      AppToast.success(context, 'Report saved to album.');
    } on GalleryImageSaveException catch (error) {
      if (!mounted) return;
      AppToast.error(context, _saveErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Unable to create report image.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.securityCenterBackground,
      appBar: const FlinxNavigationBar(
        title: 'Full Report',
        showBottomDivider: false,
      ),
      body: SingleChildScrollView(
        key: const ValueKey<String>('full-report-scroll'),
        padding: const EdgeInsets.only(bottom: 112),
        child: RepaintBoundary(
          key: _reportBoundaryKey,
          child: ColoredBox(
            color: AppColors.securityCenterBackground,
            child: Column(
              children: [
                const SecurityReportHero(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const CycleSummaryCard(),
                      const SizedBox(height: 20),
                      const BalanceEvaluationCard(
                        selection: BalanceEvaluation.open,
                      ),
                      const SizedBox(height: 20),
                      const BalanceEvaluationCard(
                        selection: BalanceEvaluation.close,
                      ),
                      const SizedBox(height: 20),
                      const OperationChartCard(range: RecordRange.last24Hours),
                      const SizedBox(height: 20),
                      const OperationChartCard(range: RecordRange.last7Days),
                      const SizedBox(height: 20),
                      const MotorFunctionStatusCard(),
                      const SizedBox(height: 20),
                      const SensorStatusCard(
                        title: 'Wired sensor status',
                        sensors: ['Wired photo beam', 'Wired E-lock'],
                      ),
                      const SizedBox(height: 20),
                      const SensorStatusCard(
                        title: 'Wireless Sensors Status',
                        sensors: [
                          'Wireless Photo Beam',
                          'Wireless wicket door',
                          'Wireless safety edge',
                          'Wireless E-lock',
                          'Wireless rope sensor',
                        ],
                      ),
                      const SizedBox(height: 20),
                      const SafetySuggestionCard(),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SecurityReportActionBar(
        isSaving: _isSaving,
        onSave: _saveReportImage,
      ),
    );
  }

  String _saveErrorMessage(GalleryImageSaveException error) {
    return switch (error.failure) {
      GalleryImageSaveFailure.accessDenied =>
        'Photo library permission is required to save the report.',
      GalleryImageSaveFailure.notEnoughSpace =>
        'Not enough storage space to save the report.',
      GalleryImageSaveFailure.unsupported =>
        'Unable to save this image format.',
      GalleryImageSaveFailure.failed => 'Unable to save report image.',
    };
  }
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
    required this.onSave,
    this.onShare,
    super.key,
  });

  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback? onShare;

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
                  label: isSaving ? 'Saving' : 'Save',
                  onTap: isSaving ? null : onSave,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: SecurityReportActionButton(
                  key: const ValueKey<String>('full-report-share-action'),
                  icon: Icons.open_in_new,
                  label: 'Share',
                  onTap: onShare ?? () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
