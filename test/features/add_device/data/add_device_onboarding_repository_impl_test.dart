import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/api_business_failure.dart';
import 'package:flinx/features/add_device/data/data_sources/add_device_onboarding_remote_data_source.dart';
import 'package:flinx/features/add_device/data/dto/force_door_response_dto.dart';
import 'package:flinx/features/add_device/data/dto/onboarding_device_key_response_dto.dart';
import 'package:flinx/features/add_device/data/repositories/add_device_onboarding_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps current-user ownership to a dedicated app error', () async {
    final repository = AddDeviceOnboardingRepositoryImpl(
      remoteDataSource: _ThrowingRemoteDataSource(
        AddDeviceOnboardingRemoteException.alreadyBound(
          ownedByCurrentUser: true,
        ),
      ),
      logger: const _NoopLogger(),
    );

    expect(
      () => repository.validateBindingStatus(
        sn: 'SN-001',
        requestId: 'request-current-owner',
      ),
      throwsA(
        isA<AppError>()
            .having(
              (error) => error.messageKey,
              'messageKey',
              'addDevice.deviceAlreadyBoundToCurrentUser',
            )
            .having((error) => error.retryable, 'retryable', isFalse),
      ),
    );
  });

  test('maps another-user ownership to a dedicated app error', () async {
    final repository = AddDeviceOnboardingRepositoryImpl(
      remoteDataSource: const _ThrowingRemoteDataSource(
        AddDeviceOnboardingRemoteException.alreadyBound(
          ownedByCurrentUser: false,
        ),
      ),
      logger: const _NoopLogger(),
    );

    expect(
      () => repository.validateBindingStatus(
        sn: 'SN-001',
        requestId: 'request-other-owner',
      ),
      throwsA(
        isA<AppError>().having(
          (error) => error.messageKey,
          'messageKey',
          'addDevice.deviceAlreadyBoundToAnotherUser',
        ),
      ),
    );
  });

  test('maps missing device server message key to add device app error', () {
    final repository = AddDeviceOnboardingRepositoryImpl(
      remoteDataSource: _ThrowingRemoteDataSource(
        AddDeviceOnboardingRemoteException.businessFailure(
          ApiBusinessFailure(
            code: 100408,
            messageKey: 'app.door.device_not_exists',
          ),
        ),
      ),
      logger: const _NoopLogger(),
    );

    expect(
      () => repository.addForceDoor(
        sn: 'SN-001',
        doorId: '7',
        doorType: 0,
        requestId: 'request-1',
      ),
      throwsA(
        isA<AppError>()
            .having(
              (error) => error.messageKey,
              'messageKey',
              'addDevice.deviceNotExists',
            )
            .having((error) => error.requestId, 'requestId', 'request-1')
            .having((error) => error.businessCode, 'businessCode', 100408)
            .having(
              (error) => error.businessMessageKey,
              'businessMessageKey',
              'app.door.device_not_exists',
            ),
      ),
    );
  });
}

class _ThrowingRemoteDataSource implements AddDeviceOnboardingRemoteDataSource {
  const _ThrowingRemoteDataSource(this.exception);

  final AddDeviceOnboardingRemoteException exception;

  @override
  Future<void> validateBindingStatus({
    required String sn,
    required String requestId,
  }) async {
    throw exception;
  }

  @override
  Future<ForceDoorResponseDto> addForceDoor({
    required String sn,
    String? doorId,
    int? sceneId,
    required int doorType,
    required String requestId,
  }) async {
    throw exception;
  }

  @override
  Future<OnboardingDeviceKeyResponseDto> fetchDeviceKey({
    required String sn,
    required String requestId,
  }) async {
    throw exception;
  }
}

class _NoopLogger implements AppLogger {
  const _NoopLogger();

  @override
  void error(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void info(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void warning(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}
}
