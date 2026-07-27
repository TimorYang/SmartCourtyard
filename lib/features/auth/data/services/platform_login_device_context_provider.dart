import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/login_device_context.dart';
import '../../domain/services/login_device_context_provider.dart';

class PlatformLoginDeviceContextProvider implements LoginDeviceContextProvider {
  PlatformLoginDeviceContextProvider({
    FlutterSecureStorage? storage,
    DeviceInfoPlugin? deviceInfo,
    Future<Directory> Function()? applicationSupportDirectory,
    Future<PackageInfo> Function()? packageInfo,
  }) : _storage =
           storage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(),
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.unlocked_this_device,
             ),
           ),
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
       _applicationSupportDirectory =
           applicationSupportDirectory ?? getApplicationSupportDirectory,
       _packageInfo = packageInfo ?? PackageInfo.fromPlatform;

  static const _deviceIdKey = 'auth.login.installation_device_id';
  static const _installationMarkerFileName = '.installation_marker';

  final FlutterSecureStorage _storage;
  final DeviceInfoPlugin _deviceInfo;
  final Future<Directory> Function() _applicationSupportDirectory;
  final Future<PackageInfo> Function() _packageInfo;

  Future<String>? _deviceIdFuture;

  @override
  Future<LoginDeviceContext> read() async {
    final results = await Future.wait<String>([
      _readDeviceId(),
      _readDeviceModel(),
      _readAppVersion(),
    ]);
    return LoginDeviceContext(
      deviceId: results[0],
      deviceModel: results[1],
      platform: Platform.isIOS ? 'IOS' : 'ANDROID',
      appVersion: results[2],
    );
  }

  Future<String> _readDeviceId() => _deviceIdFuture ??= _readOrCreateDeviceId();

  Future<String> _readOrCreateDeviceId() async {
    try {
      final directory = await _applicationSupportDirectory();
      final marker = File('${directory.path}/$_installationMarkerFileName');
      if (await marker.exists()) {
        final storedId = await _storage.read(key: _deviceIdKey);
        if (_isUuid(storedId)) {
          return storedId!;
        }
      }

      final deviceId = _newUuid();
      await directory.create(recursive: true);
      await _storage.write(key: _deviceIdKey, value: deviceId);
      await marker.writeAsString(deviceId, flush: true);
      return deviceId;
    } on Object {
      // A non-empty per-process UUID keeps the required request field valid if
      // platform storage is temporarily unavailable.
      return _newUuid();
    }
  }

  Future<String> _readDeviceModel() async {
    try {
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        final identifier = info.utsname.machine.trim();
        if (identifier.isNotEmpty) {
          return identifier;
        }
        final model = info.model.trim();
        return model.isEmpty ? 'iPhone' : model;
      }
      final info = await _deviceInfo.androidInfo;
      final manufacturer = info.manufacturer.trim();
      final model = info.model.trim();
      final deviceModel = [
        manufacturer,
        model,
      ].where((value) => value.isNotEmpty).join(' ');
      return deviceModel.isEmpty ? 'Android' : deviceModel;
    } on Object {
      return Platform.isIOS ? 'iPhone' : 'Android';
    }
  }

  Future<String> _readAppVersion() async {
    try {
      final version = (await _packageInfo()).version.trim();
      return version.isEmpty ? '0.1.0' : version;
    } on Object {
      return '0.1.0';
    }
  }

  bool _isUuid(String? value) =>
      value != null &&
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(value);

  String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
