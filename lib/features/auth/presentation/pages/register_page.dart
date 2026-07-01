import 'package:flutter/material.dart';

import '../../../../shared/l10n/app_localizations.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  static const routeName = 'register';
  static const routePath = '/register';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text(
          l10n.registerComingSoon,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
