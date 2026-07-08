import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/device_command_controller.dart';

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
  bool _autoCloseEnabled = true;

  @override
  Widget build(BuildContext context) {
    final commandState = ref.watch(deviceCommandControllerProvider);
    final controller = ref.read(deviceCommandControllerProvider.notifier);
    final isBusy =
        commandState.pendingAction != null ||
        commandState.pendingRemotePairingAction != null ||
        commandState.pendingRemoteManagementAction != null;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: FlinxNavigationBar(
        title: 'Garage door',
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
      body: SafeArea(
        top: false,
        child: ListView(
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
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Closed',
                style: AppTextTokens.deviceControlDoorState(textTheme),
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 28),
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
              onPartialOpen: () => controller.runAction(
                deviceId: widget.deviceId,
                action: DeviceCommandAction.partialOpenDoor,
              ),
              onMoreSettings: () =>
                  controller.queryRemotes(deviceId: widget.deviceId),
            ),
            const SizedBox(height: 22),
            const _DeviceControlBottomTabs(),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CycleMetric(
                label: 'Operated cycles',
                value: '100',
                textTheme: textTheme,
              ),
            ),
            Container(
              width: 1,
              height: 62,
              color: AppColors.deviceControlDivider,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 48),
                child: _CycleMetric(
                  label: 'Remaining',
                  value: '4900',
                  textTheme: textTheme,
                ),
              ),
            ),
            _PlaybackButton(onPressed: () {}),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.deviceControlDivider),
      ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextTokens.deviceControlMetricLabel(textTheme)),
        const SizedBox(height: 6),
        Text(value, style: AppTextTokens.deviceControlMetricValue(textTheme)),
      ],
    );
  }
}

class _PlaybackButton extends StatelessWidget {
  const _PlaybackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: 'Operation records',
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(44),
        backgroundColor: AppColors.deviceControlPanel,
        foregroundColor: AppColors.textPrimary,
      ),
      icon: const Icon(Icons.play_arrow_outlined, size: 24),
    );
  }
}

class _DeviceConnectionStrip extends StatelessWidget {
  const _DeviceConnectionStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
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
        fixedSize: const Size.square(82),
        backgroundColor: AppColors.deviceControlPrimaryAction,
        disabledBackgroundColor: AppColors.deviceControlPrimaryAction
            .withValues(alpha: 0.42),
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
          : Icon(icon, size: 44),
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
                  fontWeight: FontWeight.w500,
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
    required this.busy,
    required this.onLedChanged,
    required this.onAutoCloseChanged,
    required this.onPartialOpen,
    required this.onMoreSettings,
  });

  final bool ledEnabled;
  final bool autoCloseEnabled;
  final bool busy;
  final ValueChanged<bool> onLedChanged;
  final ValueChanged<bool> onAutoCloseChanged;
  final VoidCallback onPartialOpen;
  final VoidCallback onMoreSettings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.2,
      children: [
        _LedActionCard(
          enabled: ledEnabled,
          busy: busy,
          textTheme: textTheme,
          onChanged: onLedChanged,
        ),
        _PartialOpenCard(
          busy: busy,
          textTheme: textTheme,
          onPressed: onPartialOpen,
        ),
        _AutoCloseCard(
          enabled: autoCloseEnabled,
          textTheme: textTheme,
          onChanged: onAutoCloseChanged,
        ),
        _MoreSettingsCard(
          busy: busy,
          textTheme: textTheme,
          onPressed: onMoreSettings,
        ),
      ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.light_mode_outlined, size: 42),
              _FlinxSwitch(
                value: enabled,
                enabled: !busy,
                onChanged: onChanged,
              ),
            ],
          ),
          const Spacer(),
          Text('LED', style: AppTextTokens.deviceControlCardTitle(textTheme)),
          const SizedBox(height: 6),
          Text('1 min', style: AppTextTokens.deviceControlCardMeta(textTheme)),
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
                  '60cm',
                  style: AppTextTokens.deviceControlBadge(textTheme),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 92,
              height: 92,
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
              style: AppTextTokens.deviceControlCardTitle(textTheme),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoCloseCard extends StatelessWidget {
  const _AutoCloseCard({
    required this.enabled,
    required this.textTheme,
    required this.onChanged,
  });

  final bool enabled;
  final TextTheme textTheme;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ControlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.event_available_outlined, size: 42),
              _FlinxSwitch(value: enabled, enabled: true, onChanged: onChanged),
            ],
          ),
          const Spacer(),
          Text(
            'Auto close',
            style: AppTextTokens.deviceControlCardTitle(textTheme),
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
      onTap: busy ? null : onPressed,
      child: Row(
        children: [
          const Icon(Icons.settings_outlined, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'More setting',
              style: AppTextTokens.deviceControlCardTitle(textTheme),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.deviceControlPanel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(padding: const EdgeInsets.all(18), child: child),
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
    return Switch(
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
    );
  }
}

class _DeviceControlBottomTabs extends StatelessWidget {
  const _DeviceControlBottomTabs();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _BottomTab(icon: Icons.description_outlined, selected: false),
        _BottomTab(icon: Icons.home_filled, selected: true),
        _BottomTab(icon: Icons.health_and_safety_outlined, selected: false),
      ],
    );
  }
}

class _BottomTab extends StatelessWidget {
  const _BottomTab({required this.icon, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.textPrimary
        : AppColors.deviceControlInactive;
    return SizedBox(
      width: 72,
      height: 58,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 42),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 10 : 0,
            height: selected ? 10 : 0,
            decoration: const BoxDecoration(
              color: AppColors.textPrimary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
