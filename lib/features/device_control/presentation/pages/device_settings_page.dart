import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../../shared/widgets/flinx_switch.dart';
import 'transmitter_learning_page.dart';
import 'transmitter_list_page.dart';

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
  static const management =
      'assets/icons/device_settings/device_settings_management_icon.png';
  static const openingSpeedIndicatorPlaceholder =
      'assets/icons/device_settings/opening_speed_indicator_placeholder.png';
  static const forceMarginWarningPlaceholder =
      'assets/icons/device_settings/force_margin_warning_placeholder.png';
  static const forceMarginIndicatorPlaceholder =
      'assets/icons/device_settings/force_margin_indicator_placeholder.png';
  static const transmitterRenamePlaceholder =
      'assets/icons/device_settings/transmitter_rename_placeholder.png';
  static const transmitterAddPlaceholder =
      'assets/icons/device_settings/transmitter_add_placeholder.png';
  static const aboutDeviceBluetoothName =
      'assets/icons/device_settings/about_device_bluetooth_name.png';
  static const aboutDeviceFirmwareVersion =
      'assets/icons/device_settings/about_device_firmware_version.png';
  static const aboutDeviceHardwareVersion =
      'assets/icons/device_settings/about_device_hardware_version.png';
  static const aboutDeviceCheckVersion =
      'assets/icons/device_settings/about_device_check_version.png';
}

class OpeningSpeedConfig {
  const OpeningSpeedConfig({
    required this.minimum,
    required this.maximum,
    required this.current,
  }) : assert(minimum <= current && current <= maximum);

  final int minimum;
  final int maximum;
  final int current;
}

class DeviceSettingsPage extends StatefulWidget {
  const DeviceSettingsPage({
    required this.deviceId,
    this.forceMarginDialogState = 1,
    this.openingSpeedConfig = const OpeningSpeedConfig(
      minimum: 80,
      maximum: 100,
      current: 80,
    ),
    super.key,
  }) : assert(forceMarginDialogState >= 0 && forceMarginDialogState <= 2);

  static const routeName = 'device-settings';
  static const routePath = '/device-settings';

  final String deviceId;
  final int forceMarginDialogState;
  final OpeningSpeedConfig openingSpeedConfig;

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
                      onTap: _showOpeningSpeedSheet,
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
                      onTap: _showForceMargin,
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
      options: _ledOffDelayOptions,
      initialValue: _ledOffDelay,
      heightFactor: 0.50,
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
      heightFactor: 0.50,
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
          heightFactor: 0.65,
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

  Future<void> _showOpeningSpeedSheet() async {
    await _showSpeedSheet(
      title: AppLocalizations.of(context).deviceSettingsOpeningSpeed,
      currentSetting: AppLocalizations.of(
        context,
      ).deviceSettingsOpeningSpeedCurrent(widget.openingSpeedConfig.current),
      speedConfig: widget.openingSpeedConfig,
      placeholderAssetPath:
          DeviceSettingsAssetPaths.openingSpeedIndicatorPlaceholder,
    );
  }

  Future<void> _showForceMargin() async {
    final l10n = AppLocalizations.of(context);
    switch (widget.forceMarginDialogState) {
      case 0:
        await showDialog<void>(
          context: context,
          builder: (context) => _ForceMarginWarningDialog(
            description: l10n.deviceSettingsForceMarginWarning15Days,
          ),
        );
      case 1:
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: AppColors.deviceSettingsSheetScrim,
          builder: (context) => _ForceMarginAdjustmentSheet(
            description: l10n.deviceSettingsForceMarginWarning3DaysFull,
            placeholderAssetPath:
                DeviceSettingsAssetPaths.forceMarginIndicatorPlaceholder,
          ),
        );
      case 2:
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: AppColors.deviceSettingsSheetScrim,
          builder: (context) => _ForceMarginLevelSheet(),
        );
    }
  }

  Future<void> _showSpeedSheet({
    required String title,
    required String currentSetting,
    OpeningSpeedConfig speedConfig = const OpeningSpeedConfig(
      minimum: 80,
      maximum: 100,
      current: 80,
    ),
    String? notice,
    required String placeholderAssetPath,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.deviceSettingsSheetScrim,
      builder: (context) => _SpeedAdjustmentSheet(
        title: title,
        currentSetting: currentSetting,
        speedConfig: speedConfig,
        notice: notice,
        placeholderAssetPath: placeholderAssetPath,
      ),
    );
  }
}

final _zeroToOneHundredOptions = List<String>.generate(
  101,
  (index) => index.toString(),
);

