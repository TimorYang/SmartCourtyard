import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/home/data/data_sources/door_share_remote_data_source.dart';
import 'package:flinx/features/home/data/data_sources/home_api.dart';
import 'package:flinx/features/home/data/dto/door_share_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates a share with sendEmail and request ID', () async {
    final api = _RecordingHomeApi();
    final dataSource = DoorShareRemoteDataSourceImpl(api: api);
    const request = CreateDoorShareRequestDto(
      receiverEmail: 'alex@example.com',
      role: '0',
      expiryType: '0',
      capabilities: ['DOOR_CONTROL'],
      sendEmail: false,
    );

    await dataSource.createShare(
      doorId: 12,
      request: request,
      requestId: 'door-share-create-12',
    );

    expect(api.createDoorId, 12);
    expect(api.createRequest.toJson(), request.toJson());
    expect(api.createRequest.toJson()['sendEmail'], isFalse);
    expect(
      api.createOptions.extra?[NetworkRequestExtras.requestId],
      'door-share-create-12',
    );
  });

  test('updates share permissions with request ID and required body', () async {
    final api = _RecordingHomeApi();
    final dataSource = DoorShareRemoteDataSourceImpl(api: api);
    const request = UpdateDoorShareRequestDto(
      role: '1',
      expiryType: '2',
      expiresAt: 1775930400000,
      capabilities: ['DOOR_CONTROL'],
    );

    await dataSource.updateShare(
      shareId: 7,
      request: request,
      requestId: 'door-share-update-7',
    );

    expect(api.updateShareId, 7);
    expect(api.updateRequest.toJson(), request.toJson());
    expect(
      api.updateOptions.extra?[NetworkRequestExtras.requestId],
      'door-share-update-7',
    );
  });

  test('rejects unsuccessful update responses', () async {
    final dataSource = DoorShareRemoteDataSourceImpl(
      api: _RecordingHomeApi(success: false),
    );

    await expectLater(
      dataSource.updateShare(
        shareId: 7,
        request: const UpdateDoorShareRequestDto(
          role: '0',
          expiryType: '0',
          capabilities: [],
        ),
        requestId: 'door-share-update-7',
      ),
      throwsA(isA<DoorShareRemoteException>()),
    );
  });
}

class _RecordingHomeApi implements HomeApi {
  _RecordingHomeApi({this.success = true});

  final bool success;
  late int createDoorId;
  late CreateDoorShareRequestDto createRequest;
  late Options createOptions;
  late int updateShareId;
  late UpdateDoorShareRequestDto updateRequest;
  late Options updateOptions;

  @override
  Future<ApiEnvelopeDto<DoorShareRecipientResponseDto>> createDoorShare(
    int doorId,
    CreateDoorShareRequestDto request,
    Options options,
  ) async {
    createDoorId = doorId;
    createRequest = request;
    createOptions = options;
    return ApiEnvelopeDto(
      code: success ? 200 : 500,
      success: success,
      data: const DoorShareRecipientResponseDto(shareId: 7),
    );
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> updateDoorShare(
    int shareId,
    UpdateDoorShareRequestDto request,
    Options options,
  ) async {
    updateShareId = shareId;
    updateRequest = request;
    updateOptions = options;
    return ApiEnvelopeDto(code: success ? 200 : 500, success: success);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
