// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'FLINX';

  @override
  String get operationRecordTitle => '操作记录';

  @override
  String get operationRecordLast14DaysDescription => '最近 14 天的操作数据';

  @override
  String get welcomeHeadline => '开启您的\n智慧生活';

  @override
  String get welcomeSubtitle => '让生活更加舒适便捷';

  @override
  String get loginAction => '登录';

  @override
  String get registerAction => '注册';

  @override
  String get loginComingSoon => '登录页即将上线';

  @override
  String get registerComingSoon => '注册页即将上线';

  @override
  String get registerTitle => '注册';

  @override
  String get registerDescription => '请输入与您的账号关联的邮箱地址';

  @override
  String get registerEmailPlaceholder => '请输入邮箱地址';

  @override
  String get registerAgreementPrefix => '我已阅读并同意';

  @override
  String get sendCodeAction => '发送验证码';

  @override
  String get registerSendPending => '验证码功能暂未接入';

  @override
  String get registerCodeTitle => '输入验证码';

  @override
  String registerCodeDescription(String email) {
    return '我们已向 $email 发送确认验证码。请输入邮件中的验证码继续注册。';
  }

  @override
  String get registerCodeInputLabel => '验证码';

  @override
  String registerCodeResend(int seconds) {
    return '重新发送验证码（$seconds秒）';
  }

  @override
  String get registerCodeResendAction => '重新发送验证码';

  @override
  String get registerPasswordTitle => '密码';

  @override
  String get registerPasswordDescription => '设置您的密码';

  @override
  String get registerPasswordPlaceholder => '请输入密码';

  @override
  String get registerConfirmPasswordPlaceholder => '请再次输入密码';

  @override
  String get registerPasswordPending => '密码注册功能暂未接入';

  @override
  String get registerCodeResending => '正在发送验证码…';

  @override
  String get registerRequestFailed => '注册失败，请重试。';

  @override
  String get registerNetworkUnavailable => '网络不可用，请重试。';

  @override
  String get registerAuthorizationFailed => '注册暂不可用，请稍后再试。';

  @override
  String get registerRestartRequired => '注册会话已失效，请重新开始。';

  @override
  String get registerSucceeded => '注册成功，请登录。';

  @override
  String get forgotPasswordTitle => '忘记密码？';

  @override
  String get forgotPasswordDescription => '请输入与您的账号关联的邮箱地址';

  @override
  String get forgotPasswordSendPending => '重置密码验证码功能暂未接入';

  @override
  String get forgotPasswordCodeTitle => '输入验证码';

  @override
  String forgotPasswordCodeDescription(String email) {
    return '我们已向 $email 发送确认验证码。请输入邮件中的验证码重置密码。';
  }

  @override
  String get forgotPasswordResetTitle => '密码';

  @override
  String get forgotPasswordResetDescription => '设置您的密码';

  @override
  String get authPasswordRule =>
      'Password: 8-16 chars, 1 uppercase, lowercase & number';

  @override
  String get finishAction => '完成';

  @override
  String get forgotPasswordResetPending => '重置密码功能暂未接入';

  @override
  String get passwordResetRequestFailed => '密码重置失败，请重试。';

  @override
  String get passwordResetNetworkUnavailable => '网络不可用，请重试。';

  @override
  String get passwordResetAuthorizationFailed => '密码重置暂不可用，请稍后再试。';

  @override
  String get passwordResetRestartRequired => '密码重置会话已失效，请重新开始。';

  @override
  String get passwordResetResponseContractPending => '验证码校验成功，待确认响应协议后即可设置新密码。';

  @override
  String get passwordResetSucceededTitle => '重置成功';

  @override
  String get passwordResetSucceededDescription => '密码重置成功';

  @override
  String get backToLoginAction => '返回登录';

  @override
  String get loginTitle => '登录';

  @override
  String get loginAccountPlaceholder => '请输入邮箱地址';

  @override
  String get loginEmailInvalid => '请输入有效的邮箱地址';

  @override
  String get loginPasswordPlaceholder => '请输入密码';

  @override
  String get loginAgreementPrefix => '我已阅读并同意';

  @override
  String get loginAgreementMiddle => '和';

  @override
  String get userAgreementLabel => '用户协议';

  @override
  String get privacyPolicyLabel => '隐私政策';

  @override
  String get signInAction => '登录';

  @override
  String get forgotPasswordAction => '忘记密码';

  @override
  String get loginClearAccountAction => '清空账号';

  @override
  String get loginShowPasswordAction => '显示密码';

  @override
  String get loginHidePasswordAction => '隐藏密码';

  @override
  String get continueWithApple => '使用 Apple 继续登录';

  @override
  String get continueWithGoogle => '使用 Google 继续登录';

  @override
  String get continueWithFacebook => '使用 Facebook 继续登录';

  @override
  String get otherWaysToLogin => '其他登录方式';

  @override
  String get continueWithAlexa => '使用 Alexa 继续登录';

  @override
  String get loginSubmitPending => '登录功能暂未接入';

  @override
  String get loginFailed => '登录失败，请重试。';

  @override
  String get homeShortcutAction => '首页';

  @override
  String get homeGreeting => '您好';

  @override
  String get homeWelcome => '欢迎回来';

  @override
  String get homeMenuTooltip => '菜单';

  @override
  String get homeEditTooltip => '编辑家庭';

  @override
  String get homeAddDoorTooltip => '添加门';

  @override
  String get homeAddSceneMenuAction => '添加场景';

  @override
  String get homeAddDoorMenuAction => '添加门';

  @override
  String get homeSmartDeviceMenuAction => '智能设备';

  @override
  String homeDoorCount(int count) {
    return '$count 个门';
  }

  @override
  String get homeNoDoorsTitle => '暂无门';

  @override
  String get homeNoDoorsSubtitle => '请添加门';

  @override
  String get homeAddDoorAction => '门';

  @override
  String get homeLoadDoorsFailed => '无法加载门设备。';

  @override
  String get homeDoorStateLabel => '门状态';

  @override
  String get homeConnectionStateLabel => '连接状态';

  @override
  String get homeLifeRemainingLabel => '剩余寿命';

  @override
  String get homeDoorStateOpen => '已打开';

  @override
  String get homeDoorStateOpening => '打开中';

  @override
  String get homeDoorStateStopped => '已停止';

  @override
  String get homeDoorStateClosing => '关闭中';

  @override
  String get homeDoorStateClosed => '已关闭';

  @override
  String get homeDoorStateUnknown => '未知';

  @override
  String get homeDeviceEditingTitle => '设备编辑';

  @override
  String get homeDeviceEditTopAction => '置顶';

  @override
  String get homeDeviceEditShareAction => '分享';

  @override
  String get homeDeviceEditMoveSceneAction => '移动场景';

  @override
  String get homeDeviceEditNameAction => '名称';

  @override
  String get homeDeviceEditDeleteAction => '删除设备';

  @override
  String get homeDeviceEditCustomizeAction => '自定义';

  @override
  String get deviceShareTitle => '分享';

  @override
  String get deviceShareSubtitle => '与家人一起享受智能生活！';

  @override
  String get deviceSharePermissionsLabel => '权限';

  @override
  String get deviceShareAdministratorRole => '管理员';

  @override
  String get deviceShareGuestRole => '访客';

  @override
  String get deviceShareEmailLabel => '邮箱';

  @override
  String get deviceShareEmailPlaceholder => '邮箱/账号';

  @override
  String get deviceSharePeriodLabel => '分享期限';

  @override
  String get deviceShareNeverExpired => '永不过期';

  @override
  String get deviceShareTwoHours => '2 小时';

  @override
  String get deviceShareCustomize => '自定义';

  @override
  String get deviceShareTimeLabel => '时间';

  @override
  String get deviceShareSendEmailLabel => '发送邮件';

  @override
  String get deviceShareCapabilitiesTitle => '能力';

  @override
  String get deviceShareCapabilityDoorControl => '打开/停止/关闭';

  @override
  String get deviceShareCapabilityPartialOpen => '部分打开';

  @override
  String get deviceShareCapabilityLedDelay => 'LED 延时关闭';

  @override
  String get deviceShareCancelAction => '取消';

  @override
  String get deviceShareConfirmAction => '确认';

  @override
  String get accountProfileTitle => '账户资料';

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
  String get accountSharedDevices => '共享设备';

  @override
  String get accountReceivingDevices => '接收设备';

  @override
  String get accountManageDevices => '管理设备';

  @override
  String get accountMessage => '消息';

  @override
  String get accountRegion => '地区';

  @override
  String get accountLanguage => '语言';

  @override
  String get accountSystemPermissions => '系统权限';

  @override
  String get accountCheckForUpdates => '检查更新';

  @override
  String get accountAbout => '关于';

  @override
  String get accountDefaultRegion => 'England';

  @override
  String get accountDefaultLanguage => 'English';

  @override
  String accountMenuComingSoon(String item) {
    return '$item 即将上线';
  }

  @override
  String get deviceNameDialogTitle => '设备名称';

  @override
  String get deviceNameInputPlaceholder => '请输入设备名称';

  @override
  String get deviceDeleteConfirmMessage => '确定要删除该设备吗？';

  @override
  String get deviceDeleteCancelAction => '否';

  @override
  String get deviceDeleteConfirmAction => '是';

  @override
  String get deviceCustomizeTitle => '自定义';

  @override
  String get deviceCustomizeChangePictureAction => '更换图片';

  @override
  String get deviceCustomizeDefaultPictureAction => '默认图片';

  @override
  String get addNewDoorsTitle => '添加新门';

  @override
  String get addNewDoorsSubtitle => '选择要添加的门';

  @override
  String get addNewDoorsBackTooltip => '返回';

  @override
  String get addNewDoorsGarageDoor => '车库门';

  @override
  String get addNewDoorsRollerDoor => '卷帘门';

  @override
  String get addNewDoorsIndustrialDoor => '工业门';

  @override
  String get addNewDoorsSwingGate => '平开门';

  @override
  String get addNewDoorsSlidingGate => '平移门';

  @override
  String get addDoorNameDialogTitle => '门名称';

  @override
  String get addDoorNameInputPlaceholder => '请输入门名称';

  @override
  String get addDoorSceneDefault => '首页';

  @override
  String get addDoorNameCancelAction => '取消';

  @override
  String get addDoorNameConfirmAction => '确认';

  @override
  String get addDeviceTitle => '添加设备';

  @override
  String get addDeviceSubtitle => '选择要添加的设备';

  @override
  String get addDeviceFBoxSection => 'F-box';

  @override
  String get addDeviceSmartControllerSection => '智能控制器';

  @override
  String get addDeviceSmartAccessorySection => '智能配件';

  @override
  String get addDeviceFBox => 'F-box';

  @override
  String get addDeviceUsbWifiModule => 'USB WIFI 模块';

  @override
  String get addDeviceSmartOpener => '智能开门器';

  @override
  String get addDeviceSolarEnergySystem => '太阳能系统';

  @override
  String get addDeviceCamera => '摄像头';

  @override
  String get smartOpenerScanTitle => '扫描';

  @override
  String get smartOpenerScanDescription => '请使用手机扫描包装内的二维码。';

  @override
  String get smartOpenerScanAction => '扫描';

  @override
  String get smartOpenerScannerManualAction => '没有二维码？手动添加';

  @override
  String get smartOpenerScannerGalleryAction => '相册';

  @override
  String get smartOpenerScannerFlashlightAction => '手电筒';

  @override
  String get smartOpenerScannerBackTooltip => '返回';

  @override
  String get smartOpenerScannerBluetoothTooltip => '扫描蓝牙设备';

  @override
  String get smartOpenerScannerPermissionError => '需要相机权限才能扫描二维码。';

  @override
  String get smartOpenerScannerUnknownError => '无法启动扫码器。';

  @override
  String get smartOpenerScannerNoCodeFound => '所选图片中未识别到二维码。';

  @override
  String get smartOpenerScannerImageFailed => '无法读取所选图片。';

  @override
  String get smartOpenerScannerInvalidCode => '该二维码不是有效的 Smart Opener 设备码。';

  @override
  String get smartOpenerScannerDeviceNotFound => '未找到与该二维码匹配的设备，请重试。';

  @override
  String get smartOpenerScannerConnectionFailed => '无法连接设备，请重新扫码。';

  @override
  String get smartOpenerQrPayloadReceived => '已收到二维码内容，请继续连接设备。';

  @override
  String get smartOpenerBleScanningTitle => '扫描中';

  @override
  String get smartOpenerBleScanningDescription => '请确保在现场操作！';

  @override
  String get smartOpenerBleScanningStatus => '正在扫描设备，请稍候...';

  @override
  String get smartOpenerScanResultsTitle => '扫描结果';

  @override
  String smartOpenerScanResultsCount(int count) {
    return '发现 $count 台设备';
  }

  @override
  String get smartOpenerAddAction => '+ 添加';

  @override
  String get smartOpenerDefaultDeviceSubtitle => '默认编码门|54-89';

  @override
  String get smartOpenerDeviceNotFoundTitle => '未发现设备';

  @override
  String get smartOpenerDeviceNotFoundDescription =>
      '未检测到附近设备。请确认设备已成功重置后重新扫描！';

  @override
  String get smartOpenerRescanAction => '重新扫描';

  @override
  String get smartOpenerBackHomeAction => '返回首页';

  @override
  String get smartOpenerChooseWifiTitle => '选择 WIFI';

  @override
  String get smartOpenerChooseWifiDescription => '设备仅支持 2.4GHz Wi-Fi 连接';

  @override
  String get smartOpenerSelectWifiPlaceholder => '选择 Wi-Fi';

  @override
  String get smartOpenerWifiPasswordPlaceholder => '输入 Wi-Fi 密码';

  @override
  String get smartOpenerWifiPasswordHint =>
      'Wi-Fi 密码错误是失败最常见的原因之一。请仔细检查 Wi-Fi 密码';

  @override
  String get smartOpenerEnableBluetoothTip => '提交前请开启蓝牙';

  @override
  String get smartOpenerNextAction => '下一步';

  @override
  String get smartOpenerSkipAction => '跳过';

  @override
  String get smartOpenerSkipTip => '仅使用蓝牙模式操作，跳过 Wi-Fi 配网';

  @override
  String get smartOpenerSelectWifiTitle => '选择 Wi-Fi';

  @override
  String get smartOpenerConnectingTitle => '连接中';

  @override
  String get smartOpenerConnectingTip => '请尽量让手机靠近设备';

  @override
  String get smartOpenerConnectionFailedMessage =>
      'Connection failed. Please check Wi-Fi password and try again.';

  @override
  String get smartOpenerOkAction => 'OK';

  @override
  String get smartOpenerStopAdditionTitle => '停止添加设备';

  @override
  String get smartOpenerStopAdditionDescription =>
      '设备正在添加中。终止后再次添加前，需要重置 WIFI 模块。';

  @override
  String get smartOpenerCancelAction => '取消';

  @override
  String get smartOpenerConfirmAction => '确认';

  @override
  String get smartOpenerConnectionSuccessTitle => '连接成功';

  @override
  String get smartOpenerConnectionSuccessDescription => '配置设备信息';

  @override
  String get smartOpenerDeviceNamePlaceholder => '设备名称';

  @override
  String get smartOpenerSelectScenePlaceholder => '选择场景';

  @override
  String get smartOpenerInviteFamilyTip => '邀请家人使用';

  @override
  String get smartOpenerShareAction => '去分享';

  @override
  String get smartOpenerTryAction => '试一下';

  @override
  String get smartOpenerShareDialogTitle => '分享设备';

  @override
  String get smartOpenerShareDialogDescription => '与家人一起享受智能生活！';

  @override
  String get smartOpenerShareDialogAccountHint => '邮箱/Amazon 账号/Google 账号';

  @override
  String get smartOpenerDisconnectFailedMessage => '设备断开失败，仍将继续扫描。';

  @override
  String get chooseSceneTitle => '选择场景';

  @override
  String get chooseSceneBackTooltip => '返回';

  @override
  String get chooseSceneEditTooltip => '编辑场景';

  @override
  String chooseSceneDeviceCount(int count) {
    return '$count 台设备';
  }

  @override
  String get chooseSceneNewSceneAction => '新建场景';

  @override
  String get sceneHomeShortcutTooltip => '场景';

  @override
  String get sceneTitle => '场景';

  @override
  String get sceneEditingTitle => '编辑场景';

  @override
  String sceneCount(int count) {
    return '$count 个场景';
  }

  @override
  String get sceneBackTooltip => '返回';

  @override
  String get sceneEditTooltip => '编辑场景';

  @override
  String get sceneDoneEditingTooltip => '完成编辑';

  @override
  String sceneDeviceCount(int count) {
    return '$count 台设备';
  }

  @override
  String get sceneNewSceneAction => '新建场景';

  @override
  String get sceneNameDialogTitle => '场景名称';

  @override
  String get sceneNameInputPlaceholder => '请输入场景名称';

  @override
  String get sceneNameCancelAction => '取消';

  @override
  String get sceneNameConfirmAction => '确认';

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
  String get deviceSettingsTitle => '设置';

  @override
  String get deviceSettingsForUsers => '用户设置';

  @override
  String get deviceSettingsForInstallers => '安装人员设置';

  @override
  String get deviceSettingsTransmitterManagement => '遥控器管理';

  @override
  String get deviceSettingsLedOffDelay => 'LED 熄灭延时';

  @override
  String get deviceSettingsPartialOpen => '部分开启';

  @override
  String get deviceSettingsPartialOpenHeight => '部分开启高度';

  @override
  String get deviceSettingsAutoClose => '自动关闭';

  @override
  String get deviceSettingsOpeningSpeed => '开启速度';

  @override
  String get deviceSettingsOpeningSpeedValue => 'GMT+8:00';

  @override
  String get deviceSettingsAboutDevice => '关于设备';

  @override
  String get deviceSettingsDoorOpenReminder => '开门提醒';

  @override
  String get deviceSettingsForceMargin => '力矩余量';

  @override
  String get deviceSettingsBluetoothName => '蓝牙名称';

  @override
  String get deviceSettingsFirmwareVersion => '固件版本';

  @override
  String get deviceSettingsHardwareVersion => '硬件版本';

  @override
  String get deviceSettingsCheckVersion => '检查版本';

  @override
  String get deviceSettingsTransmitterLearning => '遥控器学习';

  @override
  String get deviceSettingsManagement => '管理';

  @override
  String get deviceSettingsAutoClosingSetting => '自动关闭设置';

  @override
  String get deviceSettingsAutoCloseCaption => '当前设置：120 秒（电机设置）\n自动关闭位置';

  @override
  String get deviceSettingsAutoCloseTime => '自动关闭时间';

  @override
  String get deviceSettingsUpLimit => '上限位置';

  @override
  String get deviceSettingsAnyPosition => '任意位置';

  @override
  String get deviceSettingsCancelAction => '取消';

  @override
  String get deviceSettingsConfirmAction => '确认';

  @override
  String get transmitterManagementTipsTitle => '提示';

  @override
  String get transmitterManagementSafetyTip => '1. 为确保安全，建议通过 App 管理所有遥控器。';

  @override
  String get transmitterManagementHowToTip => '2. 如何管理遥控器？\n请通过 App 重新学习遥控器。';

  @override
  String get transmitterManagementEditAction => '编辑遥控器';

  @override
  String get transmitterManagementDeleteAction => '删除遥控器';

  @override
  String get transmitterManagementAddAction => '添加遥控器';

  @override
  String get transmitterManagementInfoTitle => '遥控器信息';

  @override
  String get transmitterManagementNameHint => '输入遥控器名称';

  @override
  String get transmitterManagementDeletePromptTitle => '提示';

  @override
  String get transmitterManagementDeletePromptMessage => '请确认是否删除该遥控器';

  @override
  String deviceSettingsMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String deviceSettingsSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String deviceSettingsOpeningSpeedCurrent(int value) {
    return '当前设置：$value%（电机设置）';
  }

  @override
  String get deviceSettingsForceMarginWarning15Days =>
      '1. 当弹簧松动或轨道堵塞导致无法操作门时，可暂时使用此功能。\n\n2. 此功能仅在 15 天内有效，请尽快联系维修人员。';

  @override
  String get deviceSettingsForceMarginWarning3Days => '此临时设置仅在三天内有效，请尽快联系维修人员。';

  @override
  String get deviceSettingsForceMarginWarning3DaysFull =>
      '1. 当弹簧松动或轨道堵塞导致无法操作门时，可暂时使用此功能。\n\n2. 此功能仅在三天内有效，请尽快联系维修人员。';

  @override
  String get deviceSettingsForceMarginTemporaryCurrent => '当前设置：标准（电机设置）';

  @override
  String deviceSettingsForceMarginLevel(int level) {
    return '等级 $level';
  }

  @override
  String deviceSettingsForceMarginLevelCurrent(int level) {
    return '当前设置：等级 $level（电机设置）';
  }

  @override
  String get transmitterLearningTitle => '遥控器学习';

  @override
  String get transmitterLearningOnSiteTip => '请务必在现场操作！';

  @override
  String get transmitterLearningKeepBluetoothOn => '保持蓝牙开启';

  @override
  String get transmitterLearningReadyDescription =>
      '1. 请确保手机与开门机之间的距离小于 5 米。\n\n2. 若 20 秒内没有操作，学习将自动结束。';

  @override
  String get transmitterLearningInProgress => '学习中…';

  @override
  String get transmitterLearningInProgressDescription => '请连续按同一个按键至少 3 次。';

  @override
  String get transmitterLearningFailed => '遥控器学习失败';

  @override
  String get transmitterLearningSucceeded => '遥控器学习成功';

  @override
  String get transmitterLearningRemoteInstruction => '请使用遥控器进行尝试';

  @override
  String get transmitterLearningStartAction => '开始学习';

  @override
  String get transmitterLearningRestartAction => '重新开始';

  @override
  String get transmitterLearningCompleteAction => '完成';

  @override
  String get hardwareDiagnosticsTitle => '硬件诊断';

  @override
  String get hardwareDiagnosticsDetailedLogging => '详细硬件诊断日志';

  @override
  String get hardwareDiagnosticsWarning =>
      '开启后会在系统控制台输出蓝牙原始帧和解密后的协议数据，便于现场排查。AES Key、Token、Wi-Fi 密码等敏感信息始终不会记录。';

  @override
  String get hardwareDiagnosticsUpdateFailed => '诊断日志设置更新失败，请重试。';

  @override
  String get securityCenterTitle => '安全中心';

  @override
  String get securityCenterProtecting => '保护中…';

  @override
  String get securityCenterDownloadFullReport => '下载完整报告';

  @override
  String get securityCenterGeneralEvaluation => '常规评估';

  @override
  String get securityCenterDoorOperationStatus => '门体运行状态';

  @override
  String get securityCenterDoorOperationRecord => '门体运行记录';

  @override
  String get securityCenterSafetySensorsEvaluation => '安全传感器评估';

  @override
  String get securityCenterWirelessPhotoBeam => '无线光电';

  @override
  String get securityCenterWirelessELock => '无线电锁';

  @override
  String get securityCenterWirelessSensors => '无线传感器';

  @override
  String get securityCenterWiredSensors => '有线传感器';

  @override
  String get securityCenterPhotoBeam => '光电';

  @override
  String get securityCenterELock => '电锁';

  @override
  String get securityCenterDoorSensor => '门磁';

  @override
  String get securityCenterRadar => '雷达';

  @override
  String get securityCenterRemote => '遥控器';

  @override
  String get securityCenterSafetyEdge => '安全边';

  @override
  String get securityCenterWiredPhotoBeam => '有线光电';

  @override
  String get securityCenterWiredELock => '有线电锁';

  @override
  String get securityReportTitle => '安全报告';

  @override
  String get securityReportMotorName => '车库门电机 01';

  @override
  String get securityReportSerialNumber => '序列号：SFD123456789';

  @override
  String get securityReportDoorName => '车库门 01';

  @override
  String get securityReportOperatedCycles => '已运行次数';

  @override
  String get securityReportRemainingCycles => '剩余次数';

  @override
  String get securityReportMaintenanceWarning => '请尽快维护车库门。';

  @override
  String get securityReportBalanceEvaluation => '车库门平衡评估';

  @override
  String get securityReportBalanceNote => '提示：评估仅基于车库门最近一次开/关门操作。';

  @override
  String get securityReportOpenEvaluation => '开门评估';

  @override
  String get securityReportCloseEvaluation => '关门评估';

  @override
  String get securityReportOverload => '过载';

  @override
  String get securityReportOperationRecord => '车库门运行记录';

  @override
  String get securityReportLast24Hours => '最近 24 小时';

  @override
  String get securityReportLast7Days => '最近 7 天';

  @override
  String get securityReportTimeCyclesAxis => 'X：时间  Y：运行次数';

  @override
  String get securityReportDateCyclesAxis => 'X：日期  Y：运行次数';

  @override
  String get securityReportFrequentOperationWarning => '周一操作频率异常，请检查。';

  @override
  String get securityReportMotorFunctionStatus => '电机功能状态';

  @override
  String get securityReportWiredSensorsDiagnosis => '有线传感器诊断';

  @override
  String get securityReportWirelessSensorsDiagnosis => '无线传感器诊断';

  @override
  String get securityReportNormal => '正常';

  @override
  String get securityReportDisconnect => '断开';

  @override
  String get safetySensorTriggered => '已触发';

  @override
  String get safetySensorReplaceBattery => '如何更换电池';

  @override
  String get safetySensorLowBatterySolution => '低电量解决方案';

  @override
  String get safetySensorLowBatteryWarning => '低电量';

  @override
  String safetySensorBatteryModel(String model) {
    return '电池型号：$model';
  }

  @override
  String get safetySensorBatteryModelLabel => '电池型号：';

  @override
  String safetySensorRatedVoltage(String voltage) {
    return '额定电压：$voltage';
  }

  @override
  String get safetySensorRatedVoltageLabel => '额定电压：';

  @override
  String get safetySensorLowBatteryInstruction =>
      '*电量不足，请及时更换电池。错误的电池型号可能导致设备无法正常工作。';

  @override
  String get safetySensorImagePlaceholder => '图片占位图';

  @override
  String get safetySensorDefaultName => '安全传感器';

  @override
  String get securityReportAbnormal => '异常';

  @override
  String get securityReportNotTriggered => '未触发';

  @override
  String get securityReportLocked => '已锁定';

  @override
  String get securityReportBatteryEnough => '电池电量充足';

  @override
  String get securityReportWirelessWicketDoor => '无线小门传感器';

  @override
  String get securityReportWirelessSafetyEdge => '无线安全边';

  @override
  String get securityReportWirelessPositionSensor => '无线位置传感器';

  @override
  String get securityReportSafetySuggestion => '安全建议：';

  @override
  String get securityReportSuggestionCycles => '运行次数已达到维护预警值；';

  @override
  String get securityReportSuggestionBattery => '安全边电池电量低，请及时更换；';

  @override
  String get securityReportSuggestionMaintenance => '请联系安装人员进行必要维护，确保车库门安全。';

  @override
  String get securityReportSuggestionCurrent => '开门机开门电流超过了设定的最大值。';

  @override
  String get securityReportSaveSuccess => '报告已保存至相册。';

  @override
  String get securityReportSaveAccessDenied => '保存报告需要照片库权限。';

  @override
  String get securityReportSaveNoSpace => '没有足够的存储空间保存报告。';

  @override
  String get securityReportSaveUnsupported => '无法保存该图像格式。';

  @override
  String get securityReportSaveFailed => '无法保存报告图片。';

  @override
  String get securityReportCaptureFailed => '无法生成报告图片。';

  @override
  String get securityReportDoorOpeningForce => '开门力度';

  @override
  String get securityReportDoorClosingForce => '关门力度';

  @override
  String get securityReportAutoCloseTime => '自动关门时间';

  @override
  String get securityReportAutoCloseCondition => '自动关门条件';

  @override
  String get securityReportLedOffDelay => 'LED 熄灭延迟';

  @override
  String get securityReportPartialOpen => '部分开启';

  @override
  String get securityReportIgnoreObstructionHeight => '忽略障碍物高度';

  @override
  String get securityReportPhotoBeamFunction => '光电功能';

  @override
  String get securityReportCommunityMode => '社区模式';

  @override
  String get securityReportLevel1 => '等级 1';

  @override
  String get securityReportAnyPosition => '任意位置';

  @override
  String get securityReportOn => '开启';
}
