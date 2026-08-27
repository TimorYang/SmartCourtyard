import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../dto/upgrade_dto.dart';

class PlatformAppReleaseContextProvider {
  PlatformAppReleaseContextProvider({
    Future<PackageInfo> Function()? packageInfo,
    TargetPlatform Function()? targetPlatform,
  }) : _packageInfo = packageInfo ?? PackageInfo.fromPlatform,
       _targetPlatform = targetPlatform ?? (() => defaultTargetPlatform);

  final Future<PackageInfo> Function() _packageInfo;
  final TargetPlatform Function() _targetPlatform;

  Future<AppReleaseCheckRequestDto> read() async {
    final platform = switch (_targetPlatform()) {
      TargetPlatform.iOS => 'IOS',
      TargetPlatform.android => 'ANDROID',
      _ => throw UnsupportedError('App release checks require iOS or Android.'),
    };
    final buildNumber = (await _packageInfo()).buildNumber.trim();
    if (int.tryParse(buildNumber) == null) {
      throw const FormatException('The app build number must be numeric.');
    }
    return AppReleaseCheckRequestDto(
      platform: platform,
      buildNumber: buildNumber,
    );
  }
}
