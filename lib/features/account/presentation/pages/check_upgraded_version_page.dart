import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/check_upgraded_version_controller.dart';
import '../../domain/entities/upgrade_check.dart';

class CheckUpgradedVersionKeys {
  const CheckUpgradedVersionKeys._();

  static const applicationCheckbox = ValueKey(
    'upgrade-check-application-checkbox',
  );
  static const startButton = ValueKey('upgrade-check-start-button');
  static const scheduleDialog = ValueKey('upgrade-check-schedule-dialog');
  static const scheduleImmediate = ValueKey('upgrade-check-schedule-immediate');
  static const schedulePostpone = ValueKey('upgrade-check-schedule-postpone');
  static const scheduleConfirm = ValueKey('upgrade-check-schedule-confirm');
  static const scheduleCancel = ValueKey('upgrade-check-schedule-cancel');
  static ValueKey<String> deviceCheckbox(String id) =>
      ValueKey('upgrade-check-device-checkbox-$id');
  static ValueKey<String> deviceExpansion(String id) =>
      ValueKey('upgrade-check-device-expansion-$id');
  static ValueKey<String> packageCheckbox(String deviceId, String packageId) =>
      ValueKey('upgrade-check-package-checkbox-$deviceId-$packageId');
  static ValueKey<String> progressCard(String id) =>
      ValueKey('upgrade-check-progress-card-$id');
}

class CheckUpgradedVersionPage extends ConsumerWidget {
  const CheckUpgradedVersionPage({super.key});

