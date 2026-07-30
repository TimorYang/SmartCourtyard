import '../entities/app_language_option.dart';
import '../repositories/app_language_options_repository.dart';

class FetchAppLanguageOptionsUseCase {
  const FetchAppLanguageOptionsUseCase({required this.repository});

  final AppLanguageOptionsRepository repository;

  Future<List<AppLanguageOption>> call({required String requestId}) {
    return repository.fetchLanguageOptions(requestId: requestId);
  }
}
