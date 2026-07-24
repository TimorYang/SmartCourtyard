import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/security_balance_refresh_response_dto.dart';

part 'security_balance_refresh_api.g.dart';

@RestApi()
abstract class SecurityBalanceRefreshApi {
  factory SecurityBalanceRefreshApi(Dio dio, {String? baseUrl}) =
      _SecurityBalanceRefreshApi;

  @FormUrlEncoded()
  @POST('app/doors/{doorId}/security/balance/refresh')
  Future<ApiEnvelopeDto<SecurityBalanceRefreshResponseDto>> refreshBalance(
    @Path('doorId') int doorId,
    @DioOptions() Options options,
  );
}