  static const routeName = 'check-upgraded-version';
  static const routePath = '/account/check-upgraded-version';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkUpgradedVersionControllerProvider);
    final controller = ref.read(
      checkUpgradedVersionControllerProvider.notifier,
    );
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.upgradeCheckBackground,
      appBar: FlinxNavigationBar(
        title: l10n.upgradeCheckTitle,
        showBottomDivider: false,
      ),
      body: SafeArea(
        top: false,
        child: state.isShowingProgress
            ? _UpgradeProgressList(state: state)
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacingTokens.upgradeCheckPageHorizontal,
                  AppSpacingTokens.upgradeCheckSectionTop,
                  AppSpacingTokens.upgradeCheckPageHorizontal,
                  108,
                ),
                children: [
                  Text(
                    l10n.upgradeCheckAppSection,
                    style: AppTextTokens.upgradeCheckSectionTitle(
                      Theme.of(context).textTheme,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ApplicationCard(
                    item: state.application,
                    onChanged: controller.toggleApplication,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.upgradeCheckFirmwareSection,
                    style: AppTextTokens.upgradeCheckSectionTitle(
                      Theme.of(context).textTheme,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final device in state.devices) ...[
                    _DeviceCard(
                      device: device,
                      onDeviceSelected: () =>
                          controller.toggleDevice(device.id),
                      onExpanded: () => controller.toggleExpanded(device.id),
                      onPackageSelected: (packageId) =>
                          controller.togglePackage(device.id, packageId),
                    ),
                    const SizedBox(
                      height: AppSpacingTokens.upgradeCheckCardGap,
                    ),
                  ],
                ],
              ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          child: SizedBox(
            height: AppSpacingTokens.upgradeCheckActionHeight,
            child: FilledButton(
              key: CheckUpgradedVersionKeys.startButton,
              onPressed: state.hasSelection && !state.isShowingProgress
                  ? () =>
                        _showScheduleDialog(context, state.targets, controller)
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
                  fontSize: 19,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showScheduleDialog(
    BuildContext context,
    List<UpgradeTargetStatus> targets,
    CheckUpgradedVersionController controller,
  ) async {
    final schedule = await showDialog<UpgradeSchedule>(
      context: context,
      barrierColor: AppColors.upgradeCheckDialogScrim,
      builder: (context) => _UpgradeScheduleDialog(targets: targets),
    );
    if (schedule != null) controller.startUpgrade(schedule);
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.item, required this.onChanged});

  final UpgradePackage item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _UpdateCard(
      child: Row(
        children: [
          _SelectionBox(
            key: CheckUpgradedVersionKeys.applicationCheckbox,
            selected: item.isSelected,
            onTap: onChanged,
            label: item.name,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextTokens.upgradeCheckCardTitle(
                    Theme.of(context).textTheme,
                  ),
                ),
                const SizedBox(height: 12),
                _PackageMeta(item: item),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.onDeviceSelected,
    required this.onExpanded,
    required this.onPackageSelected,
  });

  final UpgradeableDevice device;
  final VoidCallback onDeviceSelected;
  final VoidCallback onExpanded;
  final ValueChanged<String> onPackageSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _UpdateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SelectionBox(
                key: CheckUpgradedVersionKeys.deviceCheckbox(device.id),
                selected: device.isFullySelected,
                mixed: device.hasSelection && !device.isFullySelected,
                onTap: onDeviceSelected,
                label: device.name,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  device.name,
                  style: AppTextTokens.upgradeCheckCardTitle(
                    Theme.of(context).textTheme,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: device.isExpanded
                    ? 'collapse ${device.name}'
                    : 'expand ${device.name}',
                child: GestureDetector(
                  key: CheckUpgradedVersionKeys.deviceExpansion(device.id),
                  onTap: onExpanded,
                  child: Icon(
                    device.isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          if (device.isExpanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: AppColors.upgradeCheckDivider),
            ),
            Text(
              l10n.upgradeCheckDoorDeviceName(device.doorDeviceName),
              style: AppTextTokens.upgradeCheckBody(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.upgradeCheckSerialNumber(device.serialNumber),
              style: AppTextTokens.upgradeCheckBody(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.upgradeCheckCurrentVersion(device.currentVersion),
              style: AppTextTokens.upgradeCheckBody(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: 20),
            for (var index = 0; index < device.packages.length; index++) ...[
              _PackageRow(
                deviceId: device.id,
                item: device.packages[index],
                onChanged: () => onPackageSelected(device.packages[index].id),
              ),
              if (index != device.packages.length - 1)
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

class _PackageRow extends StatelessWidget {
  const _PackageRow({
    required this.deviceId,
    required this.item,
    required this.onChanged,
  });

  final String deviceId;
  final UpgradePackage item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SelectionBox(
              key: CheckUpgradedVersionKeys.packageCheckbox(deviceId, item.id),
              selected: item.isSelected,
              onTap: onChanged,
              label: item.name,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.name,
                style: AppTextTokens.upgradeCheckCardTitle(
                  Theme.of(context).textTheme,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 42),
          child: _PackageMeta(item: item),
        ),
      ],
    );
  }
}

class _PackageMeta extends StatelessWidget {
  const _PackageMeta({required this.item});
  final UpgradePackage item;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 22,
    children: [
      Text(
        item.version,
        style: AppTextTokens.upgradeCheckMeta(Theme.of(context).textTheme),
      ),
      Text(
        item.sizeLabel,
        style: AppTextTokens.upgradeCheckMeta(Theme.of(context).textTheme),
      ),
      Text(
        item.releaseDateLabel,
        style: AppTextTokens.upgradeCheckMeta(Theme.of(context).textTheme),
      ),
    ],
  );
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.upgradeCheckCard,
      borderRadius: BorderRadius.all(
        Radius.circular(AppShapeTokens.upgradeCheckCardRadius),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacingTokens.upgradeCheckCardPadding),
      child: child,
    ),
  );
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
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: selected,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
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
            ? const Icon(Icons.remove_rounded, size: 20, color: Colors.white)
            : null,
      ),
    ),
  );
}

class _UpgradeScheduleDialog extends StatefulWidget {
  const _UpgradeScheduleDialog({required this.targets});
  final List<UpgradeTargetStatus> targets;

  @override
  State<_UpgradeScheduleDialog> createState() => _UpgradeScheduleDialogState();
}

class _UpgradeScheduleDialogState extends State<_UpgradeScheduleDialog> {
  late DateTime _scheduledAt;
  var _mode = UpgradeScheduleMode.postpone;

  @override
  void initState() {
    super.initState();
    _scheduledAt = DateTime.now().add(const Duration(minutes: 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isScheduledTimeValid =
        _mode == UpgradeScheduleMode.immediate ||
        !_scheduledAt.isBefore(DateTime.now());
    return Dialog(
      key: CheckUpgradedVersionKeys.scheduleDialog,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.upgradeCheckDialogInset,
      ),
      backgroundColor: AppColors.upgradeCheckDialogSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(AppShapeTokens.upgradeCheckDialogRadius),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          AppSpacingTokens.upgradeCheckDialogPadding,
        ),
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'West Gate Access Control',
                      style: AppTextTokens.upgradeCheckCardTitle(
                        Theme.of(context).textTheme,
                      ),
                    ),
                  ),
                  Text(
                    l10n.upgradeCheckStatus,
                    style: AppTextTokens.upgradeCheckCardTitle(
                      Theme.of(context).textTheme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (final target in widget.targets) _StatusRow(target: target),
              const SizedBox(height: 10),
              _ScheduleModeRow(
                mode: _mode,
                onChanged: (mode) => setState(() => _mode = mode),
              ),
              if (_mode == UpgradeScheduleMode.postpone) ...[
                const SizedBox(height: 14),
                _DateTimeSelector(
                  value: _scheduledAt,
                  onChanged: (value) => setState(() => _scheduledAt = value),
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      key: CheckUpgradedVersionKeys.scheduleCancel,
                      label: l10n.upgradeCheckCancelAction,
                      primary: false,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _DialogButton(
                      key: CheckUpgradedVersionKeys.scheduleConfirm,
                      label: l10n.upgradeCheckConfirmAction,
                      primary: true,
                      onPressed: isScheduledTimeValid
                          ? () => Navigator.pop(
                              context,
                              UpgradeSchedule(
                                mode: _mode,
                                scheduledAt:
                                    _mode == UpgradeScheduleMode.postpone
                                    ? _scheduledAt
                                    : null,
                              ),
                            )
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
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.target});
  final UpgradeTargetStatus target;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isOnline = target.availability == UpgradeTargetAvailability.online;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              target.name,
              style: AppTextTokens.upgradeCheckBody(
                Theme.of(context).textTheme,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: isOnline
                  ? AppColors.upgradeCheckOnlineSurface
                  : AppColors.upgradeCheckOfflineSurface,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Text(
                isOnline ? l10n.upgradeCheckOnline : l10n.upgradeCheckOffline,
                style: AppTextTokens.upgradeCheckStatus(
                  Theme.of(context).textTheme,
                  online: isOnline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleModeRow extends StatelessWidget {
  const _ScheduleModeRow({required this.mode, required this.onChanged});
  final UpgradeScheduleMode mode;
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
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _DateTimeSelector extends StatelessWidget {
  const _DateTimeSelector({required this.value, required this.onChanged});
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formatted =
        '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
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
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date == null || !context.mounted) {
                return;
              }
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(value),
              );
              if (time != null) {
                onChanged(
                  DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  ),
                );
              }
            },
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: Text(formatted),
          ),
        ),
      ],
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.primary,
    required this.onPressed,
    super.key,
  });
  final String label;
  final bool primary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSpacingTokens.upgradeCheckDialogActionHeight,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: primary
            ? AppColors.upgradeCheckCheckboxSelected
            : AppColors.accountLanguageDialogCancelSurface,
        foregroundColor: primary ? Colors.white : AppColors.textPrimary,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
      ),
    ),
  );
}

