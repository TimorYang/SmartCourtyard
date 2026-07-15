import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/auth/data/data_sources/auth_api.dart';
import 'package:flinx/features/auth/data/data_sources/auth_password_reset_remote_data_source.dart';
import 'package:flinx/features/auth/data/dto/auth_login_response_dto.dart';
import 'package:flinx/features/auth/data/dto/auth_profile_response_dto.dart';
import 'package:flinx/features/auth/data/dto/auth_public_key_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'sends password-reset requests with protected request metadata',
    () async {
      final api = _FakeAuthApi();
      final dataSource = AuthPasswordResetRemoteDataSourceImpl(
        api: api,
        clientAuthorization: 'encoded-client-credentials',
      );

      await dataSource.sendEmailCode(
        email: 'alice@example.com',
        requestId: 'send-request',
      );
      final verification = await dataSource.verifyEmailCode(
        email: 'alice@example.com',
        code: '012345',
        requestId: 'verify-request',
      );
      await dataSource.completePasswordReset(
        requestId: 'reset-request',
        request: const {
          'keyId': 'app-password-key-v1',
          'nonce': 'nonce',
          'passwordResetToken': 'one-time-token',
          'newPasswordCiphertext': 'new-ciphertext',
          'confirmPasswordCiphertext': 'confirm-ciphertext',
        },
      );

      expect(api.sendBody, {'email': 'alice@example.com'});
      expect(api.verifyBody, {'email': 'alice@example.com', 'code': '012345'});
      expect(verification.passwordResetToken, 'one-time-token');
      expect(verification.expiresIn, const Duration(seconds: 600));
      expect(
        api.completeBody,
        containsPair('passwordResetToken', 'one-time-token'),
      );
      for (final options in api.options) {
        expect(
          options.headers?['authorization'],
          'Basic encoded-client-credentials',
        );
        expect(options.extra?[NetworkRequestExtras.requestId], isNotEmpty);
      }
    },
  );

  test('rejects a failed response envelope', () async {
    final dataSource = AuthPasswordResetRemoteDataSourceImpl(
      api: _FakeAuthApi(
        sendResponse: const ApiEnvelopeDto(code: 200, success: false),
      ),
      clientAuthorization: 'encoded-client-credentials',
    );

    expect(
      () =>
          dataSource.sendEmailCode(email: 'alice@example.com', requestId: 'id'),
      throwsA(isA<AuthPasswordResetRemoteException>()),
    );
  });

  test('maps a Dio error into the password-reset remote exception', () async {
    final requestOptions = RequestOptions(
      path: 'app/auth/password-reset/email-code',
    );
    final dataSource = AuthPasswordResetRemoteDataSourceImpl(
      api: _FakeAuthApi(
        error: DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        ),
      ),
      clientAuthorization: 'encoded-client-credentials',
    );

    expect(
      () =>
          dataSource.sendEmailCode(email: 'alice@example.com', requestId: 'id'),
      throwsA(
        isA<AuthPasswordResetRemoteException>().having(
          (error) => error.kind,
          'kind',
          AuthPasswordResetRemoteErrorKind.network,
        ),
      ),
    );
  });
}

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi({
    this.sendResponse = const ApiEnvelopeDto(code: 200, success: true),
    this.error,
  });

  final ApiEnvelopeDto<dynamic> sendResponse;
  final DioException? error;
  final options = <Options>[];
  Map<String, dynamic>? sendBody;
  Map<String, dynamic>? verifyBody;
  Map<String, dynamic>? completeBody;

  @override
  Future<ApiEnvelopeDto<dynamic>> completePasswordReset(
    Map<String, dynamic> body,
    Options requestOptions,
  ) async {
    completeBody = body;
    options.add(requestOptions);
    return const ApiEnvelopeDto(code: 200, success: true);
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> completeRegistration(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<AuthProfileResponseDto>> fetchAccountProfile(
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<AuthPublicKeyResponseDto>> fetchPublicKey(
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<AuthLoginResponseDto>> login(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> sendPasswordResetEmailCode(
    Map<String, dynamic> body,
    Options requestOptions,
  ) async {
    sendBody = body;
    options.add(requestOptions);
    if (error != null) throw error!;
    return sendResponse;
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> sendRegistrationEmailCode(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> verifyPasswordResetEmailCode(
    Map<String, dynamic> body,
    Options requestOptions,
  ) async {
    verifyBody = body;
    options.add(requestOptions);
    return const ApiEnvelopeDto(
      code: 200,
      success: true,
      data: {'passwordResetToken': 'one-time-token', 'expiresIn': '600'},
    );
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> verifyRegistrationEmailCode(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();
}
