import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/platform_login_device_context_provider.dart';
import '../domain/services/login_device_context_provider.dart';

/// Provides the stable per-installation context shared by login and push.
final loginDeviceContextProvider = Provider<LoginDeviceContextProvider>((ref) {
  return PlatformLoginDeviceContextProvider();
});
