import 'package:flutter_test/flutter_test.dart';
import 'package:flinx/features/account/data/dto/account_profile_dto.dart';
import 'package:flinx/features/account/data/dto/account_remote_dto.dart';
import 'package:flinx/features/account/data/mappers/account_profile_mapper.dart';
import 'package:flinx/features/account/domain/entities/account_profile.dart';

void main() {
  test('maps local dto to domain and normalizes values', () {
    final dto = AccountProfileDto(
      schemaVersion: 1,
      userId: 'user-1',
      email: '  USER@Example.COM ',
      nickname: ' Alice ',
      avatarUrl: ' ',
      registeredAtIso8601: '2026-01-02T03:04:05Z',
      country: 'CN',
    );

    final profile = dto.toDomain();

    expect(profile.userId, 'user-1');
    expect(profile.email, 'user@example.com');
    expect(profile.nickname, 'Alice');
    expect(profile.avatarUrl, isNull);
    expect(profile.registeredAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
    expect(profile.country, 'CN');
  });

  test('maps domain to local dto without token fields', () {
    final profile = AccountProfile(
      userId: 'user-1',
      email: 'user@example.com',
      nickname: 'Alice',
      avatarUrl: 'https://example.com/avatar.png',
      registeredAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
      country: 'US',
    );

    final json = profile.toLocalDto().toJson();

    expect(json['schemaVersion'], AccountProfileDto.currentSchemaVersion);
    expect(json['userId'], 'user-1');
    expect(json['email'], 'user@example.com');
    expect(json['nickname'], 'Alice');
    expect(json['avatarUrl'], 'https://example.com/avatar.png');
    expect(json['registeredAt'], '2026-01-02T03:04:05.000Z');
    expect(json['country'], 'US');
    expect(json.containsKey('token'), isFalse);
    expect(json.containsKey('accessToken'), isFalse);
    expect(json.containsKey('refreshToken'), isFalse);
  });

  test('maps remote dto through the app-local domain boundary', () {
    const remoteDto = AccountRemoteDto(
      userId: 'remote-user',
      email: 'Remote@Example.COM',
      nickname: 'Remote User',
      registeredAtIso8601: '2026-04-05T06:07:08Z',
    );

    final profile = remoteDto.toDomain();

    expect(profile.userId, 'remote-user');
    expect(profile.email, 'remote@example.com');
    expect(profile.nickname, 'Remote User');
    expect(profile.avatarUrl, isNull);
    expect(profile.country, isNull);
    expect(profile.registeredAt, DateTime.utc(2026, 4, 5, 6, 7, 8));
  });
}
