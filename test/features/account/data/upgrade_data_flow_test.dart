import 'package:dio/dio.dart';
import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/account/data/data_sources/upgrade_api.dart';
import 'package:flinx/features/account/data/data_sources/upgrade_progress_local_data_source.dart';
import 'package:flinx/features/account/data/data_sources/upgrade_remote_data_source.dart';
import 'package:flinx/features/account/data/dto/upgrade_dto.dart';
import 'package:flinx/features/account/data/repositories/upgrade_repository_impl.dart';
import 'package:flinx/features/account/data/services/platform_app_release_context_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  test('parses the app release published timestamp from the real response', () {
    final dto = AppReleaseCheckResponseDto.fromJson({
      'action': 'OPTIONAL',
      'targetVersion': 'v1.0.0',
      'targetBuildNumber': '110001',
      'publishedAt': 1786348310000,
      'updateUrl': 'https://play.google.com/store/search?q=F-linX&c=apps',
    });

    expect(dto.publishedAt, '1786348310000');
    final update = dto.toDomain();
    expect(update.hasUpdate, isTrue);
    expect(update.targetVersion, 'v1.0.0');
    expect(
      update.publishedAt,
      DateTime.fromMillisecondsSinceEpoch(1786348310000, isUtc: true),
    );
    expect(dto.toJson()['publishedAt'], 1786348310000);

    final withoutDate = AppReleaseCheckResponseDto.fromJson({
      'action': 'OPTIONAL',
      'targetVersion': 'v1.0.0',
      'targetBuildNumber': '110001',
      'publishedAt': '',
      'updateUrl': null,
    });
    expect(withoutDate.publishedAt, isNull);
  });

  test('parses the door-grouped firmware response with numeric strings', () {
    final dto = FirmwareUpgradeDoorDto.fromJson(_firmwareDoorJson);

    expect(dto.doorId, '11');
    expect(dto.upgrades.single.deviceId, '101');
    expect(dto.upgrades.single.packageSize, '19188941');
    expect(dto.upgrades.single.lastFirmwareUpgradedAt, '1787796465000');
    final target = dto.toDomain().upgrades.single;
    expect(target.packageSizeBytes, 19188941);
    expect(
      target.lastFirmwareUpgradedAt,
      DateTime.fromMillisecondsSinceEpoch(1787796465000, isUtc: true),
    );
    expect(
      dto.upgrades.single.toJson()['lastFirmwareUpgradedAt'],
      1787796465000,
    );
  });

  test('parses the immediate firmware upgrade response timestamp', () {
    final dto = FirmwareUpgradeSubmitResponseDto.fromJson({
      'deviceId': '10',
      'firmwareReleaseId': '5',
      'accepted': true,
      'scheduledAt': null,
      'upgradeExpireAt': 1788421950225,
      'failureMessage': '',
    });

    expect(dto.upgradeExpireAt, '1788421950225');
    expect(dto.failureMessage, isNull);
    expect(dto.toJson()['upgradeExpireAt'], 1788421950225);
    expect(
      dto.toDomain().upgradeExpireAt,
      DateTime.fromMillisecondsSinceEpoch(1788421950225, isUtc: true),
    );
  });

  test('rejects unknown firmware statuses', () {
    final target = Map<String, dynamic>.from(
      (_firmwareDoorJson['upgrades'] as List).single as Map,
    )..['status'] = 'DONE';
    expect(
      () => FirmwareUpgradeTargetDto.fromJson(target),
      throwsFormatException,
    );
  });

  test('sends app context, submit body, and request IDs', () async {
    final api = _FakeUpgradeApi();
    final dataSource = UpgradeRemoteDataSourceImpl(
      api: api,
      appReleaseContextProvider: PlatformAppReleaseContextProvider(
        packageInfo: () async => PackageInfo(
          appName: 'FLINX',
          packageName: 'com.example.flinx',
          version: '1.2.3',
          buildNumber: '124',
        ),
        targetPlatform: () => TargetPlatform.android,
      ),
    );

    await dataSource.checkAppRelease(requestId: 'app-check-1');
    await dataSource.fetchFirmwareUpgrades(requestId: 'firmware-list-1');
    await dataSource.submitFirmwareUpgrades(
      request: const FirmwareUpgradeSubmitRequestDto(
        upgradeMode: 'IMMEDIATE',
        scheduledAt: null,
        items: [
          FirmwareUpgradeSubmitItemDto(
            deviceId: '101',
            firmwareReleaseId: '1001',
          ),
        ],
      ),
      requestId: 'firmware-submit-1',
    );

    expect(api.appRequest.toJson(), {
      'platform': 'ANDROID',
      'buildNumber': 124,
    });
    expect(
      api.appOptions.extra?[NetworkRequestExtras.requestId],
      'app-check-1',
    );
    expect(
      api.listOptions.extra?[NetworkRequestExtras.requestId],
      'firmware-list-1',
    );
    expect(
      api.submitOptions.extra?[NetworkRequestExtras.requestId],
      'firmware-submit-1',
    );
    expect(api.submitRequest.toJson()['items'], [
      {'deviceId': 101, 'firmwareReleaseId': 1001},
    ]);
  });

  test('maps invalid protocol responses to a server AppError', () async {
    final repository = UpgradeRepositoryImpl(
      remoteDataSource: _FailingUpgradeRemoteDataSource(
        const UpgradeRemoteException.invalidResponse(),
      ),
      localDataSource: InMemoryUpgradeProgressLocalDataSource(),
      logger: const DebugAppLogger(),
    );

    await expectLater(
      repository.fetchFirmwareUpgrades(requestId: 'invalid-upgrades'),
      throwsA(
        isA<AppError>().having(
          (error) => error.code,
          'code',
          AppErrorCode.serverError,
        ),
      ),
    );
  });

  test('keeps persisted progress isolated by user', () async {
    final localDataSource = InMemoryUpgradeProgressLocalDataSource();

    await localDataSource.replaceProgresses(
      userId: 'user-a',
      progresses: {'101:1001': 45},
    );
    await localDataSource.replaceProgresses(
      userId: 'user-b',
      progresses: {'101:1001': 12},
    );

    expect(await localDataSource.readProgresses(userId: 'user-a'), {
      '101:1001': 45,
    });
    expect(await localDataSource.readProgresses(userId: 'user-b'), {
      '101:1001': 12,
    });
  });
}

