import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../core/logging/app_logger.dart';
import '../core/network/startup_network_access_probe.dart';
import 'flinx_app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ProviderScope(child: FlinxApp()));

  unawaited(
    StartupNetworkAccessProbe(logger: const DebugAppLogger()).trigger(),
  );
}
