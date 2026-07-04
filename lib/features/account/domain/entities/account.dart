import 'account_profile.dart';

class Account {
  const Account({required this.profile, required this.isAuthenticated});

  final AccountProfile profile;
  final bool isAuthenticated;
}
