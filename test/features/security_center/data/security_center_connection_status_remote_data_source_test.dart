import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/security_center/data/data_sources/security_center_connection_status_api.dart';
import 'package:flinx/features/security_center/data/data_sources/security_center_connection_status_remote_data_source.dart';
import 'package:flinx/features/security_center/data/dto/security_center_connection_status_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('passes request ID and preserves sensor status data', () async {
    final api = _FakeConnectionStatusApi(
      const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: SecurityCenterConnectionStatusDto(
          wifiConnectionStatus: '2',
          sensorStatus: '1',
          wirelessSensors: [
            SecurityCenterSensorStatusItemDto(
              sensorCode: 'WIRELESS_SLACK_ROPE',
              status: '1',
              batteryStatus: '1',
            ),
          ],
        ),
      ),
    );
    final dataSource = SecurityCenterConnectionStatusRemoteDataSourceImpl(
      api: api,
    );

    final result = await dataSource.fetchConnectionStatus(
      doorId: 12,
      requestId: 'connection-12',
    );

    expect(api.doorId, 12);
    expect(api.options.extra?[NetworkRequestExtras.requestId], 'connection-12');
    expect(result.sensorStatus, '1');
    expect(result.wirelessSensors.single.sensorCode, 'WIRELESS_SLACK_ROPE');
  });

  test('rejects an invalid Wi-Fi connection status', () async {
    final dataSource = SecurityCenterConnectionStatusRemoteDataSourceImpl(
      api: _FakeConnectionStatusApi(
        const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: SecurityCenterConnectionStatusDto(wifiConnectionStatus: '9'),
        ),
      ),
    );

    await expectLater(
      dataSource.fetchConnectionStatus(doorId: 12, requestId: 'connection-12'),
      throwsA(isA<SecurityCenterConnectionStatusRemoteException>()),
    );
  });
}

class _FakeConnectionStatusApi implements SecurityCenterConnectionStatusApi {
  _FakeConnectionStatusApi(this.response);

  final ApiEnvelopeDto<SecurityCenterConnectionStatusDto> response;
  late int doorId;
  late Options options;

  @override
  Future<ApiEnvelopeDto<SecurityCenterConnectionStatusDto>> connectionStatus(
    int doorId,
    Options options,
  ) async {
    this.doorId = doorId;
    this.options = options;
    return response;
  }
}
