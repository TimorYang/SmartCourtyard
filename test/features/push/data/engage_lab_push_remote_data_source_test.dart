import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flinx/core/config/app_api_configuration.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/push/data/data_sources/engage_lab_push_api.dart';
import 'package:flinx/features/push/data/data_sources/engage_lab_push_remote_data_source.dart';
import 'package:flinx/features/push/data/dto/engage_lab_registration_request_dto.dart';
import 'package:flinx/features/push/domain/entities/push_registration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'sends the documented Retrofit methods, path, body, and request id',
    () async {
      final adapter = _CapturingAdapter();
      final dio = DioFactory.create(
        configuration: const AppApiConfiguration(
          apiOrigin: 'https://api.flinx.example',
          apiPathPrefix: '/api/force-door',
        ),
        logger: const _TestLogger(),
      )..httpClientAdapter = adapter;
      final dataSource = EngageLabPushRemoteDataSourceImpl(
        api: EngageLabPushApi(dio),
      );

      await dataSource.bind(
        registration: _registration,
        requestId: 'push-bind-http',
      );

      final bindOptions = adapter.requests.single;
      expect(bindOptions.method, 'PUT');
      expect(
        bindOptions.uri.toString(),
        'https://api.flinx.example/api/force-door/app/push/engagelab/registration-id',
      );
      expect(bindOptions.data, {
        'registrationId': 'registration-1',
        'deviceId': 'device-1',
        'platform': 'ANDROID',
      });
      expect(bindOptions.headers[NetworkHeaders.requestId], 'push-bind-http');

      await dataSource.unbind(requestId: 'push-unbind-http');

      final unbindOptions = adapter.requests.last;
      expect(unbindOptions.method, 'DELETE');
      expect(
        unbindOptions.uri.toString(),
        'https://api.flinx.example/api/force-door/app/push/engagelab/registration-id',
      );
      expect(unbindOptions.data, isNull);
      expect(
        unbindOptions.headers[Headers.contentTypeHeader],
        Headers.formUrlEncodedContentType,
      );
      expect(
        unbindOptions.headers[NetworkHeaders.requestId],
        'push-unbind-http',
      );
    },
  );

  test(
    'binds the registration payload and preserves request metadata',
    () async {
      final api = _FakeEngageLabPushApi();
      final dataSource = EngageLabPushRemoteDataSourceImpl(api: api);

      await dataSource.bind(
        registration: const PushRegistration(
          registrationId: 'registration-1',
          deviceId: 'device-1',
          platform: PushPlatform.ios,
        ),
        requestId: 'push-bind-123',
      );

      expect(api.bindRequest?.toJson(), {
        'registrationId': 'registration-1',
        'deviceId': 'device-1',
        'platform': 'IOS',
      });
      expect(
        api.bindOptions?.extra?[NetworkRequestExtras.requestId],
        'push-bind-123',
      );
      expect(
        api.bindOptions?.extra?[NetworkRequestExtras.logTag],
        AppLogTag.push,
      );
    },
  );

  test('unbinds without a body using form-url-encoded content type', () async {
    final api = _FakeEngageLabPushApi();
    final dataSource = EngageLabPushRemoteDataSourceImpl(api: api);

    await dataSource.unbind(requestId: 'push-unbind-123');

    expect(api.unbindOptions?.contentType, Headers.formUrlEncodedContentType);
    expect(api.unbindOptions?.extra, {
      NetworkRequestExtras.requestId: 'push-unbind-123',
      NetworkRequestExtras.logTag: AppLogTag.push,
    });
  });

  test('accepts a successful response without response data', () async {
    final api = _FakeEngageLabPushApi(bindData: null, unbindData: null);
    final dataSource = EngageLabPushRemoteDataSourceImpl(api: api);

    await dataSource.bind(
      registration: _registration,
      requestId: 'push-bind-200',
    );
    await dataSource.unbind(requestId: 'push-unbind-200');
  });

  test('ignores response data for a successful write operation', () async {
    final api = _FakeEngageLabPushApi();
    final dataSource = EngageLabPushRemoteDataSourceImpl(api: api);

    await dataSource.bind(
      registration: _registration,
      requestId: 'push-bind-200',
    );
    await dataSource.unbind(requestId: 'push-unbind-200');
  });

  test('rejects obsolete business code zero', () async {
    final api = _FakeEngageLabPushApi(bindCode: 0);
    final dataSource = EngageLabPushRemoteDataSourceImpl(api: api);

    await expectLater(
      dataSource.bind(registration: _registration, requestId: 'push-bind-0'),
      throwsA(
        isA<EngageLabPushRemoteException>().having(
          (error) => error.kind,
          'kind',
          EngageLabPushRemoteErrorKind.businessFailure,
        ),
      ),
    );
  });

  test('rejects a response whose success flag is false', () async {
    final api = _FakeEngageLabPushApi(bindSuccess: false);
    final dataSource = EngageLabPushRemoteDataSourceImpl(api: api);

    await expectLater(
      dataSource.bind(
        registration: _registration,
        requestId: 'push-bind-false',
      ),
      throwsA(isA<EngageLabPushRemoteException>()),
    );
  });

  test('converts network failures to a feature remote exception', () async {
    final api = _FakeEngageLabPushApi(
      bindError: DioException(
        requestOptions: RequestOptions(
          path: 'app/push/engagelab/registration-id',
        ),
        type: DioExceptionType.connectionError,
      ),
    );
    final dataSource = EngageLabPushRemoteDataSourceImpl(api: api);

    await expectLater(
      dataSource.bind(
        registration: _registration,
        requestId: 'push-bind-network',
      ),
      throwsA(
        isA<EngageLabPushRemoteException>().having(
          (error) => error.kind,
          'kind',
          EngageLabPushRemoteErrorKind.network,
        ),
      ),
    );
  });
}

const _registration = PushRegistration(
  registrationId: 'registration-1',
  deviceId: 'device-1',
  platform: PushPlatform.android,
);

class _FakeEngageLabPushApi implements EngageLabPushApi {
  _FakeEngageLabPushApi({
    int bindCode = 200,
    bool bindSuccess = true,
    Object? bindData = true,
    Object? unbindData = true,
    this.bindError,
  }) : bindResponse = ApiEnvelopeDto<dynamic>(
         code: bindCode,
         success: bindSuccess,
         data: bindData,
       ),
       unbindResponse = ApiEnvelopeDto<dynamic>(
         code: 200,
         success: true,
         data: unbindData,
       );

  final ApiEnvelopeDto<dynamic> bindResponse;
  final ApiEnvelopeDto<dynamic> unbindResponse;
  final Object? bindError;
  EngageLabRegistrationRequestDto? bindRequest;
  Options? bindOptions;
  Options? unbindOptions;

  @override
  Future<ApiEnvelopeDto<dynamic>> bindRegistrationId(
    EngageLabRegistrationRequestDto request,
    Options options,
  ) async {
    bindRequest = request;
    bindOptions = options;
    if (bindError != null) throw bindError!;
    return bindResponse;
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> unbindRegistrationId(Options options) async {
    unbindOptions = options;
    return unbindResponse;
  }
}

class _CapturingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'code': 200, 'success': true, 'data': null}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _TestLogger implements AppLogger {
  const _TestLogger();

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
}
