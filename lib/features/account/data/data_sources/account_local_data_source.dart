import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../dto/account_profile_dto.dart';

abstract class AccountLocalDataSource {
  Future<AccountProfileDto?> readProfile();

  Stream<AccountProfileDto?> watchProfile();

  Future<void> saveProfile(AccountProfileDto profile);

  Future<void> clearProfile();
}

class InMemoryAccountLocalDataSource implements AccountLocalDataSource {
  InMemoryAccountLocalDataSource({AccountProfileDto? initialProfile})
    : _profile = initialProfile;

  AccountProfileDto? _profile;
  final StreamController<AccountProfileDto?> _profileController =
      StreamController<AccountProfileDto?>.broadcast();

  @override
  Future<AccountProfileDto?> readProfile() async {
    return _profile;
  }

  @override
  Stream<AccountProfileDto?> watchProfile() {
    return _profileController.stream;
  }

  @override
  Future<void> saveProfile(AccountProfileDto profile) async {
    _profile = profile;
    _profileController.add(profile);
  }

  @override
  Future<void> clearProfile() async {
    _profile = null;
    _profileController.add(null);
  }
}

class JsonFileAccountLocalDataSource implements AccountLocalDataSource {
  JsonFileAccountLocalDataSource({
    required this.profileFile,
    this.legacyProfileFiles = const [],
  });

  final File profileFile;
  final List<File> legacyProfileFiles;
  final StreamController<AccountProfileDto?> _profileController =
      StreamController<AccountProfileDto?>.broadcast();

  @override
  Future<AccountProfileDto?> readProfile() async {
    try {
      if (await profileFile.exists()) {
        return _readProfileFile(profileFile);
      }

      return _migrateLegacyProfile();
    } on Object {
      return null;
    }
  }

  Future<AccountProfileDto?> _readProfileFile(File file) async {
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map) {
        return null;
      }

      return AccountProfileDto.fromJson(Map<String, Object?>.from(json));
    } catch (_) {
      return null;
    }
  }

  Future<AccountProfileDto?> _migrateLegacyProfile() async {
    for (final legacyProfileFile in legacyProfileFiles) {
      if (!await legacyProfileFile.exists()) {
        continue;
      }
      final profile = await _readProfileFile(legacyProfileFile);
      if (profile == null) {
        continue;
      }
      try {
        await profileFile.parent.create(recursive: true);
        await profileFile.writeAsString(jsonEncode(profile.toJson()));
        await legacyProfileFile.delete();
        return profile;
      } on Object {
        return null;
      }
    }
    return null;
  }

  @override
  Stream<AccountProfileDto?> watchProfile() {
    return _profileController.stream;
  }

  @override
  Future<void> saveProfile(AccountProfileDto profile) async {
    await profileFile.parent.create(recursive: true);
    await profileFile.writeAsString(jsonEncode(profile.toJson()));
    _profileController.add(profile);
  }

  @override
  Future<void> clearProfile() async {
    try {
      if (await profileFile.exists()) {
        await profileFile.delete();
      }
    } on Object {
      // Best-effort cleanup must not prevent the signed-out state transition.
    }
    for (final legacyProfileFile in legacyProfileFiles) {
      try {
        if (await legacyProfileFile.exists()) {
          await legacyProfileFile.delete();
        }
      } on Object {
        continue;
      }
    }
    _profileController.add(null);
  }
}
