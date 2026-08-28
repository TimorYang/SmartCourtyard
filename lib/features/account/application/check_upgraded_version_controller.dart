import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/upgrade_check.dart';
import 'providers.dart';

final checkUpgradedVersionControllerProvider =
    AsyncNotifierProvider.autoDispose<
      CheckUpgradedVersionController,
      CheckUpgradedVersionState
    >(CheckUpgradedVersionController.new);

enum UpgradeSelectionResult { changed, limitReached, ignored }

enum UpgradeSubmitUiResult { success, partial, failed }

class CheckUpgradedVersionController
    extends AsyncNotifier<CheckUpgradedVersionState> {
  static const maxSelectionCount = 10;

  Timer? _progressTimer;
  var _userId = 'anonymous';

  @override
  Future<CheckUpgradedVersionState> build() async {
    ref.onDispose(() => _progressTimer?.cancel());

    final profile = await ref.watch(cachedAccountProfileProvider.future);
    _userId = profile?.userId.trim().isNotEmpty == true
        ? profile!.userId
        : 'anonymous';

    AppReleaseUpdate? application;
    var doors = const <FirmwareUpgradeDoor>[];
    var appLoadFailed = false;
    var firmwareLoadFailed = false;

    await Future.wait<void>([
      () async {
        try {
          application = await ref.read(checkAppReleaseUseCaseProvider)(
            requestId: _requestId('app-release-check'),
          );
        } on Object {
          appLoadFailed = true;
        }
      }(),
      () async {
        try {
          doors = await ref.read(fetchFirmwareUpgradesUseCaseProvider)(
            requestId: _requestId('firmware-upgrades'),
          );
        } on Object {
          firmwareLoadFailed = true;
        }
      }(),
    ]);

    var progressByTarget = const <String, int>{};
    if (!firmwareLoadFailed) {
      final stored = await ref.read(readUpgradeProgressesUseCaseProvider)(
        userId: _userId,
      );
      progressByTarget = {
        for (final target in _targetsWithStatus(
          doors,
          FirmwareUpgradeStatus.upgrading,
        ))
          target.key: (stored[target.key] ?? 1).clamp(1, 99),
      };
      await ref.read(replaceUpgradeProgressesUseCaseProvider)(
        userId: _userId,
        progresses: progressByTarget,
      );
    }

    final result = CheckUpgradedVersionState(
      application: application?.hasUpdate == true ? application : null,
      doors: doors,
      expandedDoorIds: doors.map((door) => door.doorId).toSet(),
      progressByTarget: progressByTarget,
      appLoadFailed: appLoadFailed,
      firmwareLoadFailed: firmwareLoadFailed,
    );
    if (result.isShowingProgress) {
      _startProgressTimer();
    }
    return result;
  }

  Future<bool> openApplicationUpdate() {
    final current = state.value;
    if (current == null || current.isShowingProgress) {
      return Future.value(false);
    }
    final updateUrl = current.application?.updateUrl;
    if (updateUrl == null) return Future.value(false);
    return ref.read(appUpdateUrlLauncherProvider).open(updateUrl);
  }

  UpgradeSelectionResult toggleDoor(String doorId) {
    final current = state.value;
    if (current == null || current.isSubmitting || current.isShowingProgress) {
      return UpgradeSelectionResult.ignored;
    }
    final door = current.doors
        .where((item) => item.doorId == doorId)
        .firstOrNull;
    if (door == null) return UpgradeSelectionResult.ignored;

    final candidates = <FirmwareUpgradeTarget>[];
    final seenDeviceIds = <String>{};
    for (final target in door.upgrades) {
      if (target.isSelectable && seenDeviceIds.add(target.deviceId)) {
        candidates.add(target);
      }
    }
    if (candidates.isEmpty) return UpgradeSelectionResult.ignored;

    final next = Set<String>.from(current.selectedTargetKeys);
    final allSelected = candidates.every((target) => next.contains(target.key));
    if (allSelected) {
      next.removeAll(candidates.map((target) => target.key));
    } else {
      for (final target in candidates) {
        next.removeWhere(
          (key) =>
              current.targetForKey(key)?.deviceId == target.deviceId &&
              key != target.key,
        );
        next.add(target.key);
      }
      if (next.length > maxSelectionCount) {
        return UpgradeSelectionResult.limitReached;
      }
    }

    state = AsyncData(current.copyWith(selectedTargetKeys: next));
    return UpgradeSelectionResult.changed;
  }

  UpgradeSelectionResult toggleTarget(String targetKey) {
    final current = state.value;
    if (current == null || current.isSubmitting || current.isShowingProgress) {
      return UpgradeSelectionResult.ignored;
    }
    final target = current.targetForKey(targetKey);
    if (target == null || !target.isSelectable) {
      return UpgradeSelectionResult.ignored;
    }
    final next = Set<String>.from(current.selectedTargetKeys);
    if (!next.remove(targetKey)) {
      next.removeWhere(
        (key) => current.targetForKey(key)?.deviceId == target.deviceId,
      );
      if (next.length >= maxSelectionCount) {
        return UpgradeSelectionResult.limitReached;
      }
      next.add(targetKey);
    }
    state = AsyncData(current.copyWith(selectedTargetKeys: next));
    return UpgradeSelectionResult.changed;
  }

  void toggleExpanded(String doorId) {
    final current = state.value;
    if (current == null || current.isSubmitting || current.isShowingProgress) {
      return;
    }
    final next = Set<String>.from(current.expandedDoorIds);
    if (!next.remove(doorId)) next.add(doorId);
    state = AsyncData(current.copyWith(expandedDoorIds: next));
  }

  Future<UpgradeSubmitUiResult> submitFirmwareUpgrades(
    UpgradeSchedule schedule,
  ) async {
    final current = state.value;
    if (current == null || current.isSubmitting) {
      return UpgradeSubmitUiResult.failed;
    }
    final selected = current.selectedFirmwareEntries
        .map((entry) => entry.target)
        .toList(growable: false);
    if (selected.isEmpty) {
      return UpgradeSubmitUiResult.failed;
    }

    state = AsyncData(current.copyWith(isSubmitting: true));
    try {
      final results = await ref.read(submitFirmwareUpgradesUseCaseProvider)(
        schedule: schedule,
        targets: selected,
        requestId: _requestId('firmware-upgrades-submit'),
      );
      if (!ref.mounted) return UpgradeSubmitUiResult.failed;

      final resultByKey = {for (final result in results) result.key: result};
      final acceptedKeys = <String>{};
      for (final target in selected) {
        if (resultByKey[target.key]?.accepted == true) {
          acceptedKeys.add(target.key);
        }
      }
      final rejectedKeys = selected
          .map((target) => target.key)
          .where((key) => !acceptedKeys.contains(key))
          .toSet();

      final nextDoors = current.doors
          .map(
            (door) => door.copyWith(
              upgrades: door.upgrades
                  .map((target) {
                    if (!acceptedKeys.contains(target.key)) return target;
                    final result = resultByKey[target.key]!;
                    if (schedule.mode == UpgradeScheduleMode.immediate) {
                      return target.copyWith(
                        status: FirmwareUpgradeStatus.upgrading,
                        scheduledAt: null,
                        upgradeExpireAt: result.upgradeExpireAt,
                      );
                    }
                    return target.copyWith(
                      status: FirmwareUpgradeStatus.scheduled,
                      scheduledAt:
                          result.scheduledAt ??
                          schedule.normalizedScheduledAt?.toUtc(),
                      upgradeExpireAt: null,
                    );
                  })
                  .toList(growable: false),
            ),
          )
          .toList(growable: false);

      final nextProgresses = Map<String, int>.from(current.progressByTarget);
      if (schedule.mode == UpgradeScheduleMode.immediate) {
        for (final key in acceptedKeys) {
          nextProgresses[key] = 1;
        }
      }
      final nextState = current.copyWith(
        doors: nextDoors,
        selectedTargetKeys: rejectedKeys,
        progressByTarget: nextProgresses,
        isSubmitting: false,
      );
      state = AsyncData(nextState);
      if (schedule.mode == UpgradeScheduleMode.immediate &&
          acceptedKeys.isNotEmpty) {
        await _persistActiveProgresses(nextState);
        _startProgressTimer();
      }
      return rejectedKeys.isEmpty
          ? UpgradeSubmitUiResult.success
          : UpgradeSubmitUiResult.partial;
    } on Object {
      if (ref.mounted) {
        state = AsyncData(current.copyWith(isSubmitting: false));
      }
      return UpgradeSubmitUiResult.failed;
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!ref.mounted) return;
      final current = state.value;
      if (current == null || !current.isShowingProgress) {
        _progressTimer?.cancel();
        return;
      }
      final nextProgresses = Map<String, int>.from(current.progressByTarget);
      var changed = false;
      for (final entry in current.upgradingEntries) {
        final progress = nextProgresses[entry.target.key] ?? 1;
        if (progress < 99) {
          nextProgresses[entry.target.key] = progress + 1;
          changed = true;
        }
      }
      if (!changed) {
        _progressTimer?.cancel();
        return;
      }
      final nextState = current.copyWith(progressByTarget: nextProgresses);
      state = AsyncData(nextState);
      unawaited(_persistActiveProgresses(nextState));
    });
  }

  Future<void> _persistActiveProgresses(CheckUpgradedVersionState current) {
    final active = {
      for (final entry in current.upgradingEntries)
        entry.target.key: (current.progressByTarget[entry.target.key] ?? 1)
            .clamp(1, 99),
    };
    return ref.read(replaceUpgradeProgressesUseCaseProvider)(
      userId: _userId,
      progresses: active,
    );
  }

  String _requestId(String operation) {
    return 'upgrade-check-$operation-${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }

  Iterable<FirmwareUpgradeTarget> _targetsWithStatus(
    List<FirmwareUpgradeDoor> doors,
    FirmwareUpgradeStatus status,
  ) sync* {
    for (final door in doors) {
      for (final target in door.upgrades) {
        if (target.status == status) yield target;
      }
    }
  }
}

