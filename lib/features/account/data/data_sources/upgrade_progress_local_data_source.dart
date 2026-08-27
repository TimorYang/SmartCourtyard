import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract interface class UpgradeProgressLocalDataSource {
  Future<Map<String, int>> readProgresses({required String userId});

  Future<void> replaceProgresses({
    required String userId,
    required Map<String, int> progresses,
  });
}

class InMemoryUpgradeProgressLocalDataSource
    implements UpgradeProgressLocalDataSource {
  final Map<String, Map<String, int>> _progressesByUser = {};

  @override
  Future<Map<String, int>> readProgresses({required String userId}) async {
    return Map<String, int>.from(_progressesByUser[userId] ?? const {});
  }

  @override
  Future<void> replaceProgresses({
    required String userId,
    required Map<String, int> progresses,
  }) async {
    _progressesByUser[userId] = Map<String, int>.from(progresses);
  }
}

class JsonFileUpgradeProgressLocalDataSource
    implements UpgradeProgressLocalDataSource {
  JsonFileUpgradeProgressLocalDataSource({required this.progressFile});

  final File progressFile;
  Future<void> _pendingWrite = Future<void>.value();

  @override
  Future<Map<String, int>> readProgresses({required String userId}) async {
    try {
      await _pendingWrite;
      final users = await _readUsers();
      return Map<String, int>.from(users[userId] ?? const {});
    } on Object {
      return const {};
    }
  }

  @override
  Future<void> replaceProgresses({
    required String userId,
    required Map<String, int> progresses,
  }) {
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        final users = await _readUsers();
        if (progresses.isEmpty) {
          users.remove(userId);
        } else {
          users[userId] = progresses.map(
            (key, value) => MapEntry(key, value.clamp(1, 99)),
          );
        }
        await progressFile.parent.create(recursive: true);
        await progressFile.writeAsString(
          jsonEncode({'users': users}),
          flush: true,
        );
      } on Object {
        // Progress persistence must never block the upgrade page.
      }
    });
    return _pendingWrite;
  }

  Future<Map<String, Map<String, int>>> _readUsers() async {
    if (!await progressFile.exists()) return {};
    final decoded = jsonDecode(await progressFile.readAsString());
    if (decoded is! Map || decoded['users'] is! Map) return {};
    final users = <String, Map<String, int>>{};
    for (final userEntry in (decoded['users'] as Map).entries) {
      final rawProgresses = userEntry.value;
      if (rawProgresses is! Map) continue;
      final progresses = <String, int>{};
      for (final progressEntry in rawProgresses.entries) {
        final value = progressEntry.value;
        final progress = value is num ? value.toInt() : null;
        if (progress != null && progress >= 1 && progress <= 99) {
          progresses[progressEntry.key.toString()] = progress;
        }
      }
      users[userEntry.key.toString()] = progresses;
    }
    return users;
  }
}
