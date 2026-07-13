import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';

class DeviceSharePage extends StatefulWidget {
  const DeviceSharePage({super.key});

  static const routeName = 'device-share';
  static const routePath = '/device-share';

  @override
  State<DeviceSharePage> createState() => _DeviceSharePageState();
}

enum _SharePermission { administrator, guest }

enum _SharePeriod { neverExpired, twoHours, customize }

class _DeviceSharePageState extends State<DeviceSharePage> {
  final _emailController = TextEditingController();
  var _permission = _SharePermission.administrator;
  var _period = _SharePeriod.neverExpired;
  var _sendEmail = true;
  late DateTime _periodEndsAt;

  @override
  void initState() {
    super.initState();
    _periodEndsAt = _roundedTwoHourExpiry(DateTime.now());
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final capabilities = [
      l10n.deviceShareCapabilityDoorControl,
      if (_permission == _SharePermission.administrator) ...[
        l10n.deviceShareCapabilityPartialOpen,
        l10n.deviceShareCapabilityLedDelay,
      ],
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(30, 4, 30, 18),
                    children: [
                      Text(
                        l10n.deviceShareTitle,
                        style: AppTextTokens.deviceShareTitle(textTheme),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.deviceShareSubtitle,
                        style: AppTextTokens.deviceShareSubtitle(textTheme),
                      ),
                      const SizedBox(height: 58),
                      _ShareFormRow(
                        label: l10n.deviceSharePermissionsLabel,
                        child: _ShareSelectField(
                          value: _permissionLabel(l10n),
                          onTap: _selectPermission,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _ShareFormRow(
                        label: l10n.deviceShareEmailLabel,
                        child: _ShareTextField(
                          controller: _emailController,
                          hintText: l10n.deviceShareEmailPlaceholder,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _ShareFormRow(
                        label: l10n.deviceSharePeriodLabel,
                        child: _ShareSelectField(
                          value: _periodLabel(l10n),
                          onTap: _selectPeriod,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SharePeriodSummary(
                        title: _period == _SharePeriod.neverExpired
                            ? l10n.deviceShareNeverExpired
                            : l10n.deviceShareTimeLabel,
                        value: _period == _SharePeriod.neverExpired
                            ? null
                            : _formatExpiry(_periodEndsAt),
                        onTap: _period == _SharePeriod.neverExpired
                            ? null
                            : _selectCustomTimeFromSummary,
                      ),
                      const SizedBox(height: 34),
                      _SendEmailToggle(
                        value: _sendEmail,
                        label: l10n.deviceShareSendEmailLabel,
                        onChanged: (value) {
                          setState(() {
                            _sendEmail = value;
                          });
                        },
                      ),
                      const SizedBox(height: 38),
                      Text(
                        l10n.deviceShareCapabilitiesTitle,
                        style: AppTextTokens.deviceShareSectionTitle(textTheme),
                      ),
                      const SizedBox(height: 14),
                      _CapabilitiesPanel(items: capabilities),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 22),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ShareActionButton(
                          label: l10n.deviceShareCancelAction,
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: AppColors.deviceShareCancelButton,
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _ShareActionButton(
                          label: l10n.deviceShareConfirmAction,
                          foregroundColor: Colors.white,
                          backgroundColor: AppColors.brandPrimary,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectPermission() async {
    final l10n = AppLocalizations.of(context);
    final selected = await showDialog<_SharePermission>(
      context: context,
      barrierColor: AppColors.deviceShareDialogOverlay,
      builder: (context) {
        return _ShareOptionDialog<_SharePermission>(
          options: [
            _ShareOption(
              value: _SharePermission.administrator,
              label: l10n.deviceShareAdministratorRole,
            ),
            _ShareOption(
              value: _SharePermission.guest,
              label: l10n.deviceShareGuestRole,
            ),
          ],
        );
      },
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _permission = selected;
    });
  }

  Future<void> _selectPeriod() async {
    final l10n = AppLocalizations.of(context);
    final selected = await showDialog<_SharePeriod>(
      context: context,
      barrierColor: AppColors.deviceShareDialogOverlay,
      builder: (context) {
        return _ShareOptionDialog<_SharePeriod>(
          options: [
            _ShareOption(
              value: _SharePeriod.neverExpired,
              label: l10n.deviceShareNeverExpired,
            ),
            _ShareOption(
              value: _SharePeriod.twoHours,
              label: l10n.deviceShareTwoHours,
            ),
            _ShareOption(
              value: _SharePeriod.customize,
              label: l10n.deviceShareCustomize,
            ),
          ],
        );
      },
    );
    if (selected == null) {
      return;
    }
    if (selected == _SharePeriod.customize) {
      await _selectCustomTimeFromSummary();
      return;
    }
    setState(() {
      _period = selected;
      if (selected == _SharePeriod.twoHours) {
        _periodEndsAt = _roundedTwoHourExpiry(DateTime.now());
      }
    });
  }

  Future<void> _selectCustomTimeFromSummary() async {
    final customTime = await _showCustomizeTimeDialog();
    if (customTime == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _period = _SharePeriod.customize;
      _periodEndsAt = customTime;
    });
  }

  Future<DateTime?> _showCustomizeTimeDialog() {
    return showDialog<DateTime>(
      context: context,
      barrierColor: AppColors.deviceShareDialogOverlay,
      builder: (context) {
        return _CustomizeTimeDialog(
          initialDateTime: _periodEndsAt.isAfter(DateTime.now())
              ? _periodEndsAt
              : _roundedTwoHourExpiry(DateTime.now()),
        );
      },
    );
  }

  String _permissionLabel(AppLocalizations l10n) {
    return switch (_permission) {
      _SharePermission.administrator => l10n.deviceShareAdministratorRole,
      _SharePermission.guest => l10n.deviceShareGuestRole,
    };
  }

  String _periodLabel(AppLocalizations l10n) {
    return switch (_period) {
      _SharePeriod.neverExpired => l10n.deviceShareNeverExpired,
      _SharePeriod.twoHours => l10n.deviceShareTwoHours,
      _SharePeriod.customize => l10n.deviceShareCustomize,
    };
  }

  DateTime _roundedTwoHourExpiry(DateTime now) {
    return DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
    ).add(const Duration(hours: 2));
  }

  String _formatExpiry(DateTime value) {
    return DateFormat('HH:mm dd-MM-yyyy').format(value);
  }
}

class _ShareFormRow extends StatelessWidget {
  const _ShareFormRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: AppTextTokens.deviceShareLabel(Theme.of(context).textTheme),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _ShareSelectField extends StatelessWidget {
  const _ShareSelectField({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _ShareFieldShell(
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: AppTextTokens.deviceShareField(
                  Theme.of(context).textTheme,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.brandPrimary,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareTextField extends StatelessWidget {
  const _ShareTextField({required this.controller, required this.hintText});

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return _ShareFieldShell(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        style: AppTextTokens.deviceShareField(Theme.of(context).textTheme),
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          hintText: hintText,
          hintStyle: AppTextTokens.deviceShareHint(Theme.of(context).textTheme),
        ),
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
      ),
    );
  }
}

class _ShareFieldShell extends StatelessWidget {
  const _ShareFieldShell({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.deviceShareFieldBorder),
      ),
      child: child,
    );
  }
}

class _SharePeriodSummary extends StatelessWidget {
  const _SharePeriodSummary({required this.title, this.value, this.onTap});

  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEnabled = onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.deviceShareFieldDisabled,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.deviceShareFieldBorder),
          boxShadow: const [
            BoxShadow(
              color: AppColors.deviceShareFieldShadow,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              color: AppColors.textIcon,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextTokens.deviceShareField(textTheme),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: AppTextTokens.deviceShareSummaryValue(textTheme),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isEnabled
                  ? AppColors.brandPrimary
                  : AppColors.borderHomePlaceholder,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendEmailToggle extends StatelessWidget {
  const _SendEmailToggle({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextTokens.deviceShareSectionTitle(
              Theme.of(context).textTheme,
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value
                  ? AppColors.deviceShareCheckbox
                  : AppColors.backgroundPrimary,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: value
                    ? AppColors.deviceShareCheckbox
                    : AppColors.deviceShareFieldBorder,
                width: 2,
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                : null,
          ),
        ),
      ],
    );
  }
}

class _CapabilitiesPanel extends StatelessWidget {
  const _CapabilitiesPanel({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: items.length == 1 ? 50 : 140,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.deviceShareFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items) ...[
            Text(
              item,
              style: AppTextTokens.deviceShareField(
                Theme.of(context).textTheme,
              ),
            ),
            if (item != items.last) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _ShareOption<T> {
  const _ShareOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _ShareOptionDialog<T> extends StatelessWidget {
  const _ShareOptionDialog({required this.options});

  final List<_ShareOption<T>> options;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 58),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < options.length; index++) ...[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          Navigator.of(context).pop(options[index].value),
                      child: SizedBox(
                        height: 42,
                        child: Center(
                          child: Text(
                            options[index].label,
                            style: AppTextTokens.deviceShareDialogOption(
                              textTheme,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (index != options.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 18,
                        endIndent: 18,
                        color: AppColors.deviceShareFieldBorder,
                      ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const Positioned(
              right: 18,
              top: 12,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.brandPrimary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomizeTimeDialog extends StatefulWidget {
  const _CustomizeTimeDialog({required this.initialDateTime});

  final DateTime initialDateTime;

  @override
  State<_CustomizeTimeDialog> createState() => _CustomizeTimeDialogState();
}

class _CustomizeTimeDialogState extends State<_CustomizeTimeDialog> {
  late DateTime _visibleMonth;
  late DateTime _today;
  late DateTime _selectedDate;
  late int _selectedHour;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initial = widget.initialDateTime;
    _today = DateTime(now.year, now.month, now.day);
    _selectedDate = _today.add(const Duration(days: 1));
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _selectedHour = initial.hour;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 344),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.textIcon,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.deviceShareTimeLabel,
                    style: AppTextTokens.deviceShareSectionTitle(textTheme),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.brandPrimary,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _TimeTextBox(
                    value: _selectedHour.toString().padLeft(2, '0'),
                    onTap: _selectHour,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    ':',
                    style: AppTextTokens.deviceShareTimeSeparator(textTheme),
                  ),
                ),
                SizedBox(width: 64, child: _TimeTextBox(value: '00')),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_visibleMonth),
                      style: AppTextTokens.deviceShareCalendarTitle(textTheme),
                    ),
                  ),
                ),
                _CalendarNavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: _previousMonth,
                ),
                const SizedBox(width: 22),
                _CalendarNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _WeekdayHeader(),
            const SizedBox(height: 16),
            _CalendarGrid(
              visibleMonth: _visibleMonth,
              today: _today,
              selectedDate: _selectedDate,
              onSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: _ShareActionButton(
                    label: l10n.deviceShareCancelAction,
                    foregroundColor: AppColors.textMuted,
                    backgroundColor: AppColors.deviceShareCancelButton,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _ShareActionButton(
                    label: l10n.deviceShareConfirmAction,
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.brandPrimary,
                    onPressed: _confirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  Future<void> _selectHour() async {
    final selected = await showDialog<int>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => _HourPickerDialog(selectedHour: _selectedHour),
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _selectedHour = selected;
    });
  }

  void _confirm() {
    Navigator.of(context).pop(
      DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedHour,
      ),
    );
  }
}

class _TimeTextBox extends StatelessWidget {
  const _TimeTextBox({required this.value, this.onTap});

  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.backgroundPrimary,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.brandPrimaryLight),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                value,
                style: AppTextTokens.deviceShareField(
                  Theme.of(context).textTheme,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HourPickerDialog extends StatefulWidget {
  const _HourPickerDialog({required this.selectedHour});

  final int selectedHour;

  @override
  State<_HourPickerDialog> createState() => _HourPickerDialogState();
}

class _HourPickerDialogState extends State<_HourPickerDialog> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: math.max(0, widget.selectedHour * 48.0 - 520),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final availableHeight = MediaQuery.sizeOf(context).height - 80;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 38),
        child: Material(
          color: AppColors.backgroundPrimary,
          elevation: 4,
          child: SizedBox(
            width: 234,
            height: math.min(748, availableHeight),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                itemCount: 24,
                itemBuilder: (context, index) {
                  final isSelected = index == widget.selectedHour;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(index),
                    child: Container(
                      height: 48,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: isSelected
                          ? AppColors.deviceShareHourSelected
                          : AppColors.backgroundPrimary,
                      child: Text(
                        index.toString().padLeft(2, '0'),
                        style: AppTextTokens.deviceShareHourOption(textTheme),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Icon(icon, color: AppColors.textIcon, size: 24),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: AppTextTokens.deviceShareCalendarWeekday(textTheme),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.visibleMonth,
    required this.today,
    required this.selectedDate,
    required this.onSelected,
  });

  final DateTime visibleMonth;
  final DateTime today;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final days = _buildDays();

    return Column(
      children: [
        for (var row = 0; row < 6; row++) ...[
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: _CalendarDayCell(
                    day: days[row * 7 + column],
                    today: today,
                    selectedDate: selectedDate,
                    textTheme: textTheme,
                    onSelected: onSelected,
                  ),
                ),
            ],
          ),
          if (row != 5) const SizedBox(height: 9),
        ],
      ],
    );
  }

  List<DateTime?> _buildDays() {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final dayCount = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final days = <DateTime?>[
      for (var index = 0; index < firstDay.weekday % 7; index++) null,
      for (var day = 1; day <= dayCount; day++)
        DateTime(visibleMonth.year, visibleMonth.month, day),
    ];
    while (days.length < 42) {
      days.add(null);
    }
    return days;
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.today,
    required this.selectedDate,
    required this.textTheme,
    required this.onSelected,
  });

  final DateTime? day;
  final DateTime today;
  final DateTime selectedDate;
  final TextTheme textTheme;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final value = day;
    if (value == null) {
      return const SizedBox(height: 32);
    }

    final isSelected =
        value.year == selectedDate.year &&
        value.month == selectedDate.month &&
        value.day == selectedDate.day;
    final isToday =
        value.year == today.year &&
        value.month == today.month &&
        value.day == today.day;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isToday ? null : () => onSelected(value),
      child: SizedBox(
        height: 32,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.brandPrimary : Colors.transparent,
              shape: BoxShape.circle,
              border: isSelected
                  ? null
                  : Border.all(
                      color: isToday
                          ? AppColors.brandPrimary
                          : Colors.transparent,
                      width: 1,
                    ),
            ),
            child: Text(
              '${value.day}',
              style: AppTextTokens.deviceShareCalendarDay(
                textTheme,
                isSelected: isSelected,
                isToday: isToday,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareActionButton extends StatelessWidget {
  const _ShareActionButton({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextTokens.deviceShareButton(
                Theme.of(context).textTheme,
              ).copyWith(color: foregroundColor),
            ),
          ),
        ),
      ),
    );
  }
}
