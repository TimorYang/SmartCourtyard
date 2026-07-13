import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/create_home_scene_request_dto.dart';
import '../dto/home_scene_response_dto.dart';

part 'home_api.g.dart';

@RestApi()
abstract class HomeApi {
  factory HomeApi(Dio dio, {String? baseUrl}) = _HomeApi;

  @GET('app/scenes')
  Future<ApiEnvelopeDto<List<HomeSceneResponseDto>>> fetchScenes(
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
