import 'package:flutter/material.dart';

import '../../../../shared/l10n/app_localizations.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const routeName = 'login';
  static const routePath = '/login';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text(
          l10n.loginComingSoon,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
