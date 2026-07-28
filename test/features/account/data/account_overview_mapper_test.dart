import 'package:flinx/features/account/data/dto/account_overview_dto.dart';
import 'package:flinx/features/account/data/mappers/account_overview_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps account overview nickname, door counts, and refresh time', () {
    final refreshedAt = DateTime(2026, 7, 28, 20, 30);
    final overview = AccountOverviewDto.fromJson({
      'profile': {'nickname': '  Alex  '},
      'doorSummary': {
        'ownedDoorCount': 3,
        'sharedDoorCount': 2,
        'receivingDoorCount': 1,
      },
    }).toDomain(refreshedAt: refreshedAt);

    expect(overview.nickname, 'Alex');
    expect(overview.ownedDoorCount, 3);
    expect(overview.sharedDoorCount, 2);
    expect(overview.receivingDoorCount, 1);
    expect(overview.refreshedAt, refreshedAt);
  });

  test('rejects missing overview sections and invalid counts', () {
    expect(
      () => AccountOverviewDto.fromJson({'profile': {}}),
      throwsFormatException,
    );
    expect(
      () => AccountOverviewDto.fromJson({
        'profile': {'nickname': 'Alex'},
        'doorSummary': {
          'ownedDoorCount': -1,
          'sharedDoorCount': 0,
          'receivingDoorCount': 0,
        },
      }),
      throwsFormatException,
    );
  });
}
