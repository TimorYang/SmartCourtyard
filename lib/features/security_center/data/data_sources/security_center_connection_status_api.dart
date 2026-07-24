import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/security_center_connection_status_dto.dart';

part 'security_center_connection_status_api.g.dart';

@RestApi()
abstract class SecurityCenterConnectionStatusApi {
  factory SecurityCenterConnectionStatusApi(Dio dio, {String? baseUrl}) =
      _SecurityCenterConnectionStatusApi;

  @GET('app/doors/{doorId}/security/connection-status')
  Future<ApiEnvelopeDto<SecurityCenterConnectionStatusDto>> connectionStatus(
    @Path('doorId') int doorId,
    @DioOptions() Options options,
  );
}
