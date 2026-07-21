import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/security_center_overview.dart';

/// 安全中心页面数据入口。
///
/// 当前使用实体假数据以支持 UI 开发；接入接口后，请在此 provider 的数据
/// 来源处替换为 SecurityRepository，而保持页面消费的实体不变。
final securityCenterOverviewProvider =
    Provider.family<SecurityCenterOverview, String>((ref, deviceId) {
      return SecurityCenterOverview(
        deviceId: deviceId,
        protectionStatus: SecurityEvaluationStatus.normal,
        generalEvaluation: const SecurityEvaluationSection(
          status: SecurityEvaluationStatus.normal,
          items: [
            SecurityEvaluationItem(
              type: SecurityEvaluationItemType.doorOperationStatus,
              status: SecurityEvaluationStatus.normal,
            ),
            SecurityEvaluationItem(
              type: SecurityEvaluationItemType.doorOperationRecord,
              status: SecurityEvaluationStatus.normal,
            ),
          ],
        ),
        safetySensorEvaluation: const SecuritySensorEvaluation(
          status: SecurityEvaluationStatus.critical,
          highlightedSensorTypes: [
            SecuritySensorType.photoBeam,
            SecuritySensorType.eLock,
          ],
          wirelessSensors: [
            SecuritySensorSnapshot(
              id: 'wireless-photo-beam',
              type: SecuritySensorType.photoBeam,
              status: SecurityEvaluationStatus.normal,
              batteryPercentage: 96,
            ),
            SecuritySensorSnapshot(
              id: 'wireless-e-lock',
              type: SecuritySensorType.eLock,
              status: SecurityEvaluationStatus.normal,
              batteryPercentage: 84,
            ),
            SecuritySensorSnapshot(
              id: 'wireless-door-sensor',
              type: SecuritySensorType.doorSensor,
              status: SecurityEvaluationStatus.critical,
              batteryPercentage: 12,
            ),
            SecuritySensorSnapshot(
              id: 'wireless-radar',
              type: SecuritySensorType.radar,
              status: SecurityEvaluationStatus.normal,
              batteryPercentage: 92,
            ),
            SecuritySensorSnapshot(
              id: 'wireless-remote',
              type: SecuritySensorType.remote,
              status: SecurityEvaluationStatus.offline,
              batteryPercentage: 0,
            ),
            SecuritySensorSnapshot(
              id: 'wireless-safety-edge',
              type: SecuritySensorType.safetyEdge,
              status: SecurityEvaluationStatus.critical,
              batteryPercentage: 78,
            ),
          ],
          wiredSensors: [
            SecuritySensorSnapshot(
              id: 'wired-photo-beam',
              type: SecuritySensorType.wiredPhotoBeam,
              status: SecurityEvaluationStatus.normal,
              batteryPercentage: 100,
            ),
            SecuritySensorSnapshot(
              id: 'wired-e-lock',
              type: SecuritySensorType.wiredELock,
              status: SecurityEvaluationStatus.critical,
              batteryPercentage: 100,
            ),
          ],
        ),
      );
    });
