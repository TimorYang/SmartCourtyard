import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/upgrade_dto.dart';

part 'upgrade_api.g.dart';

@RestApi()
abstract class UpgradeApi {
  factory UpgradeApi(Dio dio, {String? baseUrl}) = _UpgradeApi;

  @POST('app/releases/check')
  Future<ApiEnvelopeDto<AppReleaseCheckResponseDto>> checkAppRelease(
    @Body() AppReleaseCheckRequestDto request,
    @DioOptions() Options options,
  );

  @GET('app/firmware/upgrades')
  Future<ApiEnvelopeDto<List<FirmwareUpgradeDoorDto>>> fetchFirmwareUpgrades(
    @DioOptions() Options options,
  );

  @POST('app/firmware/upgrades')
  Future<ApiEnvelopeDto<List<FirmwareUpgradeSubmitResponseDto>>>
  submitFirmwareUpgrades(
    @Body() FirmwareUpgradeSubmitRequestDto request,
    @DioOptions() Options options,
  );
}
