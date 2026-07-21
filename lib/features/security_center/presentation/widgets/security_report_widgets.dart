import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../domain/entities/full_report.dart';

/// Replace these named placeholders with exported design cut assets when ready.
const securityReportMotorBlueBg =
    'assets/icons/security_center/security_report_blue_bg.png';
const securityReportMotorIllustrationAsset =
    'assets/icons/security_center/security_report_motor_illustration.png';
const securityReportMotorBlueUpArrow =
    'assets/icons/security_center/security_report_motor_blue_up_arrow.png';
const securityReportMotorBlueDownArrow =
    'assets/icons/security_center/security_report_motor_blue_down_arrow.png';
const securityReportWiredPhotoBeamAsset =
    'assets/icons/security_center/security_report_motor_wired_photo_beam_icon.png';
const securityReportWiredELockAsset =
    'assets/icons/security_center/security_report_motor_wired_e_lock.png';
const securityReportWirelessWicketDoorAsset =
    'assets/icons/security_center/security_report_wireless_wicket_door.png';
const securityReportWirelessSafetyEdgeAsset =
    'assets/icons/security_center/security_report_wireless_safety_edge.png';
const securityReportWirelessPositionSensorAsset =
    'assets/icons/security_center/security_report_wireless_position_sensor.png';

class SecurityReportHero extends StatelessWidget {
  const SecurityReportHero({this.motorName, this.serialNumber, super.key});

  final String? motorName;
  final String? serialNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 326,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 65,
            child: _ReportAssetPlaceholder(
              asset: securityReportMotorIllustrationAsset,
              size: const Size(190, 161),
              fallback: Icons.settings_input_component_outlined,
            ),
          ),
          Positioned(
            top: 240,
            child: Column(
              children: [
                Text(
                  motorName ?? l10n.securityReportMotorName,
                  style: AppTextTokens.securityReportDeviceName(
                    Theme.of(context).textTheme,
                  ),
                ),
                Text(
                  serialNumber == null
                      ? l10n.securityReportSerialNumber
                      : 'Serial number: $serialNumber',
                  style: AppTextTokens.securityReportHeroMeta(
                    Theme.of(context).textTheme,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityReportBlueBackdrop extends StatelessWidget {
  const SecurityReportBlueBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      width: double.infinity,
      child: Image.asset(
        securityReportMotorBlueBg,
        fit: BoxFit.fill,
        excludeFromSemantics: true,
      ),
    );
  }
}

class SecurityReportCard extends StatelessWidget {
  const SecurityReportCard({
    required this.child,
    this.padding = const EdgeInsets.only(
      left: 18,
      right: 18,
      top: 10,
      bottom: 10,
    ),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.securityCenterCard,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class CycleSummaryCard extends StatelessWidget {
  const CycleSummaryCard({this.summary, this.showWarning = true, super.key});

  final FullReportCycleSummary? summary;
  final bool showWarning;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final displayWarning = summary?.needsMaintenance ?? showWarning;
    return SecurityReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  summary?.doorName ?? l10n.securityReportDoorName,
                  style: AppTextTokens.securityReportCardTitle(textTheme),
                ),
              ),
              Icon(
                displayWarning ? Icons.error : Icons.check_circle,
                size: 13,
                color: displayWarning
                    ? AppColors.securityReportWarning
                    : AppColors.securityCenterSuccess,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.securityReportDivider),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  value: '${summary?.operatedCycles ?? 860}',
                  label: l10n.securityReportOperatedCycles,
                ),
              ),
              const SizedBox(
                height: 36,
                child: VerticalDivider(color: AppColors.securityReportDivider),
              ),
              Expanded(
                child: _Metric(
                  value: '${summary?.remainingCycles ?? 140}',
                  label: l10n.securityReportRemainingCycles,
                  alignEnd: true,
                  valueColor: AppColors.securityReportWarning,
                ),
              ),
            ],
          ),
          if (displayWarning) ...[
            const SizedBox(height: 14),
            Text(
              l10n.securityReportMaintenanceWarning,
              style: AppTextTokens.securityReportWarning(textTheme),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    this.alignEnd = false,
    this.valueColor,
  });

  final String value;
  final String label;
  final bool alignEnd;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: AppTextTokens.securityReportMetric(
          Theme.of(context).textTheme,
        ).copyWith(color: valueColor),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: AppTextTokens.securityReportLabel(Theme.of(context).textTheme),
      ),
    ],
  );
}

