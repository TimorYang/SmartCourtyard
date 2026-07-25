import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/app_locale_preference.dart';
import 'providers.dart';

class AppLocaleController extends AsyncNotifier<AppLocalePreference> {
  @override
  Future<AppLocalePreference> build() async {
    try {
      return await ref.read(readAppLocalePreferenceUseCaseProvider)() ??
          AppLocalePreference.english;
    } on Object {
      return AppLocalePreference.english;
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
