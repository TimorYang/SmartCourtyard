import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/settings/data/data_sources/auto_close_check_api.dart';
import 'package:flinx/features/settings/data/data_sources/auto_close_check_remote_data_source.dart';
import 'package:flinx/features/settings/data/dto/auto_close_check_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the allowed flag and preserves optional protocol fields', () {
    final dto = AutoCloseCheckResponseDto.fromJson(const {
      'autoCloseAllowed': true,
      'deviceRegionVersion': 'EUROPE_AUSTRALIA',
      'deviceRegionVersionLabel': '欧澳',
      'wirelessInfraredStatus': '1',
      'wirelessInfraredStatusLabel': 'Not triggered',
      'unknownField': 'ignored',
    });

    expect(dto.autoCloseAllowed, isTrue);
    expect(dto.deviceRegionVersion, 'EUROPE_AUSTRALIA');
    expect(dto.wirelessInfraredStatusLabel, 'Not triggered');
  });

  test('parses false and treats missing or invalid flags as null', () {
    expect(
      AutoCloseCheckResponseDto.fromJson(const {
        'autoCloseAllowed': false,
      }).autoCloseAllowed,
      isFalse,
    );
    expect(
      AutoCloseCheckResponseDto.fromJson(const {}).autoCloseAllowed,
      isNull,
    );
    expect(
      AutoCloseCheckResponseDto.fromJson(const {
        'autoCloseAllowed': 'false',
      }).autoCloseAllowed,
      isNull,
    );
  });

  test('passes path parameters and request id to the API', () async {
    final api = _FakeAutoCloseCheckApi(
      const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: AutoCloseCheckResponseDto(autoCloseAllowed: true),
      ),
    );
    final dataSource = AutoCloseCheckRemoteDataSourceImpl(api: api);

    final result = await dataSource.checkAutoClose(
      doorId: 10001,
      deviceId: 20001,
      requestId: 'auto-close-check-123',
    );

    expect(result.autoCloseAllowed, isTrue);
    expect(api.doorId, 10001);
    expect(api.deviceId, 20001);
    expect(
      api.options.extra?[NetworkRequestExtras.requestId],
      'auto-close-check-123',
    );
  });

  test('rejects a failed business response', () async {
    final dataSource = AutoCloseCheckRemoteDataSourceImpl(
      api: _FakeAutoCloseCheckApi(
        const ApiEnvelopeDto<AutoCloseCheckResponseDto>(
          code: 500,
          success: false,
        ),
      ),
    );

    expect(
      () => dataSource.checkAutoClose(
        doorId: 10001,
        deviceId: 20001,
        requestId: 'auto-close-check-failed',
      ),
      throwsA(
        isA<AutoCloseCheckRemoteException>().having(
          (error) => error.kind,
          'kind',
          AutoCloseCheckRemoteErrorKind.businessFailure,
        ),
      ),
    );
  });

  test('rejects empty data and an invalid allowed flag', () async {
    final emptyData = AutoCloseCheckRemoteDataSourceImpl(
      api: _FakeAutoCloseCheckApi(
        const ApiEnvelopeDto<AutoCloseCheckResponseDto>(
          code: 200,
          success: true,
        ),
      ),
    );
    final invalidFlag = AutoCloseCheckRemoteDataSourceImpl(
      api: _FakeAutoCloseCheckApi(
        const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: AutoCloseCheckResponseDto(autoCloseAllowed: null),
        ),
      ),
    );

    for (final dataSource in [emptyData, invalidFlag]) {
      expect(
        () => dataSource.checkAutoClose(
          doorId: 10001,
          deviceId: 20001,
          requestId: 'auto-close-check-invalid',
        ),
        throwsA(
          isA<AutoCloseCheckRemoteException>().having(
            (error) => error.kind,
            'kind',
            AutoCloseCheckRemoteErrorKind.invalidResponse,
          ),
        ),
      );
    }
  });

  test('maps Dio failures to a network remote exception', () async {
    final dataSource = AutoCloseCheckRemoteDataSourceImpl(
      api: _FakeAutoCloseCheckApi(
        DioException(
          requestOptions: RequestOptions(path: 'auto-close/check'),
          type: DioExceptionType.connectionError,
        ),
      ),
    );

    expect(
      () => dataSource.checkAutoClose(
        doorId: 10001,
        deviceId: 20001,
        requestId: 'auto-close-check-network',
      ),
      throwsA(
        isA<AutoCloseCheckRemoteException>().having(
          (error) => error.kind,
          'kind',
          AutoCloseCheckRemoteErrorKind.network,
        ),
      ),
    );
  });
}

class _FakeAutoCloseCheckApi implements AutoCloseCheckApi {
  _FakeAutoCloseCheckApi(this.result);

  final Object result;
  late int doorId;
  late int deviceId;
  late Options options;

  @override
  Future<ApiEnvelopeDto<AutoCloseCheckResponseDto>> checkAutoClose(
    int doorId,
    int deviceId,
    Options options,
  ) async {
    this.doorId = doorId;
    this.deviceId = deviceId;
    this.options = options;
    if (result is DioException) {
      throw result;
    }
    return result as ApiEnvelopeDto<AutoCloseCheckResponseDto>;
  }
}
