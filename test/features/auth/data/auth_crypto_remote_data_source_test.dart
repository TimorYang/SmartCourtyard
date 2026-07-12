import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/auth/data/data_sources/auth_api.dart';
import 'package:flinx/features/auth/data/data_sources/auth_crypto_remote_data_source.dart';
import 'package:flinx/features/auth/data/dto/auth_public_key_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gets and validates the RSA public key response', () async {
    final api = _FakeAuthApi(
      const ApiEnvelopeDto(
        code: 200,
        success: true,
        data: AuthPublicKeyResponseDto(
          keyId: 'app-password-key-v1',
          algorithm: 'RSA-OAEP-256',
          publicKey: 'MIIBIjANBg...',
          nonce: 'one-time-nonce',
          expiresInSeconds: 600,
        ),
      ),
    );
    final dataSource = AuthCryptoRemoteDataSourceImpl(
      api: api,
      clientAuthorization: 'encoded-client-credentials',
    );

    final result = await dataSource.fetchPublicKeyAndNonce(
      requestId: 'auth-crypto-123',
    );

    expect(
      api.options.headers!['authorization'],
      'Basic encoded-client-credentials',
    );
    expect(
      api.options.extra![NetworkRequestExtras.requestId],
      'auth-crypto-123',
    );
    expect(result.keyId, 'app-password-key-v1');
    expect(result.expiresInSeconds, 600);
  });

  test('rejects an unsupported encryption algorithm', () async {
    final dataSource = AuthCryptoRemoteDataSourceImpl(
      api: _FakeAuthApi(
        const ApiEnvelopeDto(
          code: 200,
          success: true,
          data: AuthPublicKeyResponseDto(
            keyId: 'key',
            algorithm: 'RSA-OAEP-1',
            publicKey: 'public-key',
            nonce: 'nonce',
            expiresInSeconds: 300,
          ),
        ),
      ),
      clientAuthorization: 'encoded-client-credentials',
    );

    expect(
      () => dataSource.fetchPublicKeyAndNonce(requestId: 'request-1'),
      throwsA(
        isA<AuthCryptoRemoteException>().having(
          (error) => error.kind,
          'kind',
          AuthCryptoRemoteErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('maps an HTTP error into the auth network error', () async {
    final requestOptions = RequestOptions(path: 'app/auth/crypto/public-key');
    final dataSource = AuthCryptoRemoteDataSourceImpl(
      api: _FakeAuthApi.error(
        DioException(
          requestOptions: requestOptions,
          response: Response<void>(
            requestOptions: requestOptions,
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ),
      ),
      clientAuthorization: 'encoded-client-credentials',
    );

    expect(
      () => dataSource.fetchPublicKeyAndNonce(requestId: 'request-1'),
      throwsA(
        isA<AuthCryptoRemoteException>()
            .having(
              (error) => error.kind,
              'kind',
              AuthCryptoRemoteErrorKind.network,
            )
            .having((error) => error.statusCode, 'statusCode', 401),
      ),
    );
  });
}

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi(this.response) : error = null;
  _FakeAuthApi.error(this.error) : response = null;

  final ApiEnvelopeDto<AuthPublicKeyResponseDto>? response;
  final DioException? error;
  late Options options;

  @override
  Future<ApiEnvelopeDto<dynamic>> completeRegistration(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<AuthPublicKeyResponseDto>> fetchPublicKey(
    Options requestOptions,
  ) async {
    options = requestOptions;
    if (error != null) {
      throw error!;
    }
    return response!;
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> sendRegistrationEmailCode(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> verifyRegistrationEmailCode(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();
}
