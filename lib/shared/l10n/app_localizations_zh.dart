// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get networkErrorUnavailable => '网络不可用，请检查网络连接后重试。';

  @override
  String get networkErrorSessionExpired => '登录状态已失效，请重新登录。';

  @override
  String get networkErrorAccessDenied => '你没有权限执行此操作。';

  @override
  String get networkErrorRequestTimeout => '请求超时，请重试。';

  @override
  String get networkErrorRateLimited => '请求过于频繁，请稍后重试。';

  @override
  String get networkErrorRequestFailed => '请求未完成，请重试。';

  @override
  String get networkErrorServiceUnavailable => '服务暂时不可用，请稍后重试。';

  @override
  String get appTitle => 'FLINX';

  @override
  String get operationRecordTitle => '操作记录';

  @override
  String get operationRecordLast14DaysDescription => '最近 14 天的操作数据';

  @override
  String get operationRecordLoadFailed => '操作记录加载失败，点击重试。';

  @override
  String get operationRecordLoadMoreFailed => '更多操作记录加载失败，点击重试。';

  @override
  String get operationRecordNoMore => '没有更多操作记录了';

  @override
  String get operationRecordEmpty => '暂无操作记录';

  @override
  String get operationRecordUnknownOperator => '未知操作人';

  @override
  String get operationRecordUnknownTime => '未知时间';

  @override
  String get operationRecordUnknownDoor => '未知门';

  @override
  String get operationRecordActionOpen => '开门';

  @override
  String get operationRecordActionClose => '关门';

  @override
  String get operationRecordActionStop => '停止';

  @override
  String get operationRecordActionAutoCloseToggle => '切换自动关门';

  @override
  String get operationRecordActionLedOn => '开灯';

  @override
  String get operationRecordActionLedOff => '关灯';

  @override
  String get operationRecordActionLedOffDelayChanged => '修改延迟关灯';

  @override
  String get operationRecordActionPartialOpenChanged => '修改部分开门';

  @override
  String get operationRecordActionAutoCloseDelayChanged => '修改自动关门延迟';

  @override
  String get operationRecordActionDoorOpenReminderToggle => '切换开门提醒';

  @override
  String get operationRecordActionDoorOpenReminderDelayChanged => '修改开门提醒延迟';

  @override
  String get operationRecordActionUnknown => '未知操作';

  @override
  String get refreshControlPullToRefresh => '下拉刷新';

  @override
  String get refreshControlReleaseToRefresh => '松开刷新';

  @override
  String get refreshControlRefreshing => '正在刷新...';

  @override
  String get refreshControlRefreshSucceeded => '刷新成功';

  @override
  String get refreshControlRefreshFailed => '刷新失败';

  @override
  String get refreshControlPullToLoad => '上拉加载更多';

  @override
  String get refreshControlReleaseToLoad => '松开加载更多';

  @override
  String get refreshControlLoading => '正在加载...';

  @override
  String get refreshControlLoadSucceeded => '加载成功';

  @override
  String get refreshControlLoadFailed => '加载失败';

  @override
  String get refreshControlNoMoreData => '没有更多数据了';

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
  String get registerPasswordRule => '须包含至少一个小写字母、一个大写字母和一个数字，长度为 8 至 16 个字符。';

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
  String get authPasswordRule => '密码：8 至 16 个字符，须包含大写字母、小写字母和数字';

  @override
  String get authPasswordInvalid => '密码需为 8 至 16 个字符，且至少包含一个大写字母、一个小写字母和一个数字。';

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
  String get appleLoginAgreementRequired => '请先同意用户协议和隐私政策。';

  @override
  String get appleLoginUnavailable => '当前设备无法使用 Apple 登录。';

  @override
  String get appleLoginFailed => 'Apple 登录失败，请重试。';

  @override
  String get googleLoginAgreementRequired => '请先同意用户协议和隐私政策。';

  @override
  String get googleLoginUnavailable => '当前设备无法使用 Google 登录，或 Google 登录尚未配置。';

  @override
  String get googleLoginFailed => 'Google 登录失败，请重试。';

  @override
  String get facebookLoginAgreementRequired => '请先同意用户协议和隐私政策。';

  @override
  String get facebookLoginUnavailable =>
      '当前设备无法使用 Facebook 登录，或 Facebook 登录尚未配置。';

  @override
  String get facebookLoginFailed => 'Facebook 登录失败，请重试。';

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
  String get homeNoDeviceMessage => '没有设备';

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
  String get deviceShareEmailLabel => '地址';

  @override
  String get deviceShareEmailPlaceholder => '邮箱/账号';

  @override
  String get deviceShareAddressInvalid => '请输入有效的邮箱地址';

  @override
  String get deviceSharePeriodLabel => '访问截止';

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
  String get deviceShareCapabilityPartialOpenLevel => '部分开门档位';

  @override
  String get deviceShareCapabilityLedControl => 'LED 控制';

  @override
  String get deviceShareCapabilityLedDelay => 'LED 延时关闭';

  @override
  String get deviceShareCapabilityAutoClose => '自动关闭';

  @override
  String get deviceShareCapabilityTransmitterPairing => '遥控器配对';

  @override
  String get deviceShareCapabilityDoorOpenReminder => '开门提醒';

  @override
  String get deviceShareCapabilityDoorOpenForce => '开门力度';

  @override
  String get deviceShareCapabilityDoorOpenSpeed => '开门速度';

  @override
  String get deviceShareCancelAction => '取消';

  @override
  String get deviceShareConfirmAction => '确认';

  @override
  String get deviceShareDoorUnavailable => '当前门不可分享。';

  @override
  String get deviceShareCapabilitiesLoadFailed => '无法加载可分享能力，点击重试。';

  @override
  String get deviceShareSubmitFailed => '创建分享失败，请重试。';

  @override
  String get accountProfileTitle => '账户资料';

  @override
  String get accountDetailsTitle => '账户';

  @override
  String get accountDetailsHeadPortrait => '头像';

  @override
  String get accountDetailsAccountNumber => '账号';

  @override
  String get accountDetailsFullName => '姓名';

  @override
  String get accountDetailsMailbox => '邮箱';

  @override
  String get accountDetailsChangePassword => '修改密码';

  @override
  String get accountDetailsForgotPassword => '忘记密码';

  @override
  String get accountDetailsCancelAccount => '注销账号';

  @override
  String get accountDetailsDeletionPrompt => '确定要注销账号吗？';

  @override
  String get accountDetailsDeletionNoAction => '否';

  @override
  String get accountDetailsDeletionYesAction => '是';

  @override
  String get accountDetailsDeletionSubmitting => '注销中...';

  @override
  String get accountDetailsDeletionFailed => '注销账号失败，请重试。';

  @override
  String get accountDetailsLogout => '退出登录';

  @override
  String get accountDetailsFallbackNumber => '34345435@qq.com';

  @override
  String get accountDetailsFallbackFullName => 'James';

  @override
  String get accountDetailsFallbackMailbox => '123456@qq.com';

  @override
  String get accountDetailsPhotoAlbumAction => '相册';

  @override
  String get accountDetailsPhotographAction => '拍照';

  @override
  String get accountDetailsCameraPermissionDeniedTitle => '需要相机权限';

  @override
  String get accountDetailsCameraPermissionDeniedMessage =>
      '相机权限已关闭，请前往系统设置开启。';

  @override
  String get accountDetailsCameraPermissionSettingsAction => '去设置';

  @override
  String get accountDetailsCancelAction => '取消';

  @override
  String get accountDetailsConfirmAction => '确认';

  @override
  String get accountDetailsRenameTitle => '修改名称';

  @override
  String get accountDetailsNameInputPlaceholder => 'JAMES';

  @override
  String get accountDetailsChangePasswordTitle => '修改密码';

  @override
  String get accountDetailsNewPasswordPlaceholder => '请输入新密码';

  @override
  String get accountDetailsShowPasswordAction => '显示密码';

  @override
  String get accountDetailsHidePasswordAction => '隐藏密码';

  @override
  String accountDetailsAvatarOptionLabel(int index) {
    return '头像选项 $index';
  }

  @override
  String get accountFallbackEmail => '739059568@qq.com';

  @override
  String get accountOverviewRefreshFailed => '账号概览刷新失败，请重试。';

  @override
  String get accountOverviewRefreshTimeUnavailable => '暂无刷新时间';

  @override
  String get accountSharedDevices => '共享设备';

  @override
  String get sharedDevicesTitle => '共享设备';

  @override
  String sharedDevicesShareToPeople(int count) {
    return '分享给 $count 人';
  }

  @override
  String get sharedDevicesAddLabel => '添加共享设备';

  @override
  String get sharedDevicesEmpty => '暂无共享设备';

  @override
  String get sharedDevicesLoadFailed => '共享设备加载失败';

  @override
  String get sharedDevicesRetry => '重试';

  @override
  String get sharedDeviceMemberAdministrator => '管理员';

  @override
  String get sharedDeviceMemberGuest => '访客';

  @override
  String get sharedDeviceMemberAccepted => '已接受';

  @override
  String get sharedDeviceMemberEditLabel => '编辑共享设备成员';

  @override
  String get sharedDeviceMemberDeleteLabel => '删除共享设备成员';

  @override
  String get sharedDeviceMemberAvatarPlaceholderLabel => '共享设备成员头像';

  @override
  String get accountReceivingDevices => '接收设备';

  @override
  String get receivingDevicesTitle => '接收设备';

  @override
  String get receivingDevicesEditingTitle => '编辑接收设备';

  @override
  String receivingDevicesOwnerEmail(String ownerEmail) {
    return '共享用户名:$ownerEmail';
  }

  @override
  String get receivingDevicesEmpty => '暂无接收设备';

  @override
  String get receivingDevicesLoadFailed => '接收设备加载失败';

  @override
  String get receivingDevicesRetry => '重试';

  @override
  String get receivingDevicesEditLabel => '编辑接收设备';

  @override
  String get receivingDevicesDoneEditingLabel => '完成编辑';

  @override
  String get receivingDevicesDeleteLabel => '删除接收设备';

  @override
  String get receivingDevicesDeleteFailed => '删除接收设备失败，请重试。';

  @override
  String get accountManageDevices => '管理设备';

  @override
  String get manageDevicesTitle => '管理设备';

  @override
  String get manageDevicesSubtitle => '已登录的设备';

  @override
  String get manageDevicesEmpty => '暂无已登录设备。';

  @override
  String get manageDevicesLoadFailed => '无法加载已登录设备。';

  @override
  String get manageDevicesRetry => '重试';

  @override
  String get manageDevicesIosName => 'iOS 设备';

  @override
  String get manageDevicesAndroidName => 'Android 设备';

  @override
  String get manageDevicesUnknownDevice => '未知设备';

  @override
  String get manageDevicesUnknownLoginTime => '未知登录时间';

  @override
  String get manageDevicesRemoveFailed => '无法移除此设备，请重试。';

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
  String get manageDevicesEditLabel => '编辑已登录设备';

  @override
  String get manageDevicesLogoutLabel => '退出设备登录';

  @override
  String get manageDevicesRemoveConfirmationMessage => '确定要移除此设备吗？';

  @override
  String get manageDevicesRemoveCancelAction => '取消';

  @override
  String get manageDevicesRemoveConfirmAction => '确认';

  @override
  String get accountMessage => '消息';

  @override
  String get accountRegion => '地区';

  @override
  String get accountLanguage => '语言';

  @override
  String get accountSystemPermissions => '系统权限';

  @override
  String get systemPermissionsPageTitle => '系统权限';

  @override
  String get systemPermissionsLocation => '访问地理位置';

  @override
  String get systemPermissionsCamera => '访问相机权限';

  @override
  String get systemPermissionsMicrophone => '访问录音权限';

  @override
  String get systemPermissionsStorage => '访问手机存储';

  @override
  String get systemPermissionsBluetooth => '访问手机蓝牙';

  @override
  String get systemPermissionsGranted => '已授权';

  @override
  String get systemPermissionsDenied => '未授权';

  @override
  String get systemPermissionsLoadError => '无法读取系统权限。';

  @override
  String get systemPermissionsRequestError => '无法申请此权限。';

  @override
  String get accountAfterSalesService => '售后服务';

  @override
  String get accountManualGuide => '使用手册与指南';

  @override
  String get accountCheckForUpdates => '检查更新';

  @override
  String get accountAbout => '关于';

  @override
  String get upgradeCheckTitle => '检查升级版本';

  @override
  String get upgradeCheckAppSection => '应用';

  @override
  String get upgradeCheckAppUpdateName => '应用版本更新';

  @override
  String get upgradeCheckFirmwareSection => '固件';

  @override
  String get upgradeCheckStartAction => '开始升级';

  @override
  String get upgradeCheckUpgrading => '正在升级';

  @override
  String get upgradeCheckCompleted => '已完成';

  @override
  String upgradeCheckDoorDeviceName(String name) {
    return '门设备名称：$name';
  }

  @override
  String upgradeCheckSerialNumber(String number) {
    return '序列号：$number';
  }

  @override
  String upgradeCheckCurrentVersion(String version) {
    return '当前版本：$version';
  }

  @override
  String upgradeCheckAvailableVersion(String version) {
    return '可用版本：$version';
  }

  @override
  String upgradeCheckScheduledFor(String dateTime) {
    return '预约时间：$dateTime';
  }

  @override
  String upgradeCheckExpandDoor(String name) {
    return '展开$name';
  }

  @override
  String upgradeCheckCollapseDoor(String name) {
    return '收起$name';
  }

  @override
  String get upgradeCheckSelectionLimit => '每次最多选择 10 个升级项目。';

  @override
  String get upgradeCheckPartialNotAccepted => '部分升级任务未受理。';

  @override
  String get upgradeCheckSubmitFailed => '无法提交升级任务，请重试。';

  @override
  String get upgradeCheckOpenStoreFailed => '无法打开应用商店。';

  @override
  String get upgradeCheckSubmitting => '提交中';

  @override
  String upgradeCheckSizeBytes(String value) {
    return '$value B';
  }

  @override
  String upgradeCheckSizeKilobytes(String value) {
    return '$value KB';
  }

  @override
  String upgradeCheckSizeMegabytes(String value) {
    return '$value MB';
  }

  @override
  String get upgradeCheckSelectTimeTitle => '选择升级时间';

  @override
  String get upgradeCheckStatus => '状态';

  @override
  String get upgradeCheckUpgradeTime => '升级时间';

  @override
  String get upgradeCheckImmediate => '立即升级';

  @override
  String get upgradeCheckPostpone => '延后';

  @override
  String get upgradeCheckDateAndTime => '日期和时间';

  @override
  String get upgradeCheckSchedulePastError => '请选择未来的时间。';

  @override
  String get upgradeCheckCancelAction => '取消';

  @override
  String get upgradeCheckConfirmAction => '确认';

  @override
  String get upgradeCheckOnline => '在线';

  @override
  String get upgradeCheckOffline => '离线';

  @override
  String upgradeCheckProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get accountDefaultRegion => '英国';

  @override
  String get accountDefaultLanguage => '英语';

  @override
  String get accountLanguageDialogTitle => '语言';

  @override
  String get accountLanguageOptionEnglish => '英语';

  @override
  String get accountLanguageOptionSimplifiedChinese => '中文(简体)';

  @override
  String get accountLanguageOptionArgentineSpanish => '阿根廷西班牙语';

  @override
  String get accountLanguageOptionItalian => '意大利语';

  @override
  String get accountLanguageOptionEuropeanPortuguese => '葡萄牙语（葡萄牙）';

  @override
  String get accountLanguageOptionCzech => '捷克语';

  @override
  String get accountLanguageOptionDutch => '荷兰语';

  @override
  String get accountLanguageOptionFrench => '法语';

  @override
  String get accountLanguageOptionGerman => '德语';

  @override
  String get accountLanguageOptionPolish => '波兰语';

  @override
  String get accountLanguageOptionUkrainian => '乌克兰语';

  @override
  String get accountLanguageOptionRussian => '俄语';

  @override
  String get accountLanguageOptionNorwegian => '挪威语';

  @override
  String get accountLanguageOptionHungarian => '匈牙利语';

  @override
  String get accountLanguageOptionTraditionalChinese => '中文(繁体)';

  @override
  String get accountLanguageCancelAction => '取消';

  @override
  String get accountLanguageConfirmAction => '确认';

  @override
  String get accountLanguageOptionsLoading => '正在加载可选语言…';

  @override
  String get accountLanguageOptionsLoadFailed => '无法加载可选语言。';

  @override
  String get accountLanguageOptionsRetryAction => '重试';

  @override
  String get accountLanguageSaveFailed => '无法更新语言。';

  @override
  String get regionOptionsRetryAction => '重试';

  @override
  String get regionOptionsSaveFailed => '无法更新地区。';

  @override
  String get regionPageTitle => '地区';

  @override
  String get regionChina => '中国';

  @override
  String get regionAmerica => '美国';

  @override
  String get regionEngland => '英国';

  @override
  String get regionFrance => '法兰西共和国';

  @override
  String get regionCanada => '加拿大';

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
  String get deviceCustomizeChangePictureFailed => '更换图片失败，请重试。';

  @override
  String get deviceCustomizeResetPictureFailed => '恢复默认图片失败，请重试。';

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
  String get addDoorSceneSelectPlaceholder => '选择场景';

  @override
  String get addDoorSceneLoading => '正在加载场景…';

  @override
  String get addDoorSceneEmpty => '暂无可用场景';

  @override
  String get addDoorSceneLoadFailed => '场景加载失败，点击重试。';

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
  String get fBoxConnectionGuideTitle => '连接';

  @override
  String get fBoxConnectionGuideInstructions =>
      '1. 将电源连接至开门机，确认 Wi-Fi 指示灯闪烁或常亮。\n2. 确认其他相关配件已与 F-box 配对。';

  @override
  String get fBoxConnectionGuideManualHint => '*连接步骤请参考说明书';

  @override
  String get fBoxConnectionGuideNextAction => '下一步';

  @override
  String get fBoxWiringTestAddTooltip => '添加';

  @override
  String get fBoxWiringTestTitle => '测试';

  @override
  String get fBoxWiringTestDescription =>
      '点击下方按钮；若门体正常运行，请点击“下一步”。\n如未正常运行，请切换“O/S/C 接线”后再次测试。';

  @override
  String get fBoxWiringTestPbWiring => 'PB 接线';

  @override
  String get fBoxWiringTestOscWiring => 'O/S/C 接线';

  @override
  String get fBoxWiringTestDoorOperatesNormally => '门体正常运行';

  @override
  String get fBoxWiringTestPbAction => '测试 PB 接线';

  @override
  String get fBoxWiringTestOpenAction => '开门';

  @override
  String get fBoxWiringTestStopAction => '停止';

  @override
  String get fBoxWiringTestCloseAction => '关门';

  @override
  String get fBoxWiringTestCommandRejected => '命令未被接受，请重试。';

  @override
  String get fBoxWiringTestCommandFailed => '测试失败，请检查连接后重试。';

  @override
  String get addDeviceUsbWifiModule => 'USB WIFI 模块';

  @override
  String get usbDongleGuideTitle => 'USB Dongle 安装';

  @override
  String get usbDongleGuideDescription => '请根据所选门型查看对应的安装指引。';

  @override
  String get usbDongleGuideInsertTitle => '1. 插入 USB WIFI 模块';

  @override
  String get usbDongleGuideInsertDescription => '找到对应的 USB 接口并插入 WIFI 模块。';

  @override
  String get usbDongleGuideIndicatorTitle => '2. 观察指示灯状态';

  @override
  String get usbDongleGuideIndicatorDescription =>
      '2.1 如果 USB 指示灯熄灭或闪烁，可直接搜索设备。';

  @override
  String get usbDongleGuideSearchDeviceAction => '搜索设备';

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
  String get smartOpenerScannerPermissionDialogTitle => '需要相机权限';

  @override
  String get smartOpenerScannerPermissionDialogMessage =>
      '相机权限已关闭，请前往系统设置开启；你也可以继续使用相册或蓝牙扫描。';

  @override
  String get smartOpenerScannerPermissionSettingsAction => '去设置';

  @override
  String get smartOpenerScannerPermissionSettingsFailed => '无法打开系统设置，请重试。';

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
  String get smartOpenerAddedDevicesTitle => '已添加';

  @override
  String get smartOpenerAddedDevicesDescription => '以下设备已连接';

  @override
  String get smartOpenerAddedDeviceName => '智能开门器';

  @override
  String get smartOpenerAddedDeviceIdentifier => 'opener_B8F86211A9DC';

  @override
  String get smartOpenerAddedAddTooltip => '添加设备';

  @override
  String get smartOpenerAddedDeleteTooltip => '移除设备';

  @override
  String get smartOpenerAddedDisconnectConfirmMessage => '确定要断开此设备吗？';

  @override
  String get smartOpenerAddedUnbindFailedMessage => '移除设备失败，请重试。';

  @override
  String get smartOpenerAddedLoading => '正在加载设备…';

  @override
  String get smartOpenerAddedEmptyTitle => '暂无已连接设备';

  @override
  String get smartOpenerAddedEmptyDescription => '已连接的设备将显示在这里。';

  @override
  String get smartOpenerAddedLoadFailed => '无法加载已连接设备。';

  @override
  String get smartOpenerAddedRetryAction => '重试';

  @override
  String get smartOpenerAddedNoMore => '没有更多设备了';

  @override
  String get deviceCommandMoreTooltip => '更多';

  @override
  String get deviceCommandLoading => '正在加载设备控制…';

  @override
  String get deviceCommandLoadFailed => '无法加载设备控制，请重试。';

  @override
  String get deviceCommandRetry => '重试';

  @override
  String get deviceCommandDoorStateRunning => '运行中';

  @override
  String deviceCommandDoorStateWithPercent(String state, int percent) {
    return '$state · $percent%';
  }

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
  String get smartOpenerRefreshWifiTooltip => '刷新 Wi-Fi 列表';

  @override
  String get smartOpenerConnectingTitle => '连接中';

  @override
  String get smartOpenerConnectingTip => '请尽量让手机靠近设备';

  @override
  String get smartOpenerConnectionFailedMessage => '连接失败。请检查 Wi-Fi 密码后重试。';

  @override
  String get smartOpenerOkAction => '确定';

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
  String get smartOpenerShareNowAction => '立即分享';

  @override
  String get smartOpenerConnectionSuccessTitle => '连接成功';

  @override
  String get smartOpenerConnectionSuccessDescription => '配置设备信息';

  @override
  String get smartOpenerDeviceNamePlaceholder => '设备名称';

  @override
  String get smartOpenerSelectScenePlaceholder => '选择场景';

  @override
  String get smartOpenerRenameFailed => '名称修改失败，请重试。';

  @override
  String get smartOpenerRenameNetworkUnavailable => '网络不可用，请重试。';

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
  String get chooseSceneEmpty => '暂无可用场景';

  @override
  String get chooseSceneLoadFailed => '场景加载失败，点击重试。';

  @override
  String get chooseSceneMoveFailed => '门移动失败，请重试。';

  @override
  String get chooseSceneMoveNetworkUnavailable => '网络不可用，请重试。';

  @override
  String get chooseSceneMoveUnavailable => '当前门无法移动到其他场景。';

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
  String get notificationTitle => '消息通知';

  @override
  String get notificationAllRead => '全部已读';

  @override
  String get notificationAllReadMessage => '所有通知已标记为已读';

  @override
  String get notificationNotFound => '未找到该通知';

  @override
  String get notificationEmpty => '暂无消息通知';

  @override
  String get notificationLoadFailed => '消息加载失败，请重试';

  @override
  String get notificationViewDetails => '查看详情';

  @override
  String get notificationAppointmentAfterSales => '预约售后服务';

  @override
  String get notificationUpgrade => '升级';

  @override
  String get notificationAppointmentTime => '预约时间';

  @override
  String get notificationUpgradeComingSoon => '设备升级功能即将上线';

  @override
  String get afterSalesDetailsTitle => '售后服务详情';

  @override
  String get afterSalesAppointmentTitle => '预约售后服务';

  @override
  String get afterSalesProblemDescription => '问题描述';

  @override
  String get afterSalesAppointmentTime => '预约时间';

  @override
  String get afterSalesRemark => '备注';

  @override
  String get afterSalesPicture => '图片';

  @override
  String get afterSalesInstallerConfirm => '安装人员确认';

  @override
  String get afterSalesConfirmed => '已确认';

  @override
  String get afterSalesFeedback => '反馈';

  @override
  String get afterSalesContactInstaller => '联系安装人员';

  @override
  String get afterSalesFeedbackSubmitted => '反馈已提交';

  @override
  String get afterSalesContactComingSoon => '联系安装人员功能即将上线';

  @override
  String get afterSalesDescriptionHint => '建议填写设备型号、故障症状等关键信息';

  @override
  String get afterSalesSubmitToEngineer => '提交给工程师';

  @override
  String get afterSalesDescriptionRequired => '请输入问题描述';

  @override
  String get afterSalesSubmitSuccess => '预约提交成功';

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
  String get deviceSettingsAutoCloseCondition => '自动关闭条件';

  @override
  String get deviceSettingsLoading => '正在读取设备属性…';

  @override
  String get deviceSettingsLoadFailed => '无法读取设备属性。';

  @override
  String get deviceSettingsRetry => '重试';

  @override
  String get deviceSettingsWriting => '正在写入…';

  @override
  String get deviceSettingsRawUnavailable => '设备未上报';

  @override
  String deviceSettingsRawValueDisplay(String hexValue, int decimalValue) {
    return '$hexValue（$decimalValue）';
  }

  @override
  String get deviceSettingsRawValueHelp =>
      '请输入设备原始值，可使用十进制或十六进制（例如 30 或 0x1E）。';

  @override
  String get deviceSettingsRawValueLabel => '原始值';

  @override
  String deviceSettingsRawValueInvalid(int maximum) {
    return '请输入 0 到 $maximum 之间的值。';
  }

  @override
  String get deviceSettingsRawValueProtocolInvalid => '请输入设备支持的值。';

  @override
  String get deviceSettingsBluetoothConnectionRequired => '请先连接当前设备的蓝牙，再修改设置。';

  @override
  String get deviceSettingsRawCancel => '取消';

  @override
  String get deviceSettingsRawSave => '保存';

  @override
  String get deviceSettingsOpeningSpeed => '开启速度';

  @override
  String get deviceSettingsOpeningSpeedValue => 'GMT+8:00';

  @override
  String get deviceSettingsAboutDevice => '关于设备';

  @override
  String get deviceSettingsDoorOpenReminder => '开门提醒';

  @override
  String get deviceSettingsDoorOpenReminderTime => '开门提醒时间';

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
  String deviceSettingsPercent(int value) {
    return '$value%';
  }

  @override
  String deviceSettingsOpeningSpeedStandardGuide(int value) {
    return '$value%\n(标准)';
  }

  @override
  String get deviceSettingsForceMarginMaximumGuide => '+15%';

  @override
  String get deviceSettingsStandardAbbreviation => '标准';

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
  String get hardwareDiagnosticsFlutterLogging => 'Flutter BLE Console 日志';

  @override
  String get hardwareDiagnosticsNativeLogging => '原生 BLE Console 日志';

  @override
  String get hardwareDiagnosticsWarning =>
      'Flutter 日志会在 Flutter Console 输出格式化蓝牙报文。关闭原生日志可避免重复输出。AES Key、Token、Wi-Fi 密码等敏感信息始终不会记录。';

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
  String get securityCenterWifiDisconnectedMessage =>
      '安全中心仅在电机已正确连接 Wi-Fi 时可访问。请检查电机状态。';

  @override
  String get securityCenterWifiDisconnectedBackAction => '返回';

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
  String get securityReportBalanceStatusUnavailable => '--';

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
  String get batteryReplacementIllustration => '电池更换示意图';

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
  String get securityReportBatteryLow => '电池电量低';

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
  String get securityReportSaveAction => '保存';

  @override
  String get securityReportSavingAction => '保存中';

  @override
  String get securityReportShareAction => '分享';

  @override
  String get securityReportSharingAction => '分享中';

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
  String get securityReportShareFailed => '无法分享报告图片。';

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

  @override
  String get generalEvaluationLoadFailed => '加载失败，点击重试。';

  @override
  String get safetySensorsLoadFailed => '安全传感器加载失败，点击重试。';

  @override
  String get safetySensorsEmpty => '暂无安全传感器数据。';

  @override
  String get safetySensorsWiredStatus => '有线传感器状态';

  @override
  String get safetySensorsWirelessStatus => '无线传感器状态';

  @override
  String get safetySensorsMetricSensors => '传感器';

  @override
  String get safetySensorsMetricFine => '正常';

  @override
  String get safetySensorsMetricAbnormal => '异常';

  @override
  String get safetySensorsMetricLowPower => '低电量';

  @override
  String get safetySensorsMatch => '配对';

  @override
  String get safetySensorsManage => '管理';

  @override
  String get safetySensorPairingTitle => '传感器对码';

  @override
  String get safetySensorPairingGuideTitle => '传感器匹配';

  @override
  String get safetySensorPairingGuideStatus => '保持蓝牙开启';

  @override
  String get safetySensorPairingBluetoothEnabled => '请保持蓝牙开启';

  @override
  String get safetySensorPairingGuideDescription =>
      '1.确保手机与电机的距离小于 5 米。\n2.确保安全传感器与电机的距离小于 10 米。\n3.如果 30 秒内未进行学习操作，学习将自动结束。';

  @override
  String get safetySensorPairingGuideAction => '开始学习';

  @override
  String get safetySensorPairingStart => '开始对码';

  @override
  String get safetySensorPairingInProgress => '学习中…';

  @override
  String get safetySensorPairingMatchingDescription => '长按无线传感器上的配对按钮。';

  @override
  String get safetySensorPairingCancel => '取消';

  @override
  String get safetySensorPairingCancelling => '取消对码中…';

  @override
  String get safetySensorPairingBack => '返回';

  @override
  String get safetySensorPairingFailed => '安全设备对码失败';

  @override
  String get safetySensorPairingTimeout => '安全设备对码超时';

  @override
  String get safetySensorPairingFailedDescription => '安全设备对码失败，请返回。';

  @override
  String get safetySensorPairingTimeoutDescription => '安全设备对码超时，请返回。';

  @override
  String get safetySensorPairingBluetoothDisconnected => '蓝牙连接已断开，无法进行安全设备对码。';

  @override
  String get safetySensorPairingCommunicationTimeout => '蓝牙通信超时，未收到设备响应。';

  @override
  String safetySensorPairingReasonCode(String code) {
    return '故障码：$code';
  }

  @override
  String get safetySensorPairingSuccess => '无线安全传感器学习成功';

  @override
  String get safetySensorPairingLearningFailed => '无线安全传感器学习失败';

  @override
  String get safetySensorPairingComplete => '完成';

  @override
  String get safetySensorPairingImagePlaceholder => '对码插图占位图';

  @override
  String get safetySensorManagementTitle => '传感器管理';

  @override
  String get safetySensorManagementEmpty => '暂无可管理的无线传感器。';

  @override
  String get safetySensorManagementDeleteLabel => '删除传感器';

  @override
  String safetySensorManagementDeleteMessage(String sensorName) {
    return '确认删除$sensorName？删除后设备将无法使用，且所有配置将被清除。是否确认？';
  }

  @override
  String get safetySensorManagementCancel => '取消';

  @override
  String get safetySensorManagementConfirm => '确认';

  @override
  String get safetySensorManagementDeleteSuccess => '安全传感器删除成功。';

  @override
  String get safetySensorManagementDeleteFailed => '安全传感器删除失败，请重试。';

  @override
  String get safetySensorManagementBluetoothDisconnected => '请先通过蓝牙连接当前设备。';

  @override
  String get safetySensorManagementWirelessDoorSensor => '无线门磁';

  @override
  String get safetySensorManagementUnknownType => '未知安全传感器';

  @override
  String get safetySensorsWirelessWicketDoor => '无线小门传感器';

  @override
  String get safetySensorsWirelessSafetyEdge => '无线安全边';

  @override
  String get safetySensorsWirelessSlackRope => '无线松绳传感器';

  @override
  String get safetySensorUnlocked => '已解锁';

  @override
  String get safetySensorLocked => '已锁定';

  @override
  String get safetySensorNotTriggered => '未触发';

  @override
  String get safetySensorOffline => '离线';

  @override
  String get deviceCommandFallbackDoorName => '车库门';

  @override
  String get deviceCommandOperatedCycles => '已运行次数';

  @override
  String get deviceCommandRemainingCycles => '剩余次数';

  @override
  String get deviceCommandVideoTooltip => '视频';

  @override
  String get deviceCommandCloseTooltip => '关门';

  @override
  String get deviceCommandStopTooltip => '停止';

  @override
  String get deviceCommandOpenTooltip => '开门';

  @override
  String get deviceCommandAutoCloseTitle => '自动关门';

  @override
  String get deviceCommandOpenReminderTitle => '开门提醒';

  @override
  String deviceCommandMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get deviceCommandLedTitle => 'LED';

  @override
  String deviceCommandCentimeters(int value) {
    return '$value 厘米';
  }

  @override
  String get deviceCommandPartialOpenTitle => '部分开门';

  @override
  String get deviceCommandPermissionDenied => '当前账号没有使用此功能的权限。';

  @override
  String get deviceCommandPartialOpenSettingUnavailable => '半开门档位暂不可用，请重试。';

  @override
  String get deviceCommandPartialOpenSettingFailed => '无法保存半开门位置，请重试。';

  @override
  String get deviceCommandMoreSettingsTitle => '更多设置';

  @override
  String get deviceCommandControlMethod => '控制方式';

  @override
  String get deviceCommandActionOpen => '开门';

  @override
  String get deviceCommandActionClose => '关门';

  @override
  String get deviceCommandActionStop => '暂停';

  @override
  String get deviceCommandActionPartialOpen => '部分开门';

  @override
  String get deviceCommandActionLedOn => '开灯';

  @override
  String get deviceCommandActionLedOff => '关灯';

  @override
  String get deviceCommandActionPb => 'PB';

  @override
  String deviceCommandSending(String action, String controlCode) {
    return '正在发送$action指令（$controlCode）...';
  }

  @override
  String deviceCommandSucceeded(String action, String controlCode) {
    return '$action指令已发送（$controlCode）。';
  }

  @override
  String deviceCommandRejected(String action, String controlCode) {
    return '$action指令未被接收（$controlCode）。';
  }

  @override
  String deviceCommandBluetoothRequired(String action) {
    return '请先通过蓝牙连接选中的设备，再使用$action。';
  }

  @override
  String deviceCommandRemoteFailed(String action) {
    return '$action执行失败，请重试。';
  }

  @override
  String deviceCommandRemoteUnconfirmed(String action) {
    return '设备已成功回执$action指令，但未确认实际运行状态。';
  }

  @override
  String deviceCommandRemoteTimeout(String action) {
    return '$action执行超时，请检查门状态后重试。';
  }

  @override
  String get smartOpenerAlreadyBoundToCurrentUser => '该设备已绑定至当前账号。';

  @override
  String get smartOpenerAlreadyBoundToAnotherUser => '该设备已被其他用户绑定。';

  @override
  String deviceCommandNetworkFailure(String action) {
    return '$action发送失败，请检查网络后重试。';
  }

  @override
  String get sceneCreateFailed => '创建场景失败，请重试。';

  @override
  String get sceneRenameFailed => '重命名场景失败，请重试。';

  @override
  String get sceneDeleteFailed => '删除场景失败，请重试。';

  @override
  String get deviceRenameFailed => '重命名设备失败，请重试。';

  @override
  String get deviceUnbindFailed => '解绑设备失败，请重试。';

  @override
  String get deviceTopFailed => '置顶设备失败，请重试。';
}
