import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/device_capability_response_dto.dart';

part 'device_capability_api.g.dart';

@RestApi()
abstract class DeviceCapabilityApi {
  factory DeviceCapabilityApi(Dio dio, {String? baseUrl}) =
      _DeviceCapabilityApi;

  @GET('app/devices/{deviceId}/capabilities')
  Future<ApiEnvelopeDto<List<DeviceCapabilityResponseDto>>> fetchCapabilities(
    @Path('deviceId') String deviceId,
    @DioOptions() Options options,
  );
}
