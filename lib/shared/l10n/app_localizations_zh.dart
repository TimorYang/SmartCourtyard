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
  String get registerPasswordPlaceholder => '请输入 8 位数字密码';

  @override
  String get registerConfirmPasswordPlaceholder => '请再次输入 8 位数字密码';

  @override
  String get registerPasswordPending => '密码注册功能暂未接入';

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
  String get finishAction => '完成';

  @override
  String get forgotPasswordResetPending => '重置密码功能暂未接入';

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
  String get continueWithApple => '使用 Apple 继续登录';

  @override
  String get continueWithGoogle => '使用 Google 继续登录';

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
}
