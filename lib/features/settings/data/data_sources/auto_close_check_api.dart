import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/auto_close_check_response_dto.dart';

part 'auto_close_check_api.g.dart';

@RestApi()
abstract class AutoCloseCheckApi {
  factory AutoCloseCheckApi(Dio dio, {String? baseUrl}) = _AutoCloseCheckApi;

  @GET('app/doors/{doorId}/devices/{deviceId}/auto-close/check')
  Future<ApiEnvelopeDto<AutoCloseCheckResponseDto>> checkAutoClose(
    @Path('doorId') int doorId,
    @Path('deviceId') int deviceId,
    @DioOptions() Options options,
  );
}
