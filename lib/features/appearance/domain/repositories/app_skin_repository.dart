import '../entities/app_skin_id.dart';

abstract interface class AppSkinRepository {
  Future<AppSkinId?> readSkin();
  Future<void> saveSkin(AppSkinId skin);
}
