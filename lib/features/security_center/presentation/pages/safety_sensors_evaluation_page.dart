import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../../domain/entities/safety_sensors_evaluation.dart';
import 'safety_sensor_battery_solution_page.dart';

class SafetySensorsEvaluationPage extends ConsumerWidget {
  const SafetySensorsEvaluationPage({required this.deviceId, super.key});

  static const routeName = 'safety-sensors-evaluation';
  static const routePath = '/safety-sensors-evaluation';

  static const _wiredDoorAsset =
      'assets/icons/security_center/safety_wired_door_layout.png';
  static const _wirelessDoorAsset =
      'assets/icons/security_center/safety_wired_door_layout.png';
  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evaluation = ref.watch(safetySensorsEvaluationProvider(deviceId));
    return Scaffold(
      backgroundColor: AppColors.securityCenterBackground,
      appBar: const FlinxNavigationBar(
        title: 'Safety Sensors Evaluation',
        showBottomDivider: false,
      ),
      body: ListView(
        key: ValueKey<String>('safety-sensors-scroll-$deviceId'),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          _SensorMetrics(evaluation: evaluation),
          const SizedBox(height: 16),
          _SensorGroupCard(
            title: 'Wired sensor status',
            doorAsset: _wiredDoorAsset,
            group: evaluation.wiredSensorGroup,
            deviceId: deviceId,
          ),
          const SizedBox(height: 15),
          _SensorGroupCard(
            title: 'Wireless Sensors Status',
            doorAsset: _wirelessDoorAsset,
            showActions: true,
            group: evaluation.wirelessSensorGroup,
            deviceId: deviceId,
          ),
        ],
      ),
    );
  }
}

class _SensorMetrics extends StatelessWidget {
  const _SensorMetrics({required this.evaluation});

  final SafetySensorsEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            iconAsset: 'safety_metric_sensors',
            fallbackIcon: Icons.sensors,
            label: 'Sensors',
            value: evaluation.totalSensorCount,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            iconAsset: 'safety_metric_fine',
            fallbackIcon: Icons.check_circle,
            label: 'Fine',
            value: evaluation.fineSensorCount,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            iconAsset: 'safety_metric_triggered',
            fallbackIcon: Icons.error,
            label: 'Abnormal',
            value: evaluation.abnormalSensorCount,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            iconAsset: 'safety_metric_low_power',
            fallbackIcon: Icons.battery_alert_outlined,
            label: 'Low power',
            value: evaluation.lowPowerSensorCount,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.iconAsset,
    required this.fallbackIcon,
    required this.label,
    required this.value,
  });

  final String iconAsset;
  final IconData fallbackIcon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.securityCenterCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.safetySensorMetricIconSurface,
              borderRadius: BorderRadius.circular(
                AppShapeTokens.safetySensorMetricIconRadius,
              ),
            ),
            child: SizedBox.square(
              dimension: 36,
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Image.asset(
                  'assets/icons/security_center/$iconAsset.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    fallbackIcon,
                    color: AppColors.safetySensorMetricIcon,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextTokens.safetySensorMetricLabel(textTheme),
          ),
          Text(
            '$value',
            key: ValueKey<String>('sensor-metric-$label-value'),
            style: AppTextTokens.safetySensorMetricValue(textTheme),
          ),
        ],
      ),
    );
  }
}

class _SensorGroupCard extends StatelessWidget {
  const _SensorGroupCard({
    required this.title,
    required this.doorAsset,
    required this.group,
    required this.deviceId,
    this.showActions = false,
  });

