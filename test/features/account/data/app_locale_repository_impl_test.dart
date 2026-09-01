import 'dart:io';

import 'package:flinx/features/account/data/data_sources/app_locale_local_data_source.dart';
import 'package:flinx/features/account/data/repositories/app_locale_repository_impl.dart';
import 'package:flinx/features/account/domain/entities/app_locale_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restores a saved locale from the JSON preference file', () async {
    final directory = await Directory.systemTemp.createTemp('flinx-locale-');
    addTearDown(() => directory.delete(recursive: true));
    final preferenceFile = File('${directory.path}/app_locale_preference.json');

    final writer = AppLocaleRepositoryImpl(
      JsonFileAppLocaleLocalDataSource(preferencesFile: preferenceFile),
    );
    await writer.savePreferredLocale(AppLocalePreference.argentineSpanish);

    expect(
      await JsonFileAppLocaleLocalDataSource(
        preferencesFile: preferenceFile,
      ).readLanguageCode(),
      'es-AR',
    );

    final reader = AppLocaleRepositoryImpl(
      JsonFileAppLocaleLocalDataSource(preferencesFile: preferenceFile),
    );
    expect(
      await reader.readPreferredLocale(),
      AppLocalePreference.argentineSpanish,
    );
  });

  test('ignores a malformed locale preference', () async {
    final directory = await Directory.systemTemp.createTemp('flinx-locale-');
    addTearDown(() => directory.delete(recursive: true));
    final preferenceFile = File('${directory.path}/app_locale_preference.json');
    await preferenceFile.writeAsString('{"languageCode":"xx-XX"}');

    final repository = AppLocaleRepositoryImpl(
      JsonFileAppLocaleLocalDataSource(preferencesFile: preferenceFile),
    );

    expect(await repository.readPreferredLocale(), isNull);
  });
}
