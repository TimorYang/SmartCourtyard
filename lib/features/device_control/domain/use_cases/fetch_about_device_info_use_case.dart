import '../entities/about_device_info.dart';
import '../repositories/door_detail_repository.dart';

class FetchAboutDeviceInfoUseCase {
  const FetchAboutDeviceInfoUseCase({required this.repository});

  final DoorDetailRepository repository;

  Future<AboutDeviceInfo> call({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) => repository.fetchAboutDeviceInfo(
    doorId: doorId,
    deviceId: deviceId,
    requestId: requestId,
  );
}
