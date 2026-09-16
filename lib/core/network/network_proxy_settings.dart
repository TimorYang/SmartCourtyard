/// Application-level HTTP proxy settings used by the shared Dio client.
class NetworkProxySettings {
  const NetworkProxySettings({
    required this.enabled,
    required this.host,
    required this.port,
  });

  const NetworkProxySettings.disabled()
    : enabled = false,
      host = '',
      port = null;

  final bool enabled;
  final String host;
  final int? port;

  /// Whether the settings can safely be applied to an HTTP client.
  bool get isValid {
    if (!enabled) {
      return true;
    }
    return isValidHost(host) && isValidPort(port);
  }

  bool get isActive => enabled && isValid;

  /// The Dart [HttpClient.findProxy] expression for this configuration.
  String? get proxyExpression {
    if (!isActive) {
      return null;
    }
    final normalizedHost = host.trim();
    final proxyHost =
        normalizedHost.contains(':') && !normalizedHost.startsWith('[')
        ? '[$normalizedHost]'
        : normalizedHost;
    return 'PROXY $proxyHost:$port';
  }

  NetworkProxySettings normalized() {
    return NetworkProxySettings(
      enabled: enabled,
      host: host.trim(),
      port: port,
    );
  }

  NetworkProxySettings copyWith({
    bool? enabled,
    String? host,
    int? port,
    bool clearPort = false,
  }) {
    return NetworkProxySettings(
      enabled: enabled ?? this.enabled,
      host: host ?? this.host,
      port: clearPort ? null : port ?? this.port,
    );
  }

  static bool isValidHost(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 253) {
      return false;
    }
    if (normalized.contains(RegExp(r'[\s/@?#]'))) {
      return false;
    }

    final isBracketed = normalized.startsWith('[') && normalized.endsWith(']');
    final unbracketed = isBracketed
        ? normalized.substring(1, normalized.length - 1)
        : normalized;
    if (unbracketed.isEmpty ||
        unbracketed.contains('[') ||
        unbracketed.contains(']') ||
        !RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(unbracketed)) {
      return false;
    }
    if (isBracketed && !unbracketed.contains(':')) {
      return false;
    }

    if (unbracketed.contains(':')) {
      final uri = Uri.tryParse('http://[$unbracketed]');
      return uri != null && uri.host.isNotEmpty && !uri.hasPort;
    }

    final uri = Uri.tryParse('http://$unbracketed');
    return uri != null &&
        uri.host.toLowerCase() == unbracketed.toLowerCase() &&
        !uri.hasPort;
  }

  static bool isValidPort(int? value) {
    return value != null && value >= 1 && value <= 65535;
  }

  Map<String, Object?> toJson() {
    final normalized = this.normalized();
    return <String, Object?>{
      'enabled': normalized.enabled,
      'host': normalized.host,
      'port': normalized.port,
    };
  }

  factory NetworkProxySettings.fromJson(Object? json) {
    if (json is! Map) {
      return const NetworkProxySettings.disabled();
    }

    final enabled = json['enabled'] == true;
    final host = json['host'] is String ? (json['host'] as String).trim() : '';
    final port = _parsePort(json['port']);
    final settings = NetworkProxySettings(
      enabled: enabled,
      host: host,
      port: port,
    );

    if (enabled && !settings.isValid) {
      return const NetworkProxySettings.disabled();
    }

    return NetworkProxySettings(
      enabled: false,
      host: isValidHost(host) ? host : '',
      port: isValidPort(port) ? port : null,
    ).copyWith(enabled: enabled);
  }

  static int? _parsePort(Object? value) {
    final port = switch (value) {
      final int value => value,
      final String value => int.tryParse(value.trim()),
      _ => null,
    };
    return isValidPort(port) ? port : null;
  }

  @override
  bool operator ==(Object other) {
    return other is NetworkProxySettings &&
        other.enabled == enabled &&
        other.host == host &&
        other.port == port;
  }

  @override
  int get hashCode => Object.hash(enabled, host, port);

  @override
  String toString() {
    return 'NetworkProxySettings(enabled: $enabled, host: $host, port: $port)';
  }
}
