import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/app_locale_preference.dart';
import 'package:flinx/features/account/domain/repositories/app_locale_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the system locale when no preference has been saved', () async {
    final container = ProviderContainer(
      overrides: [
        systemAppLocaleProvider.overrideWithValue(
          AppLocalePreference.simplifiedChinese,
        ),
        appLocaleRepositoryProvider.overrideWithValue(
          _FakeAppLocaleRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(appLocaleControllerProvider.future),
      AppLocalePreference.simplifiedChinese,
    );
  });

  test('restores a saved Simplified Chinese preference', () async {
    final container = ProviderContainer(
      overrides: [
        appLocaleRepositoryProvider.overrideWithValue(
          _FakeAppLocaleRepository(
            initialLocale: AppLocalePreference.simplifiedChinese,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(appLocaleControllerProvider.future),
      AppLocalePreference.simplifiedChinese,
    );
  });

  test('persists a newly selected language', () async {
    final repository = _FakeAppLocaleRepository();
    final container = ProviderContainer(
      overrides: [appLocaleRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(appLocaleControllerProvider.future);
    await container
        .read(appLocaleControllerProvider.notifier)
        .selectLocale(AppLocalePreference.simplifiedChinese);

    expect(repository.savedLocale, AppLocalePreference.simplifiedChinese);
    expect(
      _localeFrom(container.read(appLocaleControllerProvider)),
      AppLocalePreference.simplifiedChinese,
    );
  });

  test(
    'falls back to the system locale when preference storage fails',
    () async {
      final container = ProviderContainer(
        overrides: [
          systemAppLocaleProvider.overrideWithValue(
            AppLocalePreference.simplifiedChinese,
          ),
          appLocaleRepositoryProvider.overrideWithValue(
            _FakeAppLocaleRepository(throwsOnRead: true, throwsOnSave: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(appLocaleControllerProvider.future),
        AppLocalePreference.simplifiedChinese,
      );

      await container
          .read(appLocaleControllerProvider.notifier)
          .selectLocale(AppLocalePreference.simplifiedChinese);

      expect(
        _localeFrom(container.read(appLocaleControllerProvider)),
        AppLocalePreference.english,
      );
    },
  );
}

AppLocalePreference _localeFrom(AsyncValue<AppLocalePreference> state) {
  return state.maybeWhen(
    data: (locale) => locale,
    orElse: () => throw StateError('Locale state is not ready'),
  );
}

class _FakeAppLocaleRepository implements AppLocaleRepository {
  _FakeAppLocaleRepository({
    this.initialLocale,
    this.throwsOnRead = false,
    this.throwsOnSave = false,
  });

  final AppLocalePreference? initialLocale;
  final bool throwsOnRead;
  final bool throwsOnSave;
  AppLocalePreference? savedLocale;

  @override
  Future<AppLocalePreference?> readPreferredLocale() async {
    if (throwsOnRead) {
      throw StateError('read failed');
    }
    return initialLocale;
  }

  @override
  Future<void> savePreferredLocale(AppLocalePreference locale) async {
    if (throwsOnSave) {
      throw StateError('save failed');
    }
    savedLocale = locale;
  }
}