const _firmwareDoorJson = <String, dynamic>{
  'doorId': 11,
  'doorName': 'South Gate',
  'upgrades': [
    {
      'deviceId': 101,
      'firmwareReleaseId': 1001,
      'sn': 'SN001',
      'currentVersion': null,
      'deviceType': 'opener',
      'deviceTypeLabel': 'Opener',
      'packageSize': 19188941,
      'availableVersion': '1.2.5',
      'lastFirmwareUpgradedAt': 1787796465000,
      'status': 'AVAILABLE',
      'scheduledAt': null,
      'upgradeExpireAt': null,
    },
  ],
};

class _FakeUpgradeApi implements UpgradeApi {
  late AppReleaseCheckRequestDto appRequest;
  late Options appOptions;
  late Options listOptions;
  late FirmwareUpgradeSubmitRequestDto submitRequest;
  late Options submitOptions;

  @override
  Future<ApiEnvelopeDto<AppReleaseCheckResponseDto>> checkAppRelease(
    AppReleaseCheckRequestDto request,
    Options options,
  ) async {
    appRequest = request;
    appOptions = options;
    return const ApiEnvelopeDto(
      code: 200,
      success: true,
      data: AppReleaseCheckResponseDto(
        action: 'OPTIONAL',
        targetVersion: '1.2.5',
        targetBuildNumber: '125',
        publishedAt: null,
        updateUrl: null,
      ),
    );
  }

  @override
  Future<ApiEnvelopeDto<List<FirmwareUpgradeDoorDto>>> fetchFirmwareUpgrades(
    Options options,
  ) async {
    listOptions = options;
    return ApiEnvelopeDto(
      code: 200,
      success: true,
      data: [FirmwareUpgradeDoorDto.fromJson(_firmwareDoorJson)],
    );
  }

  @override
  Future<ApiEnvelopeDto<List<FirmwareUpgradeSubmitResponseDto>>>
  submitFirmwareUpgrades(
    FirmwareUpgradeSubmitRequestDto request,
    Options options,
  ) async {
    submitRequest = request;
    submitOptions = options;
    return const ApiEnvelopeDto(
      code: 200,
      success: true,
      data: [
        FirmwareUpgradeSubmitResponseDto(
          deviceId: '101',
          firmwareReleaseId: '1001',
          accepted: true,
          scheduledAt: null,
          upgradeExpireAt: null,
          failureMessage: null,
        ),
      ],
    );
  }
}

class _FailingUpgradeRemoteDataSource implements UpgradeRemoteDataSource {
  const _FailingUpgradeRemoteDataSource(this.error);

  final Object error;

  @override
  Future<AppReleaseCheckResponseDto> checkAppRelease({
    required String requestId,
  }) => Future.error(error);

  @override
  Future<List<FirmwareUpgradeDoorDto>> fetchFirmwareUpgrades({
    required String requestId,
  }) => Future.error(error);

  @override
  Future<List<FirmwareUpgradeSubmitResponseDto>> submitFirmwareUpgrades({
    required FirmwareUpgradeSubmitRequestDto request,
    required String requestId,
  }) => Future.error(error);
}
