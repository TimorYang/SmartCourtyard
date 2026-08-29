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

  NetworkFailureCategory get category {
    if (kind == NetworkErrorKind.cancelled) {
      return NetworkFailureCategory.cancelled;
    }
    if (kind != NetworkErrorKind.httpStatus) {
      return switch (kind) {
        NetworkErrorKind.connectionTimeout ||
        NetworkErrorKind.sendTimeout ||
        NetworkErrorKind.receiveTimeout ||
        NetworkErrorKind.transformTimeout ||
        NetworkErrorKind.connection ||
        NetworkErrorKind.certificate =>
          NetworkFailureCategory.networkUnavailable,
        NetworkErrorKind.unknown => NetworkFailureCategory.unknown,
        NetworkErrorKind.cancelled => NetworkFailureCategory.cancelled,
        NetworkErrorKind.httpStatus => NetworkFailureCategory.unknown,
      };
    }

    final status = statusCode;
    if (status == 401) return NetworkFailureCategory.sessionExpired;
    if (status == 403) return NetworkFailureCategory.accessDenied;
    if (status == 408) return NetworkFailureCategory.requestTimeout;
    if (status == 429) return NetworkFailureCategory.rateLimited;
    if (status != null && status >= 500 && status <= 599) {
      return NetworkFailureCategory.serviceUnavailable;
    }
    if (status != null && status >= 400 && status <= 499) {
      return NetworkFailureCategory.requestFailed;
    }
    return NetworkFailureCategory.unknown;
  }
}

enum NetworkFailureCategory {
  networkUnavailable,
  sessionExpired,
  accessDenied,
  requestTimeout,
  rateLimited,
  requestFailed,
  serviceUnavailable,
  cancelled,
  unknown,
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
