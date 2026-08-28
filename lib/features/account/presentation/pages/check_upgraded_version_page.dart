import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/check_upgraded_version_controller.dart';
import '../../domain/entities/upgrade_check.dart';

class CheckUpgradedVersionKeys {
  const CheckUpgradedVersionKeys._();

  static const applicationCard = ValueKey('upgrade-check-application-card');
  static const startButton = ValueKey('upgrade-check-start-button');
  static const scheduleDialog = ValueKey('upgrade-check-schedule-dialog');
  static const scheduleImmediate = ValueKey('upgrade-check-schedule-immediate');
  static const schedulePostpone = ValueKey('upgrade-check-schedule-postpone');
  static const scheduleConfirm = ValueKey('upgrade-check-schedule-confirm');
  static const scheduleCancel = ValueKey('upgrade-check-schedule-cancel');

  static ValueKey<String> deviceCheckbox(String id) {
    return ValueKey('upgrade-check-device-checkbox-$id');
  }

  static ValueKey<String> deviceExpansion(String id) {
    return ValueKey('upgrade-check-device-expansion-$id');
  }

  static ValueKey<String> packageCheckbox(String doorId, String targetKey) {
    return ValueKey('upgrade-check-package-checkbox-$doorId-$targetKey');
  }

  static ValueKey<String> progressCard(String id) {
    return ValueKey('upgrade-check-progress-card-$id');
  }
}

class CheckUpgradedVersionPage extends ConsumerWidget {
  const CheckUpgradedVersionPage({super.key});

  static const routeName = 'check-upgraded-version';
  static const routePath = '/account/check-upgraded-version';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(checkUpgradedVersionControllerProvider);
    final controller = ref.read(
      checkUpgradedVersionControllerProvider.notifier,
    );
    final l10n = AppLocalizations.of(context);
    final current = asyncState.value;

    return Scaffold(
      backgroundColor: AppColors.upgradeCheckBackground,
      appBar: FlinxNavigationBar(
        title: l10n.upgradeCheckTitle,
        showBottomDivider: false,
      ),
      body: SafeArea(
        top: false,
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const SizedBox.expand(),
          data: (state) => state.isShowingProgress
              ? _UpgradeProgressList(state: state)
              : _UpgradeContentList(
                  state: state,
                  onApplicationTap: () =>
                      _openApplicationUpdate(context, controller),
                  onDoorChanged: (doorId) => _handleSelectionResult(
                    context,
                    controller.toggleDoor(doorId),
                  ),
                  onDoorExpanded: controller.toggleExpanded,
                  onTargetChanged: (key) => _handleSelectionResult(
                    context,
                    controller.toggleTarget(key),
                  ),
                ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          child: SizedBox(
            height: 50,
            child: FilledButton(
              key: CheckUpgradedVersionKeys.startButton,
              onPressed:
                  current != null &&
                      current.hasFirmwareSelection &&
                      !current.isShowingProgress &&
                      !current.isSubmitting
                  ? () => _startUpgrade(context, current, controller)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.upgradeCheckCheckboxSelected,
                disabledBackgroundColor: AppColors.upgradeCheckDisabledAction,
                shape: const StadiumBorder(),
              ),
              child: Text(
                l10n.upgradeCheckStartAction,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSelectionResult(
    BuildContext context,
    UpgradeSelectionResult result,
  ) {
    if (result != UpgradeSelectionResult.limitReached) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).upgradeCheckSelectionLimit,
          ),
        ),
      );
  }

  Future<void> _openApplicationUpdate(
    BuildContext context,
    CheckUpgradedVersionController controller,
  ) async {
    final opened = await controller.openApplicationUpdate();
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).upgradeCheckOpenStoreFailed,
          ),
        ),
      );
  }

  Future<void> _startUpgrade(
    BuildContext context,
    CheckUpgradedVersionState state,
    CheckUpgradedVersionController controller,
  ) async {
    final targets = state.selectedFirmwareEntries;
    if (targets.isEmpty) {
      return;
    }
    final result = await showDialog<UpgradeSubmitUiResult>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.upgradeCheckDialogScrim,
      builder: (context) => _UpgradeScheduleDialog(
        targets: targets,
        onSubmit: controller.submitFirmwareUpgrades,
      ),
    );
    if (!context.mounted || result != UpgradeSubmitUiResult.partial) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).upgradeCheckPartialNotAccepted,
          ),
        ),
      );
  }
}

