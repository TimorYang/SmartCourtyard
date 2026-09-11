import '../entities/app_skin_id.dart';
import '../repositories/app_skin_repository.dart';

class SaveAppSkinUseCase {
  const SaveAppSkinUseCase(this.repository);
  final AppSkinRepository repository;
  Future<void> call(AppSkinId skin) => repository.saveSkin(skin);
}
