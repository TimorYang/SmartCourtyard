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
  String get forgotPasswordComingSoon => '忘记密码页面即将上线';

  @override
  String get loginTitle => '登录';

  @override
  String get loginAccountPlaceholder => '请输入账号';

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
}
