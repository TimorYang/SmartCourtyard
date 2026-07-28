import 'dart:convert';
import 'dart:io';

import '../dto/account_overview_cache_dto.dart';

abstract class AccountOverviewLocalDataSource {
  Future<AccountOverviewCacheDto?> readOverview();

  Future<void> saveOverview(AccountOverviewCacheDto overview);

  Future<void> clearOverview();
}

class InMemoryAccountOverviewLocalDataSource
    implements AccountOverviewLocalDataSource {
  InMemoryAccountOverviewLocalDataSource({
    AccountOverviewCacheDto? initialOverview,
  }) : _overview = initialOverview;

  AccountOverviewCacheDto? _overview;

  @override
  Future<AccountOverviewCacheDto?> readOverview() async => _overview;

  @override
  Future<void> saveOverview(AccountOverviewCacheDto overview) async {
    _overview = overview;
  }

  @override
  Future<void> clearOverview() async {
    _overview = null;
  }
}

class JsonFileAccountOverviewLocalDataSource
    implements AccountOverviewLocalDataSource {
  JsonFileAccountOverviewLocalDataSource({required this.overviewFile});

  final File overviewFile;

  @override
  Future<AccountOverviewCacheDto?> readOverview() async {
    try {
      if (!await overviewFile.exists()) {
        return null;
      }
      final json = jsonDecode(await overviewFile.readAsString());
      return json is Map
          ? AccountOverviewCacheDto.fromJson(Map<String, Object?>.from(json))
          : null;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> saveOverview(AccountOverviewCacheDto overview) async {
    await overviewFile.parent.create(recursive: true);
    await overviewFile.writeAsString(jsonEncode(overview.toJson()));
  }

  @override
  Future<void> clearOverview() async {
    try {
      if (await overviewFile.exists()) {
        await overviewFile.delete();
      }
    } on Object {
      // A cache cleanup failure must not prevent signing out.
    }
  }
}
