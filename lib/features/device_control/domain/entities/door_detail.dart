import '../../../../platform_bridge/hardware_models.dart';

class DoorDetail {
  const DoorDetail({
    required this.id,
    required this.name,
    required this.doorState,
    required this.doorStateLabel,
    required this.operatedCycles,
    required this.remainingCycles,
    this.sceneId,
    this.sceneName,
    this.doorType,
    this.doorTypeLabel,
    this.controlSource,
    this.controlSourceLabel,
    this.controlMode,
    this.controlModeLabel,
    this.onlineStatus,
    this.onlineStatusLabel,
    this.positionPercent,
    this.coverMode,
    this.coverModeLabel,
    this.coverFileId,
    this.top = false,
    this.hardwareSn,
    this.model,
    this.firmwareVersion,
    this.hardwareVersion,
  });

  final String id;
  final String name;
  final int? sceneId;
  final String? sceneName;
  final int? doorType;
  final String? doorTypeLabel;
  final int? controlSource;
  final String? controlSourceLabel;
  final int? controlMode;
  final String? controlModeLabel;
  final int? onlineStatus;
  final String? onlineStatusLabel;
  final DoorState doorState;
  final String doorStateLabel;
  final double? positionPercent;
  final int? coverMode;
  final String? coverModeLabel;
  final int? coverFileId;
  final bool top;
  final int operatedCycles;
  final int remainingCycles;
  final String? hardwareSn;
  final String? model;
  final String? firmwareVersion;
  final String? hardwareVersion;

  String get hardwareDeviceId {
    return hardwareSn?.trim() ?? '';
  }
}
