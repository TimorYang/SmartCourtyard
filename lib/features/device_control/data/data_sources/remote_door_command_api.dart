import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/remote_door_command_request_dto.dart';
import '../dto/remote_door_command_response_dto.dart';

part 'remote_door_command_api.g.dart';

@RestApi()
abstract class RemoteDoorCommandApi {
  factory RemoteDoorCommandApi(Dio dio, {String? baseUrl}) =
      _RemoteDoorCommandApi;

  @POST('app/doors/{doorId}/commands')
  Future<ApiEnvelopeDto<RemoteDoorCommandResponseDto>> submitCommand(
    @Path('doorId') int doorId,
    @Body() RemoteDoorCommandRequestDto body,
    @DioOptions() Options options,
  );
}
