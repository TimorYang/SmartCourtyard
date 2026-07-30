import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/app_language_option_dto.dart';
import '../dto/app_region_option_dto.dart';
import '../dto/account_profile_remote_dto.dart';

part 'account_profile_api.g.dart';

@RestApi()
abstract class AccountProfileApi {
  factory AccountProfileApi(Dio dio, {String? baseUrl}) = _AccountProfileApi;

  @POST('attachments/images')
  Future<ApiEnvelopeDto<dynamic>> uploadImage(
    @Body() FormData body,
    @DioOptions() Options options,
  );

  @PUT('app/account/profile')
  Future<ApiEnvelopeDto<dynamic>> updateProfile(
    @Body() Map<String, dynamic> body,
    @DioOptions() Options options,
  );

  @GET('app/account/profile')
  Future<ApiEnvelopeDto<AccountProfileRemoteDto>> fetchProfile(
    @DioOptions() Options options,
  );

  @GET('app/account/region-options')
  Future<ApiEnvelopeDto<List<AppRegionOptionDto>>> fetchRegionOptions(
    @DioOptions() Options options,
  );

  @GET('app/account/language-options')
  Future<ApiEnvelopeDto<List<AppLanguageOptionDto>>> fetchLanguageOptions(
    @DioOptions() Options options,
  );

  @POST('app/account/deletion/confirm')
  Future<ApiEnvelopeDto<dynamic>> confirmAccountDeletion(
    @DioOptions() Options options,
  );
}
