import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../../domain/entities/safety_sensors_evaluation.dart';

class SafetySensorBatterySolutionPage extends ConsumerWidget {
  const SafetySensorBatterySolutionPage({required this.deviceId, required this.sensorId, super.key});

  static const routeName = 'safety-sensor-battery-solution';
  static const routePath = '/safety-sensor-battery-solution';

  /// 设备总体与局部放大图的最终设计资源占位名称。
  static const _overviewImagePlaceholder = 'assets/icons/security_center/safety_sensor_low_battery_overview_placeholder_infrared_amplification.png';

  /// 电池型号示意图的最终设计资源占位名称。
  static const _batteryImagePlaceholder = 'assets/icons/security_center/safety_sensor_battery_model_placeholder.png';

  /// 更换电池步骤图的最终设计资源占位名称。
  static const _replacementImagePlaceholder = 'assets/icons/security_center/safety_sensor_battery_replacement_placeholder_infrared_amplification_battery.png';

  final String deviceId;
  final String sensorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final evaluation = ref.watch(safetySensorsEvaluationProvider(deviceId));
    final sensor = _findSensor(evaluation, sensorId);

    return Scaffold(
      backgroundColor: AppColors.securityCenterBackground,
      appBar: FlinxNavigationBar(title: sensor?.sensorName ?? l10n.safetySensorDefaultName, showBottomDivider: false),
      body: ListView(
        key: const ValueKey<String>('safety-sensor-battery-solution-scroll'),
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 28),
        children: [
          Padding(
            padding: EdgeInsetsGeometry.only(left: 17),
            child: Text(l10n.safetySensorLowBatterySolution, style: AppTextTokens.safetyBatterySolutionSectionTitle(Theme.of(context).textTheme)),
          ),
          const SizedBox(height: 18),
          _BatterySolutionSummaryCard(overviewImageAsset: _overviewImagePlaceholder, batteryImageAsset: _batteryImagePlaceholder),
          const SizedBox(height: 13),
          Padding(
            padding: EdgeInsetsGeometry.only(left: 20),
            child: Text(l10n.safetySensorLowBatterySolution, style: AppTextTokens.safetyBatterySolutionSectionTitle(Theme.of(context).textTheme)),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(color: AppColors.securityCenterCard, borderRadius: BorderRadius.circular(AppShapeTokens.safetyBatterySolutionCardRadius)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _AssetPlaceholder(assetPath: _replacementImagePlaceholder, height: 340),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatterySolutionSummaryCard extends StatelessWidget {
  const _BatterySolutionSummaryCard({required this.overviewImageAsset, required this.batteryImageAsset});

  final String overviewImageAsset;
  final String batteryImageAsset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.securityCenterCard, borderRadius: BorderRadius.circular(AppShapeTokens.safetyBatterySolutionCardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AssetPlaceholder(assetPath: overviewImageAsset, height: 240),
            const SizedBox(height: 28),
            Row(
              children: [
                const Icon(Icons.error, color: AppColors.securityCenterError, size: 13),
                const SizedBox(width: 8),
                Text(l10n.safetySensorLowBatteryWarning, style: AppTextTokens.safetySensorItemAlert(textTheme)),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BatterySpecificationLine(label: l10n.safetySensorBatteryModelLabel, value: 'ER14505'),
                      const SizedBox(height: 12),
                      _BatterySpecificationLine(label: l10n.safetySensorRatedVoltageLabel, value: '3.6V'),
                      const SizedBox(height: 12),
                      Text(l10n.safetySensorLowBatteryInstruction, style: AppTextTokens.safetyBatterySolutionWarning(textTheme)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(width: 85, child: _AssetPlaceholder(assetPath: batteryImageAsset, height: 105)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BatterySpecificationLine extends StatelessWidget {
  const _BatterySpecificationLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: label, style: AppTextTokens.safetyBatterySolutionLabel(textTheme)),
          TextSpan(text: value, style: AppTextTokens.safetyBatterySolutionValue(textTheme)),
        ],
      ),
    );
  }
}

class _AssetPlaceholder extends StatelessWidget {
  const _AssetPlaceholder({required this.assetPath, required this.height});

  final String assetPath;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppShapeTokens.safetyBatterySolutionImageRadius),
      child: Image.asset(
        assetPath,
        height: height,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          color: AppColors.safetyBatterySolutionPlaceholderSurface,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_outlined, color: AppColors.safetySensorPlaceholder, size: 42),
              const SizedBox(height: 8),
              Text(l10n.safetySensorImagePlaceholder, style: AppTextTokens.safetySensorItemStatus(Theme.of(context).textTheme)),
            ],
          ),
        ),
      ),
    );
  }
}

SafetySensor? _findSensor(SafetySensorsEvaluation evaluation, String sensorId) {
  for (final group in [evaluation.wiredSensorGroup, evaluation.wirelessSensorGroup]) {
    for (final sensor in group.sensors) {
      if (sensor.id == sensorId) return sensor;
    }
  }
  return null;
}
