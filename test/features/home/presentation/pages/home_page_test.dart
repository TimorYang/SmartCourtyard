import 'package:flinx/app/flinx_app.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/data/data_sources/account_local_data_source.dart';
import 'package:flinx/features/account/data/dto/account_profile_dto.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/domain/entities/auth_session.dart';
import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/features/home/domain/entities/home_scene.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the cached account nickname in the home header', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) async =>
                const AuthSession(isAuthenticated: true, userId: 'user-1'),
          ),
          accountLocalDataSourceProvider.overrideWithValue(
            InMemoryAccountLocalDataSource(
              initialProfile: const AccountProfileDto(
                schemaVersion: AccountProfileDto.currentSchemaVersion,
                userId: 'user-1',
                email: 'alex@example.com',
                nickname: 'Alex',
                avatarUrl: ' ',
                registeredAtIso8601: '',
              ),
            ),
          ),
          homeScenesProvider.overrideWith(
            (ref) async => const [
              HomeScene(id: 1, name: 'Home', doorCount: 0, isDefault: true),
            ],
          ),
          homeDevicesProvider.overrideWith(
            (ref) async => const <DeviceSummary>[],
          ),
        ],
        child: const FlinxApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hi Alex'), findsOneWidget);
  });
}
