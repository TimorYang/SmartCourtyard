import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppStorageLocations {
  const AppStorageLocations({
    required this.persistentDirectory,
    required this.legacyDirectories,
  });

  final Directory persistentDirectory;
  final List<Directory> legacyDirectories;
}

class AppStoragePaths {
  const AppStoragePaths._();

  static bool get isFlutterTest {
    return Platform.environment['FLUTTER_TEST'] == 'true';
  }

  static Future<AppStorageLocations> resolve() async {
    final persistentDirectory = await getApplicationSupportDirectory();
    return AppStorageLocations(
      persistentDirectory: persistentDirectory,
      legacyDirectories: _legacyDirectories()
          .where((directory) => directory.path != persistentDirectory.path)
          .toList(growable: false),
    );
  }

  static List<Directory> _legacyDirectories() {
    final directories = <Directory>[];
    final home = Platform.environment['HOME']?.trim();
    if (home != null && home.isNotEmpty) {
      directories.add(Directory('$home/.flinx'));
    }
    directories.add(Directory('${Directory.systemTemp.path}/flinx'));
    final seenPaths = <String>{};
    return directories
        .where((directory) => seenPaths.add(directory.path))
        .toList(growable: false);
  }
}
