import '../entities/app_locale_preference.dart';

abstract class AppLocaleRepository {
  Future<AppLocalePreference?> readPreferredLocale();

  Future<void> savePreferredLocale(AppLocalePreference locale);
}
