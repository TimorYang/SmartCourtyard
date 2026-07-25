import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/upgrade_check.dart';

final checkUpgradedVersionControllerProvider =
    NotifierProvider<CheckUpgradedVersionController, CheckUpgradedVersionState>(
      CheckUpgradedVersionController.new,
    );

class CheckUpgradedVersionController
    extends Notifier<CheckUpgradedVersionState> {
  Timer? _progressTimer;

  @override
  CheckUpgradedVersionState build() {
    ref.onDispose(() => _progressTimer?.cancel());
    return CheckUpgradedVersionState.mock();
  }

  void toggleApplication() {
    state = state.copyWith(
      application: state.application.copyWith(
        isSelected: !state.application.isSelected,
      ),
    );
  }

  void toggleDevice(String deviceId) {
    state = state.copyWith(
      devices: state.devices
          .map((device) {
            if (device.id != deviceId) return device;
            final shouldSelect = !device.isFullySelected;
            return device.copyWith(
              packages: device.packages
                  .map((item) => item.copyWith(isSelected: shouldSelect))
                  .toList(growable: false),
            );
          })
          .toList(growable: false),
    );
  }

  void togglePackage(String deviceId, String packageId) {
    state = state.copyWith(
      devices: state.devices
          .map((device) {
            if (device.id != deviceId) return device;
            return device.copyWith(
              packages: device.packages
                  .map((item) {
                    return item.id == packageId
                        ? item.copyWith(isSelected: !item.isSelected)
                        : item;
                  })
                  .toList(growable: false),
            );
          })
          .toList(growable: false),
    );
  }

  void toggleExpanded(String deviceId) {
    state = state.copyWith(
      devices: state.devices
          .map(
            (device) => device.id == deviceId
                ? device.copyWith(isExpanded: !device.isExpanded)
                : device,
          )
          .toList(growable: false),
    );
  }

  void startUpgrade(UpgradeSchedule schedule) {
    if (!state.hasSelection) return;
    final devices = state.devices
        .map((device) {
          return device.hasSelection
              ? device.copyWith(
                  status: UpgradeExecutionStatus.upgrading,
                  progress: 0,
                )
              : device;
        })
        .toList(growable: false);
    state = state.copyWith(
      devices: devices,
      applicationStatus: state.application.isSelected
          ? UpgradeExecutionStatus.upgrading
          : UpgradeExecutionStatus.idle,
      applicationProgress: 0,
      schedule: schedule,
      isShowingProgress: true,
    );
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      _advanceProgress();
    });
  }

  void _advanceProgress() {
    final nextApplicationProgress =
        state.applicationStatus == UpgradeExecutionStatus.upgrading
        ? (state.applicationProgress + 10).clamp(0, 100)
        : state.applicationProgress;
    final nextDevices = state.devices
        .map((device) {
          if (device.status != UpgradeExecutionStatus.upgrading) return device;
          final progress = (device.progress + 10).clamp(0, 100);
          return device.copyWith(
            progress: progress,
            status: progress == 100
                ? UpgradeExecutionStatus.completed
                : UpgradeExecutionStatus.upgrading,
          );
        })
        .toList(growable: false);
    state = state.copyWith(
      devices: nextDevices,
      applicationProgress: nextApplicationProgress,
      applicationStatus: nextApplicationProgress == 100
          ? UpgradeExecutionStatus.completed
          : state.applicationStatus,
    );
    if (state.isComplete) _progressTimer?.cancel();
  }
}

class CheckUpgradedVersionState {
  const CheckUpgradedVersionState({
    required this.application,
    required this.devices,
    required this.targets,
    this.applicationStatus = UpgradeExecutionStatus.idle,
    this.applicationProgress = 0,
    this.schedule,
    this.isShowingProgress = false,
  });

  final UpgradePackage application;
  final List<UpgradeableDevice> devices;
  final List<UpgradeTargetStatus> targets;
  final UpgradeExecutionStatus applicationStatus;
  final int applicationProgress;
  final UpgradeSchedule? schedule;
  final bool isShowingProgress;

  bool get hasSelection =>
      application.isSelected || devices.any((device) => device.hasSelection);
  bool get isComplete =>
      applicationStatus != UpgradeExecutionStatus.upgrading &&
      devices.every(
        (device) => device.status != UpgradeExecutionStatus.upgrading,
      );

  CheckUpgradedVersionState copyWith({
    UpgradePackage? application,
    List<UpgradeableDevice>? devices,
    UpgradeExecutionStatus? applicationStatus,
    int? applicationProgress,
    UpgradeSchedule? schedule,
    bool? isShowingProgress,
  }) => CheckUpgradedVersionState(
    application: application ?? this.application,
    devices: devices ?? this.devices,
    targets: targets,
    applicationStatus: applicationStatus ?? this.applicationStatus,
    applicationProgress: applicationProgress ?? this.applicationProgress,
    schedule: schedule ?? this.schedule,
    isShowingProgress: isShowingProgress ?? this.isShowingProgress,
  );

  factory CheckUpgradedVersionState.mock() => CheckUpgradedVersionState(
    application: UpgradePackage.mockApp(),
    devices: [
      UpgradeableDevice.mock(id: 'gdo-1', name: 'Opener · Garage Door Machine'),
      UpgradeableDevice.mock(id: 'rdo-1', name: 'New roll door machine RDO'),
      UpgradeableDevice.mock(id: 'gdo-2', name: 'Opener · Garage Door Machine'),
    ],
    targets: const [
      UpgradeTargetStatus(
        name: 'South Gate Access Control',
        availability: UpgradeTargetAvailability.offline,
      ),
      UpgradeTargetStatus(
        name: 'South Gate Access Control',
        availability: UpgradeTargetAvailability.online,
      ),
      UpgradeTargetStatus(
        name: 'North Gate Access Control',
        availability: UpgradeTargetAvailability.offline,
      ),
      UpgradeTargetStatus(
        name: 'Parking Entrance',
        availability: UpgradeTargetAvailability.online,
      ),
    ],
  );
}
