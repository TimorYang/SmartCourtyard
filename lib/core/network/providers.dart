import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/providers.dart';
import '../logging/providers.dart';
import 'dio_factory.dart';
import 'network_proxy_controller.dart';
import 'session_expired_handler.dart';

final sessionExpiredHandlerProvider = Provider<SessionExpiredHandler>(
  (ref) => ignoreSessionExpired,
);

final tokenRefreshHandlerProvider = Provider<TokenRefreshHandler>(
  (ref) => noTokenRefreshAvailable,
);

final dioProvider = Provider((ref) {
  final dio = DioFactory.create(
    configuration: ref.watch(appApiConfigurationProvider),
    logger: ref.watch(appLoggerProvider),
    proxySettings: ref.watch(networkProxySettingsProvider),
    onSessionExpired: ref.watch(sessionExpiredHandlerProvider),
    onTokenRefresh: ref.watch(tokenRefreshHandlerProvider),
  );
  // A settings change rebuilds this provider. Allow requests already using
  // the old client to finish while preventing new requests from using it.
  ref.onDispose(() => dio.close());
  return dio;
});
