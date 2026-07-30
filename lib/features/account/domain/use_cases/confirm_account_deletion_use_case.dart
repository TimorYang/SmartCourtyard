import '../repositories/account_repository.dart';

class ConfirmAccountDeletionUseCase {
  const ConfirmAccountDeletionUseCase(this._repository);

  final AccountRepository _repository;

  Future<void> call({required String requestId}) {
    return _repository.confirmAccountDeletion(requestId: requestId);
  }
}
