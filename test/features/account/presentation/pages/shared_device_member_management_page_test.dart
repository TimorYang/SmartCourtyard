import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/shared_door.dart';
import 'package:flinx/features/account/domain/entities/shared_door_members.dart';
import 'package:flinx/features/account/domain/repositories/shared_devices_repository.dart';
import 'package:flinx/features/account/presentation/pages/shared_device_member_management_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fetches shared door members once when the page opens', (
    tester,
  ) async {
    final repository = _CountingSharedDevicesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedDevicesRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SharedDeviceMemberManagementPage(
            device: SharedDoor(
              doorId: 31,
              name: 'Garage door',
              sharedUserCount: 0,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(repository.fetchDoorMembersCalls, 1);
    expect(repository.lastDoorId, 31);
  });
}

class _CountingSharedDevicesRepository implements SharedDevicesRepository {
  var fetchDoorMembersCalls = 0;
  int? lastDoorId;

  @override
  Future<SharedDoorMembers> fetchDoorMembers({
    required int doorId,
    required String requestId,
  }) async {
    fetchDoorMembersCalls++;
    lastDoorId = doorId;
    return SharedDoorMembers(
      doorId: doorId,
      doorName: 'Garage door',
      administrators: const [],
      guests: const [],
    );
  }

  @override
  Future<List<SharedDoor>> fetchSharedDoors({
    required String requestId,
  }) async => const [];

  @override
  Future<void> deleteDoorMember({
    required int shareId,
    required String requestId,
  }) async {}
}