class _UpgradeContentList extends StatelessWidget {
  const _UpgradeContentList({
    required this.state,
    required this.onApplicationTap,
    required this.onDoorChanged,
    required this.onDoorExpanded,
    required this.onTargetChanged,
  });

  final CheckUpgradedVersionState state;
  final VoidCallback onApplicationTap;
  final ValueChanged<String> onDoorChanged;
  final ValueChanged<String> onDoorExpanded;
  final ValueChanged<String> onTargetChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (state.application == null && state.doors.isEmpty) {
      return const SizedBox.expand();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 108),
      children: [
        if (state.application case final application?) ...[
          Text(
            l10n.upgradeCheckAppSection,
            style: AppTextTokens.upgradeCheckSectionTitle(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: 12),
          _ApplicationCard(
            update: application,
            onTap: application.updateUrl == null ? null : onApplicationTap,
          ),
          if (state.doors.isNotEmpty) const SizedBox(height: 20),
        ],
        if (state.doors.isNotEmpty) ...[
          Text(
            l10n.upgradeCheckFirmwareSection,
            style: AppTextTokens.upgradeCheckSectionTitle(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: 12),
          for (final door in state.doors) ...[
            _DoorUpgradeCard(
              door: door,
              expanded: state.expandedDoorIds.contains(door.doorId),
              fullySelected: state.isDoorFullySelected(door),
              partiallySelected: state.isDoorPartiallySelected(door),
              selectedTargetKeys: state.selectedTargetKeys,
              submitting: state.isSubmitting,
              onDoorChanged: () => onDoorChanged(door.doorId),
              onExpanded: () => onDoorExpanded(door.doorId),
              onTargetChanged: onTargetChanged,
            ),
            const SizedBox(height: 18),
          ],
        ],
      ],
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.update, required this.onTap});

