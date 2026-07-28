import 'package:dio/dio.dart';
import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/core/network/network_exception.dart';
import 'package:flinx/features/account/data/data_sources/shared_devices_api.dart';
import 'package:flinx/features/account/data/data_sources/shared_devices_remote_data_source.dart';
import 'package:flinx/features/account/data/dto/shared_door_response_dto.dart';
import 'package:flinx/features/account/data/dto/shared_door_members_response_dto.dart';
import 'package:flinx/features/account/data/repositories/shared_devices_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses shared door DTO including a nullable cover and zero count', () {
    final dto = SharedDoorResponseDto.fromJson(const {
      'doorId': '12',
      'name': 'Main gate',
      'coverFileId': null,
      'sharedUserCount': 0,
    });

    expect(dto.doorId, 12);
    expect(dto.coverFileId, isNull);
    expect(dto.sharedUserCount, 0);
    expect(dto.toJson()['name'], 'Main gate');
  });

  test('rejects a shared door DTO without a valid door ID', () {
    expect(
      () => SharedDoorResponseDto.fromJson(const {'doorId': 'invalid'}),
      throwsFormatException,
    );
  });

  test('passes the request ID and validates a successful response', () async {
    final api = _FakeSharedDevicesApi(
      const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: [
          SharedDoorResponseDto(
            doorId: 12,
            name: 'Main gate',
            coverFileId: null,
            sharedUserCount: 2,
          ),
        ],
      ),
    );
    final dataSource = SharedDevicesRemoteDataSourceImpl(api: api);

    final doors = await dataSource.fetchSharedDoors(requestId: 'shared-123');

    expect(doors.single.doorId, 12);
    expect(api.options.extra?[NetworkRequestExtras.requestId], 'shared-123');
  });

  test('maps an unauthorized remote failure to access denied', () async {
    final repository = SharedDevicesRepositoryImpl(
      remoteDataSource: _FailingSharedDevicesRemoteDataSource(
        SharedDevicesRemoteException.fromNetwork(
          NetworkException.fromDio(
            DioException(
              requestOptions: RequestOptions(path: 'shared-devices'),
              response: Response(
                requestOptions: RequestOptions(path: 'shared-devices'),
                statusCode: 401,
              ),
              type: DioExceptionType.badResponse,
            ),
          ),
        ),
      ),
      logger: const DebugAppLogger(),
    );

    await expectLater(
      repository.fetchSharedDoors(requestId: 'shared-401'),
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

class _FakeSharedDevicesApi implements SharedDevicesApi {
  _FakeSharedDevicesApi(this.response);

  final ApiEnvelopeDto<List<SharedDoorResponseDto>> response;
  late Options options;

  @override
  Future<ApiEnvelopeDto<List<SharedDoorResponseDto>>> fetchSharedDoors(
    Options options,
  ) async {
    this.options = options;
    return response;
  }

  @override
  Future<ApiEnvelopeDto<SharedDoorMembersResponseDto>> fetchDoorMembers(
    int doorId,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> deleteDoorMember(
    int shareId,
    Options options,
  ) => throw UnimplementedError();
}

class _FailingSharedDevicesRemoteDataSource
    implements SharedDevicesRemoteDataSource {
  const _FailingSharedDevicesRemoteDataSource(this.error);

  final Object error;

  @override
  Future<List<SharedDoorResponseDto>> fetchSharedDoors({
    required String requestId,
  }) => Future.error(error);

  @override
  Future<SharedDoorMembersResponseDto> fetchDoorMembers({
    required int doorId,
    required String requestId,
  }) => Future.error(error);

  @override
  Future<void> deleteDoorMember({
    required int shareId,
    required String requestId,
  }) => Future.error(error);
}
