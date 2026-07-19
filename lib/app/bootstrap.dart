import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../core/logging/app_logger.dart';
import '../core/network/startup_network_access_probe.dart';
import '../core/storage/app_storage_paths.dart';
import '../features/account/application/providers.dart';
import 'flinx_app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  AppStorageLocations? storageLocations;
  try {
    storageLocations = await AppStoragePaths.resolve();
  } on Object {
    // Storage failures must leave the app signed out instead of blocking launch.
  }

  runApp(
    ProviderScope(
      overrides: [
        appStorageLocationsProvider.overrideWithValue(storageLocations),
      ],
      child: const FlinxApp(),
    ),
  );

  unawaited(
    StartupNetworkAccessProbe(logger: const DebugAppLogger()).trigger(),
  );
}
