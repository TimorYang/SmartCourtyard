import 'dart:async';

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
