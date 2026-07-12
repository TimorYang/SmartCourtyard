import 'package:dio/dio.dart';

import '../logging/app_logger.dart';
import 'dio_factory.dart';

/// Starts a lightweight outbound request so iOS can present its initial
/// per-app network access prompt on devices that support it.
///
/// The result is deliberately not a connectivity verdict: Baidu can be
/// unavailable, and a user can change this setting at any time.
class StartupNetworkAccessProbe {
  factory StartupNetworkAccessProbe({
    required AppLogger logger,
    Dio? dio,
    String Function()? requestIdGenerator,
  }) {
    return StartupNetworkAccessProbe._(
      logger: logger,
      dio: dio,
      requestIdGenerator: requestIdGenerator,
    );
  }

  StartupNetworkAccessProbe._({
    required this._logger,
    Dio? dio,
    String Function()? requestIdGenerator,
  }) : _dio = dio ?? Dio(),
       _target = Uri.https('www.baidu.com'),
       _requestIdGenerator =
           requestIdGenerator ??
           (() => 'startup-network-${DateTime.now().microsecondsSinceEpoch}');

  final Dio _dio;
  final AppLogger _logger;
  final Uri _target;
  final String Function() _requestIdGenerator;

  /// Never throws: app startup must remain available when network access is
  /// declined or unavailable.
  Future<void> trigger() async {
    final requestId = _requestIdGenerator();
    _logger.info('Startup network access probe started.', requestId: requestId);

    try {
      final response = await _dio.getUri<void>(
        _target,
        options: Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
          headers: {NetworkHeaders.requestId: requestId},
          extra: {NetworkRequestExtras.requestId: requestId},
        ),
      );
      _logger.info(
        'Startup network access probe completed.',
        requestId: requestId,
        context: {'statusCode': response.statusCode},
      );
    } on DioException catch (error, stackTrace) {
      _logger.warning(
        'Startup network access probe could not complete.',
        requestId: requestId,
        context: {'errorType': error.type.name},
      );
      _logger.error(
        'Startup network access probe failed.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
