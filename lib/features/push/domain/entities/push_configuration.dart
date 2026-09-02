class PushConfiguration {
  const PushConfiguration({
    required this.appKey,
    required this.channel,
    required this.iosProduction,
  });

  static const fromEnvironment = PushConfiguration(
    appKey: String.fromEnvironment('FLINX_ENGAGELAB_APP_KEY'),
    channel: String.fromEnvironment(
      'FLINX_ENGAGELAB_CHANNEL',
      defaultValue: 'developer',
    ),
    iosProduction: bool.fromEnvironment(
      'FLINX_ENGAGELAB_IOS_PRODUCTION',
      defaultValue: false,
    ),
  );

  final String appKey;
  final String channel;
  final bool iosProduction;

  bool get isConfigured => appKey.trim().isNotEmpty;

  String get effectiveChannel {
    final value = channel.trim();
    return value.isEmpty ? 'developer' : value;
  }
}
