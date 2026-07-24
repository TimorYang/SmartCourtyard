import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/providers.dart';
import '../../../core/network/providers.dart';
import '../data/data_sources/security_balance_refresh_api.dart';
import '../data/data_sources/security_balance_refresh_remote_data_source.dart';
import '../data/repositories/security_balance_refresh_repository_impl.dart';
import '../data/data_sources/security_center_connection_status_api.dart';
import '../data/data_sources/security_center_connection_status_remote_data_source.dart';
import '../data/repositories/security_center_connection_status_repository_impl.dart';
import '../domain/entities/security_center_overview.dart';
import '../domain/entities/full_report.dart';
import '../domain/entities/safety_sensors_evaluation.dart';
import '../domain/repositories/security_balance_refresh_repository.dart';
import '../domain/repositories/security_center_connection_status_repository.dart';
import '../domain/use_cases/refresh_security_balance_use_case.dart';
import '../domain/use_cases/fetch_security_center_connection_status_use_case.dart';
import '../data/data_sources/general_evaluation_api.dart';
import '../data/data_sources/general_evaluation_remote_data_source.dart';
import '../data/repositories/general_evaluation_repository_impl.dart';
import '../domain/repositories/general_evaluation_repository.dart';
import '../domain/use_cases/fetch_general_evaluation_use_case.dart';

final securityBalanceRefreshApiProvider = Provider<SecurityBalanceRefreshApi>((
  ref,
) {
  return SecurityBalanceRefreshApi(ref.watch(dioProvider));
});

final securityBalanceRefreshRemoteDataSourceProvider =
    Provider<SecurityBalanceRefreshRemoteDataSource>((ref) {
      return SecurityBalanceRefreshRemoteDataSourceImpl(
        api: ref.watch(securityBalanceRefreshApiProvider),
      );
    });

final securityBalanceRefreshRepositoryProvider =
    Provider<SecurityBalanceRefreshRepository>((ref) {
      return SecurityBalanceRefreshRepositoryImpl(
        remoteDataSource: ref.watch(
          securityBalanceRefreshRemoteDataSourceProvider,
        ),
        logger: ref.watch(appLoggerProvider),
      );
    });

final refreshSecurityBalanceUseCaseProvider =
    Provider<RefreshSecurityBalanceUseCase>((ref) {
      return RefreshSecurityBalanceUseCase(
        repository: ref.watch(securityBalanceRefreshRepositoryProvider),
      );
    });

final securityCenterConnectionStatusApiProvider =
    Provider<SecurityCenterConnectionStatusApi>((ref) {
      return SecurityCenterConnectionStatusApi(ref.watch(dioProvider));
    });

final securityCenterConnectionStatusRemoteDataSourceProvider =
    Provider<SecurityCenterConnectionStatusRemoteDataSource>((ref) {
      return SecurityCenterConnectionStatusRemoteDataSourceImpl(
        api: ref.watch(securityCenterConnectionStatusApiProvider),
      );
    });

final securityCenterConnectionStatusRepositoryProvider =
    Provider<SecurityCenterConnectionStatusRepository>((ref) {
      return SecurityCenterConnectionStatusRepositoryImpl(
        remoteDataSource: ref.watch(
          securityCenterConnectionStatusRemoteDataSourceProvider,
        ),
        logger: ref.watch(appLoggerProvider),
      );
    });

final fetchSecurityCenterConnectionStatusUseCaseProvider =
    Provider<FetchSecurityCenterConnectionStatusUseCase>((ref) {
      return FetchSecurityCenterConnectionStatusUseCase(
        repository: ref.watch(securityCenterConnectionStatusRepositoryProvider),
      );
    });

final generalEvaluationApiProvider = Provider<GeneralEvaluationApi>(
  (ref) => GeneralEvaluationApi(ref.watch(dioProvider)),
);
final generalEvaluationRemoteDataSourceProvider =
    Provider<GeneralEvaluationRemoteDataSource>(
      (ref) => GeneralEvaluationRemoteDataSourceImpl(
        api: ref.watch(generalEvaluationApiProvider),
        logger: ref.watch(appLoggerProvider),
      ),
    );
final generalEvaluationRepositoryProvider =
    Provider<GeneralEvaluationRepository>(
      (ref) => GeneralEvaluationRepositoryImpl(
        remote: ref.watch(generalEvaluationRemoteDataSourceProvider),
        logger: ref.watch(appLoggerProvider),
      ),
    );
