import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/features/security_center/application/providers.dart';
import 'package:flinx/features/security_center/domain/entities/security_center_connection_status.dart';
import 'package:flinx/features/security_center/domain/repositories/security_center_connection_status_repository.dart';
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
        securityCenterConnectionStatusRepositoryProvider.overrideWithValue(
          _FakeSecurityCenterConnectionStatusRepository(status: '2'),
        ),
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

  testWidgets(
    'blocks Wi-Fi-disconnected security center before balance refresh',
    (tester) async {
      final balanceRepository = _RecordingSecurityBalanceRefreshRepository();
      final container = ProviderContainer(
        overrides: [
          securityBalanceRefreshRepositoryProvider.overrideWithValue(
            balanceRepository,
          ),
          securityCenterConnectionStatusRepositoryProvider.overrideWithValue(
            _FakeSecurityCenterConnectionStatusRepository(status: '1'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(isActive: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
      expect(balanceRepository.doorIds, isEmpty);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Back'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Back'), findsNothing);
    },
  );

  testWidgets('refreshes balance for a non-blocking connection status', (
    tester,
  ) async {
    final balanceRepository = _RecordingSecurityBalanceRefreshRepository();
    final container = ProviderContainer(
      overrides: [
        securityBalanceRefreshRepositoryProvider.overrideWithValue(
          balanceRepository,
        ),
        securityCenterConnectionStatusRepositoryProvider.overrideWithValue(
          _FakeSecurityCenterConnectionStatusRepository(status: '0'),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _app(isActive: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Back'), findsNothing);
    expect(balanceRepository.doorIds, ['12']);
  });

  testWidgets('preserves balance refresh when the connection check fails', (
    tester,
  ) async {
    final balanceRepository = _RecordingSecurityBalanceRefreshRepository();
    final container = ProviderContainer(
      overrides: [
        securityBalanceRefreshRepositoryProvider.overrideWithValue(
          balanceRepository,
        ),
        securityCenterConnectionStatusRepositoryProvider.overrideWithValue(
          _FailingSecurityCenterConnectionStatusRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _app(isActive: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Back'), findsNothing);
    expect(balanceRepository.doorIds, ['12']);
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

class _FakeSecurityCenterConnectionStatusRepository
    implements SecurityCenterConnectionStatusRepository {
  _FakeSecurityCenterConnectionStatusRepository({required this.status});

  final String status;

  @override
  Future<SecurityCenterConnectionStatus> fetchConnectionStatus({
    required String doorId,
    required String requestId,
  }) async => SecurityCenterConnectionStatus(wifiConnectionStatus: status);
}

class _FailingSecurityCenterConnectionStatusRepository
    implements SecurityCenterConnectionStatusRepository {
  @override
  Future<SecurityCenterConnectionStatus> fetchConnectionStatus({
    required String doorId,
    required String requestId,
  }) => Future<SecurityCenterConnectionStatus>.error(
    AppError(
      code: AppErrorCode.networkUnavailable,
      messageKey: 'test_connection_status_failure',
      requestId: requestId,
    ),
  );
}
