import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../platform_bridge/providers.dart';

class DiagnosticLoggingSettings {
  const DiagnosticLoggingSettings({
    required this.flutterConsoleEnabled,
    required this.nativeConsoleEnabled,
  });

  const DiagnosticLoggingSettings.defaults()
    : flutterConsoleEnabled = true,
      nativeConsoleEnabled = false;

  final bool flutterConsoleEnabled;
  final bool nativeConsoleEnabled;

  DiagnosticLoggingSettings copyWith({
    bool? flutterConsoleEnabled,
    bool? nativeConsoleEnabled,
  }) {
    return DiagnosticLoggingSettings(
      flutterConsoleEnabled:
          flutterConsoleEnabled ?? this.flutterConsoleEnabled,
      nativeConsoleEnabled: nativeConsoleEnabled ?? this.nativeConsoleEnabled,
    );
  }
}

abstract interface class DiagnosticLoggingPreferences {
  Future<DiagnosticLoggingSettings> read();

  Future<void> write(DiagnosticLoggingSettings settings);
}

class SecureDiagnosticLoggingPreferences
    implements DiagnosticLoggingPreferences {
  const SecureDiagnosticLoggingPreferences(this.storage);

  static const _legacyEnabledKey = 'diagnostics.detailed_hardware_logging';
  static const _flutterEnabledKey =
      'diagnostics.flutter_console_hardware_logging';
  static const _nativeEnabledKey =
      'diagnostics.native_console_hardware_logging';

  final FlutterSecureStorage storage;

  @override
  Future<DiagnosticLoggingSettings> read() async {
    final values = await storage.readAll();
    final flutterValue = values[_flutterEnabledKey];
    final nativeValue = values[_nativeEnabledKey];
    if (flutterValue == null && nativeValue == null) {
      final legacyEnabled = values[_legacyEnabledKey];
      if (legacyEnabled != null) {
        return DiagnosticLoggingSettings(
          flutterConsoleEnabled: legacyEnabled == 'true',
          nativeConsoleEnabled: false,
        );
      }
      return const DiagnosticLoggingSettings.defaults();
    }
    return DiagnosticLoggingSettings(
      flutterConsoleEnabled: flutterValue == 'true',
      nativeConsoleEnabled: nativeValue == 'true',
    );
  }

  @override
  Future<void> write(DiagnosticLoggingSettings settings) async {
    await storage.write(
      key: _flutterEnabledKey,
      value: settings.flutterConsoleEnabled.toString(),
    );
    await storage.write(
      key: _nativeEnabledKey,
      value: settings.nativeConsoleEnabled.toString(),
    );
  }
}

final diagnosticLoggingPreferencesProvider =
    Provider<DiagnosticLoggingPreferences>((ref) {
      return SecureDiagnosticLoggingPreferences(
        const FlutterSecureStorage(
          aOptions: AndroidOptions(),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.unlocked_this_device,
          ),
        ),
      );
    });

final diagnosticLoggingControllerProvider =
    AsyncNotifierProvider<
      DiagnosticLoggingController,
      DiagnosticLoggingSettings
    >(DiagnosticLoggingController.new);

class DiagnosticLoggingController
    extends AsyncNotifier<DiagnosticLoggingSettings> {
  @override
  Future<DiagnosticLoggingSettings> build() async {
    final settings = await ref
        .watch(diagnosticLoggingPreferencesProvider)
        .read();
    await _apply(settings);
    return settings;
  }

  Future<void> setFlutterConsoleEnabled(bool enabled) {
    final current = state.value ?? const DiagnosticLoggingSettings.defaults();
    return _set(current.copyWith(flutterConsoleEnabled: enabled));
  }

  Future<void> setNativeConsoleEnabled(bool enabled) {
    final current = state.value ?? const DiagnosticLoggingSettings.defaults();
    return _set(current.copyWith(nativeConsoleEnabled: enabled));
  }

  Future<void> _set(DiagnosticLoggingSettings settings) async {
    if (state.value?.flutterConsoleEnabled == settings.flutterConsoleEnabled &&
        state.value?.nativeConsoleEnabled == settings.nativeConsoleEnabled &&
        !state.isLoading) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _apply(settings);
      await ref.read(diagnosticLoggingPreferencesProvider).write(settings);
      return settings;
    });
  }

  Future<void> _apply(DiagnosticLoggingSettings settings) {
    return ref
        .read(nativeHardwareGatewayProvider)
        .configureHardwareLogging(
          flutterConsoleEnabled: settings.flutterConsoleEnabled,
          nativeConsoleEnabled: settings.nativeConsoleEnabled,
        );
  }
}