class FirmwareUpgradeEntry {
  const FirmwareUpgradeEntry({
    required this.doorId,
    required this.doorName,
    required this.target,
  });

  final String doorId;
  final String doorName;
  final FirmwareUpgradeTarget target;
}

class CheckUpgradedVersionState {
  const CheckUpgradedVersionState({
    required this.application,
    required this.doors,
    this.selectedTargetKeys = const {},
    this.expandedDoorIds = const {},
    this.progressByTarget = const {},
    this.isSubmitting = false,
    this.appLoadFailed = false,
    this.firmwareLoadFailed = false,
  });

  final AppReleaseUpdate? application;
  final List<FirmwareUpgradeDoor> doors;
  final Set<String> selectedTargetKeys;
  final Set<String> expandedDoorIds;
  final Map<String, int> progressByTarget;
  final bool isSubmitting;
  final bool appLoadFailed;
  final bool firmwareLoadFailed;

  List<FirmwareUpgradeEntry> get entries => [
    for (final door in doors)
      for (final target in door.upgrades)
        FirmwareUpgradeEntry(
          doorId: door.doorId,
          doorName: door.doorName,
          target: target,
        ),
  ];

  List<FirmwareUpgradeEntry> get selectedFirmwareEntries => entries
      .where((entry) => selectedTargetKeys.contains(entry.target.key))
      .toList(growable: false);

