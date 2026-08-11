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
  String get operationRecordTitle => 'Operation Record';

  @override
  String get operationRecordLast14DaysDescription =>
      'Operation data of the last 14 days';

  @override
  String get operationRecordLoadFailed =>
      'Unable to load operation records. Tap to retry.';

  @override
  String get operationRecordLoadMoreFailed =>
      'Unable to load more records. Tap to retry.';

  @override
  String get operationRecordNoMore => 'No more records';

  @override
  String get operationRecordEmpty => 'No operation records yet';

  @override
  String get operationRecordUnknownOperator => 'Unknown operator';

  @override
  String get operationRecordUnknownTime => 'Unknown time';

  @override
  String get operationRecordUnknownDoor => 'Unknown door';

  @override
  String get operationRecordActionOpen => 'Open door';

  @override
  String get operationRecordActionClose => 'Close door';

  @override
  String get operationRecordActionStop => 'Stop door';

  @override
  String get operationRecordActionLedOn => 'LED on';

  @override
  String get operationRecordActionLedOff => 'LED off';

  @override
  String get operationRecordActionUnknown => 'Unknown action';

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

  @override
  String get registerTitle => 'Register';

  @override
  String get registerDescription =>
      'Please enter the address associated your account';

  @override
  String get registerEmailPlaceholder => 'Enter your email address';

  @override
  String get registerAgreementPrefix => 'I have read and agreed ';

  @override
  String get sendCodeAction => 'Send code';

  @override
  String get registerSendPending => 'Verification code is not connected yet';

  @override
  String get registerCodeTitle => 'Enter Code';

  @override
  String registerCodeDescription(String email) {
    return 'We\'ve sent an email to $email with a confirmation code. Enter the code below to continue registration.';
  }

  @override
  String get registerCodeInputLabel => 'Verification code';

  @override
  String registerCodeResend(int seconds) {
    return 'Send Again OTP (${seconds}s)';
  }

  @override
  String get registerCodeResendAction => 'Send Again OTP';

  @override
  String get registerPasswordTitle => 'Password';

  @override
  String get registerPasswordDescription => 'Set your password';

  @override
  String get registerPasswordPlaceholder => 'Enter password';

  @override
  String get registerConfirmPasswordPlaceholder => 'Enter password again';

  @override
  String get registerPasswordPending =>
      'Password registration is not connected yet';

  @override
  String get registerCodeResending => 'Sending verification code…';

  @override
  String get registerRequestFailed =>
      'Unable to complete registration. Please try again.';

  @override
  String get registerNetworkUnavailable =>
      'Network unavailable. Please try again.';

  @override
  String get registerAuthorizationFailed =>
      'Registration is temporarily unavailable.';

  @override
  String get registerRestartRequired =>
      'Your registration session has expired. Please start again.';

  @override
  String get registerSucceeded => 'Registration successful. Please log in.';

  @override
  String get forgotPasswordTitle => 'Forget Password?';

  @override
  String get forgotPasswordDescription =>
      'Please enter the address associated your account';

  @override
  String get forgotPasswordSendPending =>
      'Password reset code is not connected yet';

  @override
  String get forgotPasswordCodeTitle => 'Enter Code';

  @override
  String forgotPasswordCodeDescription(String email) {
    return 'We\'ve sent an email to $email with a confirmation code. Enter the code below to reset your password.';
  }

  @override
  String get forgotPasswordResetTitle => 'Password';

  @override
  String get forgotPasswordResetDescription => 'Set your password';

  @override
  String get authPasswordRule =>
      'Password: 8-16 chars, 1 uppercase, lowercase & number';

  @override
  String get finishAction => 'Finish';

  @override
  String get forgotPasswordResetPending =>
      'Password reset is not connected yet';

  @override
  String get passwordResetRequestFailed =>
      'Unable to reset password. Please try again.';

  @override
  String get passwordResetNetworkUnavailable =>
      'Network unavailable. Please try again.';

  @override
  String get passwordResetAuthorizationFailed =>
      'Password reset is temporarily unavailable.';

  @override
  String get passwordResetRestartRequired =>
      'Your password reset session has expired. Please start again.';

  @override
  String get passwordResetResponseContractPending =>
      'Verification succeeded. Password reset will be enabled after the response contract is confirmed.';

  @override
  String get passwordResetSucceededTitle => 'Reset Succeeded';

  @override
  String get passwordResetSucceededDescription => 'Password reset succeeded';

  @override
  String get backToLoginAction => 'Back to Login';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginAccountPlaceholder => 'Enter your email address';

  @override
  String get loginEmailInvalid => 'Enter a valid email address';

  @override
  String get loginPasswordPlaceholder => 'Enter password';

  @override
  String get loginAgreementPrefix => 'I have read and agreed ';

  @override
  String get loginAgreementMiddle => ' and ';

  @override
  String get userAgreementLabel => 'User Agreement';

  @override
  String get privacyPolicyLabel => 'Privacy Policy';

  @override
  String get signInAction => 'Sign in';

  @override
  String get forgotPasswordAction => 'Forgot password';

  @override
  String get loginClearAccountAction => 'Clear account';

  @override
  String get loginShowPasswordAction => 'Show password';

  @override
  String get loginHidePasswordAction => 'Hide password';

  @override
  String get continueWithApple => 'Continue Sign in with Apple';

  @override
  String get continueWithGoogle => 'Continue Sign in with Google';

  @override
  String get continueWithFacebook => 'Continue Sign in with Facebook';

  @override
  String get otherWaysToLogin => 'Other ways to login';

  @override
  String get continueWithAlexa => 'Continue Sign in with Alexa';

  @override
  String get loginSubmitPending => 'Login is not connected yet';

  @override
  String get loginFailed => 'Login failed. Please try again.';

  @override
  String get homeShortcutAction => 'Home';

  @override
  String get homeGreeting => 'Hi xxxxx';

  @override
  String get homeWelcome => 'Welcome';

  @override
  String get homeMenuTooltip => 'Menu';

  @override
  String get homeEditTooltip => 'Edit home';

  @override
  String get homeAddDoorTooltip => 'Add door';

  @override
  String get homeAddSceneMenuAction => 'Add Scene';

  @override
  String get homeAddDoorMenuAction => 'Add Door';

  @override
  String get homeSmartDeviceMenuAction => 'Smart Device';

  @override
  String homeDoorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Doors',
      one: '1 Door',
      zero: '0 Door',
    );
    return '$_temp0';
  }

  @override
  String get homeNoDoorsTitle => 'No doors';

  @override
  String get homeNoDoorsSubtitle => 'Please add Doors';

  @override
  String get homeAddDoorAction => 'New door';

  @override
  String get homeLoadDoorsFailed => 'Unable to load doors.';

  @override
  String get homeDoorStateLabel => 'Door';

  @override
  String get homeConnectionStateLabel => 'Connection';

  @override
  String get homeLifeRemainingLabel => 'Life remaining';

  @override
  String get homeDoorStateOpen => 'Opened';

  @override
  String get homeDoorStateOpening => 'Opening';

  @override
  String get homeDoorStateStopped => 'Stopped';

  @override
  String get homeDoorStateClosing => 'Closing';

  @override
  String get homeDoorStateClosed => 'Closed';

  @override
  String get homeDoorStateUnknown => 'Unknown';

  @override
  String get homeDeviceEditingTitle => 'Device editing';

  @override
  String get homeDeviceEditTopAction => 'Top';

  @override
  String get homeDeviceEditShareAction => 'Share';

  @override
  String get homeNoDeviceMessage => 'No Device';

  @override
  String get homeDeviceEditMoveSceneAction => 'Move Scene';

  @override
  String get homeDeviceEditNameAction => 'Name';

  @override
  String get homeDeviceEditDeleteAction => 'Delete Device';

  @override
  String get homeDeviceEditCustomizeAction => 'Customize';

  @override
  String get deviceShareTitle => 'Share';

  @override
  String get deviceShareSubtitle => 'Enjoy the smart life with your family!';

  @override
  String get deviceSharePermissionsLabel => 'Permissions';

  @override
  String get deviceShareAdministratorRole => 'Administrator';

  @override
  String get deviceShareGuestRole => 'Guest';

  @override
  String get deviceShareEmailLabel => 'Address';

  @override
  String get deviceShareEmailPlaceholder => 'Email/Account';

  @override
  String get deviceShareAddressInvalid => 'Enter a valid email address';

  @override
  String get deviceSharePeriodLabel => 'Access end';

  @override
  String get deviceShareNeverExpired => 'Never expired';

  @override
  String get deviceShareTwoHours => '2 hours';

  @override
  String get deviceShareCustomize => 'Customize';

  @override
  String get deviceShareTimeLabel => 'Time';

  @override
  String get deviceShareSendEmailLabel => 'Send email';

  @override
  String get deviceShareCapabilitiesTitle => 'Capabilities';

  @override
  String get deviceShareCapabilityDoorControl => 'Open/stop/close';

  @override
  String get deviceShareCapabilityPartialOpen => 'Partial open';

  @override
  String get deviceShareCapabilityPartialOpenLevel => 'Partial opening level';

  @override
  String get deviceShareCapabilityLedControl => 'LED control';

  @override
  String get deviceShareCapabilityLedDelay => 'LED off delay';

  @override
  String get deviceShareCapabilityAutoClose => 'Auto-close';

  @override
  String get deviceShareCapabilityTransmitterPairing => 'Transmitter pairing';

  @override
  String get deviceShareCapabilityDoorOpenReminder => 'Door open reminder';

  @override
  String get deviceShareCapabilityDoorOpenForce => 'Door open force';

  @override
  String get deviceShareCapabilityDoorOpenSpeed => 'Door open speed';

  @override
  String get deviceShareCancelAction => 'Cancel';

  @override
  String get deviceShareConfirmAction => 'Confirm';

  @override
  String get deviceShareDoorUnavailable =>
      'This door is unavailable for sharing.';

  @override
  String get deviceShareCapabilitiesLoadFailed =>
      'Unable to load share capabilities. Tap to retry.';

  @override
  String get deviceShareSubmitFailed =>
      'Unable to create the share. Please try again.';

  @override
  String get accountProfileTitle => 'Account profile';

  @override
  String get accountDetailsTitle => 'ACCOUNT';

  @override
  String get accountDetailsHeadPortrait => 'Head portrait';

  @override
  String get accountDetailsAccountNumber => 'Account number';

  @override
  String get accountDetailsFullName => 'Full name';

  @override
  String get accountDetailsMailbox => 'Mailbox';

  @override
  String get accountDetailsChangePassword => 'Change Password';

  @override
  String get accountDetailsForgotPassword => 'Forgot password';

  @override
  String get accountDetailsCancelAccount => 'Cancel account';

  @override
  String get accountDetailsDeletionPrompt =>
      'Are you sure to cancel the account?';

  @override
  String get accountDetailsDeletionNoAction => 'No';

  @override
  String get accountDetailsDeletionYesAction => 'Yes';

  @override
  String get accountDetailsDeletionSubmitting => 'Deleting...';

  @override
  String get accountDetailsDeletionFailed =>
      'Unable to cancel the account. Please try again.';

  @override
  String get accountDetailsLogout => 'Log out';

  @override
  String get accountDetailsFallbackNumber => '34345435@qq.com';

  @override
  String get accountDetailsFallbackFullName => 'James';

  @override
  String get accountDetailsFallbackMailbox => '123456@qq.com';

  @override
  String get accountDetailsPhotoAlbumAction => 'Photo album';

  @override
  String get accountDetailsPhotographAction => 'Photograph';

  @override
  String get accountDetailsCancelAction => 'Cancel';

  @override
  String get accountDetailsConfirmAction => 'confirm';

  @override
  String get accountDetailsRenameTitle => 'Rename';

  @override
  String get accountDetailsNameInputPlaceholder => 'JAMES';

  @override
  String get accountDetailsChangePasswordTitle => 'Change Password';

  @override
  String get accountDetailsNewPasswordPlaceholder => 'Enter New Password';

  @override
  String get accountDetailsShowPasswordAction => 'Show password';

  @override
  String get accountDetailsHidePasswordAction => 'Hide password';

  @override
  String accountDetailsAvatarOptionLabel(int index) {
    return 'Avatar option $index';
  }

  @override
  String get accountFallbackEmail => '739059568@qq.com';

  @override
  String get accountOverviewRefreshFailed =>
      'Unable to refresh account overview. Please try again.';

  @override
  String get accountOverviewRefreshTimeUnavailable =>
      'Refresh time unavailable';

  @override
  String get accountSharedDevices => 'Shared devices';

  @override
  String get sharedDevicesTitle => 'Shared devices';

  @override
  String sharedDevicesShareToPeople(int count) {
    return 'Share to $count people';
  }

  @override
  String get sharedDevicesAddLabel => 'Add shared device';

  @override
  String get sharedDevicesEmpty => 'No shared devices yet.';

  @override
  String get sharedDevicesLoadFailed => 'Unable to load shared devices.';

  @override
  String get sharedDevicesRetry => 'Retry';

  @override
  String get sharedDeviceMemberAdministrator => 'Administrator';

  @override
  String get sharedDeviceMemberGuest => 'Guest';

  @override
  String get sharedDeviceMemberAccepted => 'Accepted';

  @override
  String get sharedDeviceMemberEditLabel => 'Edit shared device member';

  @override
  String get sharedDeviceMemberDeleteLabel => 'Delete shared device member';

  @override
  String get sharedDeviceMemberAvatarPlaceholderLabel =>
      'Shared device member avatar';

  @override
  String get accountReceivingDevices => 'Receiving devices';

  @override
  String get receivingDevicesTitle => 'RECEIVING DEVICES';

  @override
  String receivingDevicesOwnerEmail(String ownerEmail) {
    return 'Shared by: $ownerEmail';
  }

  @override
  String get receivingDevicesEmpty => 'No receiving devices yet.';

  @override
  String get receivingDevicesLoadFailed => 'Unable to load receiving devices.';

  @override
  String get receivingDevicesRetry => 'Retry';

  @override
  String get receivingDevicesEditLabel => 'Edit receiving devices';

  @override
  String get accountManageDevices => 'manage devices';

  @override
  String get manageDevicesTitle => 'Manage devices';

  @override
  String get manageDevicesSubtitle => 'Devices logged in';

  @override
  String get manageDevicesEmpty => 'No signed-in devices.';

  @override
  String get manageDevicesLoadFailed => 'Unable to load signed-in devices.';

  @override
  String get manageDevicesRetry => 'Retry';

  @override
  String get manageDevicesIosName => 'iOS device';

  @override
  String get manageDevicesAndroidName => 'Android device';

  @override
  String get manageDevicesUnknownDevice => 'Unknown device';

  @override
  String get manageDevicesUnknownLoginTime => 'Unknown login time';

  @override
  String get manageDevicesRemoveFailed =>
      'Unable to remove this device. Please try again.';

  @override
  String get manageDevicesPhoneName => 'Iphone 16 pro max';

  @override
  String get manageDevicesTabletName => 'Ipad air';

  @override
  String get manageDevicesLastActiveAt => '2025-08-02 11:02';

  @override
  String manageDevicesLoginTimestamp(
    int year,
    String month,
    String day,
    String hour,
    String minute,
  ) {
    return '$year-$month-$day $hour:$minute';
  }

  @override
  String get manageDevicesEditLabel => 'Edit signed-in devices';

  @override
  String get manageDevicesLogoutLabel => 'Sign out device';

  @override
  String get manageDevicesRemoveConfirmationMessage =>
      'Are you sure you want to remove\nthis device?';

  @override
  String get manageDevicesRemoveCancelAction => 'Cancel';

  @override
  String get manageDevicesRemoveConfirmAction => 'Confirm';

  @override
  String get accountMessage => 'message';

  @override
  String get accountRegion => 'Region';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountSystemPermissions => 'System permissions';

  @override
  String get systemPermissionsPageTitle => 'SYSTEM PERMISSIONS';

  @override
  String get systemPermissionsLocation => 'Access Geographic Location';

  @override
  String get systemPermissionsCamera => 'Access Camera Permissions';

  @override
  String get systemPermissionsMicrophone => 'Access recording permission';

  @override
  String get systemPermissionsStorage => 'Access phone storage';

  @override
  String get systemPermissionsBluetooth => 'Access mobile Bluetooth';

  @override
  String get systemPermissionsGranted => 'Granted';

  @override
  String get systemPermissionsDenied => 'Not granted';

  @override
  String get systemPermissionsLoadError => 'Unable to load system permissions.';

  @override
  String get systemPermissionsRequestError =>
      'Unable to request this permission.';

  @override
  String get accountAfterSalesService => 'after-sales service';

  @override
  String get accountManualGuide => 'Manual & guide';

  @override
  String get accountCheckForUpdates => 'Check for updates';

  @override
  String get accountAbout => 'About';

  @override
  String get upgradeCheckTitle => 'Check the upgraded version';

  @override
  String get upgradeCheckAppSection => 'APP';

  @override
  String get upgradeCheckFirmwareSection => 'firmware';

  @override
  String get upgradeCheckStartAction => 'Start upgrading';

  @override
  String get upgradeCheckUpgrading => 'Upgrading';

  @override
  String get upgradeCheckCompleted => 'Completed';

  @override
  String upgradeCheckDoorDeviceName(String name) {
    return 'Door Device Name : $name';
  }

  @override
  String upgradeCheckSerialNumber(String number) {
    return 'serial number : $number';
  }

  @override
  String upgradeCheckCurrentVersion(String version) {
    return 'Current Version : $version';
  }

  @override
  String get upgradeCheckSelectTimeTitle => 'Select upgrade time';

  @override
  String get upgradeCheckStatus => 'Status';

  @override
  String get upgradeCheckUpgradeTime => 'Upgrade time';

  @override
  String get upgradeCheckImmediate => 'immediate';

  @override
  String get upgradeCheckPostpone => 'postpone';

  @override
  String get upgradeCheckDateAndTime => 'date and time';

  @override
  String get upgradeCheckSchedulePastError => 'Choose a time in the future.';

  @override
  String get upgradeCheckCancelAction => 'Cancel';

  @override
  String get upgradeCheckConfirmAction => 'Confirm';

  @override
  String get upgradeCheckOnline => 'online';

  @override
  String get upgradeCheckOffline => 'offline';

  @override
  String upgradeCheckProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get accountDefaultRegion => 'England';

  @override
  String get accountDefaultLanguage => 'English';

  @override
  String get accountLanguageDialogTitle => 'Language';

  @override
  String get accountLanguageOptionFrench => 'France';

  @override
  String get accountLanguageOptionEnglish => 'English';

  @override
  String get accountLanguageOptionSimplifiedChinese => '中文(简体)';

  @override
  String get accountLanguageOptionTraditionalChinese => '中文(繁体)';

  @override
  String get accountLanguageOptionGerman => 'Das ist Deutsch';

  @override
  String get accountLanguageCancelAction => 'Cancel';

  @override
  String get accountLanguageConfirmAction => 'Confirm';

  @override
  String get accountLanguageOptionsLoading => 'Loading available languages…';

  @override
  String get accountLanguageOptionsLoadFailed =>
      'Unable to load available languages.';

  @override
  String get accountLanguageOptionsRetryAction => 'Retry';

  @override
  String get accountLanguageSaveFailed => 'Unable to update the language.';

  @override
  String get regionOptionsRetryAction => 'Retry';

  @override
  String get regionOptionsSaveFailed => 'Unable to update the region.';

  @override
  String get regionPageTitle => 'REGION';

  @override
  String get regionChina => 'China';

  @override
  String get regionAmerica => 'America';

  @override
  String get regionEngland => 'England';

  @override
  String get regionFrance => 'La Republique francaise';

  @override
  String get regionCanada => 'Canada';

  @override
  String accountMenuComingSoon(String item) {
    return '$item is coming soon';
  }

  @override
  String get deviceNameDialogTitle => 'Device Name';

  @override
  String get deviceNameInputPlaceholder => 'Input Device Name';

  @override
  String get deviceDeleteConfirmMessage =>
      'Are you sure to delete the device ?';

  @override
  String get deviceDeleteCancelAction => 'No';

  @override
  String get deviceDeleteConfirmAction => 'Yes';

  @override
  String get deviceCustomizeTitle => 'Customize';

  @override
  String get deviceCustomizeChangePictureAction => 'Change picture';

  @override
  String get deviceCustomizeDefaultPictureAction => 'Default picture';

  @override
  String get deviceCustomizeChangePictureFailed =>
      'Failed to change picture. Please try again.';

  @override
  String get deviceCustomizeResetPictureFailed =>
      'Failed to reset the default picture. Please try again.';

  @override
  String get addNewDoorsTitle => 'Add new doors';

  @override
  String get addNewDoorsSubtitle => 'Select the door to be added';

  @override
  String get addNewDoorsBackTooltip => 'Back';

  @override
  String get addNewDoorsGarageDoor => 'Garage door';

  @override
  String get addNewDoorsRollerDoor => 'Roller door';

  @override
  String get addNewDoorsIndustrialDoor => 'Industrial door';

  @override
  String get addNewDoorsSwingGate => 'Swing gate';

  @override
  String get addNewDoorsSlidingGate => 'Sliding gate';

  @override
  String get addDoorNameDialogTitle => 'Door name';

  @override
  String get addDoorNameInputPlaceholder => 'Input door name';

  @override
  String get addDoorSceneDefault => 'Home';

  @override
  String get addDoorSceneSelectPlaceholder => 'Select scene';

  @override
  String get addDoorSceneLoading => 'Loading scenes…';

  @override
  String get addDoorSceneEmpty => 'No scenes available';

  @override
  String get addDoorSceneLoadFailed => 'Unable to load scenes. Tap to retry.';

  @override
  String get addDoorNameCancelAction => 'Cancel';

  @override
  String get addDoorNameConfirmAction => 'Confirm';

  @override
  String get addDeviceTitle => 'Add New Device';

  @override
  String get addDeviceSubtitle => 'Select the device to be added';

  @override
  String get addDeviceFBoxSection => 'F-box';

  @override
  String get addDeviceSmartControllerSection => 'Smart controller';

  @override
  String get addDeviceSmartAccessorySection => 'Smart accessory';

  @override
  String get addDeviceFBox => 'F-box';

  @override
  String get fBoxConnectionGuideTitle => 'Connection';

  @override
  String get fBoxConnectionGuideInstructions =>
      '1. Connect power supply to door operator, confirm the Wi-Fi light is flashing or steady\n2. Confirm other related accessories have been matched to F-box.';

  @override
  String get fBoxConnectionGuideManualHint =>
      '*Connection steps refer to manuals';

  @override
  String get fBoxConnectionGuideNextAction => 'NEXT';

  @override
  String get fBoxWiringTestTitle => 'Test';

  @override
  String get fBoxWiringTestDescription =>
      'Click the button below, if the door operates normally, press \'NEXT\'.\nIf not, change \'O/S/C wiring\' to test again.';

  @override
  String get fBoxWiringTestPbWiring => 'PB wiring';

  @override
  String get fBoxWiringTestOscWiring => 'O/S/C wiring';

  @override
  String get fBoxWiringTestDoorOperatesNormally => 'door operates normally';

  @override
  String get fBoxWiringTestPbAction => 'Test PB wiring';

  @override
  String get fBoxWiringTestOpenAction => 'Open door';

  @override
  String get fBoxWiringTestStopAction => 'Stop door';

  @override
  String get fBoxWiringTestCloseAction => 'Close door';

  @override
  String get addDeviceUsbWifiModule => 'USB WIFI module';

  @override
  String get usbDongleGuideTitle => 'USB Dongle Installation';

  @override
  String get usbDongleGuideDescription =>
      'Follow the installation guide for the selected door type.';

  @override
  String get usbDongleGuideInsertTitle => '1. Insert the USB WIFI module';

  @override
  String get usbDongleGuideInsertDescription =>
      'Find the corresponding USB interface and insert the WIFI module.';

  @override
  String get usbDongleGuideIndicatorTitle =>
      '2. Observe the status of the indicator light';

  @override
  String get usbDongleGuideIndicatorDescription =>
      '2.1 If the USB light is off or flashing, you may search for the device directly.';

  @override
  String get usbDongleGuideSearchDeviceAction => 'Search for Device';

  @override
  String get addDeviceSmartOpener => 'Smart Opener (Built-in Wi-Fi)';

  @override
  String get addDeviceSolarEnergySystem => 'Evolution module';

  @override
  String get addDeviceCamera => 'Camera';

  @override
  String get smartOpenerScanTitle => 'Scan';

  @override
  String get smartOpenerScanDescription =>
      'Scan the QR code inside the package with your smart phone.';

  @override
  String get smartOpenerScanAction => 'Scan';

  @override
  String get smartOpenerScannerManualAction =>
      'No QR code available? Add manually';

  @override
  String get smartOpenerScannerGalleryAction => 'Gallery';

  @override
  String get smartOpenerScannerFlashlightAction => 'Flashlight';

  @override
  String get smartOpenerScannerBackTooltip => 'Back';

  @override
  String get smartOpenerScannerBluetoothTooltip => 'Scan Bluetooth devices';

  @override
  String get smartOpenerScannerPermissionError =>
      'Camera permission is required to scan the QR code.';

  @override
  String get smartOpenerScannerUnknownError => 'Unable to start the scanner.';

  @override
  String get smartOpenerScannerNoCodeFound =>
      'No QR code found in the selected image.';

  @override
  String get smartOpenerScannerImageFailed =>
      'Unable to read the selected image.';

  @override
  String get smartOpenerScannerInvalidCode =>
      'This QR code is not a valid Smart Opener device code.';

  @override
  String get smartOpenerScannerDeviceNotFound =>
      'The device matching this QR code was not found. Please try again.';

  @override
  String get smartOpenerScannerConnectionFailed =>
      'Unable to connect to the device. Please try scanning again.';

  @override
  String get smartOpenerQrPayloadReceived =>
      'QR code received. Continue by connecting the device.';

  @override
  String get smartOpenerBleScanningTitle => 'Scanning';

  @override
  String get smartOpenerBleScanningDescription => 'Be sure to operate on site!';

  @override
  String get smartOpenerBleScanningStatus =>
      'Scanning the device, please wait...';

  @override
  String get smartOpenerScanResultsTitle => 'SCAN RESULTS';

  @override
  String smartOpenerScanResultsCount(int count) {
    return 'Found $count Devices';
  }

  @override
  String get smartOpenerAddAction => '+ Add';

  @override
  String get smartOpenerAddedDevicesTitle => 'Already Added';

  @override
  String get smartOpenerAddedDevicesDescription =>
      'The following devices have been connected';

  @override
  String get smartOpenerAddedDeviceName => 'Smart Opener';

  @override
  String get smartOpenerAddedDeviceIdentifier => 'opener_B8F86211A9DC';

  @override
  String get smartOpenerAddedAddTooltip => 'Add device';

  @override
  String get smartOpenerAddedDeleteTooltip => 'Remove device';

  @override
  String get smartOpenerAddedDisconnectConfirmMessage =>
      'Are you sure to disconnect this device?';

  @override
  String get smartOpenerAddedUnbindFailedMessage =>
      'Unable to remove device. Please try again.';

  @override
  String get smartOpenerAddedLoading => 'Loading devices…';

  @override
  String get smartOpenerAddedEmptyTitle => 'No connected devices';

  @override
  String get smartOpenerAddedEmptyDescription =>
      'Connected devices will appear here.';

  @override
  String get smartOpenerAddedLoadFailed => 'Unable to load connected devices.';

  @override
  String get smartOpenerAddedRetryAction => 'Retry';

  @override
  String get smartOpenerAddedNoMore => 'No more devices';

  @override
  String get deviceCommandMoreTooltip => 'More';

  @override
  String get deviceCommandLoading => 'Loading device controls…';

  @override
  String get deviceCommandLoadFailed =>
      'Unable to load device controls. Please try again.';

  @override
  String get deviceCommandRetry => 'Retry';

  @override
  String get deviceCommandDoorStateRunning => 'Running';

  @override
  String deviceCommandDoorStateWithPercent(String state, int percent) {
    return '$state · $percent%';
  }

  @override
  String get smartOpenerDefaultDeviceSubtitle => 'Default encoding door|54-89';

  @override
  String get smartOpenerDeviceNotFoundTitle => 'Device not found';

  @override
  String get smartOpenerDeviceNotFoundDescription =>
      'No nearby device is detected. Please confirm the device has been reset successfully and try scanning again!';

  @override
  String get smartOpenerRescanAction => 'Rescan';

  @override
  String get smartOpenerBackHomeAction => 'Back to home';

  @override
  String get smartOpenerChooseWifiTitle => 'CHOOSE WIFI';

  @override
  String get smartOpenerChooseWifiDescription =>
      'Device only supports a 2.4GHZ Wi-Fi connection';

  @override
  String get smartOpenerSelectWifiPlaceholder => 'Select Wi-Fi';

  @override
  String get smartOpenerWifiPasswordPlaceholder => 'Enter the Wi-Fi password';

  @override
  String get smartOpenerWifiPasswordHint =>
      'Wi-Fi password error is one of the most common reasons for failure. Please check your Wi-Fi password carefully';

  @override
  String get smartOpenerEnableBluetoothTip =>
      'Enable Bluetooth before submission';

  @override
  String get smartOpenerNextAction => 'NEXT';

  @override
  String get smartOpenerSkipAction => 'Skip';

  @override
  String get smartOpenerSkipTip =>
      'Only use Bluetooth mode to operate, skip Wifi distribution network';

  @override
  String get smartOpenerSelectWifiTitle => 'Select Wi-Fi';

  @override
  String get smartOpenerRefreshWifiTooltip => 'Refresh Wi-Fi list';

  @override
  String get smartOpenerConnectingTitle => 'Connecting';

  @override
  String get smartOpenerConnectingTip =>
      'Keep your phone as close to the device as possible';

  @override
  String get smartOpenerConnectionFailedMessage =>
      'Connection failed. Please check Wi-Fi password and try again.';

  @override
  String get smartOpenerOkAction => 'OK';

  @override
  String get smartOpenerStopAdditionTitle => 'STOP DEVICE ADDITION';

  @override
  String get smartOpenerStopAdditionDescription =>
      'The device is being added. The WIFI module needs to be reset before add it again after termination.';

  @override
  String get smartOpenerCancelAction => 'Cancel';

  @override
  String get smartOpenerConfirmAction => 'Confirm';

  @override
  String get smartOpenerConnectionSuccessTitle => 'Connection successful';

  @override
  String get smartOpenerConnectionSuccessDescription =>
      'configure the device information';

  @override
  String get smartOpenerDeviceNamePlaceholder => 'Device Name';

  @override
  String get smartOpenerSelectScenePlaceholder => 'Select scene';

  @override
  String get smartOpenerRenameFailed =>
      'Unable to update the name. Please try again.';

  @override
  String get smartOpenerRenameNetworkUnavailable =>
      'Network unavailable. Please try again.';

  @override
  String get smartOpenerInviteFamilyTip => 'Invite the family to use it';

  @override
  String get smartOpenerShareAction => 'To share';

  @override
  String get smartOpenerTryAction => 'Try it';

  @override
  String get smartOpenerShareDialogTitle => 'SHARE DEVICE';

  @override
  String get smartOpenerShareDialogDescription =>
      'Enjoy the smart life with your family!';

  @override
  String get smartOpenerShareDialogAccountHint =>
      'Email/Amazon account /Google account';

  @override
  String get smartOpenerDisconnectFailedMessage =>
      'Unable to disconnect device. Scanning continues.';

  @override
  String get chooseSceneTitle => 'CHOOSE A SCENE';

  @override
  String get chooseSceneBackTooltip => 'Back';

  @override
  String get chooseSceneEditTooltip => 'Edit scene';

  @override
  String chooseSceneDeviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Devices',
      one: '1 Device',
      zero: '0 Devices',
    );
    return '$_temp0';
  }

  @override
  String get chooseSceneNewSceneAction => 'New scene';

  @override
  String get chooseSceneEmpty => 'No scenes available';

  @override
  String get chooseSceneLoadFailed => 'Unable to load scenes. Tap to retry.';

  @override
  String get chooseSceneMoveFailed =>
      'Unable to move the door. Please try again.';

  @override
  String get chooseSceneMoveNetworkUnavailable =>
      'Network unavailable. Please try again.';

  @override
  String get chooseSceneMoveUnavailable =>
      'This door cannot be moved to another scene.';

  @override
  String get sceneHomeShortcutTooltip => 'Scene';

  @override
  String get sceneTitle => 'SCENE';

  @override
  String get sceneEditingTitle => 'SCENE EDITING';

  @override
  String sceneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Scenes',
      one: '1 Scene',
      zero: '0 Scenes',
    );
    return '$_temp0';
  }

  @override
  String get sceneBackTooltip => 'Back';

  @override
  String get sceneEditTooltip => 'Edit scene';

  @override
  String get sceneDoneEditingTooltip => 'Done editing';

  @override
  String sceneDeviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Devices',
      one: '1 Device',
      zero: '0 Devices',
    );
    return '$_temp0';
  }

  @override
  String get sceneNewSceneAction => 'New scene';

  @override
  String get sceneNameDialogTitle => 'Scene Name';

  @override
  String get sceneNameInputPlaceholder => 'Input scene name';

  @override
  String get sceneNameCancelAction => 'Cancel';

  @override
  String get sceneNameConfirmAction => 'confirm';

  @override
  String get notificationTitle => 'Notification';

  @override
  String get notificationAllRead => 'All read';

  @override
  String get notificationAllReadMessage =>
      'All notifications have been marked as read';

  @override
  String get notificationNotFound => 'Notification not found';

  @override
  String get notificationViewDetails => 'View details';

  @override
  String get notificationAppointmentAfterSales =>
      'Appointment for after-sales service';

  @override
  String get notificationUpgrade => 'Upgrade';

  @override
  String get notificationAppointmentTime => 'Appointment time';

  @override
  String get notificationUpgradeComingSoon => 'Device upgrade is coming soon';

  @override
  String get afterSalesDetailsTitle => 'After sales service details';

  @override
  String get afterSalesAppointmentTitle =>
      'Appointment for after-sales service';

  @override
  String get afterSalesProblemDescription => 'Problem description';

  @override
  String get afterSalesAppointmentTime => 'appointment time';

  @override
  String get afterSalesRemark => 'Remark';

  @override
  String get afterSalesPicture => 'Picture';

  @override
  String get afterSalesInstallerConfirm => 'Installation personnel confirm';

  @override
  String get afterSalesConfirmed => 'Confirmed';

  @override
  String get afterSalesFeedback => 'feedback';

  @override
  String get afterSalesContactInstaller => 'Contact the installer';

  @override
  String get afterSalesFeedbackSubmitted => 'Feedback submitted';

  @override
  String get afterSalesContactComingSoon => 'Installer contact is coming soon';

  @override
  String get afterSalesDescriptionHint =>
      'Suggest including key information such as equipment model, fault symptoms, etc';

  @override
  String get afterSalesSubmitToEngineer => 'Submit to Engineer';

  @override
  String get afterSalesDescriptionRequired =>
      'Please enter a problem description';

  @override
  String get afterSalesSubmitSuccess => 'Appointment submitted successfully';

  @override
  String get deviceSettingsTitle => 'Setting';

  @override
  String get deviceSettingsForUsers => 'For users';

  @override
  String get deviceSettingsForInstallers => 'For installers';

  @override
  String get deviceSettingsTransmitterManagement => 'Transmitter management';

  @override
  String get deviceSettingsLedOffDelay => 'LED off delay';

  @override
  String get deviceSettingsPartialOpen => 'Partial open';

  @override
  String get deviceSettingsPartialOpenHeight => 'Partial open height';

  @override
  String get deviceSettingsAutoClose => 'Auto close';

  @override
  String get deviceSettingsAutoCloseCondition => 'Auto close condition';

  @override
  String get deviceSettingsLoading => 'Reading device attributes…';

  @override
  String get deviceSettingsLoadFailed => 'Unable to read device attributes.';

  @override
  String get deviceSettingsRetry => 'Retry';

  @override
  String get deviceSettingsWriting => 'Writing…';

  @override
  String get deviceSettingsRawUnavailable => 'Not reported';

  @override
  String deviceSettingsRawValueDisplay(String hexValue, int decimalValue) {
    return '$hexValue ($decimalValue)';
  }

  @override
  String get deviceSettingsRawValueHelp =>
      'Enter the raw device value in decimal or hexadecimal (for example, 30 or 0x1E).';

  @override
  String get deviceSettingsRawValueLabel => 'Raw value';

  @override
  String deviceSettingsRawValueInvalid(int maximum) {
    return 'Enter a value from 0 to $maximum.';
  }

  @override
  String get deviceSettingsRawValueProtocolInvalid =>
      'Enter a value supported by the device.';

  @override
  String get deviceSettingsBluetoothConnectionRequired =>
      'Connect this device by Bluetooth before changing settings.';

  @override
  String get deviceSettingsRawCancel => 'Cancel';

  @override
  String get deviceSettingsRawSave => 'Save';

  @override
  String get deviceSettingsOpeningSpeed => 'Opening speed';

  @override
  String get deviceSettingsOpeningSpeedValue => 'GMT+8:00';

  @override
  String get deviceSettingsAboutDevice => 'About the device';

  @override
  String get deviceSettingsDoorOpenReminder => 'Door open reminder';

  @override
  String get deviceSettingsDoorOpenReminderTime => 'Door open reminder time';

  @override
  String get deviceSettingsForceMargin => 'Force margin';

  @override
  String get deviceSettingsBluetoothName => 'Bluetooth name';

  @override
  String get deviceSettingsFirmwareVersion => 'Firmware version';

  @override
  String get deviceSettingsHardwareVersion => 'Hardware version';

  @override
  String get deviceSettingsCheckVersion => 'Check version';

  @override
  String get deviceSettingsTransmitterLearning => 'Transmitter learning';

  @override
  String get deviceSettingsManagement => 'Management';

  @override
  String get deviceSettingsAutoClosingSetting => 'Auto closing setting';

  @override
  String get deviceSettingsAutoCloseCaption =>
      'Current setting: 120s (motor setting)\nAuto close position';

  @override
  String get deviceSettingsAutoCloseTime => 'Auto close time';

  @override
  String get deviceSettingsUpLimit => 'Up limit';

  @override
  String get deviceSettingsAnyPosition => 'Any position';

  @override
  String get deviceSettingsCancelAction => 'Cancel';

  @override
  String get deviceSettingsConfirmAction => 'Confirm';

  @override
  String get transmitterManagementTipsTitle => 'Tips';

  @override
  String get transmitterManagementSafetyTip =>
      '1. For safety consideration, we suggest to manage all the transmitters through the app.';

  @override
  String get transmitterManagementHowToTip =>
      '2. How to manage the transmitters?\nJust relearning the transmitter through the app.';

  @override
  String get transmitterManagementEditAction => 'Edit transmitter';

  @override
  String get transmitterManagementDeleteAction => 'Delete transmitter';

  @override
  String get transmitterManagementAddAction => 'Add transmitter';

  @override
  String get transmitterManagementInfoTitle => 'Transmitter info';

  @override
  String get transmitterManagementNameHint => 'Input transmitter name';

  @override
  String get transmitterManagementDeletePromptTitle => 'Prompt';

  @override
  String get transmitterManagementDeletePromptMessage =>
      'Please confirm whether you want to delete the transmitter';

  @override
  String deviceSettingsMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String deviceSettingsSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String deviceSettingsOpeningSpeedCurrent(int value) {
    return 'Current setting: $value% (motor setting)';
  }

  @override
  String deviceSettingsPercent(int value) {
    return '$value%';
  }

  @override
  String deviceSettingsOpeningSpeedStandardGuide(int value) {
    return '$value%\n(STD)';
  }

  @override
  String get deviceSettingsForceMarginMaximumGuide => '+15%';

  @override
  String get deviceSettingsStandardAbbreviation => 'STD';

  @override
  String get deviceSettingsForceMarginWarning15Days =>
      '1. This function is temporarily used when you can\'t operate the door due to the spring being loose or the track being blocked.\n\n2. This function is only effective for 15 days. Please contact the maintenance party as soon as possible.';

  @override
  String get deviceSettingsForceMarginWarning3Days =>
      'This temporary setting is effective for three days only. Please contact the maintenance party as soon as possible.';

  @override
  String get deviceSettingsForceMarginWarning3DaysFull =>
      '1. This function is temporarily used when you can\'t operate the door due to the spring being loose or the track being blocked.\n\n2. This function is only effective for three days. Please contact the maintenance party as soon as possible.';

  @override
  String get deviceSettingsForceMarginTemporaryCurrent =>
      'Current setting: standard (motor setting)';

  @override
  String deviceSettingsForceMarginLevel(int level) {
    return 'Level $level';
  }

  @override
  String deviceSettingsForceMarginLevelCurrent(int level) {
    return 'Current setting: Level $level (motor setting)';
  }

  @override
  String get transmitterLearningTitle => 'Transmitter learning';

  @override
  String get transmitterLearningOnSiteTip => 'Be sure to operate on site!';

  @override
  String get transmitterLearningKeepBluetoothOn => 'Keep Bluetooth on';

  @override
  String get transmitterLearningReadyDescription =>
      '1. Make sure the distance between the mobile phone and the opener is less than 5 meters.\n\n2. The learning will end automatically if there\'s no operation within 20 seconds.';

  @override
  String get transmitterLearningInProgress => 'Learning...';

  @override
  String get transmitterLearningInProgressDescription =>
      'Click any button (the same button) continuously at least 3 times.';

  @override
  String get transmitterLearningFailed => 'Transmitter Learning Failed';

  @override
  String get transmitterLearningSucceeded => 'Transmitter Learning Succeed';

  @override
  String get transmitterLearningRemoteInstruction =>
      'Please use the remote control to try';

  @override
  String get transmitterLearningStartAction => 'Start Learning';

  @override
  String get transmitterLearningRestartAction => 'Restart';

  @override
  String get transmitterLearningCompleteAction => 'Complete';

  @override
  String get hardwareDiagnosticsTitle => 'Hardware diagnostics';

  @override
  String get hardwareDiagnosticsDetailedLogging =>
      'Detailed hardware diagnostics';

  @override
  String get hardwareDiagnosticsFlutterLogging => 'Flutter BLE console logging';

  @override
  String get hardwareDiagnosticsNativeLogging => 'Native BLE console logging';

  @override
  String get hardwareDiagnosticsWarning =>
      'Flutter logging prints formatted Bluetooth frames in the Flutter console. Keep native logging off to avoid duplicate entries. AES keys, tokens, Wi-Fi passwords, and other credentials are never logged.';

  @override
  String get hardwareDiagnosticsUpdateFailed =>
      'Failed to update diagnostic logging. Please try again.';

  @override
  String get securityCenterTitle => 'Security Center';

  @override
  String get securityCenterProtecting => 'Protecting...';

  @override
  String get securityCenterDownloadFullReport => 'Download the full report';

  @override
  String get securityCenterGeneralEvaluation => 'General Evaluation';

  @override
  String get securityCenterDoorOperationStatus => 'Door Operation Status';

  @override
  String get securityCenterDoorOperationRecord => 'Door Operation Record';

  @override
  String get securityCenterSafetySensorsEvaluation =>
      'Safety Sensors Evaluation';

  @override
  String get securityCenterWirelessPhotoBeam => 'Wireless Photo Beam';

  @override
  String get securityCenterWirelessELock => 'Wireless E-lock';

  @override
  String get securityCenterWirelessSensors => 'Wireless Sensors';

  @override
  String get securityCenterWiredSensors => 'Wired Sensors';

  @override
  String get securityCenterPhotoBeam => 'Photo beam';

  @override
  String get securityCenterELock => 'E-lock';

  @override
  String get securityCenterDoorSensor => 'Door sensor';

  @override
  String get securityCenterRadar => 'Radar';

  @override
  String get securityCenterRemote => 'Remote';

  @override
  String get securityCenterSafetyEdge => 'Safety edge';

  @override
  String get securityCenterWiredPhotoBeam => 'Wired photo beam';

  @override
  String get securityCenterWiredELock => 'Wired E-lock';

  @override
  String get securityCenterWifiDisconnectedMessage =>
      'Security center can only be accessed when your motor is properly connected to Wi-Fi. Please check the motor status.';

  @override
  String get securityCenterWifiDisconnectedBackAction => 'Back';

  @override
  String get securityReportTitle => 'Safety Report';

  @override
  String get securityReportMotorName => 'Garage door motor 01';

  @override
  String get securityReportSerialNumber => 'Serial number: SFD123456789';

  @override
  String get securityReportDoorName => 'Garage door 01';

  @override
  String get securityReportOperatedCycles => 'Operated cycles';

  @override
  String get securityReportRemainingCycles => 'Remaining cycles';

  @override
  String get securityReportMaintenanceWarning =>
      'Please maintain the door as soon as possible.';

  @override
  String get securityReportBalanceEvaluation => 'Door balance evaluation';

  @override
  String get securityReportBalanceNote =>
      'Mark: Evaluation is limited to the door\'s latest open/close operation.';

  @override
  String get securityReportOpenEvaluation => 'Open evaluation';

  @override
  String get securityReportCloseEvaluation => 'Close evaluation';

  @override
  String get securityReportBalanceStatusUnavailable => '--';

  @override
  String get securityReportOverload => 'Over load';

  @override
  String get securityReportOperationRecord => 'Door operation record';

  @override
  String get securityReportLast24Hours => 'Last 24 hours';

  @override
  String get securityReportLast7Days => 'Last 7 days';

  @override
  String get securityReportTimeCyclesAxis => 'X: Time Y: Operation cycles';

  @override
  String get securityReportDateCyclesAxis => 'X: Date Y: Operation cycles';

  @override
  String get securityReportFrequentOperationWarning =>
      'Unusually frequent operation on Monday. Please check it.';

  @override
  String get securityReportMotorFunctionStatus => 'Motor function status';

  @override
  String get securityReportWiredSensorsDiagnosis => 'Wired sensors diagnosis';

  @override
  String get securityReportWirelessSensorsDiagnosis =>
      'Wireless sensors diagnosis';

  @override
  String get securityReportNormal => 'Normal';

  @override
  String get securityReportDisconnect => 'Disconnect';

  @override
  String get safetySensorTriggered => 'Triggered';

  @override
  String get safetySensorReplaceBattery => 'How to replace the battery';

  @override
  String get safetySensorLowBatterySolution => 'Solution for low battery power';

  @override
  String get batteryReplacementIllustration =>
      'Battery replacement illustration';

  @override
  String get safetySensorLowBatteryWarning => 'Low battery power';

  @override
  String safetySensorBatteryModel(String model) {
    return 'Battery model: $model';
  }

  @override
  String get safetySensorBatteryModelLabel => 'Battery model: ';

  @override
  String safetySensorRatedVoltage(String voltage) {
    return 'Rated voltage: $voltage';
  }

  @override
  String get safetySensorRatedVoltageLabel => 'Rated voltage: ';

  @override
  String get safetySensorLowBatteryInstruction =>
      '*Low battery, please replace the battery promptly. Incorrect battery model could cause the device cannot operate';

  @override
  String get safetySensorImagePlaceholder => 'Image placeholder';

  @override
  String get safetySensorDefaultName => 'Safety sensor';

  @override
  String get securityReportAbnormal => 'Abnormal';

  @override
  String get securityReportNotTriggered => 'Not triggered';

  @override
  String get securityReportLocked => 'Locked';

  @override
  String get securityReportBatteryEnough => 'Battery power enough';

  @override
  String get securityReportBatteryLow => 'Battery is low';

  @override
  String get securityReportWirelessWicketDoor => 'Wireless wicket door';

  @override
  String get securityReportWirelessSafetyEdge => 'Wireless safety edge';

  @override
  String get securityReportWirelessPositionSensor => 'Wireless position sensor';

  @override
  String get securityReportSafetySuggestion => 'Safety suggestion:';

  @override
  String get securityReportSuggestionCycles =>
      'Operated cycles has reached the maintenance warning;';

  @override
  String get securityReportSuggestionBattery =>
      'Battery power of safety edge is low, replace it in time;';

  @override
  String get securityReportSuggestionMaintenance =>
      'Contact your installer for a necessary maintenance to ensure the safety of the door.';

  @override
  String get securityReportSuggestionCurrent =>
      'The opening current of your opener exceeds the maximum value we set.';

  @override
  String get securityReportSaveSuccess => 'Report saved to album.';

  @override
  String get securityReportSaveAccessDenied =>
      'Photo library permission is required to save the report.';

  @override
  String get securityReportSaveNoSpace =>
      'Not enough storage space to save the report.';

  @override
  String get securityReportSaveUnsupported =>
      'Unable to save this image format.';

  @override
  String get securityReportSaveFailed => 'Unable to save report image.';

  @override
  String get securityReportCaptureFailed => 'Unable to create report image.';

  @override
  String get securityReportDoorOpeningForce => 'Door opening force';

  @override
  String get securityReportDoorClosingForce => 'Door closing force';

  @override
  String get securityReportAutoCloseTime => 'Auto close time';

  @override
  String get securityReportAutoCloseCondition => 'Auto close condition';

  @override
  String get securityReportLedOffDelay => 'LED off delay';

  @override
  String get securityReportPartialOpen => 'Partial open';

  @override
  String get securityReportIgnoreObstructionHeight =>
      'Ignore obstruction height';

  @override
  String get securityReportPhotoBeamFunction => 'Photo beam function';

  @override
  String get securityReportCommunityMode => 'Community mode';

  @override
  String get securityReportLevel1 => 'Level1';

  @override
  String get securityReportAnyPosition => 'Any position';

  @override
  String get securityReportOn => 'ON';

  @override
  String get generalEvaluationLoadFailed => 'Unable to load. Tap to retry.';

  @override
  String get safetySensorsLoadFailed =>
      'Unable to load safety sensors. Tap to retry.';

  @override
  String get safetySensorsEmpty => 'No safety sensor data is available.';

  @override
  String get safetySensorsWiredStatus => 'Wired sensor status';

  @override
  String get safetySensorsWirelessStatus => 'Wireless Sensors Status';

  @override
  String get safetySensorsMetricSensors => 'Sensors';

  @override
  String get safetySensorsMetricFine => 'Fine';

  @override
  String get safetySensorsMetricAbnormal => 'Abnormal';

  @override
  String get safetySensorsMetricLowPower => 'Low power';

  @override
  String get safetySensorsMatch => 'Match';

  @override
  String get safetySensorsManage => 'Manage';

  @override
  String get safetySensorPairingTitle => 'Sensor pairing';

  @override
  String get safetySensorPairingGuideTitle => 'Sensor match';

  @override
  String get safetySensorPairingGuideStatus => 'Keep Bluetooth on';

  @override
  String get safetySensorPairingBluetoothEnabled => 'Keep Bluetooth enabled';

  @override
  String get safetySensorPairingGuideDescription =>
      '1.Make sure the distance between the phone and the motor is less than 5 meters.\n2.Make sure the distance between the safety sensor and the motor is less than 10 meters.\n3.If no learning operation is performed within 30 seconds, the learning will end automatically.';

  @override
  String get safetySensorPairingGuideAction => 'Start Learning';

  @override
  String get safetySensorPairingStart => 'Start pairing';

  @override
  String get safetySensorPairingInProgress => 'Learning...';

  @override
  String get safetySensorPairingMatchingDescription =>
      'Press and hold the pairing button on the wireless sensor.';

  @override
  String get safetySensorPairingCancel => 'Cancel';

  @override
  String get safetySensorPairingCancelling => 'Cancelling pairing...';

  @override
  String get safetySensorPairingBack => 'Back';

  @override
  String get safetySensorPairingFailed => 'Safety device pairing failed';

  @override
  String get safetySensorPairingTimeout => 'Safety device pairing timed out';

  @override
  String get safetySensorPairingFailedDescription =>
      'Safety device pairing failed. Please go back.';

  @override
  String get safetySensorPairingTimeoutDescription =>
      'Safety device pairing timed out. Please go back.';

  @override
  String get safetySensorPairingBluetoothDisconnected =>
      'Bluetooth disconnected. Safety device pairing cannot continue.';

  @override
  String get safetySensorPairingCommunicationTimeout =>
      'Bluetooth communication timed out without a device response.';

  @override
  String safetySensorPairingReasonCode(String code) {
    return 'Fault code: $code';
  }

  @override
  String get safetySensorPairingSuccess =>
      'Wireless safety sensor learning successful';

  @override
  String get safetySensorPairingLearningFailed =>
      'Wireless safety sensor learning failed';

  @override
  String get safetySensorPairingComplete => 'Complete';

  @override
  String get safetySensorPairingImagePlaceholder =>
      'Pairing illustration placeholder';

  @override
  String get safetySensorManagementTitle => 'Sensor management';

  @override
  String get safetySensorManagementEmpty => 'No wireless sensors to manage.';

  @override
  String get safetySensorManagementDeleteLabel => 'Delete sensor';

  @override
  String safetySensorManagementDeleteMessage(String sensorName) {
    return 'Delete $sensorName? The device will no longer be available and all settings will be cleared. Are you sure?';
  }

  @override
  String get safetySensorManagementCancel => 'Cancel';

  @override
  String get safetySensorManagementConfirm => 'Confirm';

  @override
  String get safetySensorsWirelessWicketDoor => 'Wireless wicket door';

  @override
  String get safetySensorsWirelessSafetyEdge => 'Wireless safety edge';

  @override
  String get safetySensorsWirelessSlackRope => 'Wireless slack rope';

  @override
  String get safetySensorUnlocked => 'Unlocked';

  @override
  String get safetySensorLocked => 'Locked';

  @override
  String get safetySensorNotTriggered => 'Not triggered';

  @override
  String get safetySensorOffline => 'Offline';

  @override
  String get deviceCommandFallbackDoorName => 'Garage door';

  @override
  String get deviceCommandOperatedCycles => 'Operated cycles';

  @override
  String get deviceCommandRemainingCycles => 'Remaining';

  @override
  String get deviceCommandVideoTooltip => 'Video';

  @override
  String get deviceCommandCloseTooltip => 'Close';

  @override
  String get deviceCommandStopTooltip => 'Stop';

  @override
  String get deviceCommandOpenTooltip => 'Open';

  @override
  String get deviceCommandAutoCloseTitle => 'Auto close';

  @override
  String get deviceCommandOpenReminderTitle => 'Open reminder';

  @override
  String deviceCommandMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get deviceCommandLedTitle => 'LED';

  @override
  String deviceCommandCentimeters(int value) {
    return '$value cm';
  }

  @override
  String get deviceCommandPartialOpenTitle => 'Partial open';

  @override
  String get deviceCommandPartialOpenSettingUnavailable =>
      'Partial-open positions are temporarily unavailable. Please try again.';

  @override
  String get deviceCommandPartialOpenSettingFailed =>
      'Unable to save the partial-open position. Please try again.';

  @override
  String get deviceCommandMoreSettingsTitle => 'More settings';

  @override
  String get deviceCommandActionOpen => 'Open';

  @override
  String get deviceCommandActionClose => 'Close';

  @override
  String get deviceCommandActionStop => 'Stop';

  @override
  String get deviceCommandActionPartialOpen => 'Partial open';

  @override
  String get deviceCommandActionLedOn => 'Turn LED on';

  @override
  String get deviceCommandActionLedOff => 'Turn LED off';

  @override
  String get deviceCommandActionPb => 'PB';

  @override
  String deviceCommandSending(String action, String controlCode) {
    return 'Sending $action command ($controlCode)...';
  }

  @override
  String deviceCommandSucceeded(String action, String controlCode) {
    return '$action command sent ($controlCode).';
  }

  @override
  String deviceCommandRejected(String action, String controlCode) {
    return '$action command was rejected ($controlCode).';
  }

  @override
  String deviceCommandBluetoothRequired(String action) {
    return 'Connect the selected device via Bluetooth to use $action.';
  }

  @override
  String deviceCommandRemoteFailed(String action) {
    return 'Unable to complete $action. Please try again.';
  }

  @override
  String deviceCommandRemoteUnconfirmed(String action) {
    return 'The device acknowledged $action, but the actual door movement could not be confirmed.';
  }

  @override
  String deviceCommandRemoteTimeout(String action) {
    return '$action timed out. Check the door state and try again.';
  }

  @override
  String deviceCommandNetworkFailure(String action) {
    return 'Unable to send $action. Check your network and try again.';
  }
}
