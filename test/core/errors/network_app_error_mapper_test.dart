import 'package:dio/dio.dart';
import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/errors/network_app_error_mapper.dart';
import 'package:flinx/core/network/network_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps HTTP 400 business fields to AppError', () {
    final requestOptions = RequestOptions(path: '/test');
    final network = NetworkException.fromDio(
      DioException.badResponse(
        statusCode: 400,
        requestOptions: requestOptions,
        response: Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 400,
          data: const {
            'code': 100001,
            'msg': '  Account or password error.  ',
            'message': 'must not win',
            'messageKey': '  account_or_password_error  ',
          },
        ),
      ),
    );

    final error = mapNetworkExceptionToAppError(
      network,
      requestId: 'request-1',
    );

    expect(error.code, AppErrorCode.serverError);
    expect(error.messageKey, 'networkErrorRequestFailed');
    expect(error.businessCode, 100001);
    expect(error.businessMessageKey, 'account_or_password_error');
    expect(error.userMessage, 'Account or password error.');
  });

  test('HTTP 400 uses message when msg is blank', () {
    final requestOptions = RequestOptions(path: '/test');
    final network = NetworkException.fromDio(
      DioException.badResponse(
        statusCode: 400,
        requestOptions: requestOptions,
        response: Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 400,
          data: const {'msg': '   ', 'message': ' Fallback message '},
        ),
      ),
    );

    final error = mapNetworkExceptionToAppError(
      network,
      requestId: 'request-1',
    );

    expect(error.userMessage, 'Fallback message');
  });

  test('HTTP 400 malformed response data keeps the local fallback', () {
    for (final data in <Object?>[
      'not-json',
      const {'msg': 7, 'message': false, 'code': '100001'},
      const {'msg': '   ', 'message': '\n'},
    ]) {
      final requestOptions = RequestOptions(path: '/test');
      final network = NetworkException.fromDio(
        DioException.badResponse(
          statusCode: 400,
          requestOptions: requestOptions,
          response: Response<dynamic>(
            requestOptions: requestOptions,
            statusCode: 400,
            data: data,
          ),
        ),
      );
      final error = mapNetworkExceptionToAppError(
        network,
        requestId: 'request-1',
      );

      expect(error.messageKey, 'networkErrorRequestFailed');
      expect(error.businessCode, isNull);
      expect(error.businessMessageKey, isNull);
      expect(error.userMessage, isNull);
    }
  });

  test('maps non-400 HTTP status categories without response messages', () {
    final expectations = <int, (AppErrorCode, String, bool)>{
      401: (AppErrorCode.accessDenied, 'networkErrorSessionExpired', false),
      403: (AppErrorCode.accessDenied, 'networkErrorAccessDenied', false),
      408: (AppErrorCode.serverError, 'networkErrorRequestTimeout', true),
      429: (AppErrorCode.serverError, 'networkErrorRateLimited', true),
      422: (AppErrorCode.serverError, 'networkErrorRequestFailed', false),
      503: (AppErrorCode.serverError, 'networkErrorServiceUnavailable', true),
    };

    for (final entry in expectations.entries) {
      final network = NetworkException.fromDio(
        DioException.badResponse(
          statusCode: entry.key,
          requestOptions: RequestOptions(path: '/test'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: entry.key,
            data: const {'msg': 'must not be shown'},
          ),
        ),
      );
      final error = mapNetworkExceptionToAppError(
        network,
        requestId: 'request-1',
      );

      expect(error.code, entry.value.$1);
      expect(error.messageKey, entry.value.$2);
      expect(error.retryable, entry.value.$3);
      expect(error.businessCode, isNull);
      expect(error.businessMessageKey, isNull);
      expect(error.userMessage, isNull);
    }
  });
}
