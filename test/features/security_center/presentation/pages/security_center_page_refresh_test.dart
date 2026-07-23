import 'package:flinx/features/security_center/application/providers.dart';
import 'package:flinx/features/security_center/domain/repositories/security_balance_refresh_repository.dart';
import 'package:flinx/features/security_center/domain/entities/security_balance_refresh_result.dart';
import 'package:flinx/features/security_center/presentation/pages/security_center_page.dart';
import 'package:flinx/features/device_control/presentation/widgets/device_detail_bottom_navigation.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('triggers refresh only when the security center becomes active', (
    tester,
  ) async {
    final repository = _RecordingSecurityBalanceRefreshRepository();
    final container = ProviderContainer(
      overrides: [
        securityBalanceRefreshRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _app(isActive: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.doorIds, isEmpty);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _app(isActive: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.doorIds, ['12']);
    expect(
      repository.requestIds.single,
      startsWith('security-balance-refresh-12-'),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _app(isActive: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.doorIds, ['12']);
  });
}

Widget _app({required bool isActive}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: SecurityCenterPage(
      doorId: '12',
      deviceId: 'hardware-device',
      isActive: isActive,
      onTabSelected: _ignoreTab,
    ),
  );
}

void _ignoreTab(DeviceDetailTab _) {}

class _RecordingSecurityBalanceRefreshRepository
    implements SecurityBalanceRefreshRepository {
  final List<String> doorIds = <String>[];
  final List<String> requestIds = <String>[];

  @override
  Future<SecurityBalanceRefreshResult> refreshBalance({
    required String doorId,
    required String requestId,
  }) async {
    doorIds.add(doorId);
    requestIds.add(requestId);
    return const SecurityBalanceRefreshResult(
      requestId: 'test-request',
      status: '1',
    );
  }
}
