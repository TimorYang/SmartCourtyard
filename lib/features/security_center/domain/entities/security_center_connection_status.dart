import 'security_center_overview.dart';

class SecurityCenterConnectionStatus {
  const SecurityCenterConnectionStatus({
    required this.wifiConnectionStatus,
    this.sensorEvaluation = offlineSensorEvaluation,
  });

  final String wifiConnectionStatus;
  final SecuritySensorEvaluation sensorEvaluation;

  bool get isWifiDisconnected => wifiConnectionStatus == '1';

  static const offlineSensorEvaluation = SecuritySensorEvaluation(
    status: SecurityEvaluationStatus.offline,
    highlightedSensorTypes: [
      SecuritySensorType.photoBeam,
      SecuritySensorType.eLock,
    ],
    wirelessSensors: [
      SecuritySensorSnapshot(
        id: 'WIRELESS_PHOTO_BEAM',
        type: SecuritySensorType.photoBeam,
        status: SecurityEvaluationStatus.offline,
        batteryPercentage: 0,
      ),
      SecuritySensorSnapshot(
        id: 'WIRELESS_WICKET_DOOR',
        type: SecuritySensorType.doorSensor,
        status: SecurityEvaluationStatus.offline,
        batteryPercentage: 0,
      ),
      SecuritySensorSnapshot(
        id: 'WIRELESS_ELECTRONIC_LOCK',
        type: SecuritySensorType.eLock,
        status: SecurityEvaluationStatus.offline,
        batteryPercentage: 0,
      ),
      SecuritySensorSnapshot(
        id: 'WIRELESS_SAFETY_EDGE',
        type: SecuritySensorType.safetyEdge,
        status: SecurityEvaluationStatus.offline,
        batteryPercentage: 0,
      ),
      SecuritySensorSnapshot(
        id: 'WIRELESS_SLACK_ROPE',
        type: SecuritySensorType.radar,
        status: SecurityEvaluationStatus.offline,
        batteryPercentage: 0,
      ),
    ],
    wiredSensors: [
      SecuritySensorSnapshot(
        id: 'WIRED_PHOTO_BEAM',
        type: SecuritySensorType.wiredPhotoBeam,
        status: SecurityEvaluationStatus.offline,
        batteryPercentage: 0,
        hasBattery: false,
      ),
      SecuritySensorSnapshot(
        id: 'WIRED_ELECTRONIC_LOCK',
        type: SecuritySensorType.wiredELock,
        status: SecurityEvaluationStatus.offline,
        batteryPercentage: 0,
        hasBattery: false,
      ),
    ],
  );
}
