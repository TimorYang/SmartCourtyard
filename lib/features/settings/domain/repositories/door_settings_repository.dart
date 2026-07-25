import '../entities/door_setting_snapshot.dart';

abstract interface class DoorSettingsRepository {
  Future<List<DoorSettingSnapshot>> fetchSettings({
    required String doorId,
    required String requestId,
  });
}
