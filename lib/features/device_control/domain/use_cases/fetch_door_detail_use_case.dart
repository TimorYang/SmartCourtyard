import '../entities/door_detail.dart';
import '../repositories/door_detail_repository.dart';

class FetchDoorDetailUseCase {
  const FetchDoorDetailUseCase({required this.repository});

  final DoorDetailRepository repository;

  Future<DoorDetail> call({required String doorId, required String requestId}) {
    return repository.fetchDoorDetail(doorId: doorId, requestId: requestId);
  }
}