enum BalanceEvaluation { open, close }

class BalanceEvaluationCard extends StatelessWidget {
  const BalanceEvaluationCard({
    required this.selection,
    this.evaluation,
    this.onChanged,
    super.key,
  });

  final BalanceEvaluation selection;
  final FullReportBalanceEvaluation? evaluation;
  final ValueChanged<BalanceEvaluation>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SecurityReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            title: l10n.securityReportBalanceEvaluation,
            status: _ReportStatus.warning,
          ),
          const SizedBox(height: 5),
          Text(
            l10n.securityReportBalanceNote,
            style: AppTextTokens.securityReportValue(textTheme),
          ),
          const SizedBox(height: 10),
          ReportSegmentedControl<BalanceEvaluation>(
            selected: selection,
            options: {
              BalanceEvaluation.open: l10n.securityReportOpenEvaluation,
              BalanceEvaluation.close: l10n.securityReportCloseEvaluation,
            },
            onChanged: onChanged,
          ),
          const SizedBox(height: 22),
          _BalanceTable(selection: selection, evaluation: evaluation),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _BalanceTable extends StatelessWidget {
  const _BalanceTable({required this.selection, this.evaluation});

  final BalanceEvaluation selection;
  final FullReportBalanceEvaluation? evaluation;

  static const _rowHeight = 26.0;
  static const _rowCount = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const ranges = ['80%~100%', '60%~80%', '40%~60%', '20%~40%', '0%~20%'];
    return SizedBox(
      key: ValueKey<BalanceEvaluation>(selection),
      height: _rowHeight * _rowCount,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              key: const ValueKey<String>('balance-main-table'),
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.securityReportTableBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        for (var index = 0; index < _rowCount; index++)
                          Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: index == _rowCount - 1
                                    ? null
                                    : const Border(
                                        bottom: BorderSide(
                                          color: AppColors
                                              .securityReportTableBorder,
                                        ),
                                      ),
                              ),
                              child: Center(
                                child: Text(
                                  ranges[index],
                                  style: AppTextTokens.securityReportBody(
                                    Theme.of(context).textTheme,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  left: 10,
                  child: SizedBox(
                    key: const ValueKey<String>('balance-table-arrow'),
                    width: 22,
                    height: 93,
                    child: Image.asset(
                      selection == BalanceEvaluation.open
                          ? securityReportMotorBlueUpArrow
                          : securityReportMotorBlueDownArrow,
                      fit: BoxFit.fill,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) => const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              key: const ValueKey<String>('balance-status-table'),
              children: [
                for (var index = 0; index < _rowCount; index++)
                  Expanded(
                    child: CustomPaint(
                      foregroundPainter: const _DashedStatusRowPainter(),
                      child: Center(
                        child: _isOverload(index)
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error,
                                    size: 15,
                                    color: AppColors.securityReportWarning,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      l10n.securityReportOverload,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          AppTextTokens.securityReportWarning(
                                            Theme.of(context).textTheme,
                                          ),
                                    ),
                                  ),
                                ],
                              )
                            : const Icon(
                                Icons.check_circle,
                                size: 19,
                                color: AppColors.securityCenterSuccess,
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isOverload(int index) {
    final statuses = evaluation?.bandStatuses;
    return statuses == null
        ? index < 2
        : index < statuses.length &&
              statuses[index] == FullReportBalanceBandStatus.overload;
  }
}

class _DashedStatusRowPainter extends CustomPainter {
  const _DashedStatusRowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.securityReportTableBorder
      ..strokeWidth = 1;
    _drawDashedLine(canvas, size.width, 0, paint);
    _drawDashedLine(canvas, size.width, size.height, paint);
  }

  void _drawDashedLine(Canvas canvas, double width, double y, Paint paint) {
    const dash = 3.0;
    const gap = 3.0;
    for (var x = 0.0; x < width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dash).clamp(0, width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedStatusRowPainter oldDelegate) => false;
}

enum RecordRange { last24Hours, last7Days }

class OperationChartCard extends StatelessWidget {
  const OperationChartCard({
    required this.range,
    this.record,
    this.onChanged,
    super.key,
  });

  final RecordRange range;
  final FullReportOperationRecord? record;
  final ValueChanged<RecordRange>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SecurityReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            title: l10n.securityReportOperationRecord,
            status: _ReportStatus.warning,
          ),
          const SizedBox(height: 16),
          ReportSegmentedControl<RecordRange>(
            selected: range,
            options: {
              RecordRange.last24Hours: l10n.securityReportLast24Hours,
              RecordRange.last7Days: l10n.securityReportLast7Days,
            },
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
          Text(
            range == RecordRange.last24Hours
                ? l10n.securityReportTimeCyclesAxis
                : l10n.securityReportDateCyclesAxis,
            style: AppTextTokens.securityReportBody(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            key: ValueKey<RecordRange>(range),
            height: 174,
            width: double.infinity,
            child: CustomPaint(
              painter: _OperationChartPainter(range, record?.points),
            ),
          ),
          const SizedBox(height: 10),
          if (record?.hasFrequentOperationAlert ?? true)
            Text(
              l10n.securityReportFrequentOperationWarning,
              style: AppTextTokens.securityReportWarning(
                Theme.of(context).textTheme,
              ),
            ),
        ],
      ),
    );
  }
}

class _OperationChartPainter extends CustomPainter {
  const _OperationChartPainter(this.range, this.points);

  final RecordRange range;
  final List<FullReportOperationCyclePoint>? points;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.securityReportChartGrid
      ..strokeWidth = 1;
    final axis = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 1.2;
    final chart = Rect.fromLTWH(22, 10, size.width - 22, size.height - 26);
    for (var index = 0; index <= 5; index++) {
      final y = chart.bottom - chart.height * index / 5;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }
    canvas.drawLine(
      Offset(chart.left, chart.bottom),
      Offset(chart.right, chart.bottom),
      axis,
    );
    final bar = Paint()..color = AppColors.securityReportChartBar;
    final blueBar = Paint()..color = AppColors.securityReportSegmentSelected;
    final values =
        points?.map((point) => point.cycles).toList() ?? const [1, 24];
    final maxValue = values.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );
    final peakIndex = values.indexOf(maxValue);
    final highBarX = values.length > 1
        ? chart.left + chart.width * peakIndex / (values.length - 1)
        : chart.left + chart.width * .5;
    canvas.drawRect(
      Rect.fromLTWH(
        highBarX,
        chart.bottom - chart.height * .92,
        10,
        chart.height * .92,
      ),
      bar,
    );
    canvas.drawRect(
      Rect.fromLTWH(chart.left + chart.width * .08, chart.bottom - 6, 10, 6),
      blueBar,
    );
    _paintLabels(canvas, chart);
  }

  void _paintLabels(Canvas canvas, Rect chart) {
    for (var index = 0; index <= 5; index++) {
      final y = chart.bottom - chart.height * index / 5 - 8;
      final painter = TextPainter(
        text: TextSpan(
          text: '${index * 5}',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(chart.left - 24, y));
    }
    final count = range == RecordRange.last24Hours ? 24 : 7;
    for (var index = 0; index < count; index++) {
      final painter = TextPainter(
        text: TextSpan(
          text: range == RecordRange.last24Hours
              ? index.toString().padLeft(2, '0')
              : '${index + 3}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x =
          chart.left + chart.width * index / (count - 1) - painter.width / 2;
      painter.paint(canvas, Offset(x, chart.bottom + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _OperationChartPainter oldDelegate) =>
      oldDelegate.range != range || oldDelegate.points != points;
}

class ReportSegmentedControl<T> extends StatelessWidget {
  const ReportSegmentedControl({
    required this.selected,
    required this.options,
    this.onChanged,
    super.key,
  });

  final T selected;
  final Map<T, String> options;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = options.entries.toList(growable: false);
    return Row(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          Expanded(
            child: Semantics(
              button: true,
              selected: entries[index].key == selected,
              child: InkWell(
                key: ValueKey<String>('segment-${entries[index].value}'),
                onTap: onChanged == null
                    ? null
                    : () => onChanged!(entries[index].key),
                splashFactory: NoSplash.splashFactory,
                highlightColor: Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 6.5),
                  decoration: BoxDecoration(
                    color: entries[index].key == selected
                        ? AppColors.securityReportSegmentSelected
                        : AppColors.securityReportSegmentTrack,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    entries[index].value,
                    textAlign: TextAlign.center,
                    style:
                        AppTextTokens.securityReportBody(
                          Theme.of(context).textTheme,
                        ).copyWith(
                          color: entries[index].key == selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                  ),
                ),
              ),
            ),
          ),
          if (index < entries.length - 1) const SizedBox(width: 15),
        ],
      ],
    );
  }
}

class MotorFunctionStatusCard extends StatelessWidget {
  const MotorFunctionStatusCard({this.status, super.key});

  final FullReportMotorFunctionStatus? status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reportStatus = status;
    final values = <String, String>{
      l10n.securityReportDoorOpeningForce: l10n.securityReportLevel1,
      l10n.securityReportDoorClosingForce: l10n.securityReportLevel1,
      l10n.securityReportAutoCloseTime: '25s',
      l10n.securityReportAutoCloseCondition: l10n.securityReportAnyPosition,
      l10n.securityReportLedOffDelay: '3min',
      l10n.securityReportPartialOpen: '40cm',
      l10n.securityReportIgnoreObstructionHeight: '3cm',
      l10n.securityReportPhotoBeamFunction: l10n.securityReportOn,
      l10n.securityReportCommunityMode: l10n.securityReportOn,
      l10n.securityCenterWiredELock: l10n.securityReportOn,
    };
    if (reportStatus != null) {
      values
        ..[l10n.securityReportDoorOpeningForce] =
            'Level${reportStatus.openingForceLevel}'
        ..[l10n.securityReportDoorClosingForce] =
            'Level${reportStatus.closingForceLevel}'
        ..[l10n.securityReportAutoCloseTime] =
            '${reportStatus.autoCloseSeconds}s'
        ..[l10n.securityReportAutoCloseCondition] =
            reportStatus.autoCloseCondition ==
                FullReportAutoCloseCondition.anyPosition
            ? l10n.securityReportAnyPosition
            : 'Top position'
        ..[l10n.securityReportLedOffDelay] =
            '${reportStatus.ledOffDelayMinutes}min'
        ..[l10n.securityReportPartialOpen] =
            '${reportStatus.partialOpenCentimeters}cm'
        ..[l10n.securityReportIgnoreObstructionHeight] =
            '${reportStatus.ignoreObstructionHeightCentimeters}cm'
        ..[l10n.securityReportPhotoBeamFunction] = reportStatus.photoBeamEnabled
            ? l10n.securityReportOn
            : 'OFF'
        ..[l10n.securityReportCommunityMode] = reportStatus.communityModeEnabled
            ? l10n.securityReportOn
            : 'OFF'
        ..[l10n.securityCenterWiredELock] = reportStatus.wiredELockEnabled
            ? l10n.securityReportOn
            : 'OFF';
    }
    return SecurityReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.securityReportMotorFunctionStatus,
            style: AppTextTokens.securityReportCardTitle(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: 15),
          for (final entry in values.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: AppTextTokens.securityReportBody(
                        Theme.of(context).textTheme,
                      ),
                    ),
                  ),
                  Text(
                    entry.value,
                    style: AppTextTokens.securityReportValue(
                      Theme.of(context).textTheme,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SensorDiagnosisSection extends StatelessWidget {
  const SensorDiagnosisSection.wired({this.diagnosis, super.key})
    : _isWired = true;

  const SensorDiagnosisSection.wireless({this.diagnosis, super.key})
    : _isWired = false;
  final bool _isWired;
  final FullReportSensorDiagnosis? diagnosis;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = diagnosis == null
        ? _isWired
              ? [
                  _SensorItem(
                    asset: securityReportWiredPhotoBeamAsset,
                    fallback: Icons.sensor_door_outlined,
                    title: l10n.securityCenterWiredPhotoBeam,
                    details: [l10n.securityReportNotTriggered],
                  ),
                  _SensorItem(
                    asset: securityReportWiredELockAsset,
                    fallback: Icons.lock_outline,
                    title: l10n.securityCenterWiredELock,
                    details: [l10n.securityReportLocked],
                  ),
                ]
              : [
                  _SensorItem(
                    asset: securityReportWiredPhotoBeamAsset,
                    fallback: Icons.sensor_door_outlined,
                    title: l10n.securityCenterWiredPhotoBeam,
                    details: [
                      l10n.securityReportBatteryEnough,
                      l10n.securityReportNotTriggered,
                    ],
                  ),
                  _SensorItem(
                    asset: securityReportWirelessWicketDoorAsset,
                    fallback: Icons.meeting_room_outlined,
                    title: l10n.securityReportWirelessWicketDoor,
                    details: [
                      l10n.securityReportNotTriggered,
                      l10n.securityReportBatteryEnough,
                    ],
                  ),
                  _SensorItem(
                    asset: securityReportWirelessSafetyEdgeAsset,
                    fallback: Icons.rounded_corner_outlined,
                    title: l10n.securityReportWirelessSafetyEdge,
                    details: [
                      l10n.securityReportBatteryEnough,
                      l10n.securityReportNotTriggered,
                    ],
                  ),
                  _SensorItem(
                    asset: securityReportWirelessPositionSensorAsset,
                    fallback: Icons.sensors_outlined,
                    title: l10n.securityReportWirelessPositionSensor,
                    details: [
                      l10n.securityReportNotTriggered,
                      l10n.securityReportBatteryEnough,
                    ],
                  ),
                  _SensorItem(
                    asset: securityReportWiredELockAsset,
                    fallback: Icons.lock_outline,
                    title: l10n.securityCenterWirelessELock,
                    details: [
                      l10n.securityReportBatteryEnough,
                      l10n.securityReportLocked,
                    ],
                  ),
                ]
        : diagnosis!.sensors
              .map((sensor) => _sensorItem(sensor, l10n))
              .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 14),
          child: Text(
            _isWired
                ? l10n.securityReportWiredSensorsDiagnosis
                : l10n.securityReportWirelessSensorsDiagnosis,
            style: AppTextTokens.securityReportSectionTitle(
              Theme.of(context).textTheme,
            ),
          ),
        ),
        _SensorSummaryCard(isWired: _isWired, summary: diagnosis?.summary),
        for (final item in items)
          Padding(padding: const EdgeInsets.only(top: 20), child: item),
      ],
    );
  }

  _SensorItem _sensorItem(FullReportSensor sensor, AppLocalizations l10n) {
    final (asset, fallback, title) = switch (sensor.type) {
      FullReportSensorType.wiredPhotoBeam => (
        securityReportWiredPhotoBeamAsset,
        Icons.sensor_door_outlined,
        l10n.securityCenterWiredPhotoBeam,
      ),
      FullReportSensorType.wiredELock => (
        securityReportWiredELockAsset,
        Icons.lock_outline,
        l10n.securityCenterWiredELock,
      ),
      FullReportSensorType.wirelessWicketDoor => (
        securityReportWirelessWicketDoorAsset,
        Icons.meeting_room_outlined,
        l10n.securityReportWirelessWicketDoor,
      ),
      FullReportSensorType.wirelessSafetyEdge => (
        securityReportWirelessSafetyEdgeAsset,
        Icons.rounded_corner_outlined,
        l10n.securityReportWirelessSafetyEdge,
      ),
      FullReportSensorType.wirelessPositionSensor => (
        securityReportWirelessPositionSensorAsset,
        Icons.sensors_outlined,
        l10n.securityReportWirelessPositionSensor,
      ),
      FullReportSensorType.wirelessELock => (
        securityReportWiredELockAsset,
        Icons.lock_outline,
        l10n.securityCenterWirelessELock,
      ),
    };
    return _SensorItem(
      asset: asset,
      fallback: fallback,
      title: title,
      details: sensor.states
          .map(
            (state) => switch (state) {
              FullReportSensorDisplayState.batterySufficient =>
                l10n.securityReportBatteryEnough,
              FullReportSensorDisplayState.notTriggered =>
                l10n.securityReportNotTriggered,
              FullReportSensorDisplayState.locked => l10n.securityReportLocked,
            },
          )
          .toList(),
    );
  }
}