  final String title;
  final String doorAsset;
  final SafetySensorGroup group;
  final String deviceId;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.securityCenterCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 25, 14, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextTokens.securityCenterHeroTitle(
                      Theme.of(context).textTheme,
                    ).copyWith(fontSize: 15),
                  ),
                ),
                _GroupStatusIcon(status: group.status),
              ],
            ),
            const SizedBox(height: 20),
            _DoorLayoutPlaceholder(assetPath: doorAsset),
            if (showActions) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Expanded(
                    child: _SensorActionButton(
                      icon: Icons.link,
                      label: 'Match',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _SensorActionButton(
                      icon: Icons.tune,
                      label: 'Manage',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            for (var index = 0; index < group.sensors.length; index++) ...[
              if (index > 0) const SizedBox(height: 10),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: showActions ? 350 : 250,
                  ),
                  child: _SensorRow(
                    sensor: group.sensors[index],
                    isWireless: showActions,
                    deviceId: deviceId,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DoorLayoutPlaceholder extends StatelessWidget {
  const _DoorLayoutPlaceholder({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 225,
      width: double.infinity,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.securityCenterBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(
              Icons.image_outlined,
              size: 54,
              color: AppColors.safetySensorPlaceholder,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupStatusIcon extends StatelessWidget {
  const _GroupStatusIcon({required this.status});

  final SafetySensorGroupStatus status;

  @override
  Widget build(BuildContext context) => switch (status) {
    SafetySensorGroupStatus.normal => const Icon(
      Icons.check_circle,
      color: AppColors.securityCenterSuccess,
      size: 13,
    ),
    SafetySensorGroupStatus.abnormal => const Icon(
      Icons.error,
      color: AppColors.securityCenterError,
      size: 13,
    ),
    SafetySensorGroupStatus.offline => const Icon(
      Icons.cloud_off,
      color: AppColors.textMuted,
      size: 13,
    ),
  };
}

class _SensorActionButton extends StatelessWidget {
  const _SensorActionButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.safetySensorAction,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.safetySensorAction(
                    Theme.of(context).textTheme,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensorRow extends StatefulWidget {
  const _SensorRow({
    required this.sensor,
    required this.isWireless,
    required this.deviceId,
  });

  final SafetySensor sensor;
  final bool isWireless;
  final String deviceId;

  @override
  State<_SensorRow> createState() => _SensorRowState();
}

class _SensorRowState extends State<_SensorRow> {
  var _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isLowBatteryAlert =
        widget.isWireless &&
        widget.sensor.batteryStatus == SafetySensorBatteryStatus.low;
    final isBatteryNavigation = widget.isWireless && !isLowBatteryAlert;
    final isExpandable = widget.isWireless;

    return Semantics(
      button: isExpandable,
      expanded: isExpandable ? _isExpanded : null,
      child: GestureDetector(
        key: ValueKey<String>('sensor-toggle-${widget.sensor.sensorName}'),
        behavior: HitTestBehavior.opaque,
        onTap: isExpandable
            ? () => setState(() => _isExpanded = !_isExpanded)
            : null,
        child: Container(
          key: ValueKey<String>('sensor-${widget.sensor.sensorName}'),
          decoration: BoxDecoration(
            color: AppColors.safetySensorItemSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SensorRowHeader(
                sensor: widget.sensor,
                l10n: l10n,
                textTheme: textTheme,
                isBatteryNavigation: isBatteryNavigation,
                isLowBatteryAlert: isLowBatteryAlert,
                isExpanded: _isExpanded,
                deviceId: widget.deviceId,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: _SensorOperationChart(
                          key: ValueKey<String>(
                            'sensor-operation-chart-${widget.sensor.sensorName}',
                          ),
                          points: widget.sensor.operationPoints,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensorRowHeader extends StatelessWidget {
  const _SensorRowHeader({
    required this.sensor,
    required this.l10n,
    required this.textTheme,
    required this.isBatteryNavigation,
    required this.isLowBatteryAlert,
    required this.isExpanded,
    required this.deviceId,
  });

  final SafetySensor sensor;
  final AppLocalizations l10n;
  final TextTheme textTheme;
  final bool isBatteryNavigation;
  final bool isLowBatteryAlert;
  final bool isExpanded;
  final String deviceId;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(15, isLowBatteryAlert ? 30 : 10, 15, 10),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.securityCenterCard,
                  borderRadius: BorderRadius.circular(
                    AppShapeTokens.safetySensorMetricIconRadius,
                  ),
                ),
                child: SizedBox.square(
                  dimension: 45,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Image.asset(
                      _sensorAssetPath(sensor.id),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        _sensorFallbackIcon(sensor.id),
                        size: 34,
                        color: AppColors.securityCenterSensorIcon,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            sensor.sensorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextTokens.safetySensorItemTitle(
                              textTheme,
                            ),
                          ),
                        ),
                        if (isLowBatteryAlert) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            key: ValueKey<String>('sensor-low-battery'),
                            Icons.battery_0_bar,
                            size: 12,
                            color: AppColors.securityCenterError,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isBatteryNavigation)
                      const Icon(
                        key: ValueKey<String>('sensor-battery'),
                        Icons.battery_0_bar,
                        size: 22,
                        color: AppColors.securityCenterSuccess,
                      )
                    else
                      Text(
                        _statusLabel(l10n, sensor.status),
                        key: ValueKey<String>(
                          'sensor-status-${sensor.sensorName}',
                        ),
                        style: isLowBatteryAlert
                            ? AppTextTokens.safetySensorItemAlert(textTheme)
                            : AppTextTokens.safetySensorItemStatus(textTheme),
                      ),
                  ],
                ),
              ),
              if (isBatteryNavigation || isLowBatteryAlert)
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  child: Icon(
                    key: ValueKey<String>(
                      'sensor-navigation-chevron-${sensor.sensorName}',
                    ),
                    Icons.chevron_right,
                    size: 25,
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
        ),
        if (isLowBatteryAlert)
          Positioned(
            top: 10,
            right: 6,
            child: GestureDetector(
              key: const ValueKey<String>('sensor-replace-battery-action'),
              behavior: HitTestBehavior.opaque,
              onTap: () => context.pushNamed(
                SafetySensorBatterySolutionPage.routeName,
                queryParameters: {'deviceId': deviceId, 'sensorId': sensor.id},
              ),
              child: Container(
                key: const ValueKey<String>('sensor-replace-battery-help'),
                padding: const EdgeInsets.only(bottom: 1),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.securityCenterError,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Text(
                  l10n.safetySensorReplaceBattery,
                  style: AppTextTokens.safetySensorItemAlert(textTheme),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _statusLabel(AppLocalizations l10n, SafetySensorStatus status) =>
    switch (status) {
      SafetySensorStatus.normal => '',
      SafetySensorStatus.disconnected => l10n.securityReportDisconnect,
      SafetySensorStatus.triggered => l10n.safetySensorTriggered,
    };

String _sensorAssetPath(String sensorId) {
  final assetName = switch (sensorId) {
    'wired-photo-beam' ||
    'wireless-photo-beam' => 'security_report_motor_wired_photo_beam_icon',
    'wired-e-lock' || 'wireless-e-lock' => 'security_report_motor_wired_e_lock',
    'wireless-wicket-door' => 'security_report_wireless_wicket_door',
    'wireless-safety-edge' => 'security_report_wireless_safety_edge',
    _ => 'security_report_motor_wired_photo_beam_icon',
  };
  return 'assets/icons/security_center/$assetName.png';
}

IconData _sensorFallbackIcon(String sensorId) => switch (sensorId) {
  'wired-e-lock' || 'wireless-e-lock' => Icons.lock_outline,
  'wireless-wicket-door' => Icons.door_sliding_outlined,
  'wireless-safety-edge' => Icons.radar,
  _ => Icons.sensors,
};

class _SensorOperationChart extends StatelessWidget {
  const _SensorOperationChart({required this.points, super.key});

  final List<SafetySensorOperationPoint> points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.securityCenterCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.securityReportTimeCyclesAxis,
              style: AppTextTokens.securityReportBody(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(painter: _SensorOperationChartPainter(points)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorOperationChartPainter extends CustomPainter {
  const _SensorOperationChartPainter(this.points);

  final List<SafetySensorOperationPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.securityReportChartGrid
      ..strokeWidth = 1;
    final axis = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 1.2;
    final bar = Paint()..color = AppColors.securityReportChartBar;
    final chart = Rect.fromLTWH(30, 8, size.width - 36, size.height - 32);
    const maximumCycles = 25;

    for (var index = 0; index <= 5; index++) {
      final y = chart.bottom - chart.height * index / 5;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
      _paintText(
        canvas,
        '${index * 5}',
        Offset(chart.left - 24, y - 8),
        fontSize: 11,
        color: AppColors.textPrimary,
      );
    }
    canvas.drawLine(
      Offset(chart.left, chart.bottom),
      Offset(chart.right, chart.bottom),
      axis,
    );

    for (final point in points) {
      final x = chart.left + chart.width * point.occurredAt.hour / 23;
      final height =
          chart.height * point.cycles.clamp(0, maximumCycles) / maximumCycles;
      canvas.drawRect(
        Rect.fromLTWH(x - 4, chart.bottom - height, 8, height),
        bar,
      );
    }
    for (var hour = 0; hour < 24; hour++) {
      final painter = TextPainter(
        text: TextSpan(
          text: hour.toString(),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = chart.left + chart.width * hour / 23 - painter.width / 2;
      painter.paint(canvas, Offset(x, chart.bottom + 8));
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required Color color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SensorOperationChartPainter oldDelegate) =>
      oldDelegate.points != points;
}
