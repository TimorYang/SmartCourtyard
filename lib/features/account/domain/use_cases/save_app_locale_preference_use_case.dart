import '../entities/app_locale_preference.dart';
import '../repositories/app_locale_repository.dart';

class SaveAppLocalePreferenceUseCase {
  const SaveAppLocalePreferenceUseCase(this._repository);

  final AppLocaleRepository _repository;

  Future<void> call(AppLocalePreference locale) {
    return _repository.savePreferredLocale(locale);
  }
}
