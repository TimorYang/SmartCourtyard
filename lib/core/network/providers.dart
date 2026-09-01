import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/providers.dart';
import '../localization/providers.dart';
import '../logging/providers.dart';
import 'dio_factory.dart';
import 'session_expired_handler.dart';

final sessionExpiredHandlerProvider = Provider<SessionExpiredHandler>(
  (ref) => ignoreSessionExpired,
);

final tokenRefreshHandlerProvider = Provider<TokenRefreshHandler>(
  (ref) => noTokenRefreshAvailable,
);

final dioProvider = Provider((ref) {
  return DioFactory.create(
    configuration: ref.watch(appApiConfigurationProvider),
    logger: ref.watch(appLoggerProvider),
    onSessionExpired: ref.watch(sessionExpiredHandlerProvider),
    onTokenRefresh: ref.watch(tokenRefreshHandlerProvider),
    acceptLanguageResolver: () => ref.read(currentAppLocaleStoreProvider).value,
  );
});
