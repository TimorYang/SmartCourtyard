import 'package:flinx/features/home/domain/entities/device_share.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DeviceShareDraft serializes and deserializes nested UI state', () {
    final draft = DeviceShareDraft.mock();

    final restored = DeviceShareDraft.fromJson(draft.toJson());

    expect(restored.deviceId, 'door-001');
    expect(restored.address, 'alex@example.com');
    expect(restored.permission, DeviceSharePermission.administrator);
    expect(restored.accessEnd.mode, DeviceShareAccessEndMode.customize);
    expect(restored.accessEnd.expiresAt, DateTime.utc(2026, 7, 24, 12));
    expect(restored.selectedCapabilities, equals(DeviceShareCapability.values));
  });
}
