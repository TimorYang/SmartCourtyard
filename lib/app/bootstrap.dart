import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../core/logging/app_logger.dart';
import '../core/network/network_proxy_controller.dart';
import '../core/network/network_proxy_preferences.dart';
import '../core/network/startup_network_access_probe.dart';
import '../core/network/providers.dart';
import '../core/storage/app_storage_paths.dart';
import '../features/account/application/providers.dart';
import '../features/auth/data/services/platform_login_device_context_provider.dart';
import 'flinx_app.dart';
import 'session/network_session_handlers.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  AppStorageLocations? storageLocations;
  try {
    storageLocations = await AppStoragePaths.resolve();
  } on Object {
    // Storage failures must leave the app signed out instead of blocking launch.
  }
  final networkProxyPreferences = storageLocations == null
      ? InMemoryNetworkProxyPreferences()
      : JsonFileNetworkProxyPreferences(
          settingsFile: File(
            '${storageLocations.persistentDirectory.path}/'
            'network_proxy_settings.json',
          ),
        );
  final networkProxySettings = await networkProxyPreferences.read();
  try {
    await PlatformLoginDeviceContextProvider().read();
  } on Object {
    // Login retries device-context creation if platform services are unavailable
    // during startup.
  }

  runApp(
    ProviderScope(
      overrides: [
        appStorageLocationsProvider.overrideWithValue(storageLocations),
        networkProxyPreferencesProvider.overrideWithValue(
          networkProxyPreferences,
        ),
        networkProxySettingsProvider.overrideWith(
          () => NetworkProxySettingsController(
            initialSettings: networkProxySettings,
          ),
        ),
        sessionExpiredHandlerProvider.overrideWith(createSessionExpiredHandler),
        tokenRefreshHandlerProvider.overrideWith(createTokenRefreshHandler),
      ],
      child: const FlinxApp(),
    ),
  );

  unawaited(
    StartupNetworkAccessProbe(
      logger: const DebugAppLogger(),
      proxySettings: networkProxySettings,
    ).trigger(),
  );
}
