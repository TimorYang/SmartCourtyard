import '../entities/f_box_control_mode.dart';
import '../repositories/door_control_mode_repository.dart';

class UpdateDoorControlModeUseCase {
  const UpdateDoorControlModeUseCase({required this.repository});

  final DoorControlModeRepository repository;

  Future<void> call({
    required String sn,
    required FBoxControlMode mode,
    required String requestId,
  }) {
    return repository.updateControlMode(
      sn: sn,
      mode: mode,
      requestId: requestId,
    );
  }
}
