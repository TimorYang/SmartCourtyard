import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/session_expired_handler.dart';
import '../../../account/domain/entities/account_token_set.dart';
import '../../../account/domain/repositories/account_repository.dart';
import '../../domain/services/login_device_context_provider.dart';
import '../data_sources/auth_api.dart';
import '../dto/auth_login_response_dto.dart';

class AuthTokenRefreshService {
  AuthTokenRefreshService({
    required this.api,
    required this.accountRepository,
    required this.deviceContextProvider,
  });

  final AuthApi api;
  final AccountRepository accountRepository;
  final LoginDeviceContextProvider deviceContextProvider;

  Future<TokenRefreshResult>? _inFlightRefresh;

  Future<TokenRefreshResult> refreshExpiredAccessToken() {
    final inFlightRefresh = _inFlightRefresh;
    if (inFlightRefresh != null) {
      return inFlightRefresh;
    }

    final refresh = _refreshExpiredAccessToken();
    _inFlightRefresh = refresh;
    refresh.then<void>(
      (_) => _clearInFlightRefresh(refresh),
      onError: (_, _) => _clearInFlightRefresh(refresh),
    );
    return refresh;
  }

  void _clearInFlightRefresh(Future<TokenRefreshResult> refresh) {
    if (identical(_inFlightRefresh, refresh)) {
      _inFlightRefresh = null;
    }
  }

  Future<TokenRefreshResult> _refreshExpiredAccessToken() async {
    final now = DateTime.now().toUtc();
    final tokenSet = await accountRepository.readTokenSet();
    if (tokenSet == null || !tokenSet.hasAccessToken) {
      return TokenRefreshResult.sessionExpired;
    }
    if (tokenSet.isUsableAt(now)) {
      return TokenRefreshResult.refreshed;
    }
    if (!tokenSet.isRefreshUsableAt(now)) {
      return TokenRefreshResult.sessionExpired;
    }

    try {
      final deviceContext = await deviceContextProvider.read();
      final requestId =
          'token-refresh-${DateTime.now().toUtc().microsecondsSinceEpoch}';
      final response = await api.refreshToken({
        'refreshToken': tokenSet.refreshToken,
        'deviceId': deviceContext.deviceId,
      }, Options(extra: {NetworkRequestExtras.requestId: requestId}));
      final data = response.data;
      if (!response.isBusinessSuccess ||
          data == null ||
          !_hasUsableTokens(data)) {
        return TokenRefreshResult.sessionExpired;
      }

      final refreshedAt = DateTime.now().toUtc();
      await accountRepository.saveTokenSet(
        AccountTokenSet(
          accessToken: data.accessToken,
          refreshToken: data.refreshToken,
          tokenType: data.tokenType,
          expiresAt: refreshedAt.add(Duration(seconds: data.expiresInSeconds)),
          refreshExpiresAt: refreshedAt.add(
            Duration(seconds: data.refreshExpiresInSeconds),
          ),
        ),
      );
      return TokenRefreshResult.refreshed;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        return TokenRefreshResult.sessionExpired;
      }
      rethrow;
    }
  }

  bool _hasUsableTokens(AuthLoginResponseDto data) {
    return data.accessToken.trim().isNotEmpty &&
        data.refreshToken.trim().isNotEmpty &&
        data.tokenType.trim().isNotEmpty &&
        data.expiresInSeconds > 0 &&
        data.refreshExpiresInSeconds > 0;
  }
}
