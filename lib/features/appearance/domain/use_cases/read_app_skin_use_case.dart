import '../entities/app_skin_id.dart';
import '../repositories/app_skin_repository.dart';

class ReadAppSkinUseCase {
  const ReadAppSkinUseCase(this.repository);
  final AppSkinRepository repository;
  Future<AppSkinId?> call() => repository.readSkin();
}
