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
  String get deviceShareEmailLabel => 'Email';

  @override
  String get deviceShareEmailPlaceholder => 'Email/Account';

  @override
  String get deviceSharePeriodLabel => 'Sharing period';

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
  String get deviceShareCapabilityLedDelay => 'LED off delay';

  @override
  String get deviceShareCancelAction => 'Cancel';

  @override
  String get deviceShareConfirmAction => 'Confirm';

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
  String get accountSharedDevices => 'Shared devices';

  @override
  String get accountReceivingDevices => 'Receiving devices';

  @override
  String get accountManageDevices => 'manage devices';

  @override
  String get accountMessage => 'message';

  @override
  String get accountRegion => 'Region';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountSystemPermissions => 'System permissions';

  @override
  String get accountCheckForUpdates => 'Check for updates';

  @override
  String get accountAbout => 'About';

  @override
  String get accountDefaultRegion => 'England';

  @override
  String get accountDefaultLanguage => 'English';

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
  String get hardwareDiagnosticsWarning =>
      'When enabled, raw Bluetooth frames and decrypted protocol data are written to the system console for troubleshooting. AES keys, tokens, Wi-Fi passwords, and other credentials are never logged.';

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
}
