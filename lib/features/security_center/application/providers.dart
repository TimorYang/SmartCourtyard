import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/security_center_overview.dart';
import '../domain/entities/full_report.dart';

/// 完整报告页面的数据入口。
///
/// 当前返回设计稿对应的假数据。接口接入后，仅替换此处的数据来源及数据层映射，
/// 页面继续消费 [FullReport] 领域实体。
final fullReportProvider = Provider.family<FullReport, String>((ref, deviceId) {
  return FullReport(
    deviceId: deviceId,
    motorName: 'Garage door motor 01',
    serialNumber: 'FSD123456789',
    cycleSummary: const FullReportCycleSummary(
      doorName: 'Garage door 01',
      operatedCycles: 860,
      remainingCycles: 140,
      needsMaintenance: true,
    ),
    openBalanceEvaluation: const FullReportBalanceEvaluation(
      indicatorPercentage: 62,
      bandStatuses: [
        FullReportBalanceBandStatus.overload,
        FullReportBalanceBandStatus.overload,
        FullReportBalanceBandStatus.normal,
        FullReportBalanceBandStatus.normal,
        FullReportBalanceBandStatus.normal,
      ],
    ),
    closeBalanceEvaluation: const FullReportBalanceEvaluation(
      indicatorPercentage: 38,
      bandStatuses: [
        FullReportBalanceBandStatus.normal,
        FullReportBalanceBandStatus.normal,
        FullReportBalanceBandStatus.normal,
        FullReportBalanceBandStatus.overload,
        FullReportBalanceBandStatus.overload,
      ],
    ),
    last24HoursRecord: FullReportOperationRecord(
      points: [
        for (var hour = 0; hour < 24; hour++)
          FullReportOperationCyclePoint(
            occurredAt: DateTime(2026, 7, 20, hour),
            cycles: hour == 9
                ? 24
                : hour == 2
                ? 1
                : 0,
          ),
      ],
      hasFrequentOperationAlert: true,
    ),
    last7DaysRecord: FullReportOperationRecord(
      points: [
        for (var day = 3; day <= 9; day++)
          FullReportOperationCyclePoint(
            occurredAt: DateTime(2026, 7, day),
            cycles: day == 8 ? 18 : 0,
          ),
      ],
    ),
    motorFunctionStatus: const FullReportMotorFunctionStatus(
      openingForceLevel: 1,
      closingForceLevel: 1,
      autoCloseSeconds: 25,
      autoCloseCondition: FullReportAutoCloseCondition.anyPosition,
      ledOffDelayMinutes: 3,
      partialOpenCentimeters: 40,
      ignoreObstructionHeightCentimeters: 3,
      photoBeamEnabled: true,
      communityModeEnabled: true,
      wiredELockEnabled: true,
    ),
    wiredSensorDiagnosis: const FullReportSensorDiagnosis(
      summary: FullReportSensorSummary(
        normalCount: 2,
        disconnectedCount: 0,
        abnormalCount: 0,
      ),
      sensors: [
        FullReportSensor(
          id: 'wired-photo-beam',
          type: FullReportSensorType.wiredPhotoBeam,
          states: [FullReportSensorDisplayState.notTriggered],
        ),
        FullReportSensor(
          id: 'wired-e-lock',
          type: FullReportSensorType.wiredELock,
          states: [FullReportSensorDisplayState.locked],
        ),
      ],
    ),
    wirelessSensorDiagnosis: const FullReportSensorDiagnosis(
      summary: FullReportSensorSummary(
        normalCount: 3,
        disconnectedCount: 1,
        abnormalCount: 2,
      ),
      sensors: [
        FullReportSensor(
          id: 'wireless-photo-beam',
          type: FullReportSensorType.wiredPhotoBeam,
          states: [
            FullReportSensorDisplayState.batterySufficient,
            FullReportSensorDisplayState.notTriggered,
          ],
        ),
        FullReportSensor(
          id: 'wireless-wicket-door',
          type: FullReportSensorType.wirelessWicketDoor,
          states: [
            FullReportSensorDisplayState.notTriggered,
            FullReportSensorDisplayState.batterySufficient,
          ],
        ),
        FullReportSensor(
          id: 'wireless-safety-edge',
          type: FullReportSensorType.wirelessSafetyEdge,
          states: [
            FullReportSensorDisplayState.batterySufficient,
            FullReportSensorDisplayState.notTriggered,
          ],
        ),
        FullReportSensor(
          id: 'wireless-position-sensor',
          type: FullReportSensorType.wirelessPositionSensor,
          states: [
            FullReportSensorDisplayState.notTriggered,
            FullReportSensorDisplayState.batterySufficient,
          ],
        ),
        FullReportSensor(
          id: 'wireless-e-lock',
          type: FullReportSensorType.wirelessELock,
          states: [
            FullReportSensorDisplayState.batterySufficient,
            FullReportSensorDisplayState.locked,
          ],
        ),
      ],
    ),
    safetySuggestions: const [
      FullReportSafetySuggestionCode.cycleMaintenance,
      FullReportSafetySuggestionCode.safetyEdgeLowBattery,
      FullReportSafetySuggestionCode.contactInstaller,
      FullReportSafetySuggestionCode.openingCurrentExceeded,
    ],
  );
});

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
