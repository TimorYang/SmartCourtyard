import '../../../account/domain/entities/account_profile.dart';
import '../../../account/domain/entities/account_token_set.dart';

class AuthLoginResult {
  const AuthLoginResult({required this.tokenSet, required this.profile});

  final AccountTokenSet tokenSet;
  final AccountProfile profile;
}
