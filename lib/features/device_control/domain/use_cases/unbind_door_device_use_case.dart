import '../repositories/door_detail_repository.dart';

class UnbindDoorDeviceUseCase {
  const UnbindDoorDeviceUseCase({required this.repository});

  final DoorDetailRepository repository;

  Future<void> call({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) {
    return repository.unbindDoorDevice(
      doorId: doorId,
      deviceId: deviceId,
      requestId: requestId,
    );
  }
}
