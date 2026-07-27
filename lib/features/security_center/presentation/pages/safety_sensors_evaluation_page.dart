import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/safety_sensors_evaluation_controller.dart';
import '../../domain/entities/safety_sensors_evaluation.dart';
import 'safety_sensor_battery_solution_page.dart';

class SafetySensorsEvaluationPage extends ConsumerStatefulWidget {
  const SafetySensorsEvaluationPage({
    required this.doorId,
    required this.deviceId,
    super.key,
  });

  static const routeName = 'safety-sensors-evaluation';
  static const routePath = '/safety-sensors-evaluation';

  static const _wiredDoorAsset =
      'assets/icons/security_center/safety_wired_door_layout.png';
  static const _wirelessDoorAsset =
      'assets/icons/security_center/safety_wired_door_asset.png';
  final String doorId;
  final String deviceId;

  @override
  ConsumerState<SafetySensorsEvaluationPage> createState() =>
      _SafetySensorsEvaluationPageState();
}

class _SafetySensorsEvaluationPageState
    extends ConsumerState<SafetySensorsEvaluationPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(
            safetySensorsEvaluationControllerProvider(widget.doorId).notifier,
          )
          .load(doorId: widget.doorId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      safetySensorsEvaluationControllerProvider(widget.doorId),
    );
    return state.when(
      loading: () =>
          _stateScaffold(const Center(child: CircularProgressIndicator())),
      error: (_, _) => _stateScaffold(
        Center(
          child: TextButton(
            onPressed: () => ref
                .read(
                  safetySensorsEvaluationControllerProvider(
                    widget.doorId,
                  ).notifier,
                )
                .load(doorId: widget.doorId),
            child: Text(AppLocalizations.of(context).safetySensorsLoadFailed),
          ),
        ),
      ),
      data: (evaluation) =>
          evaluation.wiredSensorGroup.sensors.isEmpty &&
              evaluation.wirelessSensorGroup.sensors.isEmpty
          ? _stateScaffold(
              Center(
                child: Text(AppLocalizations.of(context).safetySensorsEmpty),
              ),
            )
          : _contentScaffold(context, evaluation),
    );
  }

  Widget _stateScaffold(Widget body) => Scaffold(
    backgroundColor: AppColors.securityCenterBackground,
    appBar: FlinxNavigationBar(
      title: AppLocalizations.of(context).securityCenterSafetySensorsEvaluation,
      showBottomDivider: false,
    ),
    body: body,
  );

  Widget _contentScaffold(
    BuildContext context,
    SafetySensorsEvaluation evaluation,
  ) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.securityCenterBackground,
      appBar: FlinxNavigationBar(
        title: l10n.securityCenterSafetySensorsEvaluation,
        showBottomDivider: false,
      ),
      body: ListView(
        key: ValueKey<String>('safety-sensors-scroll-${widget.deviceId}'),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          _SensorMetrics(evaluation: evaluation),
          const SizedBox(height: 16),
          _SensorGroupCard(
            title: l10n.safetySensorsWiredStatus,
            doorAsset: SafetySensorsEvaluationPage._wiredDoorAsset,
            group: evaluation.wiredSensorGroup,
            deviceId: widget.deviceId,
            doorId: widget.doorId,
          ),
          const SizedBox(height: 15),
          _SensorGroupCard(
            title: l10n.safetySensorsWirelessStatus,
            doorAsset: SafetySensorsEvaluationPage._wirelessDoorAsset,
            showActions: true,
            group: evaluation.wirelessSensorGroup,
            deviceId: widget.deviceId,
            doorId: widget.doorId,
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
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            iconAsset: 'safety_metric_sensors',
            fallbackIcon: Icons.sensors,
            label: l10n.safetySensorsMetricSensors,
            value: evaluation.totalSensorCount,
            error: false,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            iconAsset: 'safety_metric_fine',
            fallbackIcon: Icons.check_circle,
            label: l10n.safetySensorsMetricFine,
            value: evaluation.fineSensorCount,
            error: false,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            iconAsset: 'safety_metric_triggered',
            fallbackIcon: Icons.error,
            label: l10n.safetySensorsMetricAbnormal,
            value: evaluation.abnormalSensorCount,
            error: true,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            iconAsset: 'safety_metric_low_power',
            fallbackIcon: Icons.battery_alert_outlined,
            label: l10n.safetySensorsMetricLowPower,
            value: evaluation.lowPowerSensorCount,
            error: true,
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
    required this.error,
  });

  final String iconAsset;
  final IconData fallbackIcon;
  final String label;
  final int value;
  final bool error;

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
            style: error
                ? AppTextTokens.safetySensorMetricValueError(textTheme)
                : AppTextTokens.safetySensorMetricValue(textTheme),
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
    required this.doorId,
    this.showActions = false,
  });

  final String title;
  final String doorAsset;
  final SafetySensorGroup group;
  final String deviceId;
  final String doorId;
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
              Row(
                children: [
                  Expanded(
                    child: _SensorActionButton(
                      icon: Icons.link,
                      label: AppLocalizations.of(context).safetySensorsMatch,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _SensorActionButton(
                      icon: Icons.tune,
                      label: AppLocalizations.of(context).safetySensorsManage,
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
                    doorId: doorId,
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
      Icons.error,
      color: AppColors.securityCenterError,
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
    required this.doorId,
  });

  final SafetySensor sensor;
  final bool isWireless;
  final String deviceId;
  final String doorId;

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
    final showBatteryOnStatusLine =
        widget.isWireless &&
        _isNormalSensorStatus(widget.sensor.status) &&
        widget.sensor.batteryStatus == SafetySensorBatteryStatus.normal;
    final isExpandable = widget.isWireless;

    return Semantics(
      button: isExpandable,
      expanded: isExpandable ? _isExpanded : null,
      child: GestureDetector(
        key: ValueKey<String>(
          'sensor-toggle-${_sensorName(l10n, widget.sensor.sensorCode)}',
        ),
        behavior: HitTestBehavior.opaque,
        onTap: isExpandable
            ? () => setState(() => _isExpanded = !_isExpanded)
            : null,
        child: Container(
          key: ValueKey<String>(
            'sensor-${_sensorName(l10n, widget.sensor.sensorCode)}',
          ),
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
                isLowBatteryAlert: isLowBatteryAlert,
                showBatteryOnStatusLine: showBatteryOnStatusLine,
                isExpanded: _isExpanded,
                isWireless: widget.isWireless,
                deviceId: widget.deviceId,
                doorId: widget.doorId,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: _SensorOperationChart(
                          key: ValueKey<String>(
                            'sensor-operation-chart-${_sensorName(l10n, widget.sensor.sensorCode)}',
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
    required this.isLowBatteryAlert,
    required this.showBatteryOnStatusLine,
    required this.isExpanded,
    required this.isWireless,
    required this.deviceId,
    required this.doorId,
  });

  final SafetySensor sensor;
  final AppLocalizations l10n;
  final TextTheme textTheme;
  final bool isLowBatteryAlert;
  final bool showBatteryOnStatusLine;
  final bool isExpanded;
  final bool isWireless;
  final String deviceId;
  final String doorId;

  @override
  Widget build(BuildContext context) {
    final sensorName = _sensorName(l10n, sensor.sensorCode);
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
                      _sensorAssetPath(sensor.sensorCode),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        _sensorFallbackIcon(sensor.sensorCode),
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
                            sensorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextTokens.safetySensorItemTitle(
                              textTheme,
                            ),
                          ),
                        ),
                        if (isLowBatteryAlert) ...[
                          const SizedBox(width: 4),
                          Image.asset(
                            _batteryAssetPath(sensor),
                            key: const ValueKey<String>('sensor-low-battery'),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.square(dimension: 12),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (showBatteryOnStatusLine)
                      Image.asset(
                        _batteryAssetPath(sensor),
                        key: ValueKey<String>('sensor-battery'),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.square(dimension: 22),
                      )
                    else
                      Text(
                        _statusLabel(l10n, sensor.status),
                        key: ValueKey<String>('sensor-status-$sensorName'),
                        style: _statusStyle(textTheme, sensor.status),
                      ),
                  ],
                ),
              ),
              if (isWireless || isLowBatteryAlert)
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  child: Icon(
                    key: ValueKey<String>(
                      'sensor-navigation-chevron-$sensorName',
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
                queryParameters: {
                  'doorId': doorId,
                  'deviceId': deviceId,
                  'sensorId': sensor.id,
                },
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
      SafetySensorStatus.notTriggered => l10n.safetySensorNotTriggered,
      SafetySensorStatus.disconnected => l10n.safetySensorOffline,
      SafetySensorStatus.triggered => l10n.safetySensorTriggered,
      SafetySensorStatus.unlocked => l10n.safetySensorUnlocked,
      SafetySensorStatus.locked => l10n.safetySensorLocked,
    };

bool _isNormalSensorStatus(SafetySensorStatus status) =>
    status == SafetySensorStatus.notTriggered ||
    status == SafetySensorStatus.unlocked;

TextStyle _statusStyle(TextTheme textTheme, SafetySensorStatus status) =>
    switch (status) {
      SafetySensorStatus.disconnected => AppTextTokens.safetySensorItemOffline(
        textTheme,
      ),
      SafetySensorStatus.triggered || SafetySensorStatus.locked =>
        AppTextTokens.safetySensorItemAlert(textTheme),
      _ => AppTextTokens.safetySensorItemSuccess(textTheme),
    };

const _batteryFullAsset =
    'assets/icons/security_center/security_center_sensor_battery_full.png';
const _batteryLowAsset =
    'assets/icons/security_center/security_center_sensor_battery_low.png';
const _batteryOfflineAsset =
    'assets/icons/security_center/security_center_sensor_battery_offline.png';

String _batteryAssetPath(SafetySensor sensor) {
  if (sensor.batteryStatus == SafetySensorBatteryStatus.low) {
    return _batteryLowAsset;
  }
  if (sensor.status == SafetySensorStatus.disconnected ||
      sensor.batteryStatus == SafetySensorBatteryStatus.unknown) {
    return _batteryOfflineAsset;
  }
  return _batteryFullAsset;
}

String _sensorAssetPath(String sensorId) {
  final assetName = switch (sensorId) {
    'WIRED_PHOTO_BEAM' ||
    'WIRELESS_PHOTO_BEAM' => 'security_report_motor_wired_photo_beam_icon',
    'WIRED_ELECTRONIC_LOCK' ||
    'WIRELESS_ELECTRONIC_LOCK' => 'security_report_motor_wired_e_lock',
    'WIRELESS_WICKET_DOOR' => 'security_report_wireless_wicket_door',
    'WIRELESS_SAFETY_EDGE' => 'security_report_wireless_safety_edge',
    _ => 'security_report_motor_wired_photo_beam_icon',
  };
  return 'assets/icons/security_center/$assetName.png';
}

IconData _sensorFallbackIcon(String sensorId) => switch (sensorId) {
  'WIRED_ELECTRONIC_LOCK' || 'WIRELESS_ELECTRONIC_LOCK' => Icons.lock_outline,
  'WIRELESS_WICKET_DOOR' => Icons.door_sliding_outlined,
  'WIRELESS_SAFETY_EDGE' || 'WIRELESS_SLACK_ROPE' => Icons.radar,
  _ => Icons.sensors,
};

String _sensorName(AppLocalizations l10n, String sensorCode) =>
    switch (sensorCode) {
      'WIRED_PHOTO_BEAM' => l10n.securityCenterWiredPhotoBeam,
      'WIRED_ELECTRONIC_LOCK' => l10n.securityCenterWiredELock,
      'WIRELESS_PHOTO_BEAM' => l10n.securityCenterWirelessPhotoBeam,
      'WIRELESS_WICKET_DOOR' => l10n.safetySensorsWirelessWicketDoor,
      'WIRELESS_ELECTRONIC_LOCK' => l10n.securityCenterWirelessELock,
      'WIRELESS_SAFETY_EDGE' => l10n.safetySensorsWirelessSafetyEdge,
      'WIRELESS_SLACK_ROPE' => l10n.safetySensorsWirelessSlackRope,
      _ => l10n.safetySensorDefaultName,
    };

class _SensorOperationChart extends StatefulWidget {
  const _SensorOperationChart({required this.points, super.key});

  final List<SafetySensorOperationPoint> points;

  @override
  State<_SensorOperationChart> createState() => _SensorOperationChartState();
}

class _SensorOperationChartState extends State<_SensorOperationChart> {
  int? _selectedIndex;

  void _updateSelection(Offset position, Size size) {
    final index = _SensorOperationChartLayout.hitTest(
      position: position,
      size: size,
      points: widget.points,
    );
    if (index != _selectedIndex) setState(() => _selectedIndex = index);
  }

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) =>
                          _updateSelection(event.localPosition, size),
                      onPointerMove: (event) =>
                          _updateSelection(event.localPosition, size),
                      child: CustomPaint(
                        key: ValueKey<String>(
                          'sensor-operation-chart-selected-${_selectedIndex ?? 'none'}',
                        ),
                        painter: _SensorOperationChartPainter(
                          points: widget.points,
                          selectedIndex: _selectedIndex,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

abstract final class _SensorOperationChartLayout {
  static Rect chart(Size size) =>
      Rect.fromLTWH(30, 8, size.width - 36, size.height - 32);

  static double yAxisMaximum(List<SafetySensorOperationPoint> points) {
    final maximum = points.fold<int>(
      0,
      (value, point) => point.cycles > value ? point.cycles : value,
    );
    return maximum == 0 ? 1 : (maximum * 1.2).ceilToDouble();
  }

  static List<Rect> bars(Size size, List<SafetySensorOperationPoint> points) {
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
    required List<SafetySensorOperationPoint> points,
  }) {
    final bars = _SensorOperationChartLayout.bars(size, points);
    for (var index = 0; index < bars.length; index++) {
      if (bars[index].height > 0 && bars[index].contains(position)) {
        return index;
      }
    }
    return null;
  }
}

class _SensorOperationChartPainter extends CustomPainter {
  const _SensorOperationChartPainter({
    required this.points,
    this.selectedIndex,
  });

  final List<SafetySensorOperationPoint> points;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.securityReportChartGrid
      ..strokeWidth = 1;
    final axis = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 1.2;
    final chart = _SensorOperationChartLayout.chart(size);

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
    final maximum = _SensorOperationChartLayout.yAxisMaximum(points);
    final bars = _SensorOperationChartLayout.bars(size, points);
    for (var index = 0; index < bars.length; index++) {
      final point = points[index];
      canvas.drawRect(bars[index], point.isAbnormal ? warningBar : normalBar);
    }
    for (var index = 0; index <= 5; index++) {
      _paintText(
        canvas,
        (maximum * index / 5).round().toString(),
        Offset(chart.left - 24, chart.bottom - chart.height * index / 5 - 8),
        fontSize: 11,
        color: AppColors.textPrimary,
      );
    }
    for (var index = 0; index < points.length; index++) {
      final hour = points[index].occurredAt.hour;
      final painter = TextPainter(
        text: TextSpan(
          text: hour.toString(),
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
    if (selectedIndex case final index? when index < points.length) {
      _paintTooltip(
        canvas,
        chart,
        bars[index],
        points[index].cycles,
        points[index].isAbnormal ? warningBar.color : normalBar.color,
      );
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
        text: value.toString(),
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
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, width, height),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.securityReportChartTooltip,
    );
    textPainter.paint(
      canvas,
      Offset(left + horizontalPadding, top + verticalPadding),
    );
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
      oldDelegate.points != points ||
      oldDelegate.selectedIndex != selectedIndex;
}
