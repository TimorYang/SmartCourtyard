import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/door_setting_response_dto.dart';

part 'door_settings_api.g.dart';

@RestApi()
abstract class DoorSettingsApi {
  factory DoorSettingsApi(Dio dio, {String? baseUrl}) = _DoorSettingsApi;

  @GET('app/doors/{doorId}/settings')
  Future<ApiEnvelopeDto<List<DoorSettingResponseDto>>> fetchSettings(
    @Path('doorId') int doorId,
    @DioOptions() Options options,
  );
}
