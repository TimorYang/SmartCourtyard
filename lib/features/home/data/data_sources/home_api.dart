import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/create_home_scene_request_dto.dart';
import '../dto/attachment_upload_result_dto.dart';
import '../dto/door_share_dto.dart';
import '../dto/home_door_response_dto.dart';
import '../dto/home_scene_response_dto.dart';
import '../dto/move_home_door_scene_request_dto.dart';
import '../dto/rename_home_door_request_dto.dart';
import '../dto/update_home_door_cover_request_dto.dart';

part 'home_api.g.dart';

@RestApi()
abstract class HomeApi {
  factory HomeApi(Dio dio, {String? baseUrl}) = _HomeApi;

  @GET('app/scenes')
  Future<ApiEnvelopeDto<List<HomeSceneResponseDto>>> fetchScenes(
    @DioOptions() Options options,
  );

  @GET('app/doors')
  Future<ApiEnvelopeDto<List<HomeDoorResponseDto>>> fetchDoors(
    @Query('sceneId') int sceneId,
    @DioOptions() Options options,
  );

  @GET('app/door-shares/outgoing/doors/{doorId}/capabilities')
  Future<ApiEnvelopeDto<List<ShareCapabilityResponseDto>>>
  fetchDoorShareCapabilities(
    @Path('doorId') int doorId,
    @DioOptions() Options options,
  );

  @POST('app/door-shares/outgoing/doors/{doorId}/users')
  Future<ApiEnvelopeDto<DoorShareRecipientResponseDto>> createDoorShare(
    @Path('doorId') int doorId,
    @Body() CreateDoorShareRequestDto request,
    @DioOptions() Options options,
  );

  @PUT('app/door-shares/outgoing/{shareId}')
  Future<ApiEnvelopeDto<dynamic>> updateDoorShare(
    @Path('shareId') int shareId,
    @Body() UpdateDoorShareRequestDto request,
    @DioOptions() Options options,
  );

  @PUT('app/doors/{doorId}/top')
  Future<ApiEnvelopeDto<bool>> topDoor(
    @Path('doorId') int doorId,
    @DioOptions() Options options,
  );

  @DELETE('app/doors/{doorId}')
  Future<ApiEnvelopeDto<bool>> unbindDoor(
    @Path('doorId') int doorId,
    @DioOptions() Options options,
  );

  @PUT('app/doors/{doorId}/cover/default')
  Future<ApiEnvelopeDto<bool>> resetDoorCover(
    @Path('doorId') int doorId,
    @DioOptions() Options options,
  );

  @POST('attachments/images')
  Future<ApiEnvelopeDto<AttachmentUploadResultDto>> uploadDoorCoverImage(
    @Body() FormData formData,
    @DioOptions() Options options,
  );

  @PUT('app/doors/{doorId}/cover')
  Future<ApiEnvelopeDto<bool>> updateDoorCover(
    @Path('doorId') int doorId,
    @Body() UpdateHomeDoorCoverRequestDto request,
    @DioOptions() Options options,
  );

  @PUT('app/doors/{doorId}/name')
  Future<ApiEnvelopeDto<bool>> renameDoor(
    @Path('doorId') int doorId,
    @Body() RenameHomeDoorRequestDto request,
    @DioOptions() Options options,
  );

  @PUT('app/doors/{doorId}/scene')
  Future<ApiEnvelopeDto<bool>> moveDoorToScene(
    @Path('doorId') int doorId,
    @Body() MoveHomeDoorSceneRequestDto request,
    @DioOptions() Options options,
  );

  @POST('app/scenes')
  Future<ApiEnvelopeDto<HomeSceneResponseDto>> createScene(
    @Body() CreateHomeSceneRequestDto request,
    @DioOptions() Options options,
  );

  @DELETE('app/scenes/{sceneId}')
  Future<ApiEnvelopeDto<dynamic>> deleteScene(
    @Path('sceneId') int sceneId,
    @DioOptions() Options options,
  );

  @PUT('app/scenes/{sceneId}/name')
  Future<ApiEnvelopeDto<bool>> renameScene(
    @Path('sceneId') int sceneId,
    @Body() CreateHomeSceneRequestDto request,
    @DioOptions() Options options,
  );
}