class _SensorSummaryCard extends StatelessWidget {
  const _SensorSummaryCard({required this.isWired, this.summary});

  final bool isWired;
  final FullReportSensorSummary? summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counts = summary == null
        ? (isWired ? ['2', '0', '0'] : ['3', '1', '2'])
        : [
            '${summary!.normalCount}',
            '${summary!.disconnectedCount}',
            '${summary!.abnormalCount}',
          ];
    return SecurityReportCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SensorCount(
            icon: Icons.link,
            label: l10n.securityReportNormal,
            count: counts[0],
            color: AppColors.securityReportNormal,
          ),
          _SensorCount(
            icon: Icons.link_off,
            label: l10n.securityReportDisconnect,
            count: counts[1],
            color: AppColors.securityReportDisconnected,
          ),
          _SensorCount(
            icon: Icons.error,
            label: l10n.securityReportAbnormal,
            count: counts[2],
            color: AppColors.securityReportAbnormal,
          ),
        ],
      ),
    );
  }
}

class _SensorItem extends StatelessWidget {
  const _SensorItem({
    required this.asset,
    required this.fallback,
    required this.title,
    required this.details,
  });

  final String asset;
  final IconData fallback;
  final String title;
  final List<String> details;

  @override
  Widget build(BuildContext context) => SecurityReportCard(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
    child: Row(
      children: [
        _ReportAssetPlaceholder(
          asset: asset,
          size: const Size(45, 45),
          fallback: fallback,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextTokens.securityReportSensorTitle(
                  Theme.of(context).textTheme,
                ),
              ),
              for (final detail in details)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    detail,
                    style: AppTextTokens.securityReportSensorDetail(
                      Theme.of(context).textTheme,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReportAssetPlaceholder extends StatelessWidget {
  const _ReportAssetPlaceholder({
    required this.asset,
    required this.size,
    required this.fallback,
  });

  final String asset;
  final Size size;
  final IconData fallback;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size.width,
    height: size.height,
    child: Image.asset(
      asset,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(
        fallback,
        color: AppColors.securityCenterSensorIcon,
        size: size.shortestSide * .6,
      ),
    ),
  );
}

class SafetySuggestionCard extends StatelessWidget {
  const SafetySuggestionCard({this.suggestions, super.key});

  final List<FullReportSafetySuggestionCode>? suggestions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final defaultSuggestions = [
      l10n.securityReportSuggestionCycles,
      l10n.securityReportSuggestionBattery,
      l10n.securityReportSuggestionMaintenance,
      l10n.securityReportSuggestionCurrent,
    ];
    final displaySuggestions =
        suggestions
            ?.map(
              (suggestion) => switch (suggestion) {
                FullReportSafetySuggestionCode.cycleMaintenance =>
                  l10n.securityReportSuggestionCycles,
                FullReportSafetySuggestionCode.safetyEdgeLowBattery =>
                  l10n.securityReportSuggestionBattery,
                FullReportSafetySuggestionCode.contactInstaller =>
                  l10n.securityReportSuggestionMaintenance,
                FullReportSafetySuggestionCode.openingCurrentExceeded =>
                  l10n.securityReportSuggestionCurrent,
              },
            )
            .toList() ??
        defaultSuggestions;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.securityReportSafetySuggestion,
            style: AppTextTokens.securityReportSuggestionTitle(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: 6),
          for (var index = 0; index < displaySuggestions.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${index + 1}. ${displaySuggestions[index]}',
                style: AppTextTokens.securityReportSuggestion(
                  Theme.of(context).textTheme,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SecurityReportActionButton extends StatelessWidget {
  const SecurityReportActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.securityReportActionSurface,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Opacity(
            opacity: onTap == null ? .45 : 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: AppColors.textPrimary),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: AppTextTokens.securityReportAction(
                    Theme.of(context).textTheme,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SensorCount extends StatelessWidget {
  const _SensorCount({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: color, size: 25),
      const SizedBox(height: 10),
      Text(
        label,
        style: AppTextTokens.securityReportLabel(Theme.of(context).textTheme),
      ),
      const SizedBox(height: 8),
      Text(
        count,
        style: AppTextTokens.securityReportSensorCount(
          Theme.of(context).textTheme,
        ),
      ),
    ],
  );
}

enum _ReportStatus { warning }

class _CardHeading extends StatelessWidget {
  const _CardHeading({required this.title, required this.status});

  final String title;
  final _ReportStatus status;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: AppTextTokens.securityReportCardTitle(
            Theme.of(context).textTheme,
          ),
        ),
      ),
      Icon(
        status == _ReportStatus.warning ? Icons.error : Icons.check_circle,
        color: status == _ReportStatus.warning
            ? AppColors.securityReportWarning
            : AppColors.securityCenterSuccess,
        size: 13,
      ),
    ],
  );
}
