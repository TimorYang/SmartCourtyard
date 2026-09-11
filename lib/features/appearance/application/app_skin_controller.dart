import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/app_skin_id.dart';
import 'providers.dart';

class AppSkinController extends AsyncNotifier<AppSkinId> {
  bool _saving = false;

  @override
  Future<AppSkinId> build() async {
    try {
      return await ref.read(readAppSkinUseCaseProvider)() ??
          AppSkinId.minimalist;
    } on Object {
      return AppSkinId.minimalist;
    }
  }

  Future<bool> applySkin(AppSkinId skin) async {
    if (_saving || state.value == null) return false;
    if (state.value == skin) return true;
    _saving = true;
    try {
      await ref.read(saveAppSkinUseCaseProvider)(skin);
      if (ref.mounted) state = AsyncData(skin);
      return true;
    } on Object {
      return false;
    } finally {
      _saving = false;
    }
  }
}
