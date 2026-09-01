import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_message.dart';

import '../domain/entities/door_setting_snapshot.dart';
import '../domain/use_cases/fetch_door_settings_use_case.dart';
import 'providers.dart';

final doorSettingsControllerProvider =
    NotifierProvider.family<DoorSettingsController, DoorSettingsState, String>(
      (doorId) => DoorSettingsController(doorId),
    );

class DoorSettingsState {
  const DoorSettingsState({
    this.settings = const <DoorSettingSnapshot>[],
    this.loading = true,
    this.errorMessage,
  });

  final List<DoorSettingSnapshot> settings;
  final bool loading;
  final String? errorMessage;

  DoorSettingSnapshot? settingFor(String code) {
    for (final setting in settings) {
      if (setting.code.toUpperCase() == code) {
        return setting;
      }
    }
    return null;
  }
}

class DoorSettingsController extends Notifier<DoorSettingsState> {
  DoorSettingsController(this.doorId);

  final String doorId;
  late final FetchDoorSettingsUseCase _fetchSettings;
  int _requestCounter = 0;

  @override
  DoorSettingsState build() {
    _fetchSettings = ref.watch(fetchDoorSettingsUseCaseProvider);
    Future.microtask(load);
    return const DoorSettingsState();
  }

  Future<void> load() async {
    if (!ref.mounted) {
      return;
    }
    state = DoorSettingsState(settings: state.settings, loading: true);
    try {
      final settings = await _fetchSettings(
        doorId: doorId,
        requestId: _nextRequestId(),
      );
      if (!ref.mounted) {
        return;
      }
      state = DoorSettingsState(
        settings: List<DoorSettingSnapshot>.unmodifiable(settings),
        loading: false,
      );
    } catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = DoorSettingsState(
        settings: state.settings,
        loading: false,
        errorMessage: appErrorMessage(error, ''),
      );
    }
  }

  void updateCurrentValue(String code, int value) {
    if (!ref.mounted) {
      return;
    }
    state = DoorSettingsState(
      settings: List<DoorSettingSnapshot>.unmodifiable(
        state.settings.map(
          (setting) => setting.code.toUpperCase() == code
              ? DoorSettingSnapshot(
                  code: setting.code,
                  label: setting.label,
                  supported: setting.supported,
                  configured: setting.configured,
                  currentValue: value,
                  unit: setting.unit,
                )
              : setting,
        ),
      ),
      loading: state.loading,
      errorMessage: state.errorMessage,
    );
  }

  String _nextRequestId() {
    _requestCounter++;
    return 'door-settings-${DateTime.now().microsecondsSinceEpoch}-$_requestCounter';
  }
}
