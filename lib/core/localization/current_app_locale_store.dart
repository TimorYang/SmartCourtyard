class CurrentAppLocaleStore {
  CurrentAppLocaleStore({String initialLocale = defaultLocale})
    : _locale = _normalizeOrDefault(initialLocale);

  static const defaultLocale = 'en-US';

  String _locale;

  String get value => _locale;

  void setLocale(String locale) {
    _locale = _normalizeOrDefault(locale);
  }

  static String _normalizeOrDefault(String locale) {
    final normalized = locale.trim();
    return normalized.isEmpty ? defaultLocale : normalized;
  }
}
