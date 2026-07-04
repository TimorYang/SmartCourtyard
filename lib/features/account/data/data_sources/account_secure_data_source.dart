import '../../domain/entities/account_token_set.dart';

abstract class AccountSecureDataSource {
  Future<AccountTokenSet?> readTokenSet();

  Future<void> saveTokenSet(AccountTokenSet tokenSet);

  Future<void> clearTokenSet();
}

class InMemoryAccountSecureDataSource implements AccountSecureDataSource {
  AccountTokenSet? _tokenSet;

  @override
  Future<AccountTokenSet?> readTokenSet() async {
    return _tokenSet;
  }

  @override
  Future<void> saveTokenSet(AccountTokenSet tokenSet) async {
    _tokenSet = tokenSet;
  }

  @override
  Future<void> clearTokenSet() async {
    _tokenSet = null;
  }
}
