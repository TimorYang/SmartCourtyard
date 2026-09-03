import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/update_door_control_mode_request_dto.dart';

part 'door_control_mode_api.g.dart';

@RestApi()
abstract class DoorControlModeApi {
  factory DoorControlModeApi(Dio dio, {String? baseUrl}) = _DoorControlModeApi;

  @PUT('app/doors/control-mode')
  Future<ApiEnvelopeDto<dynamic>> updateControlMode(
    @Body() UpdateDoorControlModeRequestDto request,
    @DioOptions() Options options,
  );
}
