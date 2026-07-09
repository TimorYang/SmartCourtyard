import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';

class SafetySensorsEvaluationPage extends StatelessWidget {
  const SafetySensorsEvaluationPage({required this.deviceId, super.key});

  static const routeName = 'safety-sensors-evaluation';
  static const routePath = '/safety-sensors-evaluation';

  static const _wiredDoorAsset =
      'assets/icons/security_center/safety_wired_door_layout.png';
  static const _wirelessDoorAsset =
      'assets/icons/security_center/safety_wireless_door_layout.png';

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.securityCenterBackground,
      appBar: const FlinxNavigationBar(
        title: 'Safety Sensors Evaluation',
        showBottomDivider: false,
      ),
      body: ListView(
        key: ValueKey<String>('safety-sensors-scroll-$deviceId'),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: const [
          _SensorMetrics(),
          SizedBox(height: 42),
          _SensorGroupCard(
            title: 'Wired sensor status',
            doorAsset: _wiredDoorAsset,
            sensors: [
              _SafetySensor(
                name: 'Wired photo beam',
                assetName: 'safety_wired_photo_beam',
                fallbackIcon: Icons.sensors,
              ),
              _SafetySensor(
                name: 'Wired E-lock',
                assetName: 'safety_wired_e_lock',
                fallbackIcon: Icons.lock_outline,
              ),
            ],
          ),
          SizedBox(height: 42),
          _SensorGroupCard(
            title: 'Wireless Sensors Status',
            doorAsset: _wirelessDoorAsset,
            showActions: true,
            sensors: [
              _SafetySensor(
                name: 'Wireless Photo Beam',
                assetName: 'safety_wireless_photo_beam',
                fallbackIcon: Icons.sensors,
                wireless: true,
              ),
              _SafetySensor(
                name: 'Wireless wicket door',
                assetName: 'safety_wireless_wicket_door',
                fallbackIcon: Icons.door_sliding_outlined,
                wireless: true,
              ),
              _SafetySensor(
                name: 'Wireless E-lock',
                assetName: 'safety_wireless_e_lock',
                fallbackIcon: Icons.lock_outline,
                wireless: true,
              ),
              _SafetySensor(
                name: 'Wireless safety edge',
                assetName: 'safety_wireless_safety_edge',
                fallbackIcon: Icons.radar,
                wireless: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SensorMetrics extends StatelessWidget {
  const _SensorMetrics();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _MetricCard(icon: Icons.sensors, label: 'Sensors'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _MetricCard(icon: Icons.check_circle, label: 'Fine'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _MetricCard(icon: Icons.error, label: 'Abnormal'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            icon: Icons.battery_alert_outlined,
            label: 'Low power',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 145,
      decoration: BoxDecoration(
        color: AppColors.securityCenterCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.safetySensorMetricIcon, size: 28),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextTokens.safetySensorMetricLabel(textTheme),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('0', style: AppTextTokens.safetySensorMetricValue(textTheme)),
        ],
      ),
    );
  }
}

class _SensorGroupCard extends StatelessWidget {
  const _SensorGroupCard({
    required this.title,
    required this.doorAsset,
    required this.sensors,
    this.showActions = false,
  });

  final String title;
  final String doorAsset;
  final List<_SafetySensor> sensors;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.securityCenterCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
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
                    ).copyWith(fontSize: 20),
                  ),
                ),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.securityCenterSuccess,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DoorLayoutPlaceholder(assetPath: doorAsset),
            if (showActions) ...[
              const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            for (var index = 0; index < sensors.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              _SensorRow(sensor: sensors[index]),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: Colors.white),
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

class _SafetySensor {
  const _SafetySensor({
    required this.name,
    required this.assetName,
    required this.fallbackIcon,
    this.wireless = false,
  });

  final String name;
  final String assetName;
  final IconData fallbackIcon;
  final bool wireless;

  String get assetPath => 'assets/icons/security_center/$assetName.png';
}

class _SensorRow extends StatelessWidget {
  const _SensorRow({required this.sensor});

  final _SafetySensor sensor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      key: ValueKey<String>('sensor-${sensor.name}'),
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.safetySensorItemSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 48,
            child: Image.asset(
              sensor.assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                sensor.fallbackIcon,
                size: 34,
                color: AppColors.securityCenterSensorIcon,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        sensor.name,
                        style: AppTextTokens.safetySensorItemTitle(textTheme),
                      ),
                    ),
                    if (sensor.wireless) ...[
                      const SizedBox(width: 7),
                      const Icon(
                        Icons.battery_5_bar_outlined,
                        size: 22,
                        color: AppColors.safetySensorDisconnected,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Disconnect',
                  style: AppTextTokens.safetySensorItemStatus(textTheme),
                ),
              ],
            ),
          ),
          if (sensor.wireless)
            const Icon(
              Icons.chevron_right,
              size: 30,
              color: AppColors.textPrimary,
            ),
        ],
      ),
    );
  }
}
