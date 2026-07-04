class AppRegexPatterns {
  const AppRegexPatterns._();

  static final email = RegExp(
    r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
    caseSensitive: false,
  );
}
