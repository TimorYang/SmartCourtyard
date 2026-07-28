import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../domain/entities/full_report.dart';
import '../../domain/entities/safety_sensors_evaluation.dart';

/// Replace these named placeholders with exported design cut assets when ready.
const securityReportMotorBlueBg =
    'assets/icons/security_center/security_report_blue_bg.png';
const securityReportMotorIllustrationAssetPass =
    'assets/icons/security_center/security_report_motor_illustration_pass.png';
const securityReportMotorIllustrationAssetError =
    'assets/icons/security_center/security_report_motor_illustration_error.png';
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
  const SecurityReportHero({
    this.motorName,
    this.serialNumber,
    this.needsMaintenance = false,
    super.key,
  });

  final String? motorName;
  final String? serialNumber;
  final bool needsMaintenance;

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
              asset: needsMaintenance
                  ? securityReportMotorIllustrationAssetError
                  : securityReportMotorIllustrationAssetPass,
              size: const Size(190, 161),
              fallback: Icons.settings_input_component_outlined,
            ),
          ),
          Positioned(
            top: 240,
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    motorName ?? l10n.securityReportMotorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextTokens.securityReportDeviceName(
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
    final totalCycles =
        (summary?.operatedCycles ?? 0) + (summary?.remainingCycles ?? 0);
    final remainingRatio = totalCycles == 0
        ? 0.0
        : (summary?.remainingCycles ?? 0) / totalCycles;
    final remainingColor = remainingRatio >= .7
        ? AppColors.securityCenterSuccess2B2D2C
        : remainingRatio >= .4
        ? AppColors.securityReportWarning
        : AppColors.securityCenterError;
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
                  value: '${summary?.operatedCycles ?? 0}',
                  label: l10n.securityReportOperatedCycles,
                ),
              ),
              const SizedBox(
                height: 30,
                child: VerticalDivider(color: AppColors.securityReportDivider),
              ),
              Expanded(
                child: _Metric(
                  value: '${summary?.remainingCycles ?? 0}',
                  label: l10n.securityReportRemainingCycles,
                  valueColor: remainingColor,
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
  const _Metric({required this.value, required this.label, this.valueColor});

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsGeometry.only(left: valueColor == null ? 0 : 30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
    ),
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
            status: evaluation?.hasOverloadOrOvercurrent ?? false
                ? _ReportStatus.warning
                : _ReportStatus.normal,
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
  static const _ranges = [(80, 100), (60, 80), (40, 60), (20, 40), (0, 20)];

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
            flex: 5,
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
            flex: 2,
            child: Column(
              key: const ValueKey<String>('balance-status-table'),
              children: [
                for (var index = 0; index < _rowCount; index++)
                  Expanded(
                    child: CustomPaint(
                      key: ValueKey<String>('balance-status-row-$index'),
                      foregroundPainter: const _DashedStatusRowPainter(),
                      child: Center(
                        child: evaluation == null
                            ? const SizedBox.shrink()
                            : _segment(index) == null
                            ? Text(
                                l10n.securityReportBalanceStatusUnavailable,
                                style: AppTextTokens.securityReportBody(
                                  Theme.of(context).textTheme,
                                ),
                              )
                            : _segment(index)!.isNormal
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 13,
                                    color: AppColors.securityCenterSuccess,
                                  ),
                                  const SizedBox(width: 5),
                                  // Flexible(
                                  //   child: Text(
                                  //     _statusLabel(context, index),
                                  //     overflow: TextOverflow.ellipsis,
                                  //     style: AppTextTokens.securityReportBody(Theme.of(context).textTheme),
                                  //   ),
                                  // ),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error,
                                    size: 9,
                                    color: AppColors.securityReportWarning,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      _statusLabel(context, index),
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          AppTextTokens.securityReportWarning(
                                            Theme.of(context).textTheme,
                                          ),
                                    ),
                                  ),
                                ],
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

  FullReportBalanceSegment? _segment(int index) {
    final range = _ranges[index];
    for (final segment in evaluation?.segments ?? const []) {
      if (segment.matchesRange(range.$1, range.$2)) return segment;
    }
    return null;
  }

  String _statusLabel(BuildContext context, int index) {
    final label = _segment(index)?.statusLabel?.trim();
    return label == null || label.isEmpty
        ? AppLocalizations.of(context).securityReportBalanceStatusUnavailable
        : label;
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
    final showFrequentOperationAlert =
        record?.hasFrequentOperationAlert ?? false;
    return SecurityReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            title: l10n.securityReportOperationRecord,
            status: showFrequentOperationAlert
                ? _ReportStatus.warning
                : _ReportStatus.normal,
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
            child: _InteractiveOperationChart(
              range: range,
              points: record?.points ?? const [],
            ),
          ),
          const SizedBox(height: 10),
          if (showFrequentOperationAlert)
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

class _InteractiveOperationChart extends StatefulWidget {
  const _InteractiveOperationChart({required this.range, required this.points});

  final RecordRange range;
  final List<FullReportOperationCyclePoint> points;

  @override
  State<_InteractiveOperationChart> createState() =>
      _InteractiveOperationChartState();
}

class _InteractiveOperationChartState
    extends State<_InteractiveOperationChart> {
  int? _selectedIndex;

  void _updateSelection(Offset position, Size size) {
    final index = _OperationChartLayout.hitTest(
      position: position,
      size: size,
      points: widget.points,
    );
    if (index != _selectedIndex) setState(() => _selectedIndex = index);
  }

  void _clearSelection() {
    if (_selectedIndex != null) setState(() => _selectedIndex = null);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) => _updateSelection(event.localPosition, size),
        onPointerMove: (event) => _updateSelection(event.localPosition, size),
        onPointerUp: (_) => _clearSelection(),
        onPointerCancel: (_) => _clearSelection(),
        child: CustomPaint(
          key: ValueKey<String>(
            'operation-chart-selected-${_selectedIndex ?? 'none'}',
          ),
          painter: _OperationChartPainter(
            range: widget.range,
            points: widget.points,
            selectedIndex: _selectedIndex,
          ),
        ),
      );
    },
  );
}

