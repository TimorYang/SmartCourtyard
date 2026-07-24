import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/add_force_door_request_dto.dart';
import '../dto/binding_status_response_dto.dart';
import '../dto/force_door_response_dto.dart';
import '../dto/onboarding_device_key_response_dto.dart';

part 'add_device_onboarding_api.g.dart';

@RestApi()
abstract class AddDeviceOnboardingApi {
  factory AddDeviceOnboardingApi(Dio dio, {String? baseUrl}) =
      _AddDeviceOnboardingApi;

  @GET('app/doors/onboarding/binding-status')
  Future<ApiEnvelopeDto<BindingStatusResponseDto>> validateBindingStatus(
    @Query('sn') String sn,
    @DioOptions() Options options,
  );

  @GET('app/doors/onboarding/device-key')
  Future<ApiEnvelopeDto<OnboardingDeviceKeyResponseDto>> fetchDeviceKey(
    @Query('sn') String sn,
    @DioOptions() Options options,
  );

  @POST('app/doors/onboarding/force')
  Future<ApiEnvelopeDto<ForceDoorResponseDto>> addForceDoor(
    @Body() AddForceDoorRequestDto request,
    @DioOptions() Options options,
  );
}
