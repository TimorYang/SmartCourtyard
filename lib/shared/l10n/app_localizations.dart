import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FLINX'**
  String get appTitle;

  /// Headline shown on the unauthenticated welcome page
  ///
  /// In en, this message translates to:
  /// **'Start your\nsmart life'**
  String get welcomeHeadline;

  /// Subtitle shown on the unauthenticated welcome page
  ///
  /// In en, this message translates to:
  /// **'Make your life comfortable'**
  String get welcomeSubtitle;

  /// Primary login button label
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginAction;

  /// Secondary register button label
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerAction;

  /// Placeholder text for the login page
  ///
  /// In en, this message translates to:
  /// **'Login page coming soon'**
  String get loginComingSoon;

  /// Placeholder text for the register page
  ///
  /// In en, this message translates to:
  /// **'Register page coming soon'**
  String get registerComingSoon;

  /// Register page heading
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// Register page helper text asking for the account email address
  ///
  /// In en, this message translates to:
  /// **'Please enter the address associated your account'**
  String get registerDescription;

  /// Register email input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get registerEmailPlaceholder;

  /// Register privacy agreement prefix
  ///
  /// In en, this message translates to:
  /// **'I have read and agreed '**
  String get registerAgreementPrefix;

  /// Register send verification code button label
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCodeAction;

  /// Temporary message shown when the user submits the register form
  ///
  /// In en, this message translates to:
  /// **'Verification code is not connected yet'**
  String get registerSendPending;

  /// Register verification code page heading
  ///
  /// In en, this message translates to:
  /// **'Enter Code'**
  String get registerCodeTitle;

  /// Register verification code helper text
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent an email to {email} with a confirmation code. Enter the code below to continue registration.'**
  String registerCodeDescription(String email);

  /// Accessibility label for the verification code input
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get registerCodeInputLabel;

  /// Register verification resend countdown label
  ///
  /// In en, this message translates to:
  /// **'Send Again OTP ({seconds}s)'**
  String registerCodeResend(int seconds);

  /// Register verification resend action label when the countdown has finished
  ///
  /// In en, this message translates to:
  /// **'Send Again OTP'**
  String get registerCodeResendAction;

  /// Register password setup page heading
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registerPasswordTitle;

  /// Register password setup helper text
  ///
  /// In en, this message translates to:
  /// **'Set your password'**
  String get registerPasswordDescription;

  /// Register password input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter an 8-digit password'**
  String get registerPasswordPlaceholder;

  /// Register confirm password input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter the 8-digit password again'**
  String get registerConfirmPasswordPlaceholder;

  /// Temporary message shown when the user submits the register password form
  ///
  /// In en, this message translates to:
  /// **'Password registration is not connected yet'**
  String get registerPasswordPending;

  /// Forgot password page heading
  ///
  /// In en, this message translates to:
  /// **'Forget Password?'**
  String get forgotPasswordTitle;

  /// Forgot password page helper text asking for the account email address
  ///
  /// In en, this message translates to:
  /// **'Please enter the address associated your account'**
  String get forgotPasswordDescription;

  /// Temporary message shown when the user submits the forgot password form
  ///
  /// In en, this message translates to:
  /// **'Password reset code is not connected yet'**
  String get forgotPasswordSendPending;

  /// Forgot password verification code page heading
  ///
  /// In en, this message translates to:
  /// **'Enter Code'**
  String get forgotPasswordCodeTitle;

  /// Forgot password verification code helper text
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent an email to {email} with a confirmation code. Enter the code below to reset your password.'**
  String forgotPasswordCodeDescription(String email);

  /// Forgot password reset page heading
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get forgotPasswordResetTitle;

  /// Forgot password reset helper text
  ///
  /// In en, this message translates to:
  /// **'Set your password'**
  String get forgotPasswordResetDescription;

  /// Finish button label
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishAction;

  /// Temporary message shown when the user submits the reset password form
  ///
  /// In en, this message translates to:
  /// **'Password reset is not connected yet'**
  String get forgotPasswordResetPending;

  /// Password reset success page heading
  ///
  /// In en, this message translates to:
  /// **'Reset Succeeded'**
  String get passwordResetSucceededTitle;

  /// Password reset success page helper text
  ///
  /// In en, this message translates to:
  /// **'Password reset succeeded'**
  String get passwordResetSucceededDescription;

  /// Button label for returning from password reset success to login
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLoginAction;

  /// Login page heading
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// Login email input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get loginAccountPlaceholder;

  /// Validation message shown when the login email format is invalid
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get loginEmailInvalid;

  /// Login password input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get loginPasswordPlaceholder;

  /// Agreement prefix text on the login page
  ///
  /// In en, this message translates to:
  /// **'I have read and agreed '**
  String get loginAgreementPrefix;

  /// Agreement middle text on the login page
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get loginAgreementMiddle;

  /// User agreement link label
  ///
  /// In en, this message translates to:
  /// **'User Agreement'**
  String get userAgreementLabel;

  /// Privacy policy link label
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyLabel;

  /// Login submit button label
  ///
  /// In en, this message translates to:
  /// **'Login in'**
  String get signInAction;

  /// Forgot password action label
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordAction;

  /// Third-party sign in with Apple label
  ///
  /// In en, this message translates to:
  /// **'Continue Sign in with Apple'**
  String get continueWithApple;

  /// Third-party sign in with Google label
  ///
  /// In en, this message translates to:
  /// **'Continue Sign in with Google'**
  String get continueWithGoogle;

  /// Third-party sign in with Alexa label
  ///
  /// In en, this message translates to:
  /// **'Continue Sign in with Alexa'**
  String get continueWithAlexa;

  /// Temporary message shown when the user submits the login form
  ///
  /// In en, this message translates to:
  /// **'Login is not connected yet'**
  String get loginSubmitPending;

  /// Temporary shortcut button from the welcome page to the home page
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeShortcutAction;

  /// Greeting title on the home page
  ///
  /// In en, this message translates to:
  /// **'Hi xxxxx'**
  String get homeGreeting;

  /// Greeting subtitle on the home page
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get homeWelcome;

  /// Tooltip for the home menu action
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get homeMenuTooltip;

  /// Tooltip for editing a home
  ///
  /// In en, this message translates to:
  /// **'Edit home'**
  String get homeEditTooltip;

  /// Tooltip for adding a door from the home header
  ///
  /// In en, this message translates to:
  /// **'Add door'**
  String get homeAddDoorTooltip;

  /// Number of doors bound under the current home
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 Door} =1{1 Door} other{{count} Doors}}'**
  String homeDoorCount(int count);

  /// Title for the empty home state when no doors are bound
  ///
  /// In en, this message translates to:
  /// **'No doors'**
  String get homeNoDoorsTitle;

  /// Subtitle for the empty home state when no doors are bound
  ///
  /// In en, this message translates to:
  /// **'Please add Doors'**
  String get homeNoDoorsSubtitle;

  /// Add door button label on the empty home state
  ///
  /// In en, this message translates to:
  /// **'New door'**
  String get homeAddDoorAction;

  /// Error message shown when home door loading fails
  ///
  /// In en, this message translates to:
  /// **'Unable to load doors.'**
  String get homeLoadDoorsFailed;

  /// Device card label for door state
  ///
  /// In en, this message translates to:
  /// **'Door'**
  String get homeDoorStateLabel;

  /// Device card label for connection state
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get homeConnectionStateLabel;

  /// Device card label for remaining device life
  ///
  /// In en, this message translates to:
  /// **'Life remaining'**
  String get homeLifeRemainingLabel;

  /// Choose scene page title
  ///
  /// In en, this message translates to:
  /// **'CHOOSE A SCENE'**
  String get chooseSceneTitle;

  /// Tooltip for the choose scene page back action
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get chooseSceneBackTooltip;

  /// Tooltip for the choose scene page edit action
  ///
  /// In en, this message translates to:
  /// **'Edit scene'**
  String get chooseSceneEditTooltip;

  /// Number of devices in a scene
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 Devices} =1{1 Device} other{{count} Devices}}'**
  String chooseSceneDeviceCount(int count);

  /// New scene card action label
  ///
  /// In en, this message translates to:
  /// **'New scene'**
  String get chooseSceneNewSceneAction;

  /// Tooltip for opening the scene page from the home page
  ///
  /// In en, this message translates to:
  /// **'Scene'**
  String get sceneHomeShortcutTooltip;

  /// Scene page title
  ///
  /// In en, this message translates to:
  /// **'SCENE'**
  String get sceneTitle;

  /// Number of scenes on the scene page
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 Scenes} =1{1 Scene} other{{count} Scenes}}'**
  String sceneCount(int count);

  /// Tooltip for the scene page back action
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get sceneBackTooltip;

  /// Tooltip for the scene page edit action
  ///
  /// In en, this message translates to:
  /// **'Edit scene'**
  String get sceneEditTooltip;

  /// Number of devices in a scene on the scene page
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 Devices} =1{1 Device} other{{count} Devices}}'**
  String sceneDeviceCount(int count);

  /// New scene card action label on the scene page
  ///
  /// In en, this message translates to:
  /// **'New scene'**
  String get sceneNewSceneAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
