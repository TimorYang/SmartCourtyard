import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/providers.dart';
import '../logging/providers.dart';
import 'dio_factory.dart';

final dioProvider = Provider((ref) {
  return DioFactory.create(
    configuration: ref.watch(appApiConfigurationProvider),
    logger: ref.watch(appLoggerProvider),
  );
});
