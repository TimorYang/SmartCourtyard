import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServerBusinessMessageEvent {
  const ServerBusinessMessageEvent({
    required this.sequence,
    required this.code,
    required this.message,
  });

  final int sequence;
  final int code;
  final String message;
}

class ServerBusinessMessageController
    extends Notifier<ServerBusinessMessageEvent?> {
  var _sequence = 0;

  @override
  ServerBusinessMessageEvent? build() => null;

  void show({required int code, required String message}) {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) return;
    state = ServerBusinessMessageEvent(
      sequence: ++_sequence,
      code: code,
      message: normalizedMessage,
    );
  }
}

final serverBusinessMessageProvider =
    NotifierProvider<
      ServerBusinessMessageController,
      ServerBusinessMessageEvent?
    >(ServerBusinessMessageController.new);
