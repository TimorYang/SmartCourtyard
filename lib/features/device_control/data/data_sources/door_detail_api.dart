import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/door_detail_response_dto.dart';

part 'door_detail_api.g.dart';

@RestApi()
abstract class DoorDetailApi {
  factory DoorDetailApi(Dio dio, {String? baseUrl}) = _DoorDetailApi;

  @GET('app/doors/{doorId}')
  Future<ApiEnvelopeDto<DoorDetailResponseDto>> fetchDoorDetail(
    @Path('doorId') int doorId,
    @DioOptions() Options options,
  );
}
