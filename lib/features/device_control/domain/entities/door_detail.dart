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
    this.positionPercent,
    this.coverFileId,
    this.associatedDevices = const [],
  });

  final String id;
  final String name;
  final int? doorType;
  final String? doorTypeLabel;
  final int? controlMode;
  final String? controlModeLabel;
  final int? onlineStatus;
  final String? onlineStatusLabel;
  final DoorState doorState;
  final String doorStateLabel;
  final double? positionPercent;
  final int? coverFileId;
  final int operatedCycles;
  final int remainingCycles;
  final List<DoorAssociatedDevice> associatedDevices;

  String get hardwareDeviceId {
    final primaryControlDevice = associatedDevices.where(
      (device) =>
          device.associated &&
          device.primaryControl &&
          device.bleName.trim().isNotEmpty,
    );
    if (primaryControlDevice.isNotEmpty) {
      return primaryControlDevice.first.bleName.trim();
    }
    return '';
  }
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
