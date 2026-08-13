import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/notification_message_dto.dart';

part 'notification_message_api.g.dart';

@RestApi()
abstract class NotificationMessageApi {
  factory NotificationMessageApi(Dio dio, {String? baseUrl}) =
      _NotificationMessageApi;

  @GET('app/messages')
  Future<ApiEnvelopeDto<NotificationMessagePageDto>> fetchMessages(
    @Query('current') int current,
    @Query('size') int size,
    @DioOptions() Options options,
  );

  @GET('app/messages/{messageId}')
  Future<ApiEnvelopeDto<NotificationMessageDetailDto>> fetchMessageDetail(
    @Path('messageId') String messageId,
    @DioOptions() Options options,
  );

  @PUT('app/messages/read-all')
  Future<ApiEnvelopeDto<bool>> markAllRead(@DioOptions() Options options);

  @GET('app/messages/unread-state')
  Future<ApiEnvelopeDto<NotificationUnreadStateDto>> fetchUnreadState(
    @DioOptions() Options options,
  );
}
