import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../records/presentation/pages/operation_record_page.dart';
import '../../../security_center/presentation/pages/security_center_page.dart';
import '../../application/device_command_controller.dart';
import '../widgets/device_detail_bottom_navigation.dart';
import 'device_settings_page.dart';

class DeviceCommandPage extends ConsumerStatefulWidget {
  const DeviceCommandPage({required this.deviceId, super.key});

  static const routeName = 'device-command';
  static const routePath = '/device-command';

  final String deviceId;

  @override
  ConsumerState<DeviceCommandPage> createState() => _DeviceCommandPageState();
}

class _DeviceCommandPageState extends ConsumerState<DeviceCommandPage> {
  static const _garageDoorClosedAsset =
      'assets/images/device_control_garage_door_closed.png';
  static const _garageDoorFallbackAsset =
      'assets/icons/add_device/add_new_doors_garage_door.png';

  bool _ledEnabled = false;
  bool _unclosedReminderEnabled = false;
  bool _autoCloseEnabled = false;
  DeviceDetailTab _selectedTab = DeviceDetailTab.command;

  @override
  Widget build(BuildContext context) {
    final commandState = ref.watch(deviceCommandControllerProvider);
    final controller = ref.read(deviceCommandControllerProvider.notifier);
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
          deviceId: widget.deviceId,
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

  Widget _buildCommandPage({
    required DeviceCommandState commandState,
    required DeviceCommandController controller,
    required bool isBusy,
    required TextTheme textTheme,
  }) {
    return Scaffold(
      appBar: FlinxNavigationBar(
        title: 'TestFoor',
        showBottomDivider: false,
        actions: [
          IconButton(
            tooltip: 'More',
            onPressed: isBusy ? null : () {},
            icon: const Icon(Icons.more_horiz),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: DeviceDetailBottomNavigation(
        selectedTab: DeviceDetailTab.command,
        onSelected: _selectTab,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const PageStorageKey<String>('device-command-scroll'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          children: [
            _CycleSummary(textTheme: textTheme),
            const SizedBox(height: 16),
            const _DeviceConnectionStrip(),
            const SizedBox(height: 18),
            _DoorHeroImage(
              assetPath: _garageDoorClosedAsset,
              fallbackAssetPath: _garageDoorFallbackAsset,
            ),
            Center(
              child: Text(
                'Closed',
                style: AppTextTokens.deviceControlDoorState(textTheme),
              ),
            ),
            const SizedBox(height: 18),
            _DoorCommandRow(
              busy: isBusy,
              pendingAction: commandState.pendingAction,
              onClose: () => controller.runAction(
                deviceId: widget.deviceId,
                action: DeviceCommandAction.closeDoor,
              ),
              onStop: () => controller.runAction(
                deviceId: widget.deviceId,
                action: DeviceCommandAction.stopDoor,
              ),
              onOpen: () => controller.runAction(
                deviceId: widget.deviceId,
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
              unclosedReminderEnabled: _unclosedReminderEnabled,
              autoCloseEnabled: _autoCloseEnabled,
              busy: isBusy,
              onLedChanged: (enabled) async {
                setState(() => _ledEnabled = enabled);
                await controller.runAction(
                  deviceId: widget.deviceId,
                  action: enabled
                      ? DeviceCommandAction.turnLightOn
                      : DeviceCommandAction.turnLightOff,
                );
              },
              onAutoCloseChanged: (enabled) {
                setState(() => _autoCloseEnabled = enabled);
              },
              onUnclosedReminderChanged: (enabled) {
                setState(() => _unclosedReminderEnabled = enabled);
              },
              onPartialOpen: () => controller.runAction(
                deviceId: widget.deviceId,
                action: DeviceCommandAction.partialOpenDoor,
              ),
              onMoreSettings: () => context.push(
                '${DeviceSettingsPage.routePath}'
                '?deviceId=${Uri.encodeComponent(widget.deviceId)}',
              ),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

class _CycleSummary extends StatelessWidget {
  const _CycleSummary({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Operated cycles:',
          style: AppTextTokens.deviceControlMetricLabel(textTheme),
        ),
        const SizedBox(width: 3),
        Text(
          '3',
          style: AppTextTokens.deviceControlMetricValue(
            textTheme,
          ).copyWith(fontSize: 18),
        ),
      ],
    );
  }
}

class _DeviceConnectionStrip extends StatelessWidget {
  const _DeviceConnectionStrip();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 353,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _ConnectionGroup(
              deviceIcon: Icons.sensors_outlined,
              bluetoothActive: true,
              wifiActive: true,
            ),
            _ConnectionGroup(
              deviceIcon: Icons.settings_remote_outlined,
              bluetoothActive: false,
              wifiActive: true,
            ),
            _ConnectionGroup(
              deviceIcon: Icons.sensor_occupied_outlined,
              bluetoothActive: false,
              wifiActive: false,
            ),
            _ConnectionGroup(
              deviceIcon: Icons.solar_power_outlined,
              bluetoothActive: false,
              wifiActive: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionGroup extends StatelessWidget {
  const _ConnectionGroup({
    required this.deviceIcon,
    required this.bluetoothActive,
    required this.wifiActive,
  });

  final IconData deviceIcon;
  final bool bluetoothActive;
  final bool wifiActive;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = AppColors.deviceControlInactive.withValues(
      alpha: 0.66,
    );
    return Row(
      children: [
        Icon(deviceIcon, size: 28, color: AppColors.textPrimary),
        const SizedBox(width: 8),
        Icon(
          Icons.bluetooth,
          size: 16,
          color: bluetoothActive
              ? AppColors.deviceControlWireless
              : inactiveColor,
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.wifi,
          size: 18,
          color: wifiActive ? AppColors.deviceControlWireless : inactiveColor,
        ),
      ],
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
      aspectRatio: 1.55,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _DoorCommandButton(
          tooltip: 'Close',
          icon: Icons.keyboard_arrow_down,
          pending: pendingAction == DeviceCommandAction.closeDoor,
          onPressed: busy ? null : onClose,
        ),
        _DoorCommandButton(
          tooltip: 'Stop',
          icon: Icons.pause,
          pending: pendingAction == DeviceCommandAction.stopDoor,
          onPressed: busy ? null : onStop,
        ),
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
        fixedSize: const Size.square(55),
        backgroundColor: AppColors.deviceControlPrimaryAction,
        disabledBackgroundColor: AppColors.deviceControlPrimaryAction
            .withValues(alpha: 0.5),
        foregroundColor: AppColors.deviceControlPrimaryActionForeground,
        disabledForegroundColor: AppColors.deviceControlPrimaryActionForeground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: pending
          ? const SizedBox.square(
              dimension: 28,
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
    required this.unclosedReminderEnabled,
    required this.autoCloseEnabled,
    required this.busy,
    required this.onLedChanged,
    required this.onUnclosedReminderChanged,
    required this.onAutoCloseChanged,
    required this.onPartialOpen,
    required this.onMoreSettings,
  });

  final bool ledEnabled;
  final bool unclosedReminderEnabled;
  final bool autoCloseEnabled;
  final bool busy;
  final ValueChanged<bool> onLedChanged;
  final ValueChanged<bool> onUnclosedReminderChanged;
  final ValueChanged<bool> onAutoCloseChanged;
  final VoidCallback onPartialOpen;
  final VoidCallback onMoreSettings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 250,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 64,
                  child: _LedActionCard(
                    enabled: ledEnabled,
                    busy: busy,
                    textTheme: textTheme,
                    onChanged: onLedChanged,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 78,
                  child: _ToggleActionCard(
                    icon: Icons.door_front_door_outlined,
                    title: 'Unclosed reminding',
                    enabled: unclosedReminderEnabled,
                    busy: busy,
                    textTheme: textTheme,
                    onChanged: onUnclosedReminderChanged,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 72,
                  child: _ToggleActionCard(
                    icon: Icons.door_back_door_outlined,
                    title: 'Auto close',
                    enabled: autoCloseEnabled,
                    busy: busy,
                    textTheme: textTheme,
                    onChanged: onAutoCloseChanged,
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
                  flex: 152,
                  child: _PartialOpenCard(
                    busy: busy,
                    textTheme: textTheme,
                    onPressed: onPartialOpen,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 72,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.light_mode_outlined, size: 27),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'LED',
                    maxLines: 1,
                    style: AppTextTokens.deviceControlQuickActionTitle(
                      textTheme,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '3 min',
                    maxLines: 1,
                    style: AppTextTokens.deviceControlQuickActionMeta(
                      textTheme,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _FlinxSwitch(value: enabled, enabled: !busy, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ToggleActionCard extends StatelessWidget {
  const _ToggleActionCard({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.busy,
    required this.textTheme,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final bool busy;
  final TextTheme textTheme;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ControlCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 27),
              const Spacer(),
              _FlinxSwitch(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Text(
                  'Off',
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
                  width: 2,
                  color: AppColors.deviceControlPrimaryAction,
                ),
              ),
              child: const Icon(
                Icons.sensor_door_outlined,
                size: 44,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.settings_outlined, size: 27),
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _FlinxSwitch extends StatelessWidget {
  const _FlinxSwitch({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 32,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeThumbColor: AppColors.backgroundPrimary,
          activeTrackColor: AppColors.toggleSelected,
          inactiveThumbColor: AppColors.backgroundPrimary,
          inactiveTrackColor: AppColors.deviceControlInactive.withValues(
            alpha: 0.58,
          ),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
