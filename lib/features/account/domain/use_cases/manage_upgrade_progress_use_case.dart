import '../repositories/upgrade_repository.dart';

class ReadUpgradeProgressesUseCase {
  const ReadUpgradeProgressesUseCase(this._repository);

  final UpgradeRepository _repository;

  Future<Map<String, int>> call({required String userId}) {
    return _repository.readProgresses(userId: userId);
  }
}

class ReplaceUpgradeProgressesUseCase {
  const ReplaceUpgradeProgressesUseCase(this._repository);

  final UpgradeRepository _repository;

  Future<void> call({
    required String userId,
    required Map<String, int> progresses,
  }) {
    return _repository.replaceProgresses(
      userId: userId,
      progresses: progresses,
    );
  }
}
