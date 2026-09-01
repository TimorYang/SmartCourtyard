import 'package:dio/dio.dart';

import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import '../dto/notification_message_dto.dart';
import 'notification_message_api.dart';

abstract interface class NotificationMessageRemoteDataSource {
  Future<NotificationMessagePageDto> fetchMessages({
    required int page,
    required int pageSize,
    required String requestId,
  });
  Future<NotificationMessageDetailDto> fetchMessageDetail({
    required String messageId,
    required String requestId,
  });
  Future<void> markAllRead({required String requestId});
  Future<NotificationUnreadStateDto> fetchUnreadState({
    required String requestId,
  });
}

class NotificationMessageRemoteDataSourceImpl
    implements NotificationMessageRemoteDataSource {
  const NotificationMessageRemoteDataSourceImpl({required this.api});

  final NotificationMessageApi api;

  @override
  Future<NotificationMessagePageDto> fetchMessages({
    required int page,
    required int pageSize,
    required String requestId,
  }) async {
    final result = await _call(
      () => api.fetchMessages(page, pageSize, _options(requestId)),
    );
    final current = int.tryParse(result.current);
    final size = int.tryParse(result.size);
    final total = int.tryParse(result.total);
    if (current == null ||
        current < 1 ||
        size == null ||
        size < 1 ||
        total == null ||
        total < 0) {
      throw const NotificationMessageRemoteException.invalidResponse();
    }
    return result;
  }

  @override
  Future<NotificationMessageDetailDto> fetchMessageDetail({
    required String messageId,
    required String requestId,
  }) => _call(() => api.fetchMessageDetail(messageId, _options(requestId)));

  @override
  Future<void> markAllRead({required String requestId}) async {
    await _call<dynamic>(() => api.markAllRead(_options(requestId)));
  }

  @override
  Future<NotificationUnreadStateDto> fetchUnreadState({
    required String requestId,
  }) => _call(() => api.fetchUnreadState(_options(requestId)));

  Options _options(String requestId) =>
      Options(extra: {NetworkRequestExtras.requestId: requestId});

  Future<T> _call<T>(Future<ApiEnvelopeDto<T>> Function() request) async {
    try {
      final response = await request();
      final data = response.data;
      if (!response.isBusinessSuccess) {
        throw NotificationMessageRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const NotificationMessageRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw NotificationMessageRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on NotificationMessageRemoteException {
      rethrow;
    } on FormatException {
      throw const NotificationMessageRemoteException.invalidResponse();
    }
  }
}

class NotificationMessageRemoteException implements Exception {
  const NotificationMessageRemoteException._(
    this.kind, {
    this.network,
    this.businessFailure,
  });
  NotificationMessageRemoteException.fromNetwork(NetworkException exception)
    : this._(NotificationMessageRemoteErrorKind.network, network: exception);
  const NotificationMessageRemoteException.businessFailure(
    ApiBusinessFailure failure,
  ) : this._(
        NotificationMessageRemoteErrorKind.businessFailure,
        businessFailure: failure,
      );
  const NotificationMessageRemoteException.invalidResponse()
    : this._(NotificationMessageRemoteErrorKind.invalidResponse);
  final NotificationMessageRemoteErrorKind kind;
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
  int? get statusCode => network?.statusCode;
}

enum NotificationMessageRemoteErrorKind {
  network,
  businessFailure,
  invalidResponse,
}
