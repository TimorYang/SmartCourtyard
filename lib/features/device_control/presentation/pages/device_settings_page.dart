import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';

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
  String _partialOpen = '12cm';
  String _autoClose = '0s';
  String _autoClosePosition = 'Any position';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 42, 24, 24),
              children: [
                Text(
                  'DEVICE SETTINGS',
                  style: AppTextTokens.deviceSettingsTitle(textTheme),
                ),
                const SizedBox(height: 44),
                Text(
                  'For users',
                  style: AppTextTokens.deviceSettingsSectionLabel(textTheme),
                ),
                const SizedBox(height: 8),
                _SettingsRows(
                  rows: [
                    _SettingsRowData(
                      icon: Icons.settings_remote_outlined,
                      title: 'Transmitter management',
                      onTap: () => context.push(
                        '${TransmitterManagementPage.routePath}'
                        '?deviceId=${Uri.encodeComponent(widget.deviceId)}',
                      ),
                    ),
                    _SettingsRowData(
                      icon: Icons.light_mode_outlined,
                      title: 'LED off delay',
                      value: _ledOffDelay,
                      onTap: _showLedOffDelaySheet,
                    ),
                    _SettingsRowData(
                      icon: Icons.sensor_door_outlined,
                      title: 'Partial open',
                      value: _partialOpen,
                      onTap: _showPartialOpenSheet,
                    ),
                    _SettingsRowData(
                      icon: Icons.door_back_door_outlined,
                      title: 'Auto close',
                      value: _autoClose,
                      onTap: _showAutoCloseSheet,
                    ),
                    _SettingsRowData(
                      icon: Icons.info_outline,
                      title: 'About the device',
                      onTap: () => context.push(
                        '${AboutDevicePage.routePath}'
                        '?deviceId=${Uri.encodeComponent(widget.deviceId)}',
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

  Future<void> _showLedOffDelaySheet() async {
    final value = await _showOptionSheet(
      context: context,
      title: 'LED off delay',
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
      title: 'Partial open height',
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

class AboutDevicePage extends StatelessWidget {
  const AboutDevicePage({required this.deviceId, super.key});

  static const routeName = 'about-device';
  static const routePath = '/device-settings/about';

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                  'About the device',
                  style: AppTextTokens.deviceSettingsTitle(textTheme),
                ),
                const SizedBox(height: 28),
                _SettingsRows(
                  rows: const [
                    _SettingsRowData(
                      icon: Icons.bluetooth,
                      title: 'Bluetooth name',
                    ),
                    _SettingsRowData(
                      icon: Icons.developer_board_outlined,
                      title: 'Firmware version',
                    ),
                    _SettingsRowData(
                      icon: Icons.memory_outlined,
                      title: 'Hardware version',
                    ),
                    _SettingsRowData(
                      icon: Icons.manage_search_outlined,
                      title: 'Check version',
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
                  'Setting',
                  style: AppTextTokens.deviceSettingsTitle(textTheme),
                ),
                const SizedBox(height: 8),
                Text(
                  'For users',
                  style: AppTextTokens.deviceSettingsSectionLabel(textTheme),
                ),
                const SizedBox(height: 8),
                _SettingsRows(
                  rows: const [
                    _SettingsRowData(
                      icon: Icons.settings_remote_outlined,
                      title: 'Transmitter learning',
                    ),
                    _SettingsRowData(
                      icon: Icons.settings_outlined,
                      title: 'Management',
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
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
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
            height: 58,
            child: Row(
              children: [
                Icon(data.icon, size: 22, color: AppColors.textIcon),
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
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right,
                  size: 28,
                  color: AppColors.deviceControlInactive,
                ),
              ],
            ),
          ),
        ),
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

  final String initialPosition;
  final String initialTime;

  @override
  State<_AutoCloseSheet> createState() => _AutoCloseSheetState();
}

class _AutoCloseSheetState extends State<_AutoCloseSheet> {
  static const _positions = ['Up limit', 'Any position'];

  late String _position = widget.initialPosition;
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

    return _SettingsSheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Auto closing setting',
            textAlign: TextAlign.center,
            style: AppTextTokens.deviceSettingsSheetTitle(textTheme),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'Current setting: 120s (motor setting)\nAuto close position',
              style: AppTextTokens.deviceSettingsSheetCaption(textTheme),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (final position in _positions) ...[
                Expanded(
                  child: _SegmentButton(
                    label: position,
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
              'Auto close time',
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
                    label: time,
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

  final String position;
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
                'Cancel',
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
                'Confirm',
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
