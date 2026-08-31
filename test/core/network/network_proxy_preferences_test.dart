import 'dart:io';

import 'package:flinx/core/network/network_proxy_preferences.dart';
import 'package:flinx/core/network/network_proxy_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'flinx-network-proxy-test-',
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'returns disabled settings when the preferences file is missing',
    () async {
      final preferences = JsonFileNetworkProxyPreferences(
        settingsFile: File(
          '${temporaryDirectory.path}/network_proxy_settings.json',
        ),
      );

      expect(await preferences.read(), const NetworkProxySettings.disabled());
    },
  );

  test('round trips a valid configuration through JSON storage', () async {
    final preferences = JsonFileNetworkProxyPreferences(
      settingsFile: File(
        '${temporaryDirectory.path}/nested/network_proxy_settings.json',
      ),
    );
    const expected = NetworkProxySettings(
      enabled: true,
      host: 'proxy.example.test',
      port: 9090,
    );

    await preferences.write(expected);

    expect(await preferences.read(), expected);
  });

  test('returns disabled settings when the file is malformed', () async {
    final settingsFile = File(
      '${temporaryDirectory.path}/network_proxy_settings.json',
    );
    await settingsFile.writeAsString('{not valid json');
    final preferences = JsonFileNetworkProxyPreferences(
      settingsFile: settingsFile,
    );

    expect(await preferences.read(), const NetworkProxySettings.disabled());
  });

  test(
    'returns disabled settings when the stored enabled config is invalid',
    () async {
      final settingsFile = File(
        '${temporaryDirectory.path}/network_proxy_settings.json',
      );
      await settingsFile.writeAsString(
        '{"enabled":true,"host":"proxy.example.test","port":0}',
      );
      final preferences = JsonFileNetworkProxyPreferences(
        settingsFile: settingsFile,
      );

      expect(await preferences.read(), const NetworkProxySettings.disabled());
    },
  );
}
