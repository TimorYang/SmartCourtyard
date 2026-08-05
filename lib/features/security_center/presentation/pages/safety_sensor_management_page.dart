import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/safety_sensors_evaluation_controller.dart';
import '../../domain/entities/safety_sensor_management.dart';
import '../../domain/entities/safety_sensors_evaluation.dart';

class SafetySensorManagementPage extends ConsumerStatefulWidget {
  const SafetySensorManagementPage({
    required this.doorId,
    required this.deviceId,
    super.key,
  });

  static const routeName = 'safety-sensor-management';
  static const routePath = '/safety-sensors/management';

  final String doorId;
  final String deviceId;

  @override
  ConsumerState<SafetySensorManagementPage> createState() =>
      _SafetySensorManagementPageState();
}

class _SafetySensorManagementPageState
    extends ConsumerState<SafetySensorManagementPage> {
  final Set<String> _removedSensorIds = <String>{};

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
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(
      safetySensorsEvaluationControllerProvider(widget.doorId),
    );

    return Scaffold(
      backgroundColor: AppColors.safetySensorManagementBackground,
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Text(
                l10n.safetySensorManagementTitle,
                style: AppTextTokens.sharedDevicesTitle(textTheme),
              ),
            ),
            const SizedBox(height: 27),
            Expanded(
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: TextButton(
                    onPressed: () => ref
                        .read(
                          safetySensorsEvaluationControllerProvider(
                            widget.doorId,
                          ).notifier,
                        )
                        .load(doorId: widget.doorId),
                    child: Text(l10n.safetySensorsLoadFailed),
                  ),
                ),
                data: _buildSensorList,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorList(SafetySensorsEvaluation evaluation) {
    final l10n = AppLocalizations.of(context);
    final management = SafetySensorManagement(
      sensors: evaluation.wirelessSensorGroup.sensors
          .map(
            (sensor) => SafetySensorManagementItem(
              id: sensor.id,
              sensorCode: sensor.sensorCode,
              canDelete: true,
            ),
          )
          .where((sensor) => !_removedSensorIds.contains(sensor.id))
          .toList(growable: false),
    );
    if (management.sensors.isEmpty) {
      return Center(child: Text(l10n.safetySensorManagementEmpty));
    }
    return ListView.separated(
      key: const ValueKey<String>('safety-sensor-management-list'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      itemCount: management.sensors.length,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final sensor = management.sensors[index];
        return _ManagementSensorCard(
          key: ValueKey<String>('safety-sensor-management-card-${sensor.id}'),
          sensor: sensor,
          onDelete: () => _showDeleteDialog(sensor),
        );
      },
    );
  }

  Future<void> _showDeleteDialog(SafetySensorManagementItem sensor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.safetySensorManagementDialogScrim,
      builder: (context) => _SafetySensorDeleteDialog(sensor: sensor),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _removedSensorIds.add(sensor.id));
  }
}

class _ManagementSensorCard extends StatelessWidget {
  const _ManagementSensorCard({
    required this.sensor,
    required this.onDelete,
    super.key,
  });

  final SafetySensorManagementItem sensor;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.safetySensorManagementCard,
        borderRadius: BorderRadius.circular(
          AppShapeTokens.safetySensorManagementCardRadius,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Image.asset(
              _sensorAssetPath(sensor.sensorCode),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                _sensorFallbackIcon(sensor.sensorCode),
                color: AppColors.safetySensorManagementIcon,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _sensorName(l10n, sensor.sensorCode),
              style: AppTextTokens.safetySensorManagementItem(textTheme),
            ),
          ),
          if (sensor.canDelete)
            Semantics(
              button: true,
              label: l10n.safetySensorManagementDeleteLabel,
              child: GestureDetector(
                key: ValueKey<String>(
                  'safety-sensor-management-delete-${sensor.id}',
                ),
                behavior: HitTestBehavior.opaque,
                onTap: onDelete,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.delete,
                    color: AppColors.safetySensorManagementDelete,
                    size: 28,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SafetySensorDeleteDialog extends StatelessWidget {
  const _SafetySensorDeleteDialog({required this.sensor});

  final SafetySensorManagementItem sensor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      key: const ValueKey<String>('safety-sensor-management-delete-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      backgroundColor: AppColors.safetySensorManagementDialogSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppShapeTokens.safetySensorManagementDialogRadius,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.safetySensorManagementWarning,
                  width: 5,
                ),
              ),
              child: const Icon(
                Icons.priority_high_rounded,
                color: AppColors.safetySensorManagementWarning,
                size: 58,
              ),
            ),
            const SizedBox(height: 34),
            Text(
              l10n.safetySensorManagementDeleteMessage(
                _sensorName(l10n, sensor.sensorCode),
              ),
              textAlign: TextAlign.center,
              style: AppTextTokens.safetySensorManagementDeleteMessage(
                textTheme,
              ),
            ),
            const SizedBox(height: 52),
            Row(
              children: [
                Expanded(
                  child: _DialogAction(
                    key: const ValueKey<String>(
                      'safety-sensor-management-delete-cancel',
                    ),
                    label: l10n.safetySensorManagementCancel,
                    primary: false,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _DialogAction(
                    key: const ValueKey<String>(
                      'safety-sensor-management-delete-confirm',
                    ),
                    label: l10n.safetySensorManagementConfirm,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.onPressed,
    this.primary = true,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primary
              ? AppColors.safetySensorManagementConfirm
              : AppColors.safetySensorManagementCancel,
          foregroundColor: primary
              ? Colors.white
              : AppColors.safetySensorManagementCancelForeground,
          overlayColor: Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: primary
              ? AppTextTokens.safetySensorManagementDialogAction(textTheme)
              : AppTextTokens.safetySensorManagementDialogAction(
                  textTheme,
                ).copyWith(
                  color: AppColors.safetySensorManagementCancelForeground,
                ),
        ),
      ),
    );
  }
}

String _sensorAssetPath(String sensorCode) {
  final assetName = switch (sensorCode) {
    'WIRELESS_PHOTO_BEAM' => 'security_report_motor_wired_photo_beam_icon',
    'WIRELESS_ELECTRONIC_LOCK' => 'security_report_motor_wired_e_lock',
    'WIRELESS_WICKET_DOOR' => 'security_report_wireless_wicket_door',
    'WIRELESS_SAFETY_EDGE' => 'security_report_wireless_safety_edge',
    _ => 'security_report_motor_wired_photo_beam_icon',
  };
  return 'assets/icons/security_center/$assetName.png';
}

IconData _sensorFallbackIcon(String sensorCode) => switch (sensorCode) {
  'WIRELESS_ELECTRONIC_LOCK' => Icons.lock_outline,
  'WIRELESS_WICKET_DOOR' => Icons.door_sliding_outlined,
  'WIRELESS_SAFETY_EDGE' || 'WIRELESS_SLACK_ROPE' => Icons.radar,
  _ => Icons.sensors,
};

String _sensorName(AppLocalizations l10n, String sensorCode) =>
    switch (sensorCode) {
      'WIRELESS_PHOTO_BEAM' => l10n.securityCenterWirelessPhotoBeam,
      'WIRELESS_WICKET_DOOR' => l10n.safetySensorsWirelessWicketDoor,
      'WIRELESS_ELECTRONIC_LOCK' => l10n.securityCenterWirelessELock,
      'WIRELESS_SAFETY_EDGE' => l10n.safetySensorsWirelessSafetyEdge,
      'WIRELESS_SLACK_ROPE' => l10n.safetySensorsWirelessSlackRope,
      _ => l10n.safetySensorDefaultName,
    };