  List<FirmwareUpgradeEntry> get upgradingEntries => entries
      .where((entry) => entry.target.status == FirmwareUpgradeStatus.upgrading)
      .toList(growable: false);

  bool get isShowingProgress => upgradingEntries.isNotEmpty;

  bool get hasFirmwareSelection => selectedTargetKeys.isNotEmpty;

  FirmwareUpgradeTarget? targetForKey(String key) {
    for (final entry in entries) {
      if (entry.target.key == key) return entry.target;
    }
    return null;
  }

  bool isDoorFullySelected(FirmwareUpgradeDoor door) {
    final selectable = door.upgrades.where((target) => target.isSelectable);
    return selectable.isNotEmpty &&
        selectable.every((target) => selectedTargetKeys.contains(target.key));
  }

  bool isDoorPartiallySelected(FirmwareUpgradeDoor door) {
    final selectable = door.upgrades.where((target) => target.isSelectable);
    final selectedCount = selectable
        .where((target) => selectedTargetKeys.contains(target.key))
        .length;
    return selectedCount > 0 && selectedCount < selectable.length;
  }

  CheckUpgradedVersionState copyWith({
    Object? application = _unset,
    List<FirmwareUpgradeDoor>? doors,
    Set<String>? selectedTargetKeys,
    Set<String>? expandedDoorIds,
    Map<String, int>? progressByTarget,
    bool? isSubmitting,
    bool? appLoadFailed,
    bool? firmwareLoadFailed,
  }) {
    return CheckUpgradedVersionState(
      application: identical(application, _unset)
          ? this.application
          : application as AppReleaseUpdate?,
      doors: doors ?? this.doors,
      selectedTargetKeys: selectedTargetKeys ?? this.selectedTargetKeys,
      expandedDoorIds: expandedDoorIds ?? this.expandedDoorIds,
      progressByTarget: progressByTarget ?? this.progressByTarget,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      appLoadFailed: appLoadFailed ?? this.appLoadFailed,
      firmwareLoadFailed: firmwareLoadFailed ?? this.firmwareLoadFailed,
    );
  }
}

const Object _unset = Object();

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
