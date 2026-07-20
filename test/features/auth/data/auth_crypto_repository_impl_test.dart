import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/features/auth/data/data_sources/auth_crypto_remote_data_source.dart';
import 'package:flinx/features/auth/data/repositories/auth_crypto_repository_impl.dart';
import 'package:flinx/features/auth/data/dto/auth_public_key_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'maps a crypto response to domain material with the request id',
    () async {
      final repository = AuthCryptoRepositoryImpl(
        remoteDataSource: _FakeRemoteDataSource(
          const AuthPublicKeyResponseDto(
            keyId: 'key-v1',
            algorithm: 'RSA-OAEP-256',
            publicKey: 'public-key',
            nonce: 'single-use-nonce',
            expiresInSeconds: 300,
          ),
        ),
        logger: _FakeLogger(),
        clock: () => DateTime.utc(2026, 7, 10, 12),
      );

      final material = await repository.getPasswordEncryptionMaterial(
        requestId: 'auth-crypto-123',
      );

      expect(material.requestId, 'auth-crypto-123');
      expect(material.expiresAt, DateTime.utc(2026, 7, 10, 12, 5));
      expect(material.isExpiredAt(DateTime.utc(2026, 7, 10, 12, 5)), isTrue);
    },
  );

  test('maps an unavailable network to a retryable app error', () async {
    final repository = AuthCryptoRepositoryImpl(
      remoteDataSource: _ThrowingRemoteDataSource(
        const AuthCryptoRemoteException.network(),
      ),
      logger: _FakeLogger(),
    );

    expect(
      () => repository.getPasswordEncryptionMaterial(requestId: 'request-1'),
      throwsA(
        isA<AppError>()
            .having(
              (error) => error.code,
              'code',
              AppErrorCode.networkUnavailable,
            )
            .having((error) => error.retryable, 'retryable', isTrue)
            .having((error) => error.requestId, 'requestId', 'request-1'),
      ),
    );
  });
}

class _FakeRemoteDataSource implements AuthCryptoRemoteDataSource {
  const _FakeRemoteDataSource(this.result);

  final AuthPublicKeyResponseDto result;

  @override
  Future<AuthPublicKeyResponseDto> fetchPublicKeyAndNonce({
    required String requestId,
  }) async => result;
}

class _ThrowingRemoteDataSource implements AuthCryptoRemoteDataSource {
  const _ThrowingRemoteDataSource(this.error);

  final AuthCryptoRemoteException error;

  @override
  Future<AuthPublicKeyResponseDto> fetchPublicKeyAndNonce({
    required String requestId,
  }) async => throw error;
}

class _FakeLogger implements AppLogger {
  @override
  void error(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void info(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void warning(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}
}
