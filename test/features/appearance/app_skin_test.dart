import 'dart:async';
import 'dart:io';

import 'package:flinx/features/appearance/application/providers.dart';
import 'package:flinx/features/appearance/data/data_sources/app_skin_local_data_source.dart';
import 'package:flinx/features/appearance/data/repositories/app_skin_repository_impl.dart';
import 'package:flinx/features/appearance/domain/entities/app_skin_id.dart';
import 'package:flinx/features/appearance/domain/repositories/app_skin_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('failed file replacement preserves the last persisted skin', () async {
    final directory = await Directory.systemTemp.createTemp('flinx-skin-write');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/appearance.json');
    final source = JsonFileAppSkinLocalDataSource(file);
    await source.saveSkinId(AppSkinId.dark.storageValue);
    await Directory('${file.path}.tmp').create();
    await expectLater(
      source.saveSkinId(AppSkinId.technologyWind.storageValue),
      throwsA(isA<FileSystemException>()),
    );
    expect(await source.readSkinId(), AppSkinId.dark.storageValue);
  });

  test(
    'persists a choice across data source and controller recreation',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'flinx-skin-test',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/appearance.json');
      ProviderContainer create() => ProviderContainer(
        overrides: [
          appSkinRepositoryProvider.overrideWithValue(
            AppSkinRepositoryImpl(JsonFileAppSkinLocalDataSource(file)),
          ),
        ],
      );
      final first = create();
      expect(
        await first.read(appSkinControllerProvider.future),
        AppSkinId.minimalist,
      );
      expect(
        await first
            .read(appSkinControllerProvider.notifier)
            .applySkin(AppSkinId.dark),
        isTrue,
      );
      first.dispose();
      final second = create();
      addTearDown(second.dispose);
      expect(
        await second.read(appSkinControllerProvider.future),
        AppSkinId.dark,
      );
      expect(await File('${file.path}.tmp').exists(), isFalse);
    },
  );

  test(
    'missing, corrupt and unknown preferences fall back to minimalist',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'flinx-skin-test',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/appearance.json');
      for (final data in [
        null,
        '{broken',
        '{"skinId":42}',
        '{"skinId":"removed"}',
      ]) {
        if (data != null) await file.writeAsString(data);
        final container = ProviderContainer(
          overrides: [
            appSkinRepositoryProvider.overrideWithValue(
              AppSkinRepositoryImpl(JsonFileAppSkinLocalDataSource(file)),
            ),
          ],
        );
        expect(
          await container.read(appSkinControllerProvider.future),
          AppSkinId.minimalist,
        );
        container.dispose();
      }
    },
  );

  test(
    'read failure does not prevent startup; write failure keeps current skin',
    () async {
      final repository = _Repository()..fail = true;
      final container = ProviderContainer(
        overrides: [appSkinRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      expect(
        await container.read(appSkinControllerProvider.future),
        AppSkinId.minimalist,
      );
      expect(
        await container
            .read(appSkinControllerProvider.notifier)
            .applySkin(AppSkinId.dark),
        isFalse,
      );
      expect(
        container.read(appSkinControllerProvider).value,
        AppSkinId.minimalist,
      );
      repository.fail = false;
      expect(
        await container
            .read(appSkinControllerProvider.notifier)
            .applySkin(AppSkinId.dark),
        isTrue,
      );
    },
  );

  test(
    'keeps applied choice while saving and prevents concurrent submissions',
    () async {
      final repository = _Repository()..pending = Completer<void>();
      final container = ProviderContainer(
        overrides: [appSkinRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(appSkinControllerProvider.future);
      final controller = container.read(appSkinControllerProvider.notifier);
      final saving = controller.applySkin(AppSkinId.dark);
      expect(
        container.read(appSkinControllerProvider).value,
        AppSkinId.minimalist,
      );
      expect(await controller.applySkin(AppSkinId.technologyWind), isFalse);
      expect(repository.writes, 1);
      repository.pending!.complete();
      expect(await saving, isTrue);
      expect(container.read(appSkinControllerProvider).value, AppSkinId.dark);
      expect(await controller.applySkin(AppSkinId.dark), isTrue);
      expect(repository.writes, 1);
    },
  );
}

class _Repository implements AppSkinRepository {
  bool fail = false;
  int writes = 0;
  Completer<void>? pending;
  @override
  Future<AppSkinId?> readSkin() async {
    if (fail) throw StateError('unavailable');
    return null;
  }

  @override
  Future<void> saveSkin(AppSkinId skin) async {
    writes++;
    if (fail) throw StateError('unavailable');
    await pending?.future;
  }
}
