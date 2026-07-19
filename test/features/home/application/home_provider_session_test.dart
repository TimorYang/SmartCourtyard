import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/features/home/domain/entities/home_scene.dart';
import 'package:flinx/features/home/domain/repositories/home_scene_repository.dart';
import 'package:flinx/features/home/domain/use_cases/fetch_home_scenes_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reloads home scenes when the authenticated user changes', () async {
    final repository = _SequencedHomeSceneRepository();
    final container = ProviderContainer(
      overrides: [
        fetchHomeScenesUseCaseProvider.overrideWithValue(
          FetchHomeScenesUseCase(repository: repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(activeAuthSessionProvider.notifier)
        .markAuthenticated(userId: 'user-a');
    final firstScenes = await container.read(homeScenesProvider.future);

    container.read(activeAuthSessionProvider.notifier).clear();
    container
        .read(activeAuthSessionProvider.notifier)
        .markAuthenticated(userId: 'user-b');
    final secondScenes = await container.read(homeScenesProvider.future);

    expect(firstScenes.single.name, 'A Home');
    expect(secondScenes.single.name, 'B Home');
    expect(repository.fetchCount, 2);
  });
}

class _SequencedHomeSceneRepository implements HomeSceneRepository {
  var fetchCount = 0;

  @override
  Future<List<HomeScene>> fetchScenes({required String requestId}) async {
    fetchCount++;
    return [
      HomeScene(
        id: fetchCount,
        name: fetchCount == 1 ? 'A Home' : 'B Home',
        doorCount: 0,
        isDefault: true,
      ),
    ];
  }

  @override
  Future<HomeScene> createScene({
    required String name,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteScene({required int sceneId, required String requestId}) =>
      throw UnimplementedError();

  @override
  Future<void> renameScene({
    required int sceneId,
    required String name,
    required String requestId,
  }) => throw UnimplementedError();
}