abstract final class _OperationChartLayout {
  static Rect chart(Size size) =>
      Rect.fromLTWH(22, 10, size.width - 22, size.height - 26);

  static double yAxisMaximum(List<FullReportOperationCyclePoint> points) {
    final maximum = points.fold<int>(
      0,
      (value, point) => point.cycles > value ? point.cycles : value,
    );
    return maximum == 0 ? 1 : (maximum * 1.2).ceilToDouble();
  }

  static List<Rect> bars(
    Size size,
    List<FullReportOperationCyclePoint> points,
  ) {
    if (points.isEmpty) return const [];
    final chartArea = chart(size);
    final maximum = yAxisMaximum(points);
    final barWidth = (chartArea.width / points.length * .55)
        .clamp(3.0, 12.0)
        .toDouble();
    return List<Rect>.generate(points.length, (index) {
      final x = points.length == 1
          ? chartArea.left + chartArea.width / 2
          : chartArea.left + chartArea.width * index / (points.length - 1);
      final height = chartArea.height * points[index].cycles / maximum;
      return Rect.fromLTWH(
        x - barWidth / 2,
        chartArea.bottom - height,
        barWidth,
        height,
      );
    });
  }

  static int? hitTest({
    required Offset position,
    required Size size,
    required List<FullReportOperationCyclePoint> points,
  }) {
    final bars = _OperationChartLayout.bars(size, points);
    for (var index = 0; index < bars.length; index++) {
      if (bars[index].height > 0 && bars[index].contains(position)) {
        return index;
      }
    }
    return null;
  }
}

class _OperationChartPainter extends CustomPainter {
  const _OperationChartPainter({
    required this.range,
    required this.points,
    this.selectedIndex,
  });

