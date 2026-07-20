import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../platform_bridge/providers.dart';

abstract interface class DiagnosticLoggingPreferences {
  Future<bool> readEnabled();

  Future<void> writeEnabled(bool enabled);
}

class SecureDiagnosticLoggingPreferences
    implements DiagnosticLoggingPreferences {
  const SecureDiagnosticLoggingPreferences(this.storage);

  static const _enabledKey = 'diagnostics.detailed_hardware_logging';

  final FlutterSecureStorage storage;

  @override
  Future<bool> readEnabled() async {
    return await storage.read(key: _enabledKey) == 'true';
  }

  @override
  Future<void> writeEnabled(bool enabled) {
    return storage.write(key: _enabledKey, value: enabled.toString());
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
    AsyncNotifierProvider<DiagnosticLoggingController, bool>(
      DiagnosticLoggingController.new,
    );

class DiagnosticLoggingController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final enabled = await ref
        .watch(diagnosticLoggingPreferencesProvider)
        .readEnabled();
    await ref
        .watch(nativeHardwareGatewayProvider)
        .setDetailedHardwareLogging(enabled: enabled);
    return enabled;
  }

  Future<void> setEnabled(bool enabled) async {
    final previous = state.value ?? false;
    if (previous == enabled && !state.isLoading) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(nativeHardwareGatewayProvider)
          .setDetailedHardwareLogging(enabled: enabled);
      await ref
          .read(diagnosticLoggingPreferencesProvider)
          .writeEnabled(enabled);
      return enabled;
    });
  }
}
