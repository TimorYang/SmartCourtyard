sealed class PushEvent {
  const PushEvent();
}

final class PushConnectionChanged extends PushEvent {
  const PushConnectionChanged({required this.connected});

  final bool connected;
}

final class PushNotificationArrived extends PushEvent {
  const PushNotificationArrived({
    required this.messageId,
    required this.title,
    required this.content,
    required this.extras,
  });

  final String? messageId;
  final String? title;
  final String? content;
  final Map<String, Object?> extras;
}

final class PushNotificationClicked extends PushEvent {
  const PushNotificationClicked({
    required this.messageId,
    required this.title,
    required this.content,
    required this.extras,
  });

  final String? messageId;
  final String? title;
  final String? content;
  final Map<String, Object?> extras;
}

final class PushCustomMessageReceived extends PushEvent {
  const PushCustomMessageReceived({
    required this.messageId,
    required this.title,
    required this.content,
    required this.extras,
  });

  final String? messageId;
  final String? title;
  final String? content;
  final Map<String, Object?> extras;
}

final class PushPlatformTokenReceived extends PushEvent {
  const PushPlatformTokenReceived({
    required this.platform,
    required this.token,
  });

  final String? platform;
  final String token;
}

final class PushDeviceTokenReceived extends PushEvent {
  const PushDeviceTokenReceived({required this.token});

  final String token;
}