  final RecordRange range;
  final List<FullReportOperationCyclePoint> points;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.securityReportChartGrid
      ..strokeWidth = 1;
    final axis = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 1.2;
    final chart = _OperationChartLayout.chart(size);
    for (var index = 0; index <= 5; index++) {
      final y = chart.bottom - chart.height * index / 5;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }
    canvas.drawLine(
      Offset(chart.left, chart.bottom),
      Offset(chart.right, chart.bottom),
      axis,
    );
    final normalBar = Paint()..color = AppColors.securityReportSegmentSelected;
    final warningBar = Paint()..color = AppColors.securityReportChartBar;
    if (points.isEmpty) {
      _paintLabels(canvas, chart, maxValue: 0);
      return;
    }
    final maxValue = _OperationChartLayout.yAxisMaximum(points);
    final bars = _OperationChartLayout.bars(size, points);
    for (var index = 0; index < bars.length; index++) {
      final isWarning = points[index].isFrequentOperation;
      canvas.drawRect(bars[index], isWarning ? warningBar : normalBar);
    }
    _paintLabels(canvas, chart, maxValue: maxValue);
    if (selectedIndex case final index? when index < points.length) {
      _paintTooltip(
        canvas,
        chart,
        bars[index],
        points[index].cycles,
        points[index].isFrequentOperation ? warningBar.color : normalBar.color,
      );
    }
  }

  void _paintLabels(Canvas canvas, Rect chart, {required double maxValue}) {
    for (var index = 0; index <= 5; index++) {
      final y = chart.bottom - chart.height * index / 5 - 8;
      final painter = TextPainter(
        text: TextSpan(
          text: (maxValue * index / 5).round().toString(),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(chart.left - 24, y));
    }
    for (var index = 0; index < points.length; index++) {
      final label = points[index].axisLabel ?? '';
      if (label.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = points.length == 1
          ? chart.left + chart.width / 2 - painter.width / 2
          : chart.left +
                chart.width * index / (points.length - 1) -
                painter.width / 2;
      painter.paint(canvas, Offset(x, chart.bottom + 8));
    }
  }

  void _paintTooltip(
    Canvas canvas,
    Rect chart,
    Rect bar,
    int value,
    Color valueColor,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: _formatValue(value.toDouble()),
        style: TextStyle(
          color: valueColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    const horizontalPadding = 15.0;
    const verticalPadding = 9.0;
    final width = textPainter.width + horizontalPadding * 2;
    const height = 32.0;
    final left = (bar.center.dx - width / 2)
        .clamp(chart.left, chart.right - width)
        .toDouble();
    final top = (bar.top - height - 12)
        .clamp(chart.top, chart.bottom - height)
        .toDouble();
    final tooltip = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, width, height),
      const Radius.circular(3),
    );
    final background = Paint()..color = AppColors.securityReportChartTooltip;
    canvas.drawRRect(tooltip, background);
    textPainter.paint(
      canvas,
      Offset(left + horizontalPadding, top + verticalPadding),
    );
  }

  String _formatValue(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toString();

  @override
  bool shouldRepaint(covariant _OperationChartPainter oldDelegate) =>
      oldDelegate.range != range ||
      oldDelegate.points != points ||
      oldDelegate.selectedIndex != selectedIndex;
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

class MotorFunctionStatusCard extends StatefulWidget {
  const MotorFunctionStatusCard({this.status, super.key});

  final FullReportMotorFunctionStatus? status;

  @override
  State<MotorFunctionStatusCard> createState() =>
      _MotorFunctionStatusCardState();
}

class _MotorFunctionStatusCardState extends State<MotorFunctionStatusCard> {
  var _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reportStatus = widget.status;
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
        ..[l10n.securityReportAutoCloseTime] = _withUnit(
          reportStatus.autoCloseSeconds,
          reportStatus.autoCloseUnit,
          's',
        )
        ..[l10n.securityReportAutoCloseCondition] =
            reportStatus.autoCloseCondition ==
                FullReportAutoCloseCondition.anyPosition
            ? l10n.securityReportAnyPosition
            : 'Top position'
        ..[l10n.securityReportLedOffDelay] = _withUnit(
          reportStatus.ledOffDelayMinutes,
          reportStatus.ledOffDelayUnit,
          'min',
        )
        ..[l10n.securityReportPartialOpen] = _withUnit(
          reportStatus.partialOpenCentimeters,
          reportStatus.partialOpenUnit,
          'cm',
        )
        ..[l10n.securityReportIgnoreObstructionHeight] = _withUnit(
          reportStatus.ignoreObstructionHeightCentimeters,
          reportStatus.ignoreObstructionHeightUnit,
          'cm',
        )
        ..[l10n.securityReportPhotoBeamFunction] = reportStatus.photoBeamEnabled
            ? l10n.securityReportOn
            : 'Off'
        ..[l10n.securityReportCommunityMode] = reportStatus.communityModeEnabled
            ? l10n.securityReportOn
            : 'Off'
        ..[l10n.securityCenterWiredELock] = reportStatus.wiredELockEnabled
            ? l10n.securityReportOn
            : 'Off';
    }
    return SecurityReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            expanded: _isExpanded,
            child: InkWell(
              key: const ValueKey<String>('motor-function-status-toggle'),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.securityReportMotorFunctionStatus,
                        style: AppTextTokens.securityReportCardTitle(
                          Theme.of(context).textTheme,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0 : 0.5,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOut,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 13),
                    child: Column(
                      children: [
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
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _withUnit(int value, String? unit, String fallbackUnit) =>
      '$value${unit?.isNotEmpty == true ? unit : fallbackUnit}';
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
                    details: [
                      _SensorDetail(
                        l10n.securityReportNotTriggered,
                        _SensorDetailTone.normal,
                      ),
                    ],
                  ),
                  _SensorItem(
                    asset: securityReportWiredELockAsset,
                    fallback: Icons.lock_outline,
                    title: l10n.securityCenterWiredELock,
                    details: [
                      _SensorDetail(
                        l10n.securityReportLocked,
                        _SensorDetailTone.alert,
                      ),
                    ],
                  ),
                ]
              : [
                  _SensorItem(
                    asset: securityReportWiredPhotoBeamAsset,
                    fallback: Icons.sensor_door_outlined,
                    title: l10n.securityCenterWiredPhotoBeam,
                    details: _defaultWirelessDetails(l10n),
                  ),
                  _SensorItem(
                    asset: securityReportWirelessWicketDoorAsset,
                    fallback: Icons.meeting_room_outlined,
                    title: l10n.securityReportWirelessWicketDoor,
                    details: _defaultWirelessDetails(l10n),
                  ),
                  _SensorItem(
                    asset: securityReportWirelessSafetyEdgeAsset,
                    fallback: Icons.rounded_corner_outlined,
                    title: l10n.securityReportWirelessSafetyEdge,
                    details: _defaultWirelessDetails(l10n),
                  ),
                  _SensorItem(
                    asset: securityReportWirelessPositionSensorAsset,
                    fallback: Icons.sensors_outlined,
                    title: l10n.securityReportWirelessPositionSensor,
                    details: _defaultWirelessDetails(l10n),
                  ),
                  _SensorItem(
                    asset: securityReportWiredELockAsset,
                    fallback: Icons.lock_outline,
                    title: l10n.securityCenterWirelessELock,
                    details: [
                      _SensorDetail(
                        l10n.securityReportBatteryEnough,
                        _SensorDetailTone.normal,
                      ),
                      _SensorDetail(
                        l10n.securityReportLocked,
                        _SensorDetailTone.alert,
                      ),
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
      FullReportSensorType.wirelessPhotoBeam => (
        securityReportWiredPhotoBeamAsset,
        Icons.sensor_door_outlined,
        l10n.securityCenterWirelessPhotoBeam,
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
      FullReportSensorType.wirelessSlackRope => (
        securityReportWirelessSafetyEdgeAsset,
        Icons.radar,
        l10n.safetySensorsWirelessSlackRope,
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
      details: _detailsFor(sensor, l10n),
    );
  }

  List<_SensorDetail> _detailsFor(
    FullReportSensor sensor,
    AppLocalizations l10n,
  ) {
    final status = sensor.status;
    if (status == null) {
      return sensor.states
          .map(
            (state) => switch (state) {
              FullReportSensorDisplayState.batterySufficient => _SensorDetail(
                l10n.securityReportBatteryEnough,
                _SensorDetailTone.normal,
              ),
              FullReportSensorDisplayState.notTriggered => _SensorDetail(
                l10n.securityReportNotTriggered,
                _SensorDetailTone.normal,
              ),
              FullReportSensorDisplayState.locked => _SensorDetail(
                l10n.securityReportLocked,
                _SensorDetailTone.alert,
              ),
            },
          )
          .toList(growable: false);
    }
    if (!_isWired && status == SafetySensorStatus.disconnected) {
      return [
        _SensorDetail(l10n.safetySensorOffline, _SensorDetailTone.offline),
      ];
    }
    final statusDetail = _SensorDetail(
      sensor.statusLabel?.trim().isNotEmpty == true
          ? sensor.statusLabel!.trim()
          : _statusLabel(l10n, status),
      _statusTone(status),
    );
    if (_isWired) return [statusDetail];
    return [_batteryDetail(sensor.batteryStatus, l10n), statusDetail];
  }

  List<_SensorDetail> _defaultWirelessDetails(AppLocalizations l10n) => [
    _SensorDetail(l10n.securityReportBatteryEnough, _SensorDetailTone.normal),
    _SensorDetail(l10n.securityReportNotTriggered, _SensorDetailTone.normal),
  ];

  _SensorDetail _batteryDetail(
    SafetySensorBatteryStatus? status,
    AppLocalizations l10n,
  ) => switch (status) {
    SafetySensorBatteryStatus.normal => _SensorDetail(
      l10n.securityReportBatteryEnough,
      _SensorDetailTone.normal,
    ),
    SafetySensorBatteryStatus.low => _SensorDetail(
      l10n.securityReportBatteryLow,
      _SensorDetailTone.alert,
    ),
    SafetySensorBatteryStatus.unknown ||
    null => _SensorDetail(l10n.homeDoorStateUnknown, _SensorDetailTone.offline),
  };

  String _statusLabel(AppLocalizations l10n, SafetySensorStatus status) =>
      switch (status) {
        SafetySensorStatus.notTriggered => l10n.safetySensorNotTriggered,
        SafetySensorStatus.disconnected => l10n.safetySensorOffline,
        SafetySensorStatus.triggered => l10n.safetySensorTriggered,
        SafetySensorStatus.unlocked => l10n.safetySensorUnlocked,
        SafetySensorStatus.locked => l10n.safetySensorLocked,
      };

  _SensorDetailTone _statusTone(SafetySensorStatus status) => switch (status) {
    SafetySensorStatus.disconnected => _SensorDetailTone.offline,
    SafetySensorStatus.triggered ||
    SafetySensorStatus.locked => _SensorDetailTone.alert,
    SafetySensorStatus.notTriggered ||
    SafetySensorStatus.unlocked => _SensorDetailTone.normal,
  };
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
  final List<_SensorDetail> details;

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
                    detail.text,
                    style: switch (detail.tone) {
                      _SensorDetailTone.normal =>
                        AppTextTokens.safetySensorItemSuccess(
                          Theme.of(context).textTheme,
                        ),
                      _SensorDetailTone.alert =>
                        AppTextTokens.safetySensorItemAlert(
                          Theme.of(context).textTheme,
                        ),
                      _SensorDetailTone.offline =>
                        AppTextTokens.safetySensorItemOffline(
                          Theme.of(context).textTheme,
                        ),
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SensorDetail {
  const _SensorDetail(this.text, this.tone);

  final String text;
  final _SensorDetailTone tone;
}

enum _SensorDetailTone { normal, alert, offline }

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

enum _ReportStatus { normal, warning }

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
