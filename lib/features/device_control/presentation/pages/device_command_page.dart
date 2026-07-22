import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/providers.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../../shared/widgets/flinx_switch.dart';
import '../../../records/presentation/pages/operation_record_page.dart';
import '../../../security_center/presentation/pages/security_center_page.dart';
import '../../application/device_command_controller.dart';
import '../../domain/entities/door_detail.dart';
import '../widgets/device_detail_bottom_navigation.dart';
import 'already_added_devices_page.dart';
import 'device_settings_page.dart';

class DeviceCommandPage extends ConsumerStatefulWidget {
  const DeviceCommandPage({
    required this.doorId,
    this.deviceId = '',
    this.onboardingFlowId,
    super.key,
  });

  static const routeName = 'device-command';
  static const routePath = '/device-command';

  final String doorId;
  final String deviceId;
  final String? onboardingFlowId;

  @override
  ConsumerState<DeviceCommandPage> createState() => _DeviceCommandPageState();
}

class _DeviceCommandPageState extends ConsumerState<DeviceCommandPage> {
  static const _garageDoorClosedAsset =
      'assets/images/device_control_garage_door_closed.png';
  static const _garageDoorFallbackAsset =
      'assets/icons/add_device/add_new_doors_garage_door.png';

  bool _ledEnabled = false;
  bool _autoCloseEnabled = false;
  bool _openReminderEnabled = true;
  DeviceDetailTab _selectedTab = DeviceDetailTab.command;
  late final DeviceCommandController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(deviceCommandControllerProvider.notifier);
    final flowId = widget.onboardingFlowId?.trim();
    if (flowId != null && flowId.isNotEmpty) {
      ref
          .read(appLoggerProvider)
          .info(
            'device_detail_entered',
            tag: AppLogTag.binding,
            flowId: flowId,
            context: {
              'deviceId': widget.deviceId,
              'doorId': widget.doorId,
              'stage': 'device_detail',
              'result': 'entered',
            },
          );
    }
    Future.microtask(_loadDoorDetail);
  }

  @override
  void didUpdateWidget(covariant DeviceCommandPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doorId != widget.doorId) {
      Future.microtask(_loadDoorDetail);
    }
  }

  @override
  void dispose() {
    unawaited(_controller.disposeBleSession());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commandState = ref.watch(deviceCommandControllerProvider);
    final controller = _controller;
    final isBusy =
        commandState.pendingAction != null ||
        commandState.pendingRemotePairingAction != null ||
        commandState.pendingRemoteManagementAction != null;
    final textTheme = Theme.of(context).textTheme;

    return IndexedStack(
      index: _selectedTab.index,
      children: [
        OperationRecordPage(onTabSelected: _selectTab),
        _buildCommandPage(
          commandState: commandState,
          controller: controller,
          isBusy: isBusy,
          textTheme: textTheme,
        ),
        SecurityCenterPage(
          deviceId: _hardwareDeviceId(commandState),
          onTabSelected: _selectTab,
        ),
      ],
    );
  }

  void _selectTab(DeviceDetailTab tab) {
    if (_selectedTab == tab) {
      return;
    }
    setState(() => _selectedTab = tab);
  }

  void _loadDoorDetail() {
    _controller.loadDoorDetail(doorId: widget.doorId);
  }

  String _hardwareDeviceId(DeviceCommandState commandState) {
    if (commandState.bleConnectionStatus ==
            DeviceBleConnectionStatus.connected &&
        (commandState.bleDeviceId?.trim().isNotEmpty ?? false)) {
      return commandState.bleDeviceId!.trim();
    }
    final detailDeviceId = commandState.doorDetail?.hardwareDeviceId ?? '';
    if (detailDeviceId.trim().isNotEmpty) {
      return detailDeviceId.trim();
    }
    if (widget.deviceId.trim().isNotEmpty) {
      return widget.deviceId.trim();
    }
    return widget.doorId.trim();
  }

  Widget _buildCommandPage({
    required DeviceCommandState commandState,
    required DeviceCommandController controller,
    required bool isBusy,
    required TextTheme textTheme,
  }) {
    final doorDetail = commandState.doorDetail;
    final hardwareDeviceId = _hardwareDeviceId(commandState);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: FlinxNavigationBar(
        title: doorDetail?.name ?? 'Garage door',
        showBottomDivider: false,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            tooltip: l10n.deviceCommandMoreTooltip,
            onPressed: isBusy
                ? null
                : () => context.push(
                    '${AlreadyAddedDevicesPage.routePath}'
                    '?doorId=${Uri.encodeComponent(widget.doorId)}'
                    '&deviceId=${Uri.encodeComponent(hardwareDeviceId)}',
                  ),
            icon: const Icon(Icons.more_horiz, size: 24),
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: DeviceDetailBottomNavigation(
        selectedTab: DeviceDetailTab.command,
        onSelected: _selectTab,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.deviceControlDivider),
                  ),
                ),
                child: _CycleSummary(
                  operatedCycles: doorDetail?.operatedCycles,
                  remainingCycles: doorDetail?.remainingCycles,
                  textTheme: textTheme,
                ),
              ),
            ),
            _DeviceConnectionStrip(
              associatedDevices: doorDetail?.associatedDevices ?? const [],
              onItemTap: (index) {
                ref
                    .read(appLoggerProvider)
                    .info(
                      'device_connection_item_tapped',
                      tag: AppLogTag.binding,
                      context: {'index': index, 'deviceId': hardwareDeviceId},
                    );
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                key: const PageStorageKey<String>('device-command-scroll'),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                children: [
                  _DoorHeroImage(
                    assetPath: _garageDoorClosedAsset,
                    fallbackAssetPath: _garageDoorFallbackAsset,
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      doorDetail?.doorStateLabel ?? 'Closed',
                      style: AppTextTokens.deviceControlDoorState(textTheme),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (commandState.doorDetailErrorMessage != null) ...[
                    _CommandFeedback(
                      message: commandState.doorDetailErrorMessage!,
                      icon: Icons.error_outline,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _DoorCommandRow(
                    busy: isBusy,
                    pendingAction: commandState.pendingAction,
                    onClose: () => controller.runAction(
                      deviceId: hardwareDeviceId,
                      action: DeviceCommandAction.closeDoor,
                    ),
                    onStop: () => controller.runAction(
                      deviceId: hardwareDeviceId,
                      action: DeviceCommandAction.stopDoor,
                    ),
                    onOpen: () => controller.runAction(
                      deviceId: hardwareDeviceId,
                      action: DeviceCommandAction.openDoor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (commandState.errorMessage != null) ...[
                    _CommandFeedback(
                      message: commandState.errorMessage!,
                      icon: Icons.error_outline,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    const SizedBox(height: 12),
                  ] else if (commandState.infoMessage != null) ...[
                    _CommandFeedback(
                      message: commandState.infoMessage!,
                      icon: Icons.check_circle_outline,
                      foregroundColor: AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _QuickActionGrid(
                    ledEnabled: _ledEnabled,
                    autoCloseEnabled: _autoCloseEnabled,
                    openReminderEnabled: _openReminderEnabled,
                    busy: isBusy,
                    onLedChanged: (enabled) async {
                      setState(() => _ledEnabled = enabled);
                      await controller.runAction(
                        deviceId: hardwareDeviceId,
                        action: enabled
                            ? DeviceCommandAction.turnLightOn
                            : DeviceCommandAction.turnLightOff,
                      );
                    },
                    onAutoCloseChanged: (enabled) {
                      setState(() => _autoCloseEnabled = enabled);
                    },
                    onOpenReminderChanged: (enabled) {
                      setState(() => _openReminderEnabled = enabled);
                    },
                    onPartialOpen: () => controller.runAction(
                      deviceId: hardwareDeviceId,
                      action: DeviceCommandAction.partialOpenDoor,
                    ),
                    onMoreSettings: () => context.push(
                      '${DeviceSettingsPage.routePath}'
                      '?deviceId=${Uri.encodeComponent(hardwareDeviceId)}',
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

abstract final class _DeviceCommandAssetPaths {
  static const videoActive =
      'assets/icons/device_control/device_command_video_active.png';
  static const videoInactive =
      'assets/icons/device_control/device_command_video_inactive.png';
  static const dongleActive =
      'assets/icons/device_control/device_command_dongle_active.png';
  static const dongleInactive =
      'assets/icons/device_control/device_command_dongle_inactive.png';
  static const fboxActive =
      'assets/icons/device_control/device_command_fbox_active.png';
  static const fboxInactive =
      'assets/icons/device_control/device_command_fbox_inactive.png';
  static const evoActive =
      'assets/icons/device_control/device_command_evo_active.png';
  static const evoInactive =
      'assets/icons/device_control/device_command_evo_inactive.png';
  static const openerActive =
      'assets/icons/device_control/device_command_opener_active.png';
  static const openerInactive =
      'assets/icons/device_control/device_command_opener_inactive.png';
  static const bluetoothActive =
      'assets/icons/device_control/device_command_bluetooth_active_placeholder.png';
  static const bluetoothInactive =
      'assets/icons/device_control/device_command_bluetooth_inactive_placeholder.png';
  static const wifiActive =
      'assets/icons/device_control/device_command_wifi_active_placeholder.png';
  static const wifiInactive =
      'assets/icons/device_control/device_command_wifi_inactive_placeholder.png';
  static const led =
      'assets/icons/device_control/device_command_led_placeholder.png';
  static const autoClose =
      'assets/icons/device_control/device_command_auto_close_placeholder.png';
  static const partialOpen =
      'assets/icons/device_control/device_command_partial_open_placeholder.png';
  static const moreSetting =
      'assets/icons/device_control/device_command_more_setting_placeholder.png';
  static const openReminder =
      'assets/icons/device_settings/device_settings_door_open_reminder_icon.png';
}

class _CycleSummary extends StatelessWidget {
  const _CycleSummary({
    required this.operatedCycles,
    required this.remainingCycles,
    required this.textTheme,
  });

  final int? operatedCycles;
  final int? remainingCycles;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Expanded(
            child: _CycleMetric(
              label: 'Operated cycles',
              value: operatedCycles?.toString() ?? '100',
              textTheme: textTheme,
            ),
          ),
          Padding(
            padding: EdgeInsetsGeometry.only(top: 10, bottom: 10),
            child: VerticalDivider(
              width: 58,
              thickness: 1,
              color: AppColors.deviceControlDivider,
            ),
          ),
          Expanded(
            child: _CycleMetric(
              label: 'Remaining',
              value: remainingCycles?.toString() ?? '4900',
              textTheme: textTheme,
            ),
          ),
          const _CommandVideoButton(),
        ],
      ),
    );
  }
}

class _CycleMetric extends StatelessWidget {
  const _CycleMetric({
    required this.label,
    required this.value,
    required this.textTheme,
  });

  final String label;
  final String value;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            maxLines: 1,
            style: AppTextTokens.deviceControlMetricLabel(textTheme),
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: AppTextTokens.deviceControlMetricValue(textTheme),
          ),
        ),
      ],
    );
  }
}

class _CommandVideoButton extends StatelessWidget {
  const _CommandVideoButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.only(left: 8),
      decoration: const BoxDecoration(
        color: AppColors.deviceControlPanel,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        tooltip: 'Video',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        onPressed: () {},
        icon: const _DeviceControlAssetIcon(
          assetPath: _DeviceCommandAssetPaths.videoActive,
        ),
      ),
    );
  }
}

class _DeviceConnectionStrip extends StatelessWidget {
  const _DeviceConnectionStrip({
    required this.associatedDevices,
    required this.onItemTap,
  });

  final List<DoorAssociatedDevice> associatedDevices;
  final ValueChanged<int> onItemTap;

  bool _isAssociated(String deviceType) {
    return associatedDevices.any(
      (device) =>
          device.deviceType.trim().toLowerCase() == deviceType &&
          device.associated,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(
              child: _ConnectionGroup(
                key: const ValueKey<String>('connection-device-dongle'),
                activeDeviceIconAsset: _DeviceCommandAssetPaths.dongleActive,
                inactiveDeviceIconAsset:
                    _DeviceCommandAssetPaths.dongleInactive,
                deviceActive: _isAssociated('dongle'),
                bluetoothActive: false,
                wifiActive: false,
                onTap: () => onItemTap(0),
              ),
            ),
            Expanded(
              child: _ConnectionGroup(
                key: const ValueKey<String>('connection-device-fbox'),
                activeDeviceIconAsset: _DeviceCommandAssetPaths.fboxActive,
                inactiveDeviceIconAsset: _DeviceCommandAssetPaths.fboxInactive,
                deviceActive: _isAssociated('fbox'),
                bluetoothActive: false,
                wifiActive: true,
                onTap: () => onItemTap(1),
              ),
            ),
            Expanded(
              child: _ConnectionGroup(
                key: const ValueKey<String>('connection-device-opener'),
                activeDeviceIconAsset: _DeviceCommandAssetPaths.openerActive,
                inactiveDeviceIconAsset:
                    _DeviceCommandAssetPaths.openerInactive,
                deviceActive: _isAssociated('opener'),
                bluetoothActive: false,
                wifiActive: true,
                onTap: () => onItemTap(2),
              ),
            ),
            Expanded(
              child: _ConnectionGroup(
                key: const ValueKey<String>('connection-device-video'),
                activeDeviceIconAsset: _DeviceCommandAssetPaths.videoActive,
                inactiveDeviceIconAsset: _DeviceCommandAssetPaths.videoInactive,
                deviceActive: _isAssociated('video'),
                bluetoothActive: null,
                wifiActive: true,
                onTap: () => onItemTap(3),
              ),
            ),
            Expanded(
              child: _ConnectionGroup(
                key: const ValueKey<String>('connection-device-evo'),
                activeDeviceIconAsset: _DeviceCommandAssetPaths.evoActive,
                inactiveDeviceIconAsset: _DeviceCommandAssetPaths.evoInactive,
                deviceActive: _isAssociated('evo'),
                bluetoothActive: true,
                wifiActive: true,
                onTap: () => onItemTap(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionGroup extends StatelessWidget {
  const _ConnectionGroup({
    required this.activeDeviceIconAsset,
    required this.inactiveDeviceIconAsset,
    required this.bluetoothActive,
    required this.wifiActive,
    required this.onTap,
    this.deviceActive = true,
    super.key,
  });

  final String activeDeviceIconAsset;
  final String inactiveDeviceIconAsset;
  final bool? bluetoothActive;
  final bool wifiActive;
  final VoidCallback onTap;
  final bool deviceActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox.expand(
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                _DeviceControlAssetIcon(
                  assetPath: deviceActive
                      ? activeDeviceIconAsset
                      : inactiveDeviceIconAsset,
                ),
                if (bluetoothActive != null) ...[
                  const SizedBox(width: 7),
                  _DeviceControlAssetIcon(
                    assetPath: bluetoothActive!
                        ? _DeviceCommandAssetPaths.bluetoothActive
                        : _DeviceCommandAssetPaths.bluetoothInactive,
                  ),
                ],
                const SizedBox(width: 7),
                _DeviceControlAssetIcon(
                  assetPath: wifiActive
                      ? _DeviceCommandAssetPaths.wifiActive
                      : _DeviceCommandAssetPaths.wifiInactive,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceControlAssetIcon extends StatelessWidget {
  const _DeviceControlAssetIcon({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _DoorHeroImage extends StatelessWidget {
  const _DoorHeroImage({
    required this.assetPath,
    required this.fallbackAssetPath,
  });

  final String assetPath;
  final String fallbackAssetPath;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.95,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.backgroundPrimary,
              ),
              child: Center(
                child: Image.asset(
                  fallbackAssetPath,
                  width: 180,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DoorCommandRow extends StatelessWidget {
  const _DoorCommandRow({
    required this.busy,
    required this.pendingAction,
    required this.onClose,
    required this.onStop,
    required this.onOpen,
  });

  final bool busy;
  final DeviceCommandAction? pendingAction;
  final VoidCallback onClose;
  final VoidCallback onStop;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _DoorCommandButton(
          tooltip: 'Close',
          icon: Icons.keyboard_arrow_down,
          pending: pendingAction == DeviceCommandAction.closeDoor,
          onPressed: busy ? null : onClose,
        ),
        const SizedBox(width: 34),
        _DoorCommandButton(
          tooltip: 'Stop',
          icon: Icons.pause,
          pending: pendingAction == DeviceCommandAction.stopDoor,
          onPressed: busy ? null : onStop,
        ),
        const SizedBox(width: 34),
        _DoorCommandButton(
          tooltip: 'Open',
          icon: Icons.keyboard_arrow_up,
          pending: pendingAction == DeviceCommandAction.openDoor,
          onPressed: busy ? null : onOpen,
        ),
      ],
    );
  }
}

class _DoorCommandButton extends StatelessWidget {
  const _DoorCommandButton({
    required this.tooltip,
    required this.icon,
    required this.pending,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool pending;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(46),
        backgroundColor: AppColors.deviceControlPrimaryAction,
        disabledBackgroundColor: AppColors.deviceControlPrimaryAction
            .withValues(alpha: 0.5),
        foregroundColor: AppColors.deviceControlPrimaryActionForeground,
        disabledForegroundColor: AppColors.deviceControlPrimaryActionForeground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: pending
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.deviceControlPrimaryActionForeground,
              ),
            )
          : Icon(icon, size: 30),
    );
  }
}

class _CommandFeedback extends StatelessWidget {
  const _CommandFeedback({
    required this.message,
    required this.icon,
    required this.foregroundColor,
  });

  final String message;
  final IconData icon;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.deviceControlPanel,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: foregroundColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({
    required this.ledEnabled,
    required this.autoCloseEnabled,
    required this.openReminderEnabled,
    required this.busy,
    required this.onLedChanged,
    required this.onAutoCloseChanged,
    required this.onOpenReminderChanged,
    required this.onPartialOpen,
    required this.onMoreSettings,
  });

  final bool ledEnabled;
  final bool autoCloseEnabled;
  final bool openReminderEnabled;
  final bool busy;
  final ValueChanged<bool> onLedChanged;
  final ValueChanged<bool> onAutoCloseChanged;
  final ValueChanged<bool> onOpenReminderChanged;
  final VoidCallback onPartialOpen;
  final VoidCallback onMoreSettings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 270,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _LedActionCard(
                    enabled: ledEnabled,
                    busy: busy,
                    textTheme: textTheme,
                    onChanged: onLedChanged,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _ToggleActionCard(
                    switchKey: const ValueKey<String>('auto-close-switch'),
                    iconAssetPath: _DeviceCommandAssetPaths.autoClose,
                    title: 'Auto close',
                    enabled: autoCloseEnabled,
                    busy: busy,
                    textTheme: textTheme,
                    onChanged: onAutoCloseChanged,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _ToggleActionCard(
                    key: const ValueKey<String>('open-reminder-action'),
                    switchKey: const ValueKey<String>('open-reminder-switch'),
                    iconAssetPath: _DeviceCommandAssetPaths.openReminder,
                    title: 'Open reminder',
                    subtitle: '10 min',
                    enabled: openReminderEnabled,
                    busy: busy,
                    textTheme: textTheme,
                    onChanged: onOpenReminderChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 140,
                  child: _PartialOpenCard(
                    busy: busy,
                    textTheme: textTheme,
                    onPressed: onPartialOpen,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 44,
                  child: _MoreSettingsCard(
                    busy: busy,
                    textTheme: textTheme,
                    onPressed: onMoreSettings,
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

class _LedActionCard extends StatelessWidget {
  const _LedActionCard({
    required this.enabled,
    required this.busy,
    required this.textTheme,
    required this.onChanged,
  });

  final bool enabled;
  final bool busy;
  final TextTheme textTheme;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ControlCard(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _DeviceControlAssetIcon(
                assetPath: _DeviceCommandAssetPaths.led,
              ),
              const Spacer(),
              FlinxSwitch(
                key: const ValueKey<String>('led-switch'),
                value: enabled,
                enabled: !busy,
                onChanged: onChanged,
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsetsGeometry.only(left: 4),
            child: Text(
              'LED',
              maxLines: 1,
              style: AppTextTokens.deviceControlQuickActionTitle(textTheme),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1 min',
            maxLines: 1,
            style: AppTextTokens.deviceControlQuickActionMeta(textTheme),
          ),
        ],
      ),
    );
  }
}

class _ToggleActionCard extends StatelessWidget {
  const _ToggleActionCard({
    super.key,
    required this.iconAssetPath,
    required this.title,
    this.subtitle,
    required this.switchKey,
    required this.enabled,
    required this.busy,
    required this.textTheme,
    required this.onChanged,
  });

  final String iconAssetPath;
  final String title;
  final String? subtitle;
  final Key switchKey;
  final bool enabled;
  final bool busy;
  final TextTheme textTheme;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ControlCard(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DeviceControlAssetIcon(assetPath: iconAssetPath),
              const Spacer(),
              FlinxSwitch(
                key: switchKey,
                value: enabled,
                enabled: !busy,
                onChanged: onChanged,
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextTokens.deviceControlQuickActionTitle(textTheme),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              style: AppTextTokens.deviceControlQuickActionMeta(textTheme),
            ),
          ],
        ],
      ),
    );
  }
}

class _PartialOpenCard extends StatelessWidget {
  const _PartialOpenCard({
    required this.busy,
    required this.textTheme,
    required this.onPressed,
  });

  final bool busy;
  final TextTheme textTheme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _ControlCard(
      key: const ValueKey<String>('partial-open-action'),
      onTap: busy ? null : onPressed,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.deviceControlInactive.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                child: Text(
                  '60cm',
                  style: AppTextTokens.deviceControlBadge(textTheme),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 1.4,
                  color: AppColors.deviceControlPrimaryAction,
                ),
              ),
              child: const Center(
                child: _DeviceControlAssetIcon(
                  assetPath: _DeviceCommandAssetPaths.partialOpen,
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 1),
            child: Text(
              'Partial open',
              style: AppTextTokens.deviceControlQuickActionTitle(textTheme),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreSettingsCard extends StatelessWidget {
  const _MoreSettingsCard({
    required this.busy,
    required this.textTheme,
    required this.onPressed,
  });

  final bool busy;
  final TextTheme textTheme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _ControlCard(
      key: const ValueKey<String>('more-settings-action'),
      onTap: busy ? null : onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const _DeviceControlAssetIcon(
            assetPath: _DeviceCommandAssetPaths.moreSetting,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'More setting',
              style: AppTextTokens.deviceControlQuickActionTitle(textTheme),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.deviceControlPanel,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