final _ledOffDelayOptions = [
  for (var minute = 1; minute <= 9; minute++) '${minute}min',
];

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
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.only(left: 20),
                  child: Text(
                    l10n.deviceSettingsAboutDevice,
                    style: AppTextTokens.deviceSettingsTitle(textTheme),
                  ),
                ),
                const SizedBox(height: 28),
                _SettingsRows(
                  rows: [
                    _SettingsRowData(
                      assetPath:
                          DeviceSettingsAssetPaths.aboutDeviceBluetoothName,
                      fallbackIcon: Icons.bluetooth,
                      title: l10n.deviceSettingsBluetoothName,
                    ),
                    _SettingsRowData(
                      assetPath:
                          DeviceSettingsAssetPaths.aboutDeviceFirmwareVersion,
                      fallbackIcon: Icons.developer_board_outlined,
                      title: l10n.deviceSettingsFirmwareVersion,
                    ),
                    _SettingsRowData(
                      assetPath:
                          DeviceSettingsAssetPaths.aboutDeviceHardwareVersion,
                      fallbackIcon: Icons.memory_outlined,
                      title: l10n.deviceSettingsHardwareVersion,
                    ),
                    _SettingsRowData(
                      assetPath:
                          DeviceSettingsAssetPaths.aboutDeviceCheckVersion,
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
                      onTap: () => context.push(
                        '${TransmitterLearningPage.routePath}?deviceId=${Uri.encodeComponent(deviceId)}',
                      ),
                    ),
                    _SettingsRowData(
                      assetPath: DeviceSettingsAssetPaths.management,
                      fallbackIcon: Icons.settings_outlined,
                      title: l10n.deviceSettingsManagement,
                      onTap: () => context.push(
                        '${TransmitterListPage.routePath}?deviceId=${Uri.encodeComponent(deviceId)}',
                      ),
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
  required double heightFactor,
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
        heightFactor: heightFactor,
      );
    },
  );
}

class _OptionSheet extends StatefulWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.initialValue,
    required this.heightFactor,
  });

  final String title;
  final List<String> options;
  final String initialValue;
  final double heightFactor;

  @override
  State<_OptionSheet> createState() => _OptionSheetState();
}

