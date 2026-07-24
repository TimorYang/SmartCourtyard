import 'package:flinx/core/diagnostics/diagnostic_logging.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/platform_bridge/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restores and independently persists both logging switches', () async {
    final preferences = _MemoryPreferences(
      const DiagnosticLoggingSettings(
        flutterConsoleEnabled: true,
        nativeConsoleEnabled: false,
      ),
    );
    final gateway = MockHardwareGateway();
    final container = ProviderContainer(
      overrides: [
        diagnosticLoggingPreferencesProvider.overrideWithValue(preferences),
        nativeHardwareGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);

    final restored = await container.read(
      diagnosticLoggingControllerProvider.future,
    );
    expect(restored.flutterConsoleEnabled, isTrue);
    expect(restored.nativeConsoleEnabled, isFalse);
    expect(gateway.flutterConsoleLoggingEnabled, isTrue);
    expect(gateway.nativeConsoleLoggingEnabled, isFalse);

    await container
        .read(diagnosticLoggingControllerProvider.notifier)
        .setNativeConsoleEnabled(true);

    expect(preferences.settings.flutterConsoleEnabled, isTrue);
    expect(preferences.settings.nativeConsoleEnabled, isTrue);
    expect(gateway.flutterConsoleLoggingEnabled, isTrue);
    expect(gateway.nativeConsoleLoggingEnabled, isTrue);

    await container
        .read(diagnosticLoggingControllerProvider.notifier)
        .setFlutterConsoleEnabled(false);

    expect(preferences.settings.flutterConsoleEnabled, isFalse);
    expect(preferences.settings.nativeConsoleEnabled, isTrue);
  });
}

class _MemoryPreferences implements DiagnosticLoggingPreferences {
  _MemoryPreferences(this.settings);

  DiagnosticLoggingSettings settings;

  @override
  Future<DiagnosticLoggingSettings> read() async => settings;

  @override
  Future<void> write(DiagnosticLoggingSettings settings) async {
    this.settings = settings;
  }
}
