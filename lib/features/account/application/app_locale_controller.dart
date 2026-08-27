import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/app_locale_preference.dart';
import 'providers.dart';

class AppLocaleController extends AsyncNotifier<AppLocalePreference> {
  @override
  Future<AppLocalePreference> build() async {
    final systemLocale = ref.read(systemAppLocaleProvider);
    try {
      return await ref.read(readAppLocalePreferenceUseCaseProvider)() ??
          systemLocale;
    } on Object {
      return systemLocale;
    }
  }

  Future<void> selectLocale(AppLocalePreference locale) async {
    state = AsyncData(locale);
    try {
      await ref.read(saveAppLocalePreferenceUseCaseProvider)(locale);
    } on Object {
      state = const AsyncData(AppLocalePreference.english);
    }
  }
}
