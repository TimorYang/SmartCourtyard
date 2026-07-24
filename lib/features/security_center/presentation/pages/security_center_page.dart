import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../../application/security_balance_refresh_controller.dart';
import '../../application/security_center_connection_status_controller.dart';
import '../../domain/entities/security_center_overview.dart';
import '../../../device_control/presentation/widgets/device_detail_bottom_navigation.dart';
import '../widgets/security_center_wifi_disconnected_dialog.dart';
import 'full_report_page.dart';
import 'general_evaluation_page.dart';
import 'safety_sensors_evaluation_page.dart';

class SecurityCenterPage extends ConsumerStatefulWidget {
  const SecurityCenterPage({
    required this.doorId,
    required this.deviceId,
    required this.onTabSelected,
    this.isActive = true,
    super.key,
  });

  static const _heroAsset =
      'assets/icons/security_center/security_center_protecting_hero.png';
  static const _download =
      'assets/icons/security_center/security_center_download.png';

  final String doorId;
  final String deviceId;
  final ValueChanged<DeviceDetailTab> onTabSelected;
  final bool isActive;

  @override
  ConsumerState<SecurityCenterPage> createState() => _SecurityCenterPageState();
}

class _SecurityCenterPageState extends ConsumerState<SecurityCenterPage> {
  var _activationCheckInProgress = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _triggerActivation();
    }
  }

  @override
  void didUpdateWidget(covariant SecurityCenterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive &&
        (!oldWidget.isActive || oldWidget.doorId != widget.doorId)) {
      _triggerActivation();
    }
  }

  void _triggerActivation() {
    unawaited(Future<void>.microtask(_checkConnectionThenRefresh));
  }

  Future<void> _checkConnectionThenRefresh() async {
    if (_activationCheckInProgress) return;
    _activationCheckInProgress = true;
    try {
      final isWifiDisconnected = await ref
          .read(securityCenterConnectionStatusControllerProvider.notifier)
          .check(doorId: widget.doorId);
      if (!mounted || !widget.isActive) return;
      if (isWifiDisconnected) {
        final shouldLeave = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          barrierColor: AppColors.securityCenterDialogScrim,
          builder: (_) => const SecurityCenterWifiDisconnectedDialog(),
        );
        if (shouldLeave == true && mounted) {
          widget.onTabSelected(DeviceDetailTab.command);
        }
        return;
      }
      await ref
          .read(securityBalanceRefreshControllerProvider.notifier)
          .trigger(doorId: widget.doorId);
    } finally {
      _activationCheckInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final overview = ref.watch(securityCenterOverviewProvider(widget.deviceId));

    return Scaffold(
      backgroundColor: AppColors.securityCenterBackground,
      appBar: FlinxNavigationBar(
        title: l10n.securityCenterTitle,
        showBottomDivider: false,
      ),
      bottomNavigationBar: DeviceDetailBottomNavigation(
        selectedTab: DeviceDetailTab.securityCenter,
        onSelected: widget.onTabSelected,
      ),
      body: ListView(
        key: const PageStorageKey<String>('security-center-scroll'),
        children: [
          SizedBox(
            height: 145,
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  top: 20,
                  child: Image.asset(
                    SecurityCenterPage._heroAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const _SecurityHeroFallback(),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsGeometry.fromLTRB(20, 28, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.securityCenterProtecting,
                          style: AppTextTokens.securityCenterHeroTitle(
                            textTheme,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => context.pushNamed(
                            FullReportPage.routeName,
                            queryParameters: {
                              'doorId': widget.doorId,
                              'deviceId': widget.deviceId,
                            },
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: AppColors.securityCenterLink,
                            splashFactory: NoSplash.splashFactory,
                          ),
                          icon: Image.asset(
                            SecurityCenterPage._download,
                            fit: BoxFit.contain,
                          ),
                          label: Text(
                            l10n.securityCenterDownloadFullReport,
                            style:
                                AppTextTokens.securityCenterHeroTitle2(
                                  textTheme,
                                ).copyWith(
                                  color: AppColors.securityCenterLink,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.securityCenterLink,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          Padding(
            padding: EdgeInsetsGeometry.only(left: 20, right: 20),
            child: _EvaluationCard(
              title: l10n.securityCenterGeneralEvaluation,
              status: overview.generalEvaluation.status,
              tags: [
                for (final item in overview.generalEvaluation.items)
                  _evaluationItemLabel(l10n, item.type),
              ],
              onTap: () => context.pushNamed(
                GeneralEvaluationPage.routeName,
                queryParameters: {
                  'doorId': widget.doorId,
                  'deviceId': widget.deviceId,
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: EdgeInsetsGeometry.only(left: 20, right: 20),
            child: _SensorEvaluationCard(
              textTheme: textTheme,
              l10n: l10n,
              evaluation: overview.safetySensorEvaluation,
              onTap: () => context.pushNamed(
                SafetySensorsEvaluationPage.routeName,
                queryParameters: {'deviceId': widget.deviceId},
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  String _evaluationItemLabel(
    AppLocalizations l10n,
    SecurityEvaluationItemType type,
  ) => switch (type) {
    SecurityEvaluationItemType.doorOperationStatus =>
      l10n.securityCenterDoorOperationStatus,
    SecurityEvaluationItemType.doorOperationRecord =>
      l10n.securityCenterDoorOperationRecord,
  };
}

class _SecurityHeroFallback extends StatelessWidget {
  const _SecurityHeroFallback();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 205,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.garage_outlined,
            size: 155,
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
  const _EvaluationCard({
    required this.title,
    required this.status,
    required this.tags,
    this.onTap,
  });

  final String title;
  final SecurityEvaluationStatus status;
  final List<String> tags;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.securityCenterCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 17, 11, 17),
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
                  _EvaluationStatusIcon(status: status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var index = 0; index < tags.length; index++) ...[
                            if (index > 0) const SizedBox(width: 10),
                            _EvaluationTag(label: tags[index]),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textPrimary,
                    size: 26,
                  ),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6.5),
        child: Text(
          label,
          style: AppTextTokens.securityCenterTag(Theme.of(context).textTheme),
        ),
      ),
    );
  }
}

class _SensorEvaluationCard extends StatelessWidget {
  const _SensorEvaluationCard({
    required this.textTheme,
    required this.l10n,
    required this.evaluation,
    required this.onTap,
  });

  final TextTheme textTheme;
  final AppLocalizations l10n;
  final SecuritySensorEvaluation evaluation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlightedSensors = evaluation.highlightedSensorTypes;

    return Material(
      key: const ValueKey<String>('safety-sensors-evaluation-card'),
      color: AppColors.securityCenterCard,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11.5, 17, 11.5, 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.securityCenterSafetySensorsEvaluation,
                      style: AppTextTokens.securityCenterCardTitle(textTheme),
                    ),
                  ),
                  _EvaluationStatusIcon(status: evaluation.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (highlightedSensors.isNotEmpty)
                    Expanded(
                      child: _EvaluationTag(
                        label: _sensorLabel(l10n, highlightedSensors.first),
                      ),
                    ),
                  const SizedBox(width: 10),
                  if (highlightedSensors.length > 1)
                    Expanded(
                      child: _EvaluationTag(
                        label: _sensorLabel(l10n, highlightedSensors[1]),
                      ),
                    ),
                  const Icon(Icons.chevron_right_rounded, size: 26),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                l10n.securityCenterWirelessSensors,
                style: AppTextTokens.securityCenterSectionTitle(textTheme),
              ),
              const SizedBox(height: 16),
              _SensorGrid(
                sensors: [
                  for (final sensor in evaluation.wirelessSensors)
                    _SensorItem.fromSnapshot(sensor, l10n),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                l10n.securityCenterWiredSensors,
                style: AppTextTokens.securityCenterSectionTitle(textTheme),
              ),
              const SizedBox(height: 16),
              _SensorGrid(
                sensors: [
                  for (final sensor in evaluation.wiredSensors)
                    _SensorItem.fromSnapshot(sensor, l10n),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensorItem {
  const _SensorItem(this.imageAsset, this.label, this.snapshot);

  factory _SensorItem.fromSnapshot(
    SecuritySensorSnapshot snapshot,
    AppLocalizations l10n,
  ) {
    return _SensorItem(
      snapshot.type.imageAsset,
      _sensorLabel(l10n, snapshot.type),
      snapshot,
    );
  }

  final String imageAsset;
  final String label;
  final SecuritySensorSnapshot snapshot;
}

class _SensorGrid extends StatelessWidget {
  const _SensorGrid({required this.sensors});

  final List<_SensorItem> sensors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 32,
      runSpacing: 20,
      children: [for (final sensor in sensors) _SensorTile(sensor: sensor)],
    );
  }
}

class _SensorTile extends StatelessWidget {
  const _SensorTile({required this.sensor});

  static const _batteryFullAsset =
      'assets/icons/security_center/security_center_sensor_battery_full.png';
  static const _batteryLowAsset =
      'assets/icons/security_center/security_center_sensor_battery_low.png';
  static const _batteryOfflineAsset =
      'assets/icons/security_center/security_center_sensor_battery_offline.png';

  final _SensorItem sensor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: sensor.label,
      child: SizedBox(
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color:
                    sensor.snapshot.status == SecurityEvaluationStatus.offline
                    ? AppColors.securityCenterSensorUnavailable
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _statusColor, width: 2),
              ),
              child: SizedBox.square(
                dimension: 44,
                child: Center(
                  child: Image.asset(
                    sensor.imageAsset,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.square(dimension: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Image.asset(
              _batteryAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.square(dimension: 14),
            ),
          ],
        ),
      ),
    );
  }

  Color get _statusColor => switch (sensor.snapshot.status) {
    SecurityEvaluationStatus.normal => AppColors.securityCenterSuccess,
    SecurityEvaluationStatus.warning => AppColors.securityReportWarning,
    SecurityEvaluationStatus.critical => AppColors.securityCenterError,
    SecurityEvaluationStatus.offline =>
      AppColors.securityCenterSensorUnavailable,
  };

  String get _batteryAsset {
    if (sensor.snapshot.status == SecurityEvaluationStatus.offline) {
      return _batteryOfflineAsset;
    }
    return sensor.snapshot.batteryPercentage <= 20
        ? _batteryLowAsset
        : _batteryFullAsset;
  }
}

class _EvaluationStatusIcon extends StatelessWidget {
  const _EvaluationStatusIcon({required this.status});

  final SecurityEvaluationStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      SecurityEvaluationStatus.normal => (
        Icons.check_circle,
        AppColors.securityCenterSuccess,
      ),
      SecurityEvaluationStatus.warning => (
        Icons.warning_rounded,
        AppColors.securityReportWarning,
      ),
      SecurityEvaluationStatus.critical => (
        Icons.error,
        AppColors.securityCenterError,
      ),
      SecurityEvaluationStatus.offline => (
        Icons.cloud_off_rounded,
        AppColors.securityCenterSensorUnavailable,
      ),
    };
    return Icon(icon, color: color, size: 13);
  }
}

String _sensorLabel(AppLocalizations l10n, SecuritySensorType type) =>
    switch (type) {
      SecuritySensorType.photoBeam => l10n.securityCenterPhotoBeam,
      SecuritySensorType.eLock => l10n.securityCenterELock,
      SecuritySensorType.doorSensor => l10n.securityCenterDoorSensor,
      SecuritySensorType.radar => l10n.securityCenterRadar,
      SecuritySensorType.remote => l10n.securityCenterRemote,
      SecuritySensorType.safetyEdge => l10n.securityCenterSafetyEdge,
      SecuritySensorType.wiredPhotoBeam => l10n.securityCenterWiredPhotoBeam,
      SecuritySensorType.wiredELock => l10n.securityCenterWiredELock,
    };
