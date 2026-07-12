import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_api_configuration.dart';

final appApiConfigurationProvider = Provider<AppApiConfiguration>((ref) {
  final configuration = AppApiConfiguration.fromEnvironment();
  configuration.validate();
  return configuration;
});