class _OptionSheetState extends State<_OptionSheet> {
  late String _selectedValue = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return _SettingsSheetFrame(
      heightFactor: widget.heightFactor,
      child: Column(
        children: [
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: AppTextTokens.deviceSettingsSheetTitle(textTheme),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _FixedSelectionList<String>(
              values: widget.options,
              initialValue: _selectedValue,
              labelBuilder: (option) => _formatDuration(l10n, option),
              onSelected: (option) => setState(() => _selectedValue = option),
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
    required this.heightFactor,
  });

  final _AutoClosePosition initialPosition;
  final String initialTime;
  final double heightFactor;

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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return _SettingsSheetFrame(
      heightFactor: widget.heightFactor,
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
            child: _FixedSelectionList<String>(
              values: _autoCloseTimeOptions,
              initialValue: _time,
              labelBuilder: (time) => _formatDuration(l10n, time),
              onSelected: (time) => setState(() => _time = time),
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

class _AutoCloseSelection {
  const _AutoCloseSelection({required this.position, required this.time});

  final _AutoClosePosition position;
  final String time;
}

class _SpeedAdjustmentSheet extends StatefulWidget {
  const _SpeedAdjustmentSheet({
    required this.title,
    required this.currentSetting,
    required this.speedConfig,
    this.notice,
    required this.placeholderAssetPath,
  });

  final String title;
  final String currentSetting;
  final OpeningSpeedConfig speedConfig;
  final String? notice;
  final String placeholderAssetPath;

  @override
  State<_SpeedAdjustmentSheet> createState() => _SpeedAdjustmentSheetState();
}

class _SpeedAdjustmentSheetState extends State<_SpeedAdjustmentSheet> {
  late double _value = widget.speedConfig.current.toDouble();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return _SettingsSheetFrame(
      heightFactor: 0.61,
      child: Column(
        children: [
          Text(
            widget.title,
            style: AppTextTokens.deviceSettingsSheetTitle(textTheme),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.currentSetting,
              style: AppTextTokens.deviceSettingsSheetCaption(textTheme),
            ),
          ),
          if (widget.notice != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.notice!,
                style: AppTextTokens.deviceSettingsSheetCaption(textTheme),
              ),
            ),
          ],
          const SizedBox(height: 35),
          Expanded(
            child: Row(
              children: [
                _SpeedIndicatorCluster(assetPath: widget.placeholderAssetPath),
                const SizedBox(width: 30),
                _VerticalSpeedSlider(
                  value: _value,
                  minimum: widget.speedConfig.minimum,
                  maximum: widget.speedConfig.maximum,
                  onChanged: (value) => setState(() => _value = value),
                ),
                const SizedBox(width: 40),
                SizedBox(
                  width: 84,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.speedConfig.maximum}%',
                        style: AppTextTokens.deviceSettingsSheetCaption(
                          textTheme,
                        ),
                      ),
                      Text(
                        '${(widget.speedConfig.minimum + widget.speedConfig.maximum) ~/ 2}%',
                        style: AppTextTokens.deviceSettingsSheetCaption(
                          textTheme,
                        ),
                      ),
                      Text(
                        '${_value.round()}%\n(STD)',
                        style: AppTextTokens.deviceSettingsSheetCaption(
                          textTheme,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SheetActionRow(onConfirm: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _SpeedIndicatorCluster extends StatelessWidget {
  const _SpeedIndicatorCluster({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    const placements = [
      Offset(22, 0),
      Offset(62, 0),
      Offset(102, 0),
      Offset(22, 122),
      Offset(62, 122),
      Offset(22, 244),
    ];

    return SizedBox(
      width: 152,
      height: _VerticalSpeedSlider._height,
      child: Stack(
        children: [
          for (final placement in placements)
            Positioned(
              left: placement.dx,
              top: placement.dy,
              child: _CutAssetPlaceholder(assetPath: assetPath, height: 28),
            ),
        ],
      ),
    );
  }
}

class _VerticalSpeedSlider extends StatelessWidget {
  const _VerticalSpeedSlider({
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
  });

  final double value;
  final int minimum;
  final int maximum;
  final ValueChanged<double> onChanged;

  static const _height = 300.0;
  static const _thumbHeight = 60.0;

  void _updateValue(Offset localPosition) {
    final progress = (1 - localPosition.dy / (_height - _thumbHeight)).clamp(
      0.0,
      1.0,
    );
    final steppedValue = (minimum + (progress * (maximum - minimum)).round())
        .toDouble();
    onChanged(steppedValue);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (value - minimum) / (maximum - minimum);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (details) => _updateValue(details.localPosition),
      onVerticalDragUpdate: (details) => _updateValue(details.localPosition),
      onTapDown: (details) => _updateValue(details.localPosition),
      child: SizedBox(
        width: 40,
        height: _height,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 56,
                height: _height,
                decoration: BoxDecoration(
                  color: AppColors.deviceSettingsSheetCancel,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              Positioned(
                bottom: progress * (_height - _thumbHeight),
                child: Container(
                  width: 28,
                  height: _thumbHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: const Icon(
                    Icons.drag_handle,
                    color: AppColors.backgroundPrimary,
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

class _ForceMarginAdjustmentSheet extends StatefulWidget {
  const _ForceMarginAdjustmentSheet({
    required this.description,
    required this.placeholderAssetPath,
  });

  final String description;
  final String placeholderAssetPath;

  @override
  State<_ForceMarginAdjustmentSheet> createState() =>
      _ForceMarginAdjustmentSheetState();
}

class _ForceMarginAdjustmentSheetState
    extends State<_ForceMarginAdjustmentSheet> {
  var _value = 0.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _SettingsSheetFrame(
      heightFactor: 0.72,
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context).deviceSettingsForceMargin,
            style: AppTextTokens.deviceSettingsSheetTitle(textTheme),
          ),
          const SizedBox(height: 24),
          Text(
            widget.description,
            style: AppTextTokens.deviceSettingsSheetCaption(
              textTheme,
            ).copyWith(color: AppColors.deviceSettingsForceMarginWarningText),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                _ForceMarginIndicatorCluster(
                  assetPath: widget.placeholderAssetPath,
                ),
                const SizedBox(width: 50),
                _VerticalSpeedSlider(
                  value: _value,
                  minimum: 0,
                  maximum: 15,
                  onChanged: (value) => setState(() => _value = value),
                ),
                const _ForceMarginScaleLabels(),
              ],
            ),
          ),
          _SheetActionRow(onConfirm: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _ForceMarginIndicatorCluster extends StatelessWidget {
  const _ForceMarginIndicatorCluster({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 112,
    height: _VerticalSpeedSlider._height,
    child: Stack(
      children: [
        Positioned(
          left: 8,
          top: 0,
          child: _CutAssetPlaceholder(assetPath: assetPath, height: 28),
        ),
        Positioned(
          left: 58,
          top: 0,
          child: _CutAssetPlaceholder(assetPath: assetPath, height: 28),
        ),
        Positioned(
          left: 8,
          bottom: 0,
          child: _CutAssetPlaceholder(assetPath: assetPath, height: 28),
        ),
      ],
    ),
  );
}

class _ForceMarginScaleLabels extends StatelessWidget {
  const _ForceMarginScaleLabels();

  @override
  Widget build(BuildContext context) {
    final style = AppTextTokens.deviceSettingsSheetCaption(
      Theme.of(context).textTheme,
    );
    return SizedBox(
      width: 76,
      height: _VerticalSpeedSlider._height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text('+15%', textAlign: TextAlign.right, style: style),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text('STD', textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}

class _ForceMarginWarningDialog extends StatelessWidget {
  const _ForceMarginWarningDialog({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          const _CutAssetPlaceholder(
            assetPath: DeviceSettingsAssetPaths.forceMarginWarningPlaceholder,
            height: 72,
          ),
          const SizedBox(height: 24),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: AppColors.deviceSettingsForceMarginWarningText,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 182,
            height: 50,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deviceSettingsForceMarginConfirm,
              ),
              child: Text(l10n.deviceSettingsConfirmAction),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForceMarginLevelSheet extends StatefulWidget {
  @override
  State<_ForceMarginLevelSheet> createState() => _ForceMarginLevelSheetState();
}

class _ForceMarginLevelSheetState extends State<_ForceMarginLevelSheet> {
  var _level = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = [
      for (var level = 3; level <= 7; level++)
        l10n.deviceSettingsForceMarginLevel(level),
    ];
    return _SettingsSheetFrame(
      heightFactor: 0.5,
      child: Column(
        children: [
          Text(
            l10n.deviceSettingsForceMargin,
            style: AppTextTokens.deviceSettingsSheetTitle(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.deviceSettingsForceMarginLevelCurrent(_level),
            style: AppTextTokens.deviceSettingsSheetCaption(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _FixedSelectionList<String>(
              values: options,
              initialValue: l10n.deviceSettingsForceMarginLevel(_level),
              labelBuilder: (value) => value,
              onSelected: (value) =>
                  setState(() => _level = options.indexOf(value) + 3),
            ),
          ),
          _SheetActionRow(onConfirm: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _CutAssetPlaceholder extends StatelessWidget {
  const _CutAssetPlaceholder({required this.assetPath, this.height});

  final String assetPath;
  final double? height;

  @override
  Widget build(BuildContext context) => Image.asset(
    assetPath,
    width: height,
    height: height,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) => SizedBox(height: height),
  );
}

class _SettingsSheetFrame extends StatelessWidget {
  const _SettingsSheetFrame({required this.heightFactor, required this.child});

  final double heightFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: heightFactor,
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _FixedSelectionList<T> extends StatefulWidget {
  const _FixedSelectionList({
    required this.values,
    required this.initialValue,
    required this.labelBuilder,
    required this.onSelected,
  });

  static const itemExtent = 46.0;

  final List<T> values;
  final T initialValue;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  State<_FixedSelectionList<T>> createState() => _FixedSelectionListState<T>();
}

class _FixedSelectionListState<T> extends State<_FixedSelectionList<T>> {
  late int _selectedIndex = _initialIndex;
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: _selectedIndex);

  int get _initialIndex {
    final index = widget.values.indexOf(widget.initialValue);
    return index < 0 ? 0 : index;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final selectionTop =
            (constraints.maxHeight - _FixedSelectionList.itemExtent) / 2;

        return Stack(
          children: [
            ListWheelScrollView.useDelegate(
              controller: _controller,
              physics: const FixedExtentScrollPhysics(),
              itemExtent: _FixedSelectionList.itemExtent,
              onSelectedItemChanged: (index) {
                setState(() => _selectedIndex = index);
                widget.onSelected(widget.values[index]);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: widget.values.length,
                builder: (context, index) {
                  if (index == null) {
                    return null;
                  }
                  final selected = index == _selectedIndex;
                  return Center(
                    child: Text(
                      widget.labelBuilder(widget.values[index]),
                      style: selected
                          ? AppTextTokens.deviceSettingsSheetSelectedOption(
                              textTheme,
                            )
                          : AppTextTokens.deviceSettingsSheetOption(textTheme),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: selectionTop,
              left: 0,
              right: 0,
              height: _FixedSelectionList.itemExtent,
              child: IgnorePointer(
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: AppColors.deviceSettingsDivider,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
