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
  JsonFileAccountLocalDataSource({required this.profileFile});

  final File profileFile;
  final StreamController<AccountProfileDto?> _profileController =
      StreamController<AccountProfileDto?>.broadcast();

  @override
  Future<AccountProfileDto?> readProfile() async {
    try {
      if (!await profileFile.exists()) {
        return null;
      }

      final json = jsonDecode(await profileFile.readAsString());
      if (json is! Map) {
        return null;
      }

      return AccountProfileDto.fromJson(Map<String, Object?>.from(json));
    } catch (_) {
      return null;
    }
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
    if (await profileFile.exists()) {
      await profileFile.delete();
    }
    _profileController.add(null);
  }
}
