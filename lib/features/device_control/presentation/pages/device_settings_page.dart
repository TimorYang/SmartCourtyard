import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../../shared/widgets/flinx_switch.dart';

class DeviceSettingsAssetPaths {
  const DeviceSettingsAssetPaths._();

  static const transmitterManagement =
      'assets/icons/device_settings/device_settings_transmitter_management_icon.png';
  static const ledOffDelay =
      'assets/icons/device_settings/device_settings_led_off_delay_icon.png';
  static const partialOpen =
      'assets/icons/device_settings/device_settings_partial_open_icon.png';
  static const autoClose =
      'assets/icons/device_settings/device_settings_auto_close_icon.png';
  static const openingSpeed =
      'assets/icons/device_settings/device_settings_opening_speed_icon.png';
  static const aboutDevice =
      'assets/icons/device_settings/device_settings_about_device_icon.png';
  static const doorOpenReminder =
      'assets/icons/device_settings/device_settings_door_open_reminder_icon.png';
  static const forceMargin =
      'assets/icons/device_settings/device_settings_force_margin_icon.png';
}

class DeviceSettingsPage extends StatefulWidget {
  const DeviceSettingsPage({required this.deviceId, super.key});

  static const routeName = 'device-settings';
  static const routePath = '/device-settings';

  final String deviceId;

  @override
  State<DeviceSettingsPage> createState() => _DeviceSettingsPageState();
}

