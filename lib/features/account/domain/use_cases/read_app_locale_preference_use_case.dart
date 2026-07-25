import '../entities/app_locale_preference.dart';
import '../repositories/app_locale_repository.dart';

class ReadAppLocalePreferenceUseCase {
  const ReadAppLocalePreferenceUseCase(this._repository);

  final AppLocaleRepository _repository;

  Future<AppLocalePreference?> call() => _repository.readPreferredLocale();
}
