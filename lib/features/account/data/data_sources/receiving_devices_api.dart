import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/receiving_door_response_dto.dart';

part 'receiving_devices_api.g.dart';

@RestApi()
abstract class ReceivingDevicesApi {
  factory ReceivingDevicesApi(Dio dio, {String? baseUrl}) =
      _ReceivingDevicesApi;

  @GET('app/door-shares/incoming')
  Future<ApiEnvelopeDto<List<ReceivingDoorResponseDto>>> fetchReceivingDoors(
    @DioOptions() Options options,
  );
}
