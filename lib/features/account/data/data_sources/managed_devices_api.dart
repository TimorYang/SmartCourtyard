import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/managed_login_device_dto.dart';

part 'managed_devices_api.g.dart';

@RestApi()
abstract class ManagedDevicesApi {
  factory ManagedDevicesApi(Dio dio, {String? baseUrl}) = _ManagedDevicesApi;

  @GET('app/account/login-devices')
  Future<ApiEnvelopeDto<List<ManagedLoginDeviceDto>>> fetchLoginDevices(
    @DioOptions() Options options,
  );

  @DELETE('app/account/login-devices/{sessionId}')
  Future<ApiEnvelopeDto<dynamic>> removeLoginDevice(
    @Path('sessionId') String sessionId,
    @DioOptions() Options options,
  );
}
