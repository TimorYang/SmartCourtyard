import 'package:url_launcher/url_launcher.dart';

abstract interface class AppUpdateUrlLauncher {
  Future<bool> open(Uri url);
}

class PlatformAppUpdateUrlLauncher implements AppUpdateUrlLauncher {
  const PlatformAppUpdateUrlLauncher();

  @override
  Future<bool> open(Uri url) async {
    if (!const {'http', 'https'}.contains(url.scheme) || url.host.isEmpty) {
      return false;
    }
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}