  final AppReleaseUpdate update;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final publishedAt = update.publishedAt;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: l10n.upgradeCheckAppUpdateName,
      child: GestureDetector(
        key: CheckUpgradedVersionKeys.applicationCard,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _UpdateCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.upgradeCheckAppUpdateName,
                      style: AppTextTokens.upgradeCheckCardTitle(
                        Theme.of(context).textTheme,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 22,
                      runSpacing: 6,
                      children: [
                        if (update.targetVersion case final version?)
                          Text(
                            version,
                            style: AppTextTokens.upgradeCheckMeta(
                              Theme.of(context).textTheme,
                            ),
                          ),
                        if (publishedAt != null)
                          Text(
                            DateFormat.yMMMd(
                              Localizations.localeOf(context).toLanguageTag(),
                            ).format(publishedAt.toLocal()),
                            style: AppTextTokens.upgradeCheckMeta(
                              Theme.of(context).textTheme,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: onTap == null
                    ? AppColors.upgradeCheckDisabledAction
                    : AppColors.textPrimary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoorUpgradeCard extends StatelessWidget {
  const _DoorUpgradeCard({
    required this.door,
    required this.expanded,
    required this.fullySelected,
    required this.partiallySelected,
    required this.selectedTargetKeys,
    required this.submitting,
    required this.onDoorChanged,
    required this.onExpanded,
    required this.onTargetChanged,
  });

  final FirmwareUpgradeDoor door;
  final bool expanded;
  final bool fullySelected;
  final bool partiallySelected;
  final Set<String> selectedTargetKeys;
  final bool submitting;
  final VoidCallback onDoorChanged;
  final VoidCallback onExpanded;
  final ValueChanged<String> onTargetChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasSelectable = door.upgrades.any((target) => target.isSelectable);
    return _UpdateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SelectionBox(
                key: CheckUpgradedVersionKeys.deviceCheckbox(door.doorId),
                selected: fullySelected,
                mixed: partiallySelected,
                onTap: hasSelectable && !submitting ? onDoorChanged : null,
                label: door.doorName,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  door.doorName,
                  style: AppTextTokens.upgradeCheckCardTitle(
                    Theme.of(context).textTheme,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: expanded
                    ? l10n.upgradeCheckCollapseDoor(door.doorName)
                    : l10n.upgradeCheckExpandDoor(door.doorName),
                child: GestureDetector(
                  key: CheckUpgradedVersionKeys.deviceExpansion(door.doorId),
                  onTap: submitting ? null : onExpanded,
                  child: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          if (expanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: AppColors.upgradeCheckDivider),
            ),
            for (var index = 0; index < door.upgrades.length; index++) ...[
              _FirmwareUpgradeRow(
                doorId: door.doorId,
                target: door.upgrades[index],
                selected: selectedTargetKeys.contains(door.upgrades[index].key),
                submitting: submitting,
                onChanged: () => onTargetChanged(door.upgrades[index].key),
              ),
              if (index != door.upgrades.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    height: 1,
                    color: AppColors.upgradeCheckDivider,
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _FirmwareUpgradeRow extends StatelessWidget {
  const _FirmwareUpgradeRow({
    required this.doorId,
    required this.target,
    required this.selected,
    required this.submitting,
    required this.onChanged,
  });

  final String doorId;
  final FirmwareUpgradeTarget target;
  final bool selected;
  final bool submitting;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SelectionBox(
              key: CheckUpgradedVersionKeys.packageCheckbox(doorId, target.key),
              selected: selected,
              onTap: target.isSelectable && !submitting ? onChanged : null,
              label: target.deviceTypeLabel,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                target.deviceTypeLabel,
                style: AppTextTokens.upgradeCheckCardTitle(
                  Theme.of(context).textTheme,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.upgradeCheckSerialNumber(target.serialNumber),
                style: AppTextTokens.upgradeCheckBody(
                  Theme.of(context).textTheme,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 18,
                runSpacing: 6,
                children: [
                  Text(
                    l10n.upgradeCheckCurrentVersion(
                      target.currentVersion ?? '--',
                    ),
                    style: AppTextTokens.upgradeCheckMeta(
                      Theme.of(context).textTheme,
                    ),
                  ),
                  Text(
                    l10n.upgradeCheckAvailableVersion(target.availableVersion),
                    style: AppTextTokens.upgradeCheckMeta(
                      Theme.of(context).textTheme,
                    ),
                  ),
                  Text(
                    _formatPackageSize(l10n, target.packageSizeBytes),
                    style: AppTextTokens.upgradeCheckMeta(
                      Theme.of(context).textTheme,
                    ),
                  ),
                ],
              ),
              if (target.status == FirmwareUpgradeStatus.scheduled &&
                  target.scheduledAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.upgradeCheckScheduledFor(
                    _formatScheduledAt(context, target.scheduledAt!),
                  ),
                  style: AppTextTokens.upgradeCheckBody(
                    Theme.of(context).textTheme,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.upgradeCheckCard,
        borderRadius: BorderRadius.all(
          Radius.circular(AppShapeTokens.upgradeCheckCardRadius),
        ),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SelectionBox extends StatelessWidget {
  const _SelectionBox({
    required this.selected,
    required this.onTap,
    required this.label,
    this.mixed = false,
    super.key,
  });

  final bool selected;
  final bool mixed;
  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      checked: selected,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: selected || mixed
                  ? AppColors.upgradeCheckCheckboxSelected
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: selected || mixed
                    ? AppColors.upgradeCheckCheckboxSelected
                    : AppColors.upgradeCheckCheckboxBorder,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                : mixed
                ? const Icon(
                    Icons.remove_rounded,
                    size: 20,
                    color: Colors.white,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _UpgradeScheduleDialog extends StatefulWidget {
  const _UpgradeScheduleDialog({required this.targets, required this.onSubmit});

  final List<FirmwareUpgradeEntry> targets;
  final Future<UpgradeSubmitUiResult> Function(UpgradeSchedule) onSubmit;

  @override
  State<_UpgradeScheduleDialog> createState() => _UpgradeScheduleDialogState();
}

class _UpgradeScheduleDialogState extends State<_UpgradeScheduleDialog> {
  late DateTime _scheduledAt;
  var _mode = UpgradeScheduleMode.postpone;
  var _isSubmitting = false;
  var _submitFailed = false;

  @override
  void initState() {
    super.initState();
    final nextMinute = DateTime.now().add(const Duration(minutes: 1));
    _scheduledAt = DateTime(
      nextMinute.year,
      nextMinute.month,
      nextMinute.day,
      nextMinute.hour,
      nextMinute.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isScheduledTimeValid =
        _mode == UpgradeScheduleMode.immediate ||
        _scheduledAt.isAfter(DateTime.now());
    return Dialog(
      key: CheckUpgradedVersionKeys.scheduleDialog,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      backgroundColor: AppColors.upgradeCheckDialogSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(AppShapeTokens.upgradeCheckDialogRadius),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.upgradeCheckSelectTimeTitle,
                      style: AppTextTokens.upgradeCheckDialogTitle(
                        Theme.of(context).textTheme,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              for (final entry in widget.targets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.doorName} · ${entry.target.deviceTypeLabel}',
                        style: AppTextTokens.upgradeCheckCardTitle(
                          Theme.of(context).textTheme,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.upgradeCheckSerialNumber(
                          entry.target.serialNumber,
                        ),
                        style: AppTextTokens.upgradeCheckMeta(
                          Theme.of(context).textTheme,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              _ScheduleModeRow(
                mode: _mode,
                enabled: !_isSubmitting,
                onChanged: (mode) => setState(() {
                  _mode = mode;
                  _submitFailed = false;
                }),
              ),
              if (_mode == UpgradeScheduleMode.postpone) ...[
                const SizedBox(height: 14),
                _DateTimeSelector(
                  value: _scheduledAt,
                  enabled: !_isSubmitting,
                  onChanged: (value) => setState(() {
                    _scheduledAt = value;
                    _submitFailed = false;
                  }),
                ),
                if (!isScheduledTimeValid) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.upgradeCheckSchedulePastError,
                    style: AppTextTokens.upgradeCheckStatus(
                      Theme.of(context).textTheme,
                      online: false,
                    ),
                  ),
                ],
              ],
              if (_submitFailed) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.upgradeCheckSubmitFailed,
                  style: AppTextTokens.upgradeCheckStatus(
                    Theme.of(context).textTheme,
                    online: false,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      key: CheckUpgradedVersionKeys.scheduleCancel,
                      label: l10n.upgradeCheckCancelAction,
                      primary: false,
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _DialogButton(
                      key: CheckUpgradedVersionKeys.scheduleConfirm,
                      label: _isSubmitting
                          ? l10n.upgradeCheckSubmitting
                          : l10n.upgradeCheckConfirmAction,
                      primary: true,
                      loading: _isSubmitting,
                      onPressed: isScheduledTimeValid && !_isSubmitting
                          ? _submit
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_mode == UpgradeScheduleMode.postpone &&
        !_scheduledAt.isAfter(DateTime.now())) {
      setState(() {
        _submitFailed = false;
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _submitFailed = false;
    });
    final result = await widget.onSubmit(
      UpgradeSchedule(
        mode: _mode,
        scheduledAt: _mode == UpgradeScheduleMode.postpone
            ? _scheduledAt
            : null,
      ),
    );
    if (!mounted) return;
    if (result == UpgradeSubmitUiResult.failed) {
      setState(() {
        _isSubmitting = false;
        _submitFailed = true;
      });
      return;
    }
    Navigator.pop(context, result);
  }
}

class _ScheduleModeRow extends StatelessWidget {
  const _ScheduleModeRow({
    required this.mode,
    required this.enabled,
    required this.onChanged,
  });

  final UpgradeScheduleMode mode;
  final bool enabled;
  final ValueChanged<UpgradeScheduleMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.upgradeCheckUpgradeTime,
            style: AppTextTokens.upgradeCheckBody(Theme.of(context).textTheme),
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<UpgradeScheduleMode>(
            initialValue: mode,
            isDense: true,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: UpgradeScheduleMode.immediate,
                child: Text(l10n.upgradeCheckImmediate),
              ),
              DropdownMenuItem(
                value: UpgradeScheduleMode.postpone,
                child: Text(l10n.upgradeCheckPostpone),
              ),
            ],
            onChanged: enabled
                ? (value) {
                    if (value != null) onChanged(value);
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

class _DateTimeSelector extends StatelessWidget {
  const _DateTimeSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final DateTime value;
  final bool enabled;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.upgradeCheckDateAndTime,
            style: AppTextTokens.upgradeCheckBody(Theme.of(context).textTheme),
          ),
        ),
        SizedBox(
          width: 228,
          child: OutlinedButton.icon(
            onPressed: enabled ? () => _select(context) : null,
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: Text(DateFormat('yyyy/MM/dd HH:mm').format(value)),
          ),
        ),
      ],
    );
  }

  Future<void> _select(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (time == null) return;
    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.primary,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;
  final bool primary;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primary
              ? AppColors.upgradeCheckCheckboxSelected
              : AppColors.accountLanguageDialogCancelSurface,
          foregroundColor: primary ? Colors.white : AppColors.textPrimary,
          shape: const StadiumBorder(),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontSize: 18),
              ),
      ),
    );
  }
}

class _UpgradeProgressList extends StatelessWidget {
  const _UpgradeProgressList({required this.state});

  final CheckUpgradedVersionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l10n.upgradeCheckFirmwareSection,
          style: AppTextTokens.upgradeCheckSectionTitle(
            Theme.of(context).textTheme,
          ),
        ),
        const SizedBox(height: 10),
        for (final entry in state.upgradingEntries) ...[
          _ProgressCard(
            id: entry.target.key,
            title: '${entry.doorName} · ${entry.target.deviceTypeLabel}',
            serialNumber: entry.target.serialNumber,
            progress: state.progressByTarget[entry.target.key] ?? 1,
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.id,
    required this.title,
    required this.serialNumber,
    required this.progress,
  });

  final String id;
  final String title;
  final String serialNumber;
  final int progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _UpdateCard(
      child: Semantics(
        key: CheckUpgradedVersionKeys.progressCard(id),
        label: title,
        value: l10n.upgradeCheckProgressPercent(progress),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextTokens.upgradeCheckCardTitle(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.upgradeCheckSerialNumber(serialNumber),
              style: AppTextTokens.upgradeCheckMeta(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 14,
                backgroundColor: AppColors.upgradeCheckProgressTrack,
                color: AppColors.upgradeCheckProgress,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  l10n.upgradeCheckUpgrading,
                  style: AppTextTokens.upgradeCheckBody(
                    Theme.of(context).textTheme,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.upgradeCheckProgressPercent(progress),
                  style: AppTextTokens.upgradeCheckBody(
                    Theme.of(context).textTheme,
                  ).copyWith(color: AppColors.upgradeCheckProgress),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatPackageSize(AppLocalizations l10n, int bytes) {
  if (bytes < 1024) return l10n.upgradeCheckSizeBytes(bytes.toString());
  if (bytes < 1024 * 1024) {
    return l10n.upgradeCheckSizeKilobytes(_compact(bytes / 1024));
  }
  return l10n.upgradeCheckSizeMegabytes(_compact(bytes / (1024 * 1024)));
}

String _compact(double value) {
  final fixed = value.toStringAsFixed(1);
  return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
}

String _formatScheduledAt(BuildContext context, DateTime value) {
  final locale = Localizations.localeOf(context);
  final pattern = locale.languageCode == 'zh'
      ? 'yyyy-MM-dd HH:mm'
      : 'MMM d, yyyy HH:mm';
  return DateFormat(pattern, locale.toLanguageTag()).format(value.toLocal());
}
