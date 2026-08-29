import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/core/network/api_business_failure.dart';
import 'package:flinx/features/account/data/data_sources/account_overview_local_data_source.dart';
import 'package:flinx/features/account/data/data_sources/account_overview_remote_data_source.dart';
import 'package:flinx/features/account/data/dto/account_overview_dto.dart';
import 'package:flinx/features/account/data/repositories/account_overview_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refreshes, caches, and maps an account overview', () async {
    final remote = _FakeRemoteDataSource();
    final repository = AccountOverviewRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: InMemoryAccountOverviewLocalDataSource(),
      logger: const DebugAppLogger(),
      clock: () => DateTime(2026, 7, 28, 20, 30),
    );

    final overview = await repository.refreshOverview(requestId: 'request-1');

    expect(remote.requestId, 'request-1');
    expect(overview.nickname, 'Alex');
    expect(overview.sharedDoorCount, 2);
    expect(await repository.readCachedOverview(), overview);
  });

  test('preserves business failure metadata in an app error', () async {
    final repository = AccountOverviewRepositoryImpl(
      remoteDataSource: _BusinessFailingRemoteDataSource(),
      localDataSource: InMemoryAccountOverviewLocalDataSource(),
      logger: const DebugAppLogger(),
    );

    await expectLater(
      repository.refreshOverview(requestId: 'request-business-failure'),
      throwsA(
        isA<AppError>()
            .having((error) => error.businessCode, 'businessCode', 100901)
            .having(
              (error) => error.businessMessageKey,
              'businessMessageKey',
              'account.overview.unavailable',
            )
            .having(
              (error) => error.userMessage,
              'userMessage',
              'Account overview is temporarily unavailable.',
            )
            .having(
              (error) => error.requestId,
              'requestId',
              'request-business-failure',
            ),
      ),
    );
  });

  test('maps an invalid remote response to a retryable app error', () async {
    final repository = AccountOverviewRepositoryImpl(
      remoteDataSource: _FailingRemoteDataSource(),
      localDataSource: InMemoryAccountOverviewLocalDataSource(),
      logger: const DebugAppLogger(),
    );

    expect(
      () => repository.refreshOverview(requestId: 'request-2'),
      throwsA(
        isA<AppError>()
            .having((error) => error.code, 'code', AppErrorCode.serverError)
            .having((error) => error.retryable, 'retryable', isTrue),
      ),
    );
  });
}

class _FakeRemoteDataSource implements AccountOverviewRemoteDataSource {
  String? requestId;

  @override
  Future<AccountOverviewDto> fetchOverview({required String requestId}) async {
    this.requestId = requestId;
    return AccountOverviewDto.fromJson({
      'profile': {'nickname': 'Alex'},
      'doorSummary': {
        'ownedDoorCount': 3,
        'sharedDoorCount': 2,
        'receivingDoorCount': 1,
      },
    });
  }
}

class _FailingRemoteDataSource implements AccountOverviewRemoteDataSource {
  @override
  Future<AccountOverviewDto> fetchOverview({required String requestId}) {
    throw const AccountOverviewRemoteException.invalidResponse();
  }
}

class _BusinessFailingRemoteDataSource
    implements AccountOverviewRemoteDataSource {
  @override
  Future<AccountOverviewDto> fetchOverview({required String requestId}) {
    throw AccountOverviewRemoteException.businessFailure(
      ApiBusinessFailure(
        code: 100901,
        messageKey: 'account.overview.unavailable',
        message: 'Account overview is temporarily unavailable.',
      ),
    );
  }
}
