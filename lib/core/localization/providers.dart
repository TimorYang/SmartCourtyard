import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'current_app_locale_store.dart';

final currentAppLocaleStoreProvider = Provider<CurrentAppLocaleStore>(
  (ref) => CurrentAppLocaleStore(),
);
