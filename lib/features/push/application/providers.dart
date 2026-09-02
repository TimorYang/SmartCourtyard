import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_service.dart';

export 'dependencies.dart';
export 'push_service.dart';

final pushServiceProvider =
    NotifierProvider<PushService, PushInitializationState>(PushService.new);
