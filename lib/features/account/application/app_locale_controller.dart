import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/providers.dart';
import '../domain/entities/app_locale_preference.dart';
import 'providers.dart';

class AppLocaleController extends AsyncNotifier<AppLocalePreference> {
  @override
  Future<AppLocalePreference> build() async {
    final systemLocale = ref.read(systemAppLocaleProvider);
    _syncNetworkLocale(systemLocale);
    try {
      final locale =
          await ref.read(readAppLocalePreferenceUseCaseProvider)() ??
          systemLocale;
      _syncNetworkLocale(locale);
      return locale;
    } on Object {
      _syncNetworkLocale(systemLocale);
      return systemLocale;
    }
  }

  Future<void> selectLocale(AppLocalePreference locale) async {
    state = AsyncData(locale);
    _syncNetworkLocale(locale);
    try {
      await ref.read(saveAppLocalePreferenceUseCaseProvider)(locale);
    } on Object {
      const fallback = AppLocalePreference.english;
      state = const AsyncData(fallback);
      _syncNetworkLocale(fallback);
    }
  }

  void _syncNetworkLocale(AppLocalePreference locale) {
    ref.read(currentAppLocaleStoreProvider).setLocale(locale.serverLocale);
  }
}
