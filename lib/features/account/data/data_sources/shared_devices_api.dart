import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/shared_door_response_dto.dart';
import '../dto/shared_door_members_response_dto.dart';

part 'shared_devices_api.g.dart';

@RestApi()
abstract class SharedDevicesApi {
  factory SharedDevicesApi(Dio dio, {String? baseUrl}) = _SharedDevicesApi;

  @GET('app/door-shares/outgoing/doors')
  Future<ApiEnvelopeDto<List<SharedDoorResponseDto>>> fetchSharedDoors(
    @DioOptions() Options options,
  );

  @GET('app/door-shares/outgoing/doors/{doorId}/users')
  Future<ApiEnvelopeDto<SharedDoorMembersResponseDto>> fetchDoorMembers(
    @Path('doorId') int doorId,
    @DioOptions() Options options,
  );

  @DELETE('app/door-shares/{shareId}')
  Future<ApiEnvelopeDto<dynamic>> deleteDoorMember(
    @Path('shareId') int shareId,
    @DioOptions() Options options,
  );
}
