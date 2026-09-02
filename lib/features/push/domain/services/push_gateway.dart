import '../entities/push_event.dart';
import '../entities/push_configuration.dart';

abstract interface class PushGateway {
  Stream<PushEvent> get events;

  Future<void> initialize(PushConfiguration configuration);

  Future<String?> getRegistrationId();

  Future<void> dispose();
}
