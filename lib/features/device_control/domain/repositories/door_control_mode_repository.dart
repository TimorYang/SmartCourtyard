import '../entities/f_box_control_mode.dart';

abstract interface class DoorControlModeRepository {
  Future<void> updateControlMode({
    required String sn,
    required FBoxControlMode mode,
    required String requestId,
  });
}
