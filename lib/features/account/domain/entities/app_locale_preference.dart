enum AppLocalePreference {
  english('en'),
  simplifiedChinese('zh');

  const AppLocalePreference(this.languageCode);

  final String languageCode;

  static AppLocalePreference? fromLanguageCode(String? languageCode) {
    return switch (languageCode) {
      'en' => AppLocalePreference.english,
      'zh' => AppLocalePreference.simplifiedChinese,
      _ => null,
    };
  }
}
