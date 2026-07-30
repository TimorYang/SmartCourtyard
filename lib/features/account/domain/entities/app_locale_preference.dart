enum AppLocalePreference {
  english('en'),
  simplifiedChinese('zh');

  const AppLocalePreference(this.languageCode);

  final String languageCode;

  static AppLocalePreference? fromLanguageCode(String? languageCode) {
    final normalizedLanguageCode = languageCode
        ?.trim()
        .replaceAll('_', '-')
        .split('-')
        .first
        .toLowerCase();
    return switch (normalizedLanguageCode) {
      'en' => AppLocalePreference.english,
      'zh' => AppLocalePreference.simplifiedChinese,
      _ => null,
    };
  }
}
