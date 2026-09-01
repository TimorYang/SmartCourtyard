enum AppLocalePreference {
  english('en', 'en-US'),
  simplifiedChinese('zh', 'zh-CN'),
  argentineSpanish('es', 'es-AR'),
  italian('it', 'it-IT'),
  europeanPortuguese('pt', 'pt-PT'),
  czech('cs', 'cs-CZ'),
  dutch('nl', 'nl-NL'),
  french('fr', 'fr-FR'),
  german('de', 'de-DE'),
  polish('pl', 'pl-PL'),
  ukrainian('uk', 'uk-UA'),
  russian('ru', 'ru-RU'),
  norwegian('no', 'no-NO'),
  hungarian('hu', 'hu-HU');

  const AppLocalePreference(this.languageCode, this.serverLocale);

  final String languageCode;
  final String serverLocale;

  static AppLocalePreference? fromLanguageCode(String? languageCode) {
    final normalizedLocale = languageCode?.trim().replaceAll('_', '-');
    if (normalizedLocale == null || normalizedLocale.isEmpty) {
      return null;
    }
    final normalizedLanguageCode = normalizedLocale
        .split('-')
        .first
        .toLowerCase();
    for (final locale in values) {
      if (locale.serverLocale.toLowerCase() == normalizedLocale.toLowerCase() ||
          locale.languageCode == normalizedLanguageCode) {
        return locale;
      }
    }
    return null;
  }
}
