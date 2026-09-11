import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_storage_paths.dart';
import '../../../core/storage/providers.dart';
import '../data/data_sources/app_skin_local_data_source.dart';
import '../data/repositories/app_skin_repository_impl.dart';
import '../domain/entities/app_skin_id.dart';
import '../domain/repositories/app_skin_repository.dart';
import '../domain/use_cases/read_app_skin_use_case.dart';
import '../domain/use_cases/save_app_skin_use_case.dart';
import 'app_skin_controller.dart';

final appSkinLocalDataSourceProvider = Provider<AppSkinLocalDataSource>((ref) {
  if (AppStoragePaths.isFlutterTest) return InMemoryAppSkinLocalDataSource();
  final locations = ref.watch(appStorageLocationsProvider);
  if (locations == null) return const UnavailableAppSkinLocalDataSource();
  return JsonFileAppSkinLocalDataSource(
    File('${locations.persistentDirectory.path}/app_skin_preference.json'),
  );
});
final appSkinRepositoryProvider = Provider<AppSkinRepository>(
  (ref) => AppSkinRepositoryImpl(ref.watch(appSkinLocalDataSourceProvider)),
);
final readAppSkinUseCaseProvider = Provider(
  (ref) => ReadAppSkinUseCase(ref.watch(appSkinRepositoryProvider)),
);
final saveAppSkinUseCaseProvider = Provider(
  (ref) => SaveAppSkinUseCase(ref.watch(appSkinRepositoryProvider)),
);
final appSkinControllerProvider =
    AsyncNotifierProvider<AppSkinController, AppSkinId>(AppSkinController.new);
