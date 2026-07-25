import '../../domain/entities/app_locale_preference.dart';
import '../../domain/repositories/app_locale_repository.dart';
import '../data_sources/app_locale_local_data_source.dart';

class AppLocaleRepositoryImpl implements AppLocaleRepository {
  const AppLocaleRepositoryImpl(this._localDataSource);

  final AppLocaleLocalDataSource _localDataSource;

  @override
  Future<AppLocalePreference?> readPreferredLocale() async {
    return AppLocalePreference.fromLanguageCode(
      await _localDataSource.readLanguageCode(),
    );
  }

  @override
  Future<void> savePreferredLocale(AppLocalePreference locale) {
    return _localDataSource.saveLanguageCode(locale.languageCode);
  }
}
