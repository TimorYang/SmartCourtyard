import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../device_control/presentation/widgets/device_detail_bottom_navigation.dart';
import 'full_report_page.dart';
import 'general_evaluation_page.dart';
import 'safety_sensors_evaluation_page.dart';

class SecurityCenterPage extends StatelessWidget {
  const SecurityCenterPage({
    required this.deviceId,
    required this.onTabSelected,
    super.key,
  });

  static const _heroAsset =
      'assets/icons/security_center/security_center_protecting_hero.png';

  final String deviceId;
  final ValueChanged<DeviceDetailTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.securityCenterBackground,
      appBar: const FlinxNavigationBar(
        title: 'Security center',
        showBottomDivider: false,
      ),
      bottomNavigationBar: DeviceDetailBottomNavigation(
        selectedTab: DeviceDetailTab.securityCenter,
        onSelected: onTabSelected,
      ),
      body: ListView(
        key: const PageStorageKey<String>('security-center-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          SizedBox(
            height: 115,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    _heroAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const _SecurityHeroFallback(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Protecting...',
                        style: AppTextTokens.securityCenterHeroTitle(textTheme),
                      ),
                      TextButton.icon(
                        onPressed: () => context.pushNamed(
                          FullReportPage.routeName,
                          queryParameters: {'deviceId': deviceId},
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: AppColors.securityCenterLink,
                          splashFactory: NoSplash.splashFactory,
                        ),
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: Text(
                          'Download the full report',
                          style: AppTextTokens.securityCenterHeroTitle2(
                            textTheme,
                          ).copyWith(decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 55),
          _EvaluationCard(
            title: 'General Evaluation',
            tags: ['Door Operation Status', 'Door operation record'],
            onTap: () => context.pushNamed(
              GeneralEvaluationPage.routeName,
              queryParameters: {'deviceId': deviceId},
            ),
          ),
          const SizedBox(height: 22),
          _SensorEvaluationCard(
            textTheme: textTheme,
            onTap: () => context.pushNamed(
              SafetySensorsEvaluationPage.routeName,
              queryParameters: {'deviceId': deviceId},
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityHeroFallback extends StatelessWidget {
  const _SecurityHeroFallback();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.garage_outlined,
            size: 145,
            color: AppColors.deviceControlInactive.withValues(alpha: 0.45),
          ),
          const Positioned(
            right: 8,
            bottom: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.securityCenterShield,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(13),
                child: Icon(Icons.lock, color: Colors.white, size: 25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({required this.title, required this.tags, this.onTap});

  final String title;
  final List<String> tags;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.securityCenterCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 18, 11, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextTokens.securityCenterCardTitle(textTheme),
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.securityCenterSuccess,
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var index = 0; index < tags.length; index++) ...[
                            if (index > 0) const SizedBox(width: 8),
                            _EvaluationTag(label: tags[index]),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 34),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvaluationTag extends StatelessWidget {
  const _EvaluationTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.securityCenterTag,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: AppTextTokens.securityCenterTag(Theme.of(context).textTheme),
        ),
      ),
    );
  }
}

class _SensorEvaluationCard extends StatelessWidget {
  const _SensorEvaluationCard({required this.textTheme, required this.onTap});

  final TextTheme textTheme;
  final VoidCallback onTap;

  static const sensors = <_SensorItem>[
    _SensorItem(Icons.door_sliding_outlined, 'Photo beam'),
    _SensorItem(Icons.sensors, 'E-lock'),
    _SensorItem(Icons.sensor_door_outlined, 'Door sensor'),
    _SensorItem(Icons.radar, 'Radar'),
    _SensorItem(Icons.wifi_tethering, 'Wireless'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey<String>('safety-sensors-evaluation-card'),
      color: AppColors.securityCenterCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Safety Sensors Evaluation',
                      style: AppTextTokens.securityCenterCardTitle(textTheme),
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.securityCenterSuccess,
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 11),
              const SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _EvaluationTag(label: 'Wireless Photo Beam'),
                    SizedBox(width: 8),
                    _EvaluationTag(label: 'Wireless E-lock'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Wireless Sensors',
                style: AppTextTokens.securityCenterSectionTitle(textTheme),
              ),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sensors.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (context, index) =>
                    _SensorTile(sensor: sensors[index]),
              ),
              Text(
                'Wired Sensors',
                style: AppTextTokens.securityCenterSectionTitle(textTheme),
              ),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, index) =>
                    _SensorTile(sensor: sensors[index]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensorItem {
  const _SensorItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _SensorTile extends StatelessWidget {
  const _SensorTile({required this.sensor});

  final _SensorItem sensor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: sensor.label,
      child: SizedBox(
        width: 86,
        child: Column(
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.securityCenterSensorSurface,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 70,
                child: Icon(
                  sensor.icon,
                  size: 34,
                  color: AppColors.securityCenterSensorIcon,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Icon(
              Icons.battery_5_bar_outlined,
              size: 28,
              color: AppColors.deviceControlInactive,
            ),
          ],
        ),
      ),
    );
  }
}
