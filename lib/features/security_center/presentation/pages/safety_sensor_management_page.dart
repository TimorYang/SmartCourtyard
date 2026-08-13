import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/safety_sensor_management_controller.dart';
import '../../domain/entities/safety_sensor_management.dart';

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
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(
            safetySensorManagementControllerProvider(widget.deviceId).notifier,
          )
          .load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(
      safetySensorManagementControllerProvider(widget.deviceId),
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
              child: state.loading && state.sensors.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && state.sensors.isEmpty
                  ? Center(
                      child: TextButton(
                        onPressed: () => ref
                            .read(
                              safetySensorManagementControllerProvider(
                                widget.deviceId,
                              ).notifier,
                            )
                            .load(),
                        child: Text(l10n.safetySensorsLoadFailed),
                      ),
                    )
                  : _buildSensorList(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorList(SafetySensorManagementState state) {
    final l10n = AppLocalizations.of(context);
    if (state.sensors.isEmpty) {
      return Center(child: Text(l10n.safetySensorManagementEmpty));
    }
    return ListView.separated(
      key: const ValueKey<String>('safety-sensor-management-list'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      itemCount: state.sensors.length,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final sensor = state.sensors[index];
        return _ManagementSensorCard(
          key: ValueKey<String>('safety-sensor-management-card-${sensor.id}'),
          sensor: sensor,
          deleting: state.deletingSerialNumber == sensor.serialNumber,
          actionsEnabled: state.deletingSerialNumber == null,
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
    final deleted = await ref
        .read(
          safetySensorManagementControllerProvider(widget.deviceId).notifier,
        )
        .deleteSensor(sensor);
    if (!mounted) return;
    if (deleted) {
      AppToast.success(
        context,
        AppLocalizations.of(context).safetySensorManagementDeleteSuccess,
      );
    } else {
      AppToast.error(
        context,
        AppLocalizations.of(context).safetySensorManagementDeleteFailed,
      );
    }
  }
}

class _ManagementSensorCard extends StatelessWidget {
  const _ManagementSensorCard({
    required this.sensor,
    required this.onDelete,
    required this.deleting,
    required this.actionsEnabled,
    super.key,
  });

  final SafetySensorManagementItem sensor;
  final VoidCallback onDelete;
  final bool deleting;
  final bool actionsEnabled;

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
              _sensorAssetPath(sensor.type),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                _sensorFallbackIcon(sensor.type),
                color: AppColors.safetySensorManagementIcon,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _sensorName(l10n, sensor.type),
              style: AppTextTokens.safetySensorManagementItem(textTheme),
            ),
          ),
          Semantics(
            button: true,
            label: l10n.safetySensorManagementDeleteLabel,
            child: GestureDetector(
              key: ValueKey<String>(
                'safety-sensor-management-delete-${sensor.id}',
              ),
              behavior: HitTestBehavior.opaque,
              onTap: actionsEnabled ? onDelete : null,
              child: SizedBox(
                width: 44,
                height: 44,
                child: deleting
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
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
                _sensorName(l10n, sensor.type),
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

String _sensorAssetPath(SafetySensorManagementType type) {
  final assetName = switch (type) {
    SafetySensorManagementType.wirelessElectronicLock =>
      'security_report_motor_wired_e_lock',
    SafetySensorManagementType.wirelessWicketDoor =>
      'security_report_wireless_wicket_door',
    SafetySensorManagementType.wirelessSafetyEdge =>
      'security_report_wireless_safety_edge',
    _ => 'security_report_motor_wired_photo_beam_icon',
  };
  return 'assets/icons/security_center/$assetName.png';
}

IconData _sensorFallbackIcon(SafetySensorManagementType type) => switch (type) {
  SafetySensorManagementType.wirelessElectronicLock => Icons.lock_outline,
  SafetySensorManagementType.wirelessDoorSensor ||
  SafetySensorManagementType.wirelessWicketDoor => Icons.door_sliding_outlined,
  SafetySensorManagementType.wirelessSafetyEdge ||
  SafetySensorManagementType.wirelessSlackRope => Icons.radar,
  _ => Icons.sensors,
};

String _sensorName(AppLocalizations l10n, SafetySensorManagementType type) =>
    switch (type) {
      SafetySensorManagementType.wirelessDoorSensor =>
        l10n.safetySensorManagementWirelessDoorSensor,
      SafetySensorManagementType.wirelessPhotoBeam =>
        l10n.securityCenterWirelessPhotoBeam,
      SafetySensorManagementType.wirelessWicketDoor =>
        l10n.safetySensorsWirelessWicketDoor,
      SafetySensorManagementType.wirelessElectronicLock =>
        l10n.securityCenterWirelessELock,
      SafetySensorManagementType.wirelessSafetyEdge =>
        l10n.safetySensorsWirelessSafetyEdge,
      SafetySensorManagementType.wirelessSlackRope =>
        l10n.safetySensorsWirelessSlackRope,
      SafetySensorManagementType.unknown =>
        l10n.safetySensorManagementUnknownType,
    };
