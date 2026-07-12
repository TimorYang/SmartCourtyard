import 'package:dio/dio.dart';

class NetworkException implements Exception {
  const NetworkException._(this.kind, {this.statusCode});

  factory NetworkException.fromDio(DioException exception) {
    return switch (exception.type) {
      DioExceptionType.connectionTimeout => const NetworkException._(
        NetworkErrorKind.connectionTimeout,
      ),
      DioExceptionType.sendTimeout => const NetworkException._(
        NetworkErrorKind.sendTimeout,
      ),
      DioExceptionType.receiveTimeout => const NetworkException._(
        NetworkErrorKind.receiveTimeout,
      ),
      DioExceptionType.transformTimeout => const NetworkException._(
        NetworkErrorKind.transformTimeout,
      ),
      DioExceptionType.cancel => const NetworkException._(
        NetworkErrorKind.cancelled,
      ),
      DioExceptionType.connectionError => const NetworkException._(
        NetworkErrorKind.connection,
      ),
      DioExceptionType.badResponse => NetworkException._(
        NetworkErrorKind.httpStatus,
        statusCode: exception.response?.statusCode,
      ),
      DioExceptionType.badCertificate => const NetworkException._(
        NetworkErrorKind.certificate,
      ),
      DioExceptionType.unknown => const NetworkException._(
        NetworkErrorKind.unknown,
      ),
    };
  }

  final NetworkErrorKind kind;
  final int? statusCode;
}

enum NetworkErrorKind {
  connectionTimeout,
  sendTimeout,
  receiveTimeout,
  transformTimeout,
  cancelled,
  connection,
  httpStatus,
  certificate,
  unknown,
}