final fetchGeneralEvaluationUseCaseProvider =
    Provider<FetchGeneralEvaluationUseCase>(
      (ref) => FetchGeneralEvaluationUseCase(
        repository: ref.watch(generalEvaluationRepositoryProvider),
      ),
    );

/// 安全传感器评估页面的数据入口。
///
/// 当前返回设计稿对应的假数据。接口接入后，仅替换此处的数据来源及数据层映射，
/// 页面继续消费 [SafetySensorsEvaluation] 领域实体。
final safetySensorsEvaluationProvider =
    Provider.family<SafetySensorsEvaluation, String>((ref, deviceId) {
      return SafetySensorsEvaluation(
        deviceId: deviceId,
        totalSensorCount: 6,
        fineSensorCount: 3,
        abnormalSensorCount: 3,
        lowPowerSensorCount: 1,
        wiredSensorGroup: const SafetySensorGroup(
          status: SafetySensorGroupStatus.normal,
          sensors: [
            SafetySensor(
              id: 'wired-photo-beam',
              sensorName: 'Wired photo beam',
              status: SafetySensorStatus.disconnected,
              batteryStatus: SafetySensorBatteryStatus.normal,
              batteryPercentage: 100,
              operationPoints: [],
            ),
            SafetySensor(
              id: 'wired-e-lock',
              sensorName: 'Wired E-lock',
              status: SafetySensorStatus.disconnected,
              batteryStatus: SafetySensorBatteryStatus.normal,
              batteryPercentage: 100,
              operationPoints: [],
            ),
          ],
        ),
        wirelessSensorGroup: SafetySensorGroup(
          status: SafetySensorGroupStatus.normal,
          sensors: [
            SafetySensor(
              id: 'wireless-photo-beam',
              sensorName: 'Wireless Photo Beam',
              status: SafetySensorStatus.triggered,
              batteryStatus: SafetySensorBatteryStatus.low,
              batteryPercentage: 12,
              operationPoints: [
                SafetySensorOperationPoint(
                  occurredAt: DateTime(2026, 7, 20, 9),
                  cycles: 19,
                ),
                SafetySensorOperationPoint(
                  occurredAt: DateTime(2026, 7, 20, 14),
                  cycles: 21,
                ),
                SafetySensorOperationPoint(
                  occurredAt: DateTime(2026, 7, 20, 20),
                  cycles: 24,
                ),
              ],
            ),
            SafetySensor(
              id: 'wireless-wicket-door',
              sensorName: 'Wireless wicket door',
              status: SafetySensorStatus.normal,
              batteryStatus: SafetySensorBatteryStatus.normal,
              batteryPercentage: 84,
              operationPoints: [
                SafetySensorOperationPoint(
                  occurredAt: DateTime(2026, 7, 20, 6),
                  cycles: 8,
                ),
                SafetySensorOperationPoint(
                  occurredAt: DateTime(2026, 7, 20, 12),
                  cycles: 14,
                ),
                SafetySensorOperationPoint(
                  occurredAt: DateTime(2026, 7, 20, 18),
                  cycles: 11,
                ),
              ],
            ),
            SafetySensor(
              id: 'wireless-e-lock',
              sensorName: 'Wireless E-lock',
              status: SafetySensorStatus.normal,
              batteryStatus: SafetySensorBatteryStatus.normal,
              batteryPercentage: 72,
              operationPoints: [
                SafetySensorOperationPoint(
                  occurredAt: DateTime(2026, 7, 20, 4),
                  cycles: 4,
                ),
                SafetySensorOperationPoint(
                  occurredAt: DateTime(2026, 7, 20, 11),
                  cycles: 9,
                ),
                SafetySensorOperationPoint(
                  occurredAt: DateTime(2026, 7, 20, 16),
                  cycles: 13,
                ),
              ],
            ),
            SafetySensor(
              id: 'wireless-safety-edge',
              sensorName: 'Wireless safety edge',
              status: SafetySensorStatus.normal,
              batteryStatus: SafetySensorBatteryStatus.normal,
              batteryPercentage: 68,
              operationPoints: [
                SafetySensorOperationPoint(
                  occurredAt: DateTime(2026, 7, 20, 3),
                  cycles: 6,
                ),
                SafetySensorOperationPoint(
                  occurredAt: DateTime(2026, 7, 20, 10),
                  cycles: 12,
                ),
                SafetySensorOperationPoint(
                  occurredAt: DateTime(2026, 7, 20, 21),
                  cycles: 7,
                ),
              ],
            ),
          ],
        ),
      );
    });

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
