import 'package:dio/dio.dart';
import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/core/network/network_exception.dart';
import 'package:flinx/features/account/data/data_sources/receiving_devices_api.dart';
import 'package:flinx/features/account/data/data_sources/receiving_devices_remote_data_source.dart';
import 'package:flinx/features/account/data/dto/receiving_door_response_dto.dart';
import 'package:flinx/features/account/data/repositories/receiving_devices_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parses receiving door DTO fields including nullable protocol fields',
    () {
      final dto = ReceivingDoorResponseDto.fromJson(const {
        'shareId': '9',
        'doorId': 12,
        'name': 'Main gate',
        'coverFileId': null,
        'doorType': '4',
        'ownerEmail': 'owner@example.com',
        'expiresAt': null,
      });

      expect(dto.shareId, 9);
      expect(dto.doorId, 12);
      expect(dto.coverFileId, isNull);
      expect(dto.doorType, 4);
      expect(dto.ownerEmail, 'owner@example.com');
      expect(dto.expiresAt, isNull);
      expect(dto.toJson()['name'], 'Main gate');
    },
  );

  test('rejects a receiving door DTO without valid stable IDs', () {
    expect(
      () => ReceivingDoorResponseDto.fromJson(const {'shareId': 'invalid'}),
      throwsFormatException,
    );
  });

  test('passes request ID and returns a successful empty response', () async {
    final api = _FakeReceivingDevicesApi(
      const ApiEnvelopeDto(code: 200, success: true, data: []),
    );
    final dataSource = ReceivingDevicesRemoteDataSourceImpl(api: api);

    final doors = await dataSource.fetchReceivingDoors(
      requestId: 'receiving-123',
    );

    expect(doors, isEmpty);
    expect(api.options.extra?[NetworkRequestExtras.requestId], 'receiving-123');
  });

  test('maps unauthorized remote failures to access denied', () async {
    final repository = ReceivingDevicesRepositoryImpl(
      remoteDataSource: _FailingReceivingDevicesRemoteDataSource(
        ReceivingDevicesRemoteException.fromNetwork(
          NetworkException.fromDio(
            DioException(
              requestOptions: RequestOptions(path: 'receiving-devices'),
              response: Response(
                requestOptions: RequestOptions(path: 'receiving-devices'),
                statusCode: 403,
              ),
              type: DioExceptionType.badResponse,
            ),
          ),
        ),
      ),
      logger: const DebugAppLogger(),
    );

    await expectLater(
      repository.fetchReceivingDoors(requestId: 'receiving-403'),
      throwsA(
        isA<AppError>().having(
          (error) => error.code,
          'code',
          AppErrorCode.accessDenied,
        ),
      ),
    );
  });
}

class _FakeReceivingDevicesApi implements ReceivingDevicesApi {
  _FakeReceivingDevicesApi(this.response);

  final ApiEnvelopeDto<List<ReceivingDoorResponseDto>> response;
  late Options options;

  @override
  Future<ApiEnvelopeDto<List<ReceivingDoorResponseDto>>> fetchReceivingDoors(
    Options options,
  ) async {
    this.options = options;
    return response;
  }
}

class _FailingReceivingDevicesRemoteDataSource
    implements ReceivingDevicesRemoteDataSource {
  const _FailingReceivingDevicesRemoteDataSource(this.error);

  final Object error;

  @override
  Future<List<ReceivingDoorResponseDto>> fetchReceivingDoors({
    required String requestId,
  }) => Future.error(error);
}
