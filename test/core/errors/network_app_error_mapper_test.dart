import 'package:dio/dio.dart';
import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/errors/network_app_error_mapper.dart';
import 'package:flinx/core/network/network_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps HTTP status categories without using response messages', () {
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
      expect(error.userMessage, isNull);
    }
  });
}