class _DeviceSettingsPageState extends State<DeviceSettingsPage> {
  String _ledOffDelay = '3min';
  String _partialOpen = '12min';
  String _autoClose = '15s';
  var _autoClosePosition = _AutoClosePosition.anyPosition;
  var _doorOpenReminderEnabled = true;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 24),
              children: [
                Text(
                  l10n.deviceSettingsTitle,
                  style: AppTextTokens.deviceSettingsTitle(textTheme),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.deviceSettingsForUsers,
                  style: AppTextTokens.deviceSettingsMainSectionLabel(
                    textTheme,
                  ),
                ),
                const SizedBox(height: 10),
                _SettingsRows(
                  rows: [
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.transmitterManagement,
                      fallbackIcon: Icons.settings_remote_outlined,
                      title: l10n.deviceSettingsTransmitterManagement,
                      onTap: () => context.push(
                        '${TransmitterManagementPage.routePath}'
                        '?deviceId=${Uri.encodeComponent(widget.deviceId)}',
                      ),
                    ),
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.ledOffDelay,
                      fallbackIcon: Icons.light_mode_outlined,
                      title: l10n.deviceSettingsLedOffDelay,
                      value: _formatDuration(l10n, _ledOffDelay),
                      onTap: _showLedOffDelaySheet,
                    ),
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.partialOpen,
                      fallbackIcon: Icons.sensor_door_outlined,
                      title: l10n.deviceSettingsPartialOpen,
                      value: _formatDuration(l10n, _partialOpen),
                      onTap: _showPartialOpenSheet,
                    ),
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.autoClose,
                      fallbackIcon: Icons.door_back_door_outlined,
                      title: l10n.deviceSettingsAutoClose,
                      value: _formatDuration(l10n, _autoClose),
                      onTap: _showAutoCloseSheet,
                    ),
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.openingSpeed,
                      fallbackIcon: Icons.speed_outlined,
                      title: l10n.deviceSettingsOpeningSpeed,
                      value: l10n.deviceSettingsOpeningSpeedValue,
                    ),
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.aboutDevice,
                      fallbackIcon: Icons.info_outline,
                      title: l10n.deviceSettingsAboutDevice,
                      onTap: () => context.push(
                        '${AboutDevicePage.routePath}'
                        '?deviceId=${Uri.encodeComponent(widget.deviceId)}',
                      ),
                    ),
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.doorOpenReminder,
                      fallbackIcon: Icons.notifications_active_outlined,
                      title: l10n.deviceSettingsDoorOpenReminder,
                      trailing: FlinxSwitch(
                        value: _doorOpenReminderEnabled,
                        onChanged: (value) {
                          setState(() => _doorOpenReminderEnabled = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  l10n.deviceSettingsForInstallers,
                  style: AppTextTokens.deviceSettingsMainSectionLabel(
                    textTheme,
                  ),
                ),
                const SizedBox(height: 10),
                _SettingsRows(
                  rows: [
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.forceMargin,
                      fallbackIcon: Icons.tune_rounded,
                      title: l10n.deviceSettingsForceMargin,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLedOffDelaySheet() async {
    final value = await _showOptionSheet(
      context: context,
      title: AppLocalizations.of(context).deviceSettingsLedOffDelay,
      options: _zeroToOneHundredOptions,
      initialValue: '5',
    );
    if (value == null || !mounted) {
      return;
    }
    setState(() => _ledOffDelay = value);
  }

  Future<void> _showPartialOpenSheet() async {
    final value = await _showOptionSheet(
      context: context,
      title: AppLocalizations.of(context).deviceSettingsPartialOpenHeight,
      options: _zeroToOneHundredOptions,
      initialValue: '20',
    );
    if (value == null || !mounted) {
      return;
    }
    setState(() => _partialOpen = value);
  }

  Future<void> _showAutoCloseSheet() async {
    final result = await showModalBottomSheet<_AutoCloseSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.deviceSettingsSheetScrim,
      builder: (context) {
        return _AutoCloseSheet(
          initialPosition: _autoClosePosition,
          initialTime: '1min',
        );
      },
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _autoClose = result.time;
      _autoClosePosition = result.position;
    });
  }
}

final _zeroToOneHundredOptions = List<String>.generate(
  101,
  (index) => index.toString(),
);

final _autoCloseTimeOptions = [
  '0s',
  '30s',
  for (var minute = 1; minute <= 60; minute++) '${minute}min',
];

String _formatDuration(AppLocalizations l10n, String value) {
  if (value.endsWith('min')) {
    return l10n.deviceSettingsMinutes(
      int.parse(value.substring(0, value.length - 3)),
    );
  }
  if (value.endsWith('s')) {
    return l10n.deviceSettingsSeconds(
      int.parse(value.substring(0, value.length - 1)),
    );
  }
  return value;
}

class AboutDevicePage extends StatelessWidget {
  const AboutDevicePage({required this.deviceId, super.key});

  static const routeName = 'about-device';
  static const routePath = '/device-settings/about';

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
              children: [
                Text(
                  l10n.deviceSettingsAboutDevice,
                  style: AppTextTokens.deviceSettingsTitle(textTheme),
                ),
                const SizedBox(height: 28),
                _SettingsRows(
                  rows: [
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.aboutDevice,
                      fallbackIcon: Icons.bluetooth,
                      title: l10n.deviceSettingsBluetoothName,
                    ),
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.aboutDevice,
                      fallbackIcon: Icons.developer_board_outlined,
                      title: l10n.deviceSettingsFirmwareVersion,
                    ),
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.aboutDevice,
                      fallbackIcon: Icons.memory_outlined,
                      title: l10n.deviceSettingsHardwareVersion,
                    ),
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.aboutDevice,
                      fallbackIcon: Icons.manage_search_outlined,
                      title: l10n.deviceSettingsCheckVersion,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TransmitterManagementPage extends StatelessWidget {
  const TransmitterManagementPage({required this.deviceId, super.key});

  static const routeName = 'transmitter-management';
  static const routePath = '/device-settings/transmitters';

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              children: [
                Text(
                  l10n.deviceSettingsTitle,
                  style: AppTextTokens.deviceSettingsTitle(textTheme),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.deviceSettingsForUsers,
                  style: AppTextTokens.deviceSettingsSectionLabel(textTheme),
                ),
                const SizedBox(height: 8),
                _SettingsRows(
                  rows: [
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.transmitterManagement,
                      fallbackIcon: Icons.settings_remote_outlined,
                      title: l10n.deviceSettingsTransmitterLearning,
                    ),
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.transmitterManagement,
                      fallbackIcon: Icons.settings_outlined,
                      title: l10n.deviceSettingsManagement,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsRows extends StatelessWidget {
  const _SettingsRows({required this.rows});

  final List<_SettingsRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < rows.length; index++)
          _SettingsRow(data: rows[index], showTopDivider: index == 0),
      ],
    );
  }
}

class _SettingsRowData {
  const _SettingsRowData({
    required this.assetPath,
    required this.fallbackIcon,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.data, required this.showTopDivider});

  final _SettingsRowData data;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: showTopDivider
                  ? const BorderSide(color: AppColors.deviceSettingsDivider)
                  : BorderSide.none,
              bottom: const BorderSide(color: AppColors.deviceSettingsDivider),
            ),
          ),
          child: SizedBox(
            height: 77,
            child: Row(
              children: [
                _DeviceSettingsAssetIcon(
                  assetPath: data.assetPath,
                  fallbackIcon: data.fallbackIcon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextTokens.deviceSettingsRowTitle(textTheme),
                  ),
                ),
                if (data.value != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    data.value!,
                    style: AppTextTokens.deviceSettingsRowValue(textTheme),
                  ),
                ],
                if (data.trailing != null) ...[
                  const SizedBox(width: 12),
                  data.trailing!,
                ] else ...[
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chevron_right,
                    size: 28,
                    color: AppColors.textPrimary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceSettingsAssetIcon extends StatelessWidget {
  const _DeviceSettingsAssetIcon({
    required this.assetPath,
    required this.fallbackIcon,
  });

  final String assetPath;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: 34,
      height: 34,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: 34,
        height: 34,
        child: Icon(fallbackIcon, size: 24, color: AppColors.textIcon),
      ),
    );
  }
}

