import 'package:flinx/core/network/network_proxy_controller.dart';
import 'package:flinx/core/network/network_proxy_preferences.dart';
import 'package:flinx/core/network/network_proxy_settings.dart';
import 'package:flinx/core/config/app_api_configuration.dart';
import 'package:flinx/core/config/providers.dart';
import 'package:flinx/core/network/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'saves settings and immediately publishes the active configuration',
    () async {
      final preferences = InMemoryNetworkProxyPreferences();
      final container = ProviderContainer(
        overrides: [
          networkProxyPreferencesProvider.overrideWithValue(preferences),
        ],
      );
      addTearDown(container.dispose);
      const settings = NetworkProxySettings(
        enabled: true,
        host: 'proxy.example.test',
        port: 9090,
      );

      await container
          .read(networkProxySettingsProvider.notifier)
          .save(settings);

      expect(container.read(networkProxySettingsProvider), settings);
      expect(await preferences.read(), settings);
    },
  );

  test(
    'turning the proxy off keeps the saved host and port for later use',
    () async {
      final preferences = InMemoryNetworkProxyPreferences();
      final container = ProviderContainer(
        overrides: [
          networkProxyPreferencesProvider.overrideWithValue(preferences),
        ],
      );
      addTearDown(container.dispose);
      const enabledSettings = NetworkProxySettings(
        enabled: true,
        host: 'proxy.example.test',
        port: 9090,
      );
      const disabledSettings = NetworkProxySettings(
        enabled: false,
        host: 'proxy.example.test',
        port: 9090,
      );

      final notifier = container.read(networkProxySettingsProvider.notifier);
      await notifier.save(enabledSettings);
      await notifier.save(disabledSettings);

      expect(container.read(networkProxySettingsProvider), disabledSettings);
      expect((await preferences.read()).proxyExpression, isNull);
    },
  );

  test('does not change active settings when persistence fails', () async {
    const initialSettings = NetworkProxySettings(
      enabled: true,
      host: 'proxy.example.test',
      port: 9090,
    );
    final container = ProviderContainer(
      overrides: [
        networkProxyPreferencesProvider.overrideWithValue(
          _FailingNetworkProxyPreferences(),
        ),
        networkProxySettingsProvider.overrideWith(
          () =>
              NetworkProxySettingsController(initialSettings: initialSettings),
        ),
      ],
    );
    addTearDown(container.dispose);
    const nextSettings = NetworkProxySettings(
      enabled: false,
      host: 'proxy.example.test',
      port: 9090,
    );

    await expectLater(
      container.read(networkProxySettingsProvider.notifier).save(nextSettings),
      throwsA(isA<StateError>()),
    );

    expect(container.read(networkProxySettingsProvider), initialSettings);
  });

  test('rejects invalid enabled settings before writing them', () async {
    final preferences = InMemoryNetworkProxyPreferences();
    final container = ProviderContainer(
      overrides: [
        networkProxyPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);
    const invalidSettings = NetworkProxySettings(
      enabled: true,
      host: 'proxy.example.test',
      port: null,
    );

    await expectLater(
      container
          .read(networkProxySettingsProvider.notifier)
          .save(invalidSettings),
      throwsA(isA<NetworkProxySettingsException>()),
    );

    expect(await preferences.read(), const NetworkProxySettings.disabled());
  });

  test('recreates the shared Dio client after a successful save', () async {
    final preferences = InMemoryNetworkProxyPreferences();
    final container = ProviderContainer(
      overrides: [
        networkProxyPreferencesProvider.overrideWithValue(preferences),
        appApiConfigurationProvider.overrideWithValue(
          const AppApiConfiguration(
            apiOrigin: 'https://api.flinx.example',
            apiPathPrefix: '/api/force-door',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final originalDio = container.read(dioProvider);

    await container
        .read(networkProxySettingsProvider.notifier)
        .save(
          const NetworkProxySettings(
            enabled: true,
            host: 'proxy.example.test',
            port: 9090,
          ),
        );

    expect(container.read(dioProvider), isNot(same(originalDio)));
  });
}

class _FailingNetworkProxyPreferences implements NetworkProxyPreferences {
  @override
  Future<NetworkProxySettings> read() async {
    return const NetworkProxySettings.disabled();
  }

  @override
  Future<void> write(NetworkProxySettings settings) async {
    throw StateError('storage unavailable');
  }
}
