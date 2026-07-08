import 'dart:io';

class AppStoragePaths {
  const AppStoragePaths._();

  static bool get isFlutterTest {
    return Platform.environment['FLUTTER_TEST'] == 'true';
  }

  static Directory defaultStorageDirectory() {
    final home = Platform.environment['HOME']?.trim();
    if (home != null && home.isNotEmpty) {
      return Directory('$home/.flinx');
    }

    return Directory('${Directory.systemTemp.path}/flinx');
  }
}
