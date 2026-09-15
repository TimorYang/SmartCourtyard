import 'dart:convert';
import 'dart:io';

abstract interface class AppSkinLocalDataSource {
  Future<String?> readSkinId();
  Future<void> saveSkinId(String id);
}

class JsonFileAppSkinLocalDataSource implements AppSkinLocalDataSource {
  const JsonFileAppSkinLocalDataSource(this.file);
  final File file;

  @override
  Future<String?> readSkinId() async {
    // try {
    //   if (!await file.exists()) return null;
    //   final data = jsonDecode(await file.readAsString());
    //   return data is Map && data['skinId'] is String
    //       ? data['skinId'] as String
    //       : null;
    // } on Object {
    //   return null;
    // }
    // return 'minimalist';       // 极简风格
    // return 'dark';             // 暗夜风格
    return 'technology_wind';  // 科技风
  }

  @override
  Future<void> saveSkinId(String id) async {
    await file.parent.create(recursive: true);
    // Replace only after the complete preference has reached disk.
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode({'skinId': id}), flush: true);
    await temporary.rename(file.path);
  }
}

class InMemoryAppSkinLocalDataSource implements AppSkinLocalDataSource {
  InMemoryAppSkinLocalDataSource([this.skinId]);
  String? skinId;
  @override
  Future<String?> readSkinId() async => skinId;
  @override
  Future<void> saveSkinId(String id) async {
    skinId = id;
  }
}

class UnavailableAppSkinLocalDataSource implements AppSkinLocalDataSource {
  const UnavailableAppSkinLocalDataSource();
  @override
  Future<String?> readSkinId() async => null;
  @override
  Future<void> saveSkinId(String id) async {
    throw const FileSystemException('Appearance storage unavailable');
  }
}
