import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/auth/data/data_sources/auth_api.dart';
import 'package:flinx/features/auth/data/data_sources/auth_registration_remote_data_source.dart';
import 'package:flinx/features/auth/data/dto/auth_login_response_dto.dart';
import 'package:flinx/features/auth/data/dto/auth_profile_response_dto.dart';
import 'package:flinx/features/auth/data/dto/auth_public_key_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'sends registration requests with the client authorization and request id',
    () async {
      final api = _FakeAuthApi();
      final dataSource = AuthRegistrationRemoteDataSourceImpl(
        api: api,
        clientAuthorization: 'c2FiZXI6c2FiZXJfc2VjcmV0',
      );

      await dataSource.sendEmailCode(
        email: 'alice@example.com',
        requestId: 'send-request',
      );
      final verification = await dataSource.verifyEmailCode(
        email: 'alice@example.com',
        code: '123456',
        requestId: 'verify-request',
      );
      await dataSource.completeRegistration(
        requestId: 'complete-request',
        request: const {
          'registrationToken': 'one-time-token',
          'passwordCiphertext': 'ciphertext',
        },
      );

      expect(api.sentEmailBody, {'email': 'alice@example.com'});
      expect(api.verifyBody, {'email': 'alice@example.com', 'code': 123456});
      expect(verification.registrationToken, 'one-time-token');
      expect(verification.expiresIn, const Duration(seconds: 300));
      expect(api.completedBody, isNot(contains('nickname')));
      for (final options in api.options) {
        expect(
          options.headers?['authorization'],
          'Basic c2FiZXI6c2FiZXJfc2VjcmV0',
        );
        expect(options.extra?[NetworkRequestExtras.requestId], isNotEmpty);
      }
    },
  );
}

class _FakeAuthApi implements AuthApi {
  final options = <Options>[];
  Map<String, dynamic>? sentEmailBody;
  Map<String, dynamic>? verifyBody;
  Map<String, dynamic>? completedBody;

  @override
  Future<ApiEnvelopeDto<AuthProfileResponseDto>> fetchAccountProfile(
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<AuthLoginResponseDto>> login(
    Map<String, dynamic> body,
    Options requestOptions,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> completeRegistration(
    Map<String, dynamic> body,
    Options requestOptions,
  ) async {
    completedBody = body;
    options.add(requestOptions);
    return const ApiEnvelopeDto(code: 200, success: true, data: true);
  }

  @override
  Future<ApiEnvelopeDto<AuthPublicKeyResponseDto>> fetchPublicKey(
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> sendRegistrationEmailCode(
    Map<String, dynamic> body,
    Options requestOptions,
  ) async {
    sentEmailBody = body;
    options.add(requestOptions);
    return const ApiEnvelopeDto(code: 200, success: true, data: true);
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> verifyRegistrationEmailCode(
    Map<String, dynamic> body,
    Options requestOptions,
  ) async {
    verifyBody = body;
    options.add(requestOptions);
    return const ApiEnvelopeDto(
      code: 200,
      success: true,
      data: {'registrationToken': 'one-time-token', 'expiresIn': '300'},
    );
  }
}
