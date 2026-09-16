import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network_proxy_preferences.dart';
import 'network_proxy_settings.dart';

final networkProxyPreferencesProvider = Provider<NetworkProxyPreferences>(
  (ref) => InMemoryNetworkProxyPreferences(),
);

final networkProxySettingsProvider =
    NotifierProvider<NetworkProxySettingsController, NetworkProxySettings>(
      NetworkProxySettingsController.new,
    );

class NetworkProxySettingsController extends Notifier<NetworkProxySettings> {
  NetworkProxySettingsController({
    this.initialSettings = const NetworkProxySettings.disabled(),
  });

  final NetworkProxySettings initialSettings;

  @override
  NetworkProxySettings build() {
    final normalized = initialSettings.normalized();
    return normalized.isValid
        ? normalized
        : const NetworkProxySettings.disabled();
  }

  Future<void> save(NetworkProxySettings settings) async {
    final normalized = settings.normalized();
    if (!normalized.isValid) {
      throw const NetworkProxySettingsException.invalidSettings();
    }

    await ref.read(networkProxyPreferencesProvider).write(normalized);
    state = normalized;
  }
}

class NetworkProxySettingsException implements Exception {
  const NetworkProxySettingsException.invalidSettings();
}
