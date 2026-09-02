import 'dart:async';

enum PushRegistrationSyncResult { performed, joined, alreadyCompleted }

/// Deduplicates registration binding across [PushService] rebuilds.
///
/// Completed entries are kept only for the current authenticated user session.
/// Failed operations are removed so a later lifecycle or connection event can
/// retry them.
class PushRegistrationSyncGuard {
  final Map<String, Future<void>> _inFlight = <String, Future<void>>{};
  final Set<String> _completed = <String>{};

  Future<PushRegistrationSyncResult> run({
    required String key,
    required Future<void> Function() operation,
  }) async {
    if (_completed.contains(key)) {
      return PushRegistrationSyncResult.alreadyCompleted;
    }

    final pending = _inFlight[key];
    if (pending != null) {
      await pending;
      return PushRegistrationSyncResult.joined;
    }

    final future = operation();
    _inFlight[key] = future;
    try {
      await future;
      _completed.add(key);
      return PushRegistrationSyncResult.performed;
    } finally {
      if (identical(_inFlight[key], future)) {
        _inFlight.remove(key);
      }
    }
  }

  void clearUser(String userId) {
    final prefix = '$userId\u0000';
    _completed.removeWhere((key) => key.startsWith(prefix));
  }
}
