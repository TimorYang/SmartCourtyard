import 'dart:convert';
import 'dart:io';

import '../../domain/entities/account_token_set.dart';

abstract class AccountSecureDataSource {
  Future<AccountTokenSet?> readTokenSet();

  Future<void> saveTokenSet(AccountTokenSet tokenSet);

  Future<void> clearTokenSet();
}

class InMemoryAccountSecureDataSource implements AccountSecureDataSource {
  AccountTokenSet? _tokenSet;

  @override
  Future<AccountTokenSet?> readTokenSet() async {
    return _tokenSet;
  }

  @override
  Future<void> saveTokenSet(AccountTokenSet tokenSet) async {
    _tokenSet = tokenSet;
  }

  @override
  Future<void> clearTokenSet() async {
    _tokenSet = null;
  }
}

class JsonFileAccountSecureDataSource implements AccountSecureDataSource {
  JsonFileAccountSecureDataSource({required this.tokenFile});

  final File tokenFile;

  @override
  Future<AccountTokenSet?> readTokenSet() async {
    try {
      if (!await tokenFile.exists()) {
        return null;
      }

      final json = jsonDecode(await tokenFile.readAsString());
      if (json is! Map) {
        return null;
      }

      return AccountTokenSet(
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String?,
        expiresAt: _parseDateTime(json['expiresAt'] as String?),
        tokenType: json['tokenType'] as String? ?? 'Bearer',
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTokenSet(AccountTokenSet tokenSet) async {
    await tokenFile.parent.create(recursive: true);
    await tokenFile.writeAsString(
      jsonEncode(<String, Object?>{
        'accessToken': tokenSet.accessToken,
        'refreshToken': tokenSet.refreshToken,
        'expiresAt': tokenSet.expiresAt?.toUtc().toIso8601String(),
        'tokenType': tokenSet.tokenType,
      }),
    );
  }

  @override
  Future<void> clearTokenSet() async {
    if (await tokenFile.exists()) {
      await tokenFile.delete();
    }
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value)?.toUtc();
  }
}
