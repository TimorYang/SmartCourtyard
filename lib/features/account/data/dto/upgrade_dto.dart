class AppReleaseCheckRequestDto {
  const AppReleaseCheckRequestDto({
    required this.platform,
    required this.buildNumber,
  });

  final String platform;
  final String buildNumber;

  factory AppReleaseCheckRequestDto.fromJson(Map<String, dynamic> json) {
    return AppReleaseCheckRequestDto(
      platform: _requiredString(json, 'platform'),
      buildNumber: _requiredNumericString(json, 'buildNumber'),
    );
  }

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'buildNumber': int.parse(buildNumber),
  };
}

class AppReleaseCheckResponseDto {
  const AppReleaseCheckResponseDto({
    required this.action,
    required this.targetVersion,
    required this.targetBuildNumber,
    required this.publishedAt,
    required this.updateUrl,
  });

  final String action;
  final String? targetVersion;
  final String? targetBuildNumber;
  final String? publishedAt;
  final String? updateUrl;

  factory AppReleaseCheckResponseDto.fromJson(Map<String, dynamic> json) {
    final action = _requiredString(json, 'action');
    if (!const {'NONE', 'OPTIONAL', 'FORCE'}.contains(action)) {
      throw const FormatException('Unknown app release action.');
    }
    final targetVersion = _nullableString(json['targetVersion']);
    if (action != 'NONE' && targetVersion == null) {
      throw const FormatException(
        'targetVersion is required when an app update is available.',
      );
    }
    return AppReleaseCheckResponseDto(
      action: action,
      targetVersion: targetVersion,
      targetBuildNumber: _nullableNumericString(json['targetBuildNumber']),
      publishedAt: _nullableTimestampString(json['publishedAt']),
      updateUrl: _nullableString(json['updateUrl']),
    );
  }

  Map<String, dynamic> toJson() => {
    'action': action,
    'targetVersion': targetVersion,
    'targetBuildNumber': targetBuildNumber == null
        ? null
        : int.parse(targetBuildNumber!),
    'publishedAt': publishedAt == null ? null : int.parse(publishedAt!),
    'updateUrl': updateUrl,
  };
}

class FirmwareUpgradeDoorDto {
  const FirmwareUpgradeDoorDto({
    required this.doorId,
    required this.doorName,
    required this.upgrades,
  });

  final String doorId;
  final String doorName;
  final List<FirmwareUpgradeTargetDto> upgrades;

