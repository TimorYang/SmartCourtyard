import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/account/data/data_sources/managed_devices_api.dart';
import 'package:flinx/features/account/data/data_sources/managed_devices_remote_data_source.dart';
import 'package:flinx/features/account/data/dto/managed_login_device_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses login devices and preserves the request id', () async {
    final api = _FakeManagedDevicesApi();
    final dataSource = ManagedDevicesRemoteDataSourceImpl(api: api);

    final devices = await dataSource.fetchLoginDevices(
      requestId: 'managed-devices-123',
    );

    expect(devices.single.sessionId, '2082351509609910273');
    expect(devices.single.deviceModel, 'Pixel 9');
    expect(
      devices.single.lastLoginTime,
      DateTime.fromMillisecondsSinceEpoch(1785306263000),
    );
    expect(
      api.fetchOptions.extra?[NetworkRequestExtras.requestId],
      'managed-devices-123',
    );
  });

  test('removes a login device with its session id and request id', () async {
    final api = _FakeManagedDevicesApi();
    final dataSource = ManagedDevicesRemoteDataSourceImpl(api: api);

    await dataSource.removeLoginDevice(
      sessionId: '2082351509609910273',
      requestId: 'remove-123',
    );

    expect(api.removedSessionId, '2082351509609910273');
    expect(
      api.removeOptions.extra?[NetworkRequestExtras.requestId],
      'remove-123',
    );
  });

  test('rejects obsolete business code zero', () async {
    final api = _FakeManagedDevicesApi(code: 0);
    final dataSource = ManagedDevicesRemoteDataSourceImpl(api: api);

    await expectLater(
      dataSource.fetchLoginDevices(requestId: 'managed-devices-123'),
      throwsA(isA<ManagedDevicesRemoteException>()),
    );
  });
}

class _FakeManagedDevicesApi implements ManagedDevicesApi {
  _FakeManagedDevicesApi({this.code = 200});

  final int code;
  late Options fetchOptions;
  late Options removeOptions;
  late String removedSessionId;

  @override
  Future<ApiEnvelopeDto<List<ManagedLoginDeviceDto>>> fetchLoginDevices(
    Options options,
  ) async {
    fetchOptions = options;
    return ApiEnvelopeDto(
      code: code,
      success: true,
      data: [
        ManagedLoginDeviceDto.fromJson({
          'sessionId': '2082351509609910273',
          'deviceModel': 'Pixel 9',
          'platform': 'ANDROID',
          'lastLoginTime': 1785306263000,
          'currentDevice': false,
        }),
      ],
    );
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> removeLoginDevice(
    String sessionId,
    Options options,
  ) async {
    removedSessionId = sessionId;
    removeOptions = options;
    return ApiEnvelopeDto(code: code, success: true, data: <String, dynamic>{});
  }
}
