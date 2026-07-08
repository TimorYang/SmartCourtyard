import 'dart:math';

import '../../account/domain/entities/account_profile.dart';
import '../../account/domain/entities/account_token_set.dart';
import '../../account/domain/repositories/account_repository.dart';
import '../domain/entities/auth_session.dart';

class SimulatedLoginUseCase {
  const SimulatedLoginUseCase({required this.accountRepository});

  final AccountRepository accountRepository;

  Future<AuthSession> call({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = AccountProfile.normalizeEmail(email);
    await Future<void>.delayed(const Duration(seconds: 3));

    final generated = _generateAccount(normalizedEmail, password);
    await accountRepository.saveProfile(generated.profile);
    await accountRepository.saveTokenSet(generated.tokenSet);

    return generated.session;
  }

  _GeneratedAccount _generateAccount(String email, String password) {
    final seed = Object.hash(email, password);
    final random = Random(seed);
    final userId = 'mock-user-${_token(random, 12)}';
    final nickname = _nicknameFromEmail(email, random);
    final country = _countries[random.nextInt(_countries.length)];
    final registeredAt = DateTime.utc(
      2020 + random.nextInt(7),
      1 + random.nextInt(12),
      1 + random.nextInt(28),
      random.nextInt(24),
      random.nextInt(60),
      random.nextInt(60),
    );

    return _GeneratedAccount(
      profile: AccountProfile(
        userId: userId,
        email: email,
        nickname: nickname,
        avatarUrl: 'https://api.dicebear.com/9.x/initials/png?seed=$userId',
        registeredAt: registeredAt,
        country: country,
      ),
      tokenSet: AccountTokenSet(
        accessToken: 'mock_access_${_token(random, 32)}',
        refreshToken: 'mock_refresh_${_token(random, 32)}',
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 7)),
      ),
      session: AuthSession(isAuthenticated: true, userId: userId),
    );
  }

  String _nicknameFromEmail(String email, Random random) {
    final localPart = email.split('@').first.trim();
    final cleaned = localPart
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');

    if (cleaned.isNotEmpty) {
      return cleaned;
    }

    return 'FLINX User ${1000 + random.nextInt(9000)}';
  }

  String _token(Random random, int length) {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List<String>.generate(
      length,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }

  static const _countries = [
    'Australia',
    'Canada',
    'Germany',
    'Singapore',
    'United Kingdom',
    'United States',
  ];
}

class _GeneratedAccount {
  const _GeneratedAccount({
    required this.profile,
    required this.tokenSet,
    required this.session,
  });

  final AccountProfile profile;
  final AccountTokenSet tokenSet;
  final AuthSession session;
}
