import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/providers.dart';
import '../domain/entities/about_device_info.dart';
import '../domain/use_cases/fetch_about_device_info_use_case.dart';
import 'device_command_controller.dart';

typedef AboutDeviceRequest = ({String doorId, String deviceId});

final aboutDeviceControllerProvider =
    NotifierProvider.family<
      AboutDeviceController,
      AsyncValue<AboutDeviceInfo>,
      AboutDeviceRequest
    >((request) => AboutDeviceController());

class AboutDeviceController extends Notifier<AsyncValue<AboutDeviceInfo>> {
  late final AppLogger _logger;
  late final FetchAboutDeviceInfoUseCase _fetchAboutDeviceInfo;
  var _requestCounter = 0;

  @override
  AsyncValue<AboutDeviceInfo> build() {
    _logger = ref.watch(appLoggerProvider);
    _fetchAboutDeviceInfo = ref.watch(fetchAboutDeviceInfoUseCaseProvider);
    return const AsyncLoading();
  }

  Future<void> load({required String doorId, required String deviceId}) async {
    final requestId =
        'about-device-$doorId-$deviceId-'
        '${DateTime.now().millisecondsSinceEpoch}-${++_requestCounter}';
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await _fetchAboutDeviceInfo(
          doorId: doorId,
          deviceId: deviceId,
          requestId: requestId,
        ),
      );
    } catch (error, stackTrace) {
      _logger.error(
        'About device information load failed',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'deviceId': deviceId},
      );
      state = AsyncError(error, stackTrace);
    }
  }
}
