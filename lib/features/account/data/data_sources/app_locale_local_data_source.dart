import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract class AppLocaleLocalDataSource {
  Future<String?> readLanguageCode();

  Future<void> saveLanguageCode(String languageCode);
}

class InMemoryAppLocaleLocalDataSource implements AppLocaleLocalDataSource {
  InMemoryAppLocaleLocalDataSource({String? initialLanguageCode})
    : _languageCode = initialLanguageCode;

  String? _languageCode;

  @override
  Future<String?> readLanguageCode() async => _languageCode;

  @override
  Future<void> saveLanguageCode(String languageCode) async {
    _languageCode = languageCode;
  }
}

class JsonFileAppLocaleLocalDataSource implements AppLocaleLocalDataSource {
  JsonFileAppLocaleLocalDataSource({
    required this.preferencesFile,
    this.legacyPreferenceFiles = const [],
  });

  final File preferencesFile;
  final List<File> legacyPreferenceFiles;

  @override
  Future<String?> readLanguageCode() async {
    try {
      if (await preferencesFile.exists()) {
        return _readLanguageCode(preferencesFile);
      }

      return _migrateLegacyPreference();
    } on Object {
      return null;
    }
  }

  Future<String?> _readLanguageCode(File file) async {
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return null;
      }
      return decoded['languageCode'] as String?;
    } on Object {
      return null;
    }
  }

  Future<String?> _migrateLegacyPreference() async {
    for (final legacyFile in legacyPreferenceFiles) {
      if (!await legacyFile.exists()) {
        continue;
      }
      final languageCode = await _readLanguageCode(legacyFile);
      if (languageCode == null) {
        continue;
      }
      try {
        await saveLanguageCode(languageCode);
        await legacyFile.delete();
      } on Object {
        return null;
      }
      return languageCode;
    }
    return null;
  }

  @override
  Future<void> saveLanguageCode(String languageCode) async {
    await preferencesFile.parent.create(recursive: true);
    await preferencesFile.writeAsString(
      jsonEncode({'languageCode': languageCode}),
    );
  }
}
