// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FLINX';

  @override
  String get welcomeHeadline => 'Start your\nsmart life';

  @override
  String get welcomeSubtitle => 'Make your life comfortable';

  @override
  String get loginAction => 'Login';

  @override
  String get registerAction => 'Register';

  @override
  String get loginComingSoon => 'Login page coming soon';

  @override
  String get registerComingSoon => 'Register page coming soon';
}
