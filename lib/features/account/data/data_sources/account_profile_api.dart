import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';

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
}
