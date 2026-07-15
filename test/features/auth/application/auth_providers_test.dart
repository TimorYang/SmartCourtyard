import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/data/data_sources/auth_api.dart';
import 'package:flinx/features/auth/data/data_sources/auth_crypto_remote_data_source.dart';
import 'package:flinx/features/auth/data/dto/auth_login_response_dto.dart';
import 'package:flinx/features/auth/data/dto/auth_public_key_response_dto.dart';
import 'package:flinx/features/auth/data/dto/auth_profile_response_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auth dependencies can override the generated API client', () {
    final api = _FakeAuthApi();
    final container = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(api),
        authClientAuthorizationProvider.overrideWithValue('test-client'),
      ],
    );
    addTearDown(container.dispose);

    final dataSource = container.read(authCryptoRemoteDataSourceProvider);

    expect(dataSource, isA<AuthCryptoRemoteDataSourceImpl>());
    expect((dataSource as AuthCryptoRemoteDataSourceImpl).api, same(api));
  });
}

class _FakeAuthApi implements AuthApi {
  @override
  Future<ApiEnvelopeDto<AuthProfileResponseDto>> fetchAccountProfile(
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<AuthLoginResponseDto>> login(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> completeRegistration(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> completePasswordReset(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<AuthPublicKeyResponseDto>> fetchPublicKey(
    Options options,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> sendRegistrationEmailCode(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> sendPasswordResetEmailCode(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> verifyRegistrationEmailCode(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> verifyPasswordResetEmailCode(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();
}
