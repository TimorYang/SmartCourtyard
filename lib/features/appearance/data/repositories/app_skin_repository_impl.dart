import '../../domain/entities/app_skin_id.dart';
import '../../domain/repositories/app_skin_repository.dart';
import '../data_sources/app_skin_local_data_source.dart';

class AppSkinRepositoryImpl implements AppSkinRepository {
  const AppSkinRepositoryImpl(this.localDataSource);
  final AppSkinLocalDataSource localDataSource;
  @override
  Future<AppSkinId?> readSkin() async =>
      AppSkinId.fromStorageValue(await localDataSource.readSkinId());
  @override
  Future<void> saveSkin(AppSkinId skin) =>
      localDataSource.saveSkinId(skin.storageValue);
}
