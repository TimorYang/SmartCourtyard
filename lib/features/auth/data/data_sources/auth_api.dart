import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/auth_login_response_dto.dart';
import '../dto/auth_profile_response_dto.dart';
import '../dto/auth_public_key_response_dto.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String? baseUrl}) = _AuthApi;

  @GET('app/auth/crypto/public-key')
  Future<ApiEnvelopeDto<AuthPublicKeyResponseDto>> fetchPublicKey(
    @DioOptions() Options options,
  );

  @POST('app/auth/login')
  Future<ApiEnvelopeDto<AuthLoginResponseDto>> login(
    @Body() Map<String, dynamic> body,
    @DioOptions() Options options,
  );

  @POST('app/auth/refresh')
  Future<ApiEnvelopeDto<AuthLoginResponseDto>> refreshToken(
    @Body() Map<String, dynamic> body,
    @DioOptions() Options options,
  );

  @GET('app/account/profile')
  Future<ApiEnvelopeDto<AuthProfileResponseDto>> fetchAccountProfile(
    @DioOptions() Options options,
  );

  @POST('app/auth/register/email-code')
  Future<ApiEnvelopeDto<dynamic>> sendRegistrationEmailCode(
    @Body() Map<String, dynamic> body,
    @DioOptions() Options options,
  );

  @POST('app/auth/register/verify-code')
  Future<ApiEnvelopeDto<dynamic>> verifyRegistrationEmailCode(
    @Body() Map<String, dynamic> body,
    @DioOptions() Options options,
  );

  @POST('app/auth/register/complete')
  Future<ApiEnvelopeDto<dynamic>> completeRegistration(
    @Body() Map<String, dynamic> body,
    @DioOptions() Options options,
  );

  @POST('app/auth/password-reset/email-code')
  Future<ApiEnvelopeDto<dynamic>> sendPasswordResetEmailCode(
    @Body() Map<String, dynamic> body,
    @DioOptions() Options options,
  );

  @POST('app/auth/password-reset/verify-code')
  Future<ApiEnvelopeDto<dynamic>> verifyPasswordResetEmailCode(
    @Body() Map<String, dynamic> body,
    @DioOptions() Options options,
  );

  @POST('app/auth/password-reset')
  Future<ApiEnvelopeDto<dynamic>> completePasswordReset(
    @Body() Map<String, dynamic> body,
    @DioOptions() Options options,
  );
}
