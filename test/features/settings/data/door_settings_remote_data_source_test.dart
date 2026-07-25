import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/settings/data/data_sources/door_settings_api.dart';
import 'package:flinx/features/settings/data/data_sources/door_settings_remote_data_source.dart';
import 'package:flinx/features/settings/data/dto/door_setting_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a door setting snapshot with an absent current value', () {
    final dto = DoorSettingResponseDto.fromJson(const {
      'code': 'LED_OFF_DELAY',
      'label': 'LED off delay',
      'supported': true,
      'configured': false,
      'currentValue': null,
      'unit': 's',
      'ignored': 'value',
    });

    expect(dto.code, 'LED_OFF_DELAY');
    expect(dto.supported, isTrue);
    expect(dto.configured, isFalse);
    expect(dto.currentValue, isNull);
    expect(dto.unit, 's');
  });

  test('fetches settings using the door id and request id', () async {
    final api = _FakeDoorSettingsApi(
      const ApiEnvelopeDto(
        code: 0,
        success: true,
        data: [
          DoorSettingResponseDto(
            code: 'LED_OFF_DELAY',
            label: 'LED off delay',
            supported: true,
            configured: true,
            currentValue: 30,
            unit: 's',
          ),
        ],
      ),
    );
    final dataSource = DoorSettingsRemoteDataSourceImpl(api: api);

    final settings = await dataSource.fetchSettings(
      doorId: 12,
      requestId: 'door-settings-123',
    );

    expect(settings.single.currentValue, 30);
    expect(api.doorId, 12);
    expect(
      api.options.extra?[NetworkRequestExtras.requestId],
      'door-settings-123',
    );
  });

  test('rejects unsuccessful business responses', () async {
    final dataSource = DoorSettingsRemoteDataSourceImpl(
      api: _FakeDoorSettingsApi(
        const ApiEnvelopeDto<List<DoorSettingResponseDto>>(
          code: 500,
          success: false,
        ),
      ),
    );

    expect(
      () =>
          dataSource.fetchSettings(doorId: 12, requestId: 'door-settings-123'),
      throwsA(isA<DoorSettingsRemoteException>()),
    );
  });
}

class _FakeDoorSettingsApi implements DoorSettingsApi {
  _FakeDoorSettingsApi(this.response);

  final ApiEnvelopeDto<List<DoorSettingResponseDto>> response;
  late int doorId;
  late Options options;

  @override
  Future<ApiEnvelopeDto<List<DoorSettingResponseDto>>> fetchSettings(
    int doorId,
    Options options,
  ) async {
    this.doorId = doorId;
    this.options = options;
    return response;
  }
}
