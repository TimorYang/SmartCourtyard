enum AppReleaseAction { none, optional, force }

enum FirmwareUpgradeStatus { available, scheduled, upgrading }

enum UpgradeScheduleMode { immediate, postpone }

class AppReleaseUpdate {
  const AppReleaseUpdate({
    required this.action,
    required this.targetVersion,
    required this.targetBuildNumber,
    required this.publishedAt,
    required this.updateUrl,
  });

  final AppReleaseAction action;
  final String? targetVersion;
  final String? targetBuildNumber;
  final DateTime? publishedAt;
  final Uri? updateUrl;

  bool get hasUpdate => action != AppReleaseAction.none;
}

class FirmwareUpgradeDoor {
  const FirmwareUpgradeDoor({
    required this.doorId,
    required this.doorName,
    required this.upgrades,
  });

  final String doorId;
  final String doorName;
  final List<FirmwareUpgradeTarget> upgrades;

  FirmwareUpgradeDoor copyWith({List<FirmwareUpgradeTarget>? upgrades}) {
    return FirmwareUpgradeDoor(
      doorId: doorId,
      doorName: doorName,
      upgrades: upgrades ?? this.upgrades,
    );
  }
}

class FirmwareUpgradeTarget {
  const FirmwareUpgradeTarget({
    required this.deviceId,
    required this.firmwareReleaseId,
    required this.serialNumber,
    required this.currentVersion,
    required this.deviceType,
    required this.deviceTypeLabel,
    required this.packageSizeBytes,
    required this.availableVersion,
    required this.lastFirmwareUpgradedAt,
    required this.status,
    required this.scheduledAt,
    required this.upgradeExpireAt,
  });

  final String deviceId;
  final String firmwareReleaseId;
  final String serialNumber;
  final String? currentVersion;
  final String deviceType;
  final String deviceTypeLabel;
  final int packageSizeBytes;
  final String availableVersion;
  final DateTime? lastFirmwareUpgradedAt;
  final FirmwareUpgradeStatus status;
  final DateTime? scheduledAt;
  final DateTime? upgradeExpireAt;

  String get key => '$deviceId:$firmwareReleaseId';

  bool get isSelectable =>
      status == FirmwareUpgradeStatus.available ||
      status == FirmwareUpgradeStatus.scheduled;

  FirmwareUpgradeTarget copyWith({
    FirmwareUpgradeStatus? status,
    Object? scheduledAt = _unset,
    Object? upgradeExpireAt = _unset,
  }) {
    return FirmwareUpgradeTarget(
      deviceId: deviceId,
      firmwareReleaseId: firmwareReleaseId,
      serialNumber: serialNumber,
      currentVersion: currentVersion,
      deviceType: deviceType,
      deviceTypeLabel: deviceTypeLabel,
      packageSizeBytes: packageSizeBytes,
      availableVersion: availableVersion,
      lastFirmwareUpgradedAt: lastFirmwareUpgradedAt,
      status: status ?? this.status,
      scheduledAt: identical(scheduledAt, _unset)
          ? this.scheduledAt
          : scheduledAt as DateTime?,
      upgradeExpireAt: identical(upgradeExpireAt, _unset)
          ? this.upgradeExpireAt
          : upgradeExpireAt as DateTime?,
    );
  }
}

class FirmwareUpgradeSubmissionResult {
  const FirmwareUpgradeSubmissionResult({
    required this.deviceId,
    required this.firmwareReleaseId,
    required this.accepted,
    required this.scheduledAt,
    required this.upgradeExpireAt,
    required this.failureMessage,
  });

  final String deviceId;
  final String firmwareReleaseId;
  final bool accepted;
  final DateTime? scheduledAt;
  final DateTime? upgradeExpireAt;
  final String? failureMessage;

  String get key => '$deviceId:$firmwareReleaseId';
}

class UpgradeSchedule {
  const UpgradeSchedule({required this.mode, this.scheduledAt});

  final UpgradeScheduleMode mode;
  final DateTime? scheduledAt;

  DateTime? get normalizedScheduledAt {
    final value = scheduledAt;
    if (mode == UpgradeScheduleMode.immediate || value == null) {
      return null;
    }
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    );
  }
}

const Object _unset = Object();
