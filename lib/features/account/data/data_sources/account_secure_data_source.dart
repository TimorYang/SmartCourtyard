import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

class PlatformAccountSecureDataSource implements AccountSecureDataSource {
  const PlatformAccountSecureDataSource({
    required this.storage,
    this.legacyPlaintextTokenFile,
  });

  static const _accessTokenKey = 'account.access_token';
  static const _refreshTokenKey = 'account.refresh_token';
  static const _expiresAtKey = 'account.expires_at';
  static const _tokenTypeKey = 'account.token_type';

  final FlutterSecureStorage storage;
  final File? legacyPlaintextTokenFile;

  @override
  Future<AccountTokenSet?> readTokenSet() async {
    final values = await storage.readAll();
    final accessToken = values[_accessTokenKey];
    final AccountTokenSet? tokenSet;
    if (accessToken == null || accessToken.trim().isEmpty) {
      tokenSet = await _readLegacyPlaintextTokenSet();
      if (tokenSet != null) {
        await _writeTokenSet(tokenSet);
      }
    } else {
      tokenSet = AccountTokenSet(
        accessToken: accessToken,
        refreshToken: values[_refreshTokenKey],
        expiresAt: _parseDateTime(values[_expiresAtKey]),
        tokenType: values[_tokenTypeKey] ?? 'Bearer',
      );
    }
    await _deleteLegacyPlaintextTokenFile();
    return tokenSet;
  }

  @override
  Future<void> saveTokenSet(AccountTokenSet tokenSet) async {
    await _writeTokenSet(tokenSet);
    await _deleteLegacyPlaintextTokenFile();
  }

  Future<void> _writeTokenSet(AccountTokenSet tokenSet) async {
    await storage.write(key: _accessTokenKey, value: tokenSet.accessToken);
    await storage.write(key: _refreshTokenKey, value: tokenSet.refreshToken);
    await storage.write(
      key: _expiresAtKey,
      value: tokenSet.expiresAt?.toUtc().toIso8601String(),
    );
    await storage.write(key: _tokenTypeKey, value: tokenSet.tokenType);
  }

  @override
  Future<void> clearTokenSet() async {
    for (final key in const [
      _accessTokenKey,
      _refreshTokenKey,
      _expiresAtKey,
      _tokenTypeKey,
    ]) {
      await storage.delete(key: key);
    }
    await _deleteLegacyPlaintextTokenFile();
  }

  Future<void> _deleteLegacyPlaintextTokenFile() async {
    final file = legacyPlaintextTokenFile;
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }

  Future<AccountTokenSet?> _readLegacyPlaintextTokenSet() async {
    final file = legacyPlaintextTokenFile;
    if (file == null || !await file.exists()) {
      return null;
    }
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map) {
        return null;
      }
      final accessToken = json['accessToken'] as String?;
      if (accessToken == null || accessToken.trim().isEmpty) {
        return null;
      }
      return AccountTokenSet(
        accessToken: accessToken,
        refreshToken: json['refreshToken'] as String?,
        expiresAt: _parseDateTime(json['expiresAt'] as String?),
        tokenType: json['tokenType'] as String? ?? 'Bearer',
      );
    } on Object {
      return null;
    }
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value)?.toUtc();
  }
}
