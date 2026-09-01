import '../../../../platform_bridge/hardware_models.dart';

class DoorDetail {
  const DoorDetail({
    required this.id,
    required this.name,
    required this.doorState,
    required this.doorStateLabel,
    required this.operatedCycles,
    required this.remainingCycles,
    this.doorType,
    this.doorTypeLabel,
    this.controlMode,
    this.controlModeLabel,
    this.onlineStatus,
    this.onlineStatusLabel,
    this.relationType,
    this.effectiveCapabilities = const <String>[],
    this.positionPercent,
    this.coverFileId,
    this.operatorAvatarFileId,
    this.ledStatus,
    this.ledStatusLabel,
    this.autoCloseEnabled = false,
    this.openReminderEnabled = false,
    this.partialOpenValue,
  });

  final String id;
  final String name;
  final int? doorType;
  final String? doorTypeLabel;
  final int? controlMode;
  final String? controlModeLabel;
  final int? onlineStatus;
  final String? onlineStatusLabel;
  final int? relationType;
  final List<String> effectiveCapabilities;
  final DoorState doorState;
  final String doorStateLabel;
  final double? positionPercent;
  final int? coverFileId;
  final int? operatorAvatarFileId;
  final int? ledStatus;
  final String? ledStatusLabel;
  final bool autoCloseEnabled;
  final bool openReminderEnabled;
  final int? partialOpenValue;
  final int operatedCycles;
  final int remainingCycles;
  bool get isLedEnabled => ledStatus == 2;
}

class DoorAssociatedDevice {
  const DoorAssociatedDevice({
    required this.deviceType,
    required this.associated,
    required this.primaryControl,
    required this.bleName,
    this.deviceTypeLabel,
    this.bleUuid,
    this.bleMac,
    this.capabilities = const [],
  });

  final String deviceType;
  final String? deviceTypeLabel;
  final bool associated;
  final bool primaryControl;
  final String bleName;
  final String? bleUuid;
  final String? bleMac;
  final List<String> capabilities;
}
