import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/session_expired_handler.dart';
import '../../features/auth/application/providers.dart';
import 'session_cleanup_coordinator.dart';

// Dio depends on these handlers. Resolve services from the container when a
// callback runs; reading them through the handler's Ref creates a dependency
// cycle because the auth and account services themselves depend on Dio.
TokenRefreshHandler createTokenRefreshHandler(Ref ref) {
  final container = ref.container;
  return () => container
      .read(authTokenRefreshServiceProvider)
      .refreshExpiredAccessToken();
}

SessionExpiredHandler createSessionExpiredHandler(Ref ref) {
  final container = ref.container;
  var isClearingSession = false;
  return () async {
    if (isClearingSession) return;
    isClearingSession = true;
    try {
      await container
          .read(sessionCleanupCoordinatorProvider)
          .clearExpiredSession();
    } finally {
      isClearingSession = false;
    }
  };
}