Future<String?> _showOptionSheet({
  required BuildContext context,
  required String title,
  required List<String> options,
  required String initialValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.deviceSettingsSheetScrim,
    builder: (context) {
      return _OptionSheet(
        title: title,
        options: options,
        initialValue: initialValue,
      );
    },
  );
}

class _OptionSheet extends StatefulWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.initialValue,
  });

  final String title;
  final List<String> options;
  final String initialValue;

  @override
  State<_OptionSheet> createState() => _OptionSheetState();
}

class _OptionSheetState extends State<_OptionSheet> {
  late String _selectedValue = widget.initialValue;
  late final ScrollController _scrollController = ScrollController(
    initialScrollOffset: _initialOptionOffset(
      options: widget.options,
      selectedValue: widget.initialValue,
    ),
  );

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _SettingsSheetFrame(
      child: Column(
        children: [
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: AppTextTokens.deviceSettingsSheetTitle(textTheme),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                for (final option in widget.options)
                  _SheetOption(
                    label: option,
                    selected: option == _selectedValue,
                    onTap: () => setState(() => _selectedValue = option),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SheetActionRow(
            onConfirm: () => Navigator.pop(context, _selectedValue),
          ),
        ],
      ),
    );
  }
}

class _AutoCloseSheet extends StatefulWidget {
  const _AutoCloseSheet({
    required this.initialPosition,
    required this.initialTime,
  });

  final _AutoClosePosition initialPosition;
  final String initialTime;

  @override
  State<_AutoCloseSheet> createState() => _AutoCloseSheetState();
}

class _AutoCloseSheetState extends State<_AutoCloseSheet> {
  static const _positions = [
    _AutoClosePosition.upLimit,
    _AutoClosePosition.anyPosition,
  ];

