import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../core/logging/providers.dart';
import '../../features/account/application/providers.dart';
import '../../features/auth/application/providers.dart';
import '../../features/home/application/providers.dart';
import '../../features/push/application/providers.dart';

final sessionCleanupCoordinatorProvider = Provider<SessionCleanupCoordinator>((
  ref,
) {
  return SessionCleanupCoordinator(ref);
});

/// Coordinates the local account/session cleanup shared by every sign-out
/// entry point.
class SessionCleanupCoordinator {
  SessionCleanupCoordinator(this._ref);

  final Ref _ref;
  Future<void>? _localCleanup;

  /// Unbinds push registration while the access token is still available,
  /// then clears local account and session state regardless of unbind outcome.
  Future<void> signOut() async {
    try {
      await _ref.read(pushServiceProvider.notifier).unbindForLogout();
    } on Object catch (error, stackTrace) {
      _ref
          .read(appLoggerProvider)
          .error(
            'session_push_unbind_unexpected_failure',
            tag: AppLogTag.push,
            error: error,
            stackTrace: stackTrace,
          );
    }
    await _clearLocalSession();
  }

  /// Clears local state after automatic expiry. It deliberately does not
  /// issue a push unbind request because the access token is not usable.
  Future<void> clearExpiredSession() => _clearLocalSession();

  Future<void> _clearLocalSession() async {
    final pending = _localCleanup;
    if (pending != null) return pending;

    final future = _clearLocalSessionInternal();
    _localCleanup = future;
    try {
      await future;
    } finally {
      if (identical(_localCleanup, future)) {
        _localCleanup = null;
      }
    }
  }

  Future<void> _clearLocalSessionInternal() async {
    try {
      await _ref.read(accountControllerProvider.notifier).clearAccount();
    } finally {
      _ref.read(activeAuthSessionProvider.notifier).clear();
      _ref.invalidate(authSessionProvider);
      _ref.invalidate(cachedAccountProfileProvider);
      _ref.read(homeDeviceListsInvalidatorProvider)();
    }
  }
}
