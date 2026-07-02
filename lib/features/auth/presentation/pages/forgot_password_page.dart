import 'package:flutter/material.dart';

import '../../../../shared/l10n/app_localizations.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  static const routeName = 'forgot-password';
  static const routePath = '/forgot-password';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text(
          l10n.forgotPasswordComingSoon,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
