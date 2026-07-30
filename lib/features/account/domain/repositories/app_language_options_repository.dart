import '../entities/app_language_option.dart';

abstract interface class AppLanguageOptionsRepository {
  Future<List<AppLanguageOption>> fetchLanguageOptions({
    required String requestId,
  });
}