  factory FirmwareUpgradeDoorDto.fromJson(Map<String, dynamic> json) {
    final upgradesJson = json['upgrades'];
    if (upgradesJson is! List) {
      throw const FormatException('Firmware upgrades must be a list.');
    }
    final upgrades = upgradesJson
        .map(
          (item) => FirmwareUpgradeTargetDto.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
    return FirmwareUpgradeDoorDto(
      doorId: _requiredNumericString(json, 'doorId'),
      doorName: _requiredString(json, 'doorName'),
      upgrades: upgrades,
    );
  }

  Map<String, dynamic> toJson() => {
    'doorId': int.parse(doorId),
    'doorName': doorName,
    'upgrades': upgrades.map((item) => item.toJson()).toList(growable: false),
  };
}

class FirmwareUpgradeTargetDto {
  const FirmwareUpgradeTargetDto({
    required this.deviceId,
    required this.firmwareReleaseId,
    required this.serialNumber,
    required this.currentVersion,
    required this.deviceType,
    required this.deviceTypeLabel,
    required this.packageSize,
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
  final String packageSize;
  final String availableVersion;
  final String? lastFirmwareUpgradedAt;
  final String status;
  final String? scheduledAt;
  final String? upgradeExpireAt;

  factory FirmwareUpgradeTargetDto.fromJson(Map<String, dynamic> json) {
    final status = _requiredString(json, 'status');
    if (!const {'AVAILABLE', 'SCHEDULED', 'UPGRADING'}.contains(status)) {
      throw const FormatException('Unknown firmware upgrade status.');
    }
    return FirmwareUpgradeTargetDto(
      deviceId: _requiredNumericString(json, 'deviceId'),
      firmwareReleaseId: _requiredNumericString(json, 'firmwareReleaseId'),
      serialNumber: _requiredString(json, 'sn'),
      currentVersion: _nullableString(json['currentVersion']),
      deviceType: _requiredString(json, 'deviceType'),
      deviceTypeLabel: _requiredString(json, 'deviceTypeLabel'),
      packageSize: _requiredNumericString(json, 'packageSize'),
      availableVersion: _requiredString(json, 'availableVersion'),
      lastFirmwareUpgradedAt: _nullableNumericString(
        json['lastFirmwareUpgradedAt'],
      ),
      status: status,
      scheduledAt: _nullableNumericString(json['scheduledAt']),
      upgradeExpireAt: _nullableString(json['upgradeExpireAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': int.parse(deviceId),
    'firmwareReleaseId': int.parse(firmwareReleaseId),
    'sn': serialNumber,
    'currentVersion': currentVersion,
    'deviceType': deviceType,
    'deviceTypeLabel': deviceTypeLabel,
    'packageSize': int.parse(packageSize),
    'availableVersion': availableVersion,
    'lastFirmwareUpgradedAt': lastFirmwareUpgradedAt == null
        ? null
        : int.parse(lastFirmwareUpgradedAt!),
    'status': status,
    'scheduledAt': scheduledAt == null ? null : int.parse(scheduledAt!),
    'upgradeExpireAt': upgradeExpireAt,
  };
}

class FirmwareUpgradeSubmitRequestDto {
  const FirmwareUpgradeSubmitRequestDto({
    required this.upgradeMode,
    required this.scheduledAt,
    required this.items,
  });

  final String upgradeMode;
  final String? scheduledAt;
  final List<FirmwareUpgradeSubmitItemDto> items;

  factory FirmwareUpgradeSubmitRequestDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Firmware submit items must be a list.');
    }
    return FirmwareUpgradeSubmitRequestDto(
      upgradeMode: _requiredString(json, 'upgradeMode'),
      scheduledAt: _nullableNumericString(json['scheduledAt']),
      items: rawItems
          .map(
            (item) => FirmwareUpgradeSubmitItemDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'upgradeMode': upgradeMode,
    if (scheduledAt != null) 'scheduledAt': int.parse(scheduledAt!),
    'items': items.map((item) => item.toJson()).toList(growable: false),
  };
}

class FirmwareUpgradeSubmitItemDto {
  const FirmwareUpgradeSubmitItemDto({
    required this.deviceId,
    required this.firmwareReleaseId,
  });

  final String deviceId;
  final String firmwareReleaseId;

  factory FirmwareUpgradeSubmitItemDto.fromJson(Map<String, dynamic> json) {
    return FirmwareUpgradeSubmitItemDto(
      deviceId: _requiredNumericString(json, 'deviceId'),
      firmwareReleaseId: _requiredNumericString(json, 'firmwareReleaseId'),
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': int.parse(deviceId),
    'firmwareReleaseId': int.parse(firmwareReleaseId),
  };
}

class FirmwareUpgradeSubmitResponseDto {
  const FirmwareUpgradeSubmitResponseDto({
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
  final String? scheduledAt;
  final String? upgradeExpireAt;
  final String? failureMessage;

  factory FirmwareUpgradeSubmitResponseDto.fromJson(Map<String, dynamic> json) {
    final accepted = json['accepted'];
    if (accepted is! bool) {
      throw const FormatException('Firmware accepted flag is required.');
    }
    return FirmwareUpgradeSubmitResponseDto(
      deviceId: _requiredNumericString(json, 'deviceId'),
      firmwareReleaseId: _requiredNumericString(json, 'firmwareReleaseId'),
      accepted: accepted,
      scheduledAt: _nullableNumericString(json['scheduledAt']),
      upgradeExpireAt: _nullableString(json['upgradeExpireAt']),
      failureMessage: _nullableString(json['failureMessage']),
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': int.parse(deviceId),
    'firmwareReleaseId': int.parse(firmwareReleaseId),
    'accepted': accepted,
    'scheduledAt': scheduledAt == null ? null : int.parse(scheduledAt!),
    'upgradeExpireAt': upgradeExpireAt,
    'failureMessage': failureMessage,
  };
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('$key must be a string.');
  }
  return value;
}

String _requiredNumericString(Map<String, dynamic> json, String key) {
  final value = _nullableNumericString(json[key]);
  if (value == null) {
    throw FormatException('$key must be numeric.');
  }
  return value;
}

String? _nullableNumericString(Object? value) {
  if (value == null) return null;
  if (value is int) return value.toString();
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  if (value is String && int.tryParse(value) != null) return value;
  throw const FormatException('Expected an integer-compatible value.');
}

String? _nullableTimestampString(Object? value) {
  if (value is String && value.trim().isEmpty) return null;
  return _nullableNumericString(value);
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  if (value is! String) {
    throw const FormatException('Expected a nullable string.');
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
