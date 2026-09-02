import '../domain/entities/push_event.dart';
import '../domain/entities/push_configuration.dart';
import '../domain/services/push_gateway.dart';

class NoopPushGateway implements PushGateway {
  const NoopPushGateway();

  @override
  Stream<PushEvent> get events => const Stream<PushEvent>.empty();

  @override
  Future<void> initialize(PushConfiguration configuration) async {}

  @override
  Future<String?> getRegistrationId() async => null;

  @override
  Future<void> dispose() async {}
}
