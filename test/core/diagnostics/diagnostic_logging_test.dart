import 'package:flinx/core/diagnostics/diagnostic_logging.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/platform_bridge/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restores and persists detailed hardware logging', () async {
    final preferences = _MemoryPreferences(true);
    final gateway = MockHardwareGateway();
    final container = ProviderContainer(
      overrides: [
        diagnosticLoggingPreferencesProvider.overrideWithValue(preferences),
        nativeHardwareGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(diagnosticLoggingControllerProvider.future),
      isTrue,
    );
    expect(gateway.detailedHardwareLoggingEnabled, isTrue);

    await container
        .read(diagnosticLoggingControllerProvider.notifier)
        .setEnabled(false);

    expect(preferences.enabled, isFalse);
    expect(gateway.detailedHardwareLoggingEnabled, isFalse);
    expect(container.read(diagnosticLoggingControllerProvider).value, isFalse);
  });
}

class _MemoryPreferences implements DiagnosticLoggingPreferences {
  _MemoryPreferences(this.enabled);

  bool enabled;

  @override
  Future<bool> readEnabled() async => enabled;

  @override
  Future<void> writeEnabled(bool enabled) async {
    this.enabled = enabled;
  }
}
