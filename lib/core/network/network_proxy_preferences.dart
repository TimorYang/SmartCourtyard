import 'dart:convert';
import 'dart:io';

import 'network_proxy_settings.dart';

abstract interface class NetworkProxyPreferences {
  Future<NetworkProxySettings> read();

  Future<void> write(NetworkProxySettings settings);
}

class InMemoryNetworkProxyPreferences implements NetworkProxyPreferences {
  InMemoryNetworkProxyPreferences({
    NetworkProxySettings initialSettings =
        const NetworkProxySettings.disabled(),
  }) : _settings = initialSettings;

  NetworkProxySettings _settings;

  @override
  Future<NetworkProxySettings> read() async => _settings;

  @override
  Future<void> write(NetworkProxySettings settings) async {
    _settings = settings.normalized();
  }
}

class JsonFileNetworkProxyPreferences implements NetworkProxyPreferences {
  JsonFileNetworkProxyPreferences({required this.settingsFile});

  final File settingsFile;

  @override
  Future<NetworkProxySettings> read() async {
    try {
      if (!await settingsFile.exists()) {
        return const NetworkProxySettings.disabled();
      }
      final decoded = jsonDecode(await settingsFile.readAsString());
      return NetworkProxySettings.fromJson(decoded);
    } on Object {
      return const NetworkProxySettings.disabled();
    }
  }

  @override
  Future<void> write(NetworkProxySettings settings) async {
    await settingsFile.parent.create(recursive: true);
    await settingsFile.writeAsString(jsonEncode(settings.toJson()));
  }
}
