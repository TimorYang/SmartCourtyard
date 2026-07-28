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
import '../domain/entities/safety_sensors_evaluation.dart';
import '../domain/repositories/security_balance_refresh_repository.dart';
import '../domain/repositories/security_center_connection_status_repository.dart';
import '../domain/use_cases/refresh_security_balance_use_case.dart';
import '../domain/use_cases/fetch_security_center_connection_status_use_case.dart';
import '../data/data_sources/general_evaluation_api.dart';
import '../data/data_sources/general_evaluation_remote_data_source.dart';
import '../data/repositories/general_evaluation_repository_impl.dart';
import '../data/data_sources/safety_sensors_evaluation_api.dart';
import '../data/data_sources/safety_sensors_evaluation_remote_data_source.dart';
import '../data/repositories/safety_sensors_evaluation_repository_impl.dart';
import '../domain/repositories/general_evaluation_repository.dart';
import '../domain/use_cases/fetch_general_evaluation_use_case.dart';
import '../domain/repositories/safety_sensors_evaluation_repository.dart';
import '../domain/use_cases/fetch_safety_sensors_evaluation_use_case.dart';

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
final safetySensorsEvaluationApiProvider = Provider<SafetySensorsEvaluationApi>(
  (ref) => SafetySensorsEvaluationApi(ref.watch(dioProvider)),
);

final safetySensorsEvaluationRemoteDataSourceProvider =
    Provider<SafetySensorsEvaluationRemoteDataSource>(
      (ref) => SafetySensorsEvaluationRemoteDataSourceImpl(
        api: ref.watch(safetySensorsEvaluationApiProvider),
      ),
    );

final safetySensorsEvaluationRepositoryProvider =
    Provider<SafetySensorsEvaluationRepository>(
      (ref) => SafetySensorsEvaluationRepositoryImpl(
        remoteDataSource: ref.watch(
          safetySensorsEvaluationRemoteDataSourceProvider,
        ),
        logger: ref.watch(appLoggerProvider),
      ),
    );

final fetchSafetySensorsEvaluationUseCaseProvider =
    Provider<FetchSafetySensorsEvaluationUseCase>(
      (ref) => FetchSafetySensorsEvaluationUseCase(
        repository: ref.watch(safetySensorsEvaluationRepositoryProvider),
      ),
    );

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
              id: 'wireless-remote',
              type: SecuritySensorType.remote,
              status: SecurityEvaluationStatus.offline,
              batteryPercentage: 0,
            ),
            SecuritySensorSnapshot(
              id: 'wireless-radar',
              type: SecuritySensorType.radar,
              status: SecurityEvaluationStatus.normal,
              batteryPercentage: 92,
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