class _UpgradeProgressList extends StatelessWidget {
  const _UpgradeProgressList({required this.state});
  final CheckUpgradedVersionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = state.devices
        .where((device) => device.hasSelection)
        .toList(growable: false);
    return ListView(
      padding: const EdgeInsets.all(
        AppSpacingTokens.upgradeCheckPageHorizontal,
      ),
      children: [
        Text(
          l10n.upgradeCheckFirmwareSection,
          style: AppTextTokens.upgradeCheckSectionTitle(
            Theme.of(context).textTheme,
          ),
        ),
        const SizedBox(height: 14),
        if (state.application.isSelected) ...[
          _ProgressCard(
            id: 'application',
            title: state.application.name,
            progress: state.applicationProgress,
            status: state.applicationStatus,
          ),
          const SizedBox(height: AppSpacingTokens.upgradeCheckCardGap),
        ],
        for (final device in selected) ...[
          _ProgressCard(
            id: device.id,
            title: device.name,
            progress: device.progress,
            status: device.status,
          ),
          const SizedBox(height: AppSpacingTokens.upgradeCheckCardGap),
        ],
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.id,
    required this.title,
    required this.progress,
    required this.status,
  });
  final String id;
  final String title;
  final int progress;
  final UpgradeExecutionStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isComplete = status == UpgradeExecutionStatus.completed;
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
                  isComplete
                      ? l10n.upgradeCheckCompleted
                      : l10n.upgradeCheckUpgrading,
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