  late _AutoClosePosition _position = widget.initialPosition;
  late String _time = widget.initialTime;
  late final ScrollController _timeScrollController = ScrollController(
    initialScrollOffset: _initialOptionOffset(
      options: _autoCloseTimeOptions,
      selectedValue: widget.initialTime,
    ),
  );

  @override
  void dispose() {
    _timeScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return _SettingsSheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.deviceSettingsAutoClosingSetting,
            textAlign: TextAlign.center,
            style: AppTextTokens.deviceSettingsSheetTitle(textTheme),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              l10n.deviceSettingsAutoCloseCaption,
              style: AppTextTokens.deviceSettingsSheetCaption(textTheme),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (final position in _positions) ...[
                Expanded(
                  child: _SegmentButton(
                    label: _positionLabel(l10n, position),
                    selected: _position == position,
                    onTap: () => setState(() => _position = position),
                  ),
                ),
                if (position != _positions.last) const SizedBox(width: 36),
              ],
            ],
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              l10n.deviceSettingsAutoCloseTime,
              style: AppTextTokens.deviceSettingsSheetCaption(textTheme),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              controller: _timeScrollController,
              padding: EdgeInsets.zero,
              children: [
                for (final time in _autoCloseTimeOptions)
                  _SheetOption(
                    label: _formatDuration(l10n, time),
                    selected: time == _time,
                    onTap: () => setState(() => _time = time),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SheetActionRow(
            onConfirm: () => Navigator.pop(
              context,
              _AutoCloseSelection(position: _position, time: _time),
            ),
          ),
        ],
      ),
    );
  }
}

String _positionLabel(AppLocalizations l10n, _AutoClosePosition position) =>
    switch (position) {
      _AutoClosePosition.upLimit => l10n.deviceSettingsUpLimit,
      _AutoClosePosition.anyPosition => l10n.deviceSettingsAnyPosition,
    };

enum _AutoClosePosition { upLimit, anyPosition }

double _initialOptionOffset({
  required List<String> options,
  required String selectedValue,
}) {
  final selectedIndex = options.indexOf(selectedValue);
  if (selectedIndex <= 0) {
    return 0;
  }
  return math.max(0, selectedIndex * 46.0 - 92);
}

class _AutoCloseSelection {
  const _AutoCloseSelection({required this.position, required this.time});

  final _AutoClosePosition position;
  final String time;
}

class _SettingsSheetFrame extends StatelessWidget {
  const _SettingsSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.72,
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.backgroundPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: selected
              ? const Border.symmetric(
                  horizontal: BorderSide(
                    color: AppColors.deviceSettingsDivider,
                  ),
                )
              : null,
        ),
        child: SizedBox(
          height: 46,
          child: Center(
            child: Text(
              label,
              style: selected
                  ? AppTextTokens.deviceSettingsSheetSelectedOption(textTheme)
                  : AppTextTokens.deviceSettingsSheetOption(textTheme),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 45,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: selected
              ? AppColors.brandPrimary
              : AppColors.deviceSettingsSheetCancel,
          foregroundColor: selected
              ? AppColors.backgroundPrimary
              : AppColors.textMuted,
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: AppTextTokens.deviceSettingsSheetButton(textTheme).copyWith(
            color: selected ? AppColors.backgroundPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _SheetActionRow extends StatelessWidget {
  const _SheetActionRow({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 45,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.deviceSettingsSheetCancel,
                foregroundColor: AppColors.textMuted,
                shape: const StadiumBorder(),
              ),
              child: Text(
                l10n.deviceSettingsCancelAction,
                style: AppTextTokens.deviceSettingsSheetButton(
                  textTheme,
                ).copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          child: SizedBox(
            height: 45,
            child: FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: AppColors.backgroundPrimary,
                shape: const StadiumBorder(),
              ),
              child: Text(
                l10n.deviceSettingsConfirmAction,
                style: AppTextTokens.deviceSettingsSheetButton(
                  textTheme,
                ).copyWith(color: AppColors.backgroundPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
