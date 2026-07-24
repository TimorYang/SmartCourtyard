import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/security_center/data/data_sources/security_balance_refresh_api.dart';
import 'package:flinx/features/security_center/data/data_sources/security_balance_refresh_remote_data_source.dart';
import 'package:flinx/features/security_center/data/dto/security_balance_refresh_response_dto.dart';
import 'package:flinx/features/security_center/data/dto/general_evaluation_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the numeric refresh status returned by the server', () {
    final dto = SecurityBalanceRefreshResponseDto.fromJson(const {
      'requestId': 'bb62bd28-8812-4136-9126-71e6fa2dbb03',
      'status': 1,
      'statusLabel': 'Published',
      'requestedAt': 1784818799850,
    });

    expect(dto.requestId, 'bb62bd28-8812-4136-9126-71e6fa2dbb03');
    expect(dto.status, '1');
    expect(dto.statusLabel, 'Published');
    expect(dto.requestedAt, 1784818799850);
  });

  test('parses the numeric balance status returned by the server', () {
    final dto = BalanceResponseDto.fromJson(const {
      'requestId': 'd7a88fd6-345d-4560-80c3-f4b070eae24e',
      'status': 1,
      'statusLabel': 'Published',
      'hasOverloadOrOvercurrent': false,
      'requestedAt': 1784819049000,
      'reportedAt': null,
      'segments': [],
    });

    expect(dto.status, '1');
    expect(dto.segments, isEmpty);
  });

  test('passes door and request IDs to the refresh API', () async {
    final api = _FakeSecurityBalanceRefreshApi(
      const ApiEnvelopeDto(
        code: 0,
        success: true,
        data: SecurityBalanceRefreshResponseDto(requestId: 'server-request'),
      ),
    );
    final dataSource = SecurityBalanceRefreshRemoteDataSourceImpl(api: api);

    await dataSource.refreshBalance(doorId: 12, requestId: 'refresh-12');

    expect(api.doorId, 12);
    expect(api.options.extra?[NetworkRequestExtras.requestId], 'refresh-12');
  });

  test(
    'accepts a success code even when success and data are absent',
    () async {
      final dataSource = SecurityBalanceRefreshRemoteDataSourceImpl(
        api: _FakeSecurityBalanceRefreshApi(
          const ApiEnvelopeDto<SecurityBalanceRefreshResponseDto>(
            code: 200,
            success: false,
          ),
        ),
      );

      final response = await dataSource.refreshBalance(
        doorId: 12,
        requestId: 'refresh-12',
      );

      expect(response.requestId, isNull);
    },
  );

  test('rejects unsuccessful responses', () async {
    final dataSource = SecurityBalanceRefreshRemoteDataSourceImpl(
      api: _FakeSecurityBalanceRefreshApi(
        const ApiEnvelopeDto<SecurityBalanceRefreshResponseDto>(
          code: 500,
          success: false,
        ),
      ),
    );

    await expectLater(
      dataSource.refreshBalance(doorId: 12, requestId: 'refresh-12'),
      throwsA(isA<SecurityBalanceRefreshRemoteException>()),
    );
  });
}

class _FakeSecurityBalanceRefreshApi implements SecurityBalanceRefreshApi {
  _FakeSecurityBalanceRefreshApi(this.response);

  final ApiEnvelopeDto<SecurityBalanceRefreshResponseDto> response;
  late int doorId;
  late Options options;

  @override
  Future<ApiEnvelopeDto<SecurityBalanceRefreshResponseDto>> refreshBalance(
    int doorId,
    Options options,
  ) async {
    this.doorId = doorId;
    this.options = options;
    return response;
  }
}
