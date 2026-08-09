class AppApiConfiguration {
  const AppApiConfiguration({
    required this.apiOrigin,
    required this.apiPathPrefix,
  });

  factory AppApiConfiguration.fromEnvironment() {
    const apiOrigin = String.fromEnvironment(
      'FLINX_API_ORIGIN',
      defaultValue: 'https://forcedoor.feizhoukeji.com:15429',
    );
    const apiPathPrefix = String.fromEnvironment(
      'FLINX_API_PATH_PREFIX',
      defaultValue: '/api/force-door',
    );
    return const AppApiConfiguration(
      apiOrigin: apiOrigin,
      apiPathPrefix: apiPathPrefix,
    );
  }

  final String apiOrigin;
  final String apiPathPrefix;

  Uri get apiBaseUri {
    final origin = _validatedOrigin();
    final prefix = _validatedPathPrefix();
    return origin.replace(
      path: '${origin.path.replaceAll(RegExp(r'/+$'), '')}$prefix/',
      query: null,
      fragment: null,
    );
  }

  Uri resolveApiPath(String path) {
    final normalizedPath = path.trim().replaceFirst(RegExp(r'^/+'), '');
    if (normalizedPath.isEmpty) {
      throw const AppApiConfigurationException.invalidPath();
    }

    return apiBaseUri.resolve(normalizedPath);
  }

  void validate() {
    _validatedOrigin();
    _validatedPathPrefix();
  }

  Uri _validatedOrigin() {
    final origin = Uri.tryParse(apiOrigin.trim());
    if (origin == null ||
        (origin.scheme != 'http' && origin.scheme != 'https') ||
        origin.host.isEmpty ||
        origin.hasQuery ||
        origin.hasFragment) {
      throw const AppApiConfigurationException.invalidOrigin();
    }
    return origin;
  }

  String _validatedPathPrefix() {
    final normalized = apiPathPrefix.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    if (normalized.isEmpty) {
      throw const AppApiConfigurationException.invalidPathPrefix();
    }
    return '/$normalized';
  }
}

class AppApiConfigurationException implements Exception {
  const AppApiConfigurationException._(this.kind);

  const AppApiConfigurationException.invalidOrigin()
    : this._(AppApiConfigurationErrorKind.invalidOrigin);
  const AppApiConfigurationException.invalidPathPrefix()
    : this._(AppApiConfigurationErrorKind.invalidPathPrefix);
  const AppApiConfigurationException.invalidPath()
    : this._(AppApiConfigurationErrorKind.invalidPath);

  final AppApiConfigurationErrorKind kind;
}

enum AppApiConfigurationErrorKind {
  invalidOrigin,
  invalidPathPrefix,
  invalidPath,
}
