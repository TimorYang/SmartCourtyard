import 'package:flinx/features/account/domain/entities/app_locale_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every supported server locale', () {
    const expectedLocales = {
      'en-US': AppLocalePreference.english,
      'zh-CN': AppLocalePreference.simplifiedChinese,
      'es-AR': AppLocalePreference.argentineSpanish,
      'it-IT': AppLocalePreference.italian,
      'pt-PT': AppLocalePreference.europeanPortuguese,
      'cs-CZ': AppLocalePreference.czech,
      'nl-NL': AppLocalePreference.dutch,
      'fr-FR': AppLocalePreference.french,
      'de-DE': AppLocalePreference.german,
      'pl-PL': AppLocalePreference.polish,
      'uk-UA': AppLocalePreference.ukrainian,
      'ru-RU': AppLocalePreference.russian,
      'no-NO': AppLocalePreference.norwegian,
      'hu-HU': AppLocalePreference.hungarian,
    };

    expect(AppLocalePreference.values, hasLength(expectedLocales.length));
    for (final entry in expectedLocales.entries) {
      expect(
        AppLocalePreference.fromLanguageCode(entry.key),
        entry.value,
        reason: entry.key,
      );
      expect(entry.value.serverLocale, entry.key);
    }
  });

  test('maps platform language codes to the supported regional locale', () {
    expect(
      AppLocalePreference.fromLanguageCode('es'),
      AppLocalePreference.argentineSpanish,
    );
    expect(
      AppLocalePreference.fromLanguageCode('pt_BR'),
      AppLocalePreference.europeanPortuguese,
    );
  });

  test('rejects unsupported locales', () {
    expect(AppLocalePreference.fromLanguageCode('ja-JP'), isNull);
  });
}
