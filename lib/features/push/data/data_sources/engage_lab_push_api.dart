import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:retrofit/retrofit.dart' as retrofit;

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/engage_lab_registration_request_dto.dart';

part 'engage_lab_push_api.g.dart';

@RestApi()
abstract class EngageLabPushApi {
  factory EngageLabPushApi(Dio dio, {String? baseUrl}) = _EngageLabPushApi;

  @PUT('app/push/engagelab/registration-id')
  Future<ApiEnvelopeDto<dynamic>> bindRegistrationId(
    @Body() EngageLabRegistrationRequestDto request,
    @DioOptions() Options options,
  );

  @DELETE('app/push/engagelab/registration-id')
  @retrofit.Headers(<String, dynamic>{
    'Content-Type': 'application/x-www-form-urlencoded',
  })
  Future<ApiEnvelopeDto<dynamic>> unbindRegistrationId(
    @DioOptions() Options options,
  );
}
