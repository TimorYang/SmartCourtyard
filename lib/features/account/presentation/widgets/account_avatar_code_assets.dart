import '../../domain/entities/account_avatar_code.dart';

extension AccountAvatarCodeAssets on AccountAvatarCode {
  String get assetPath => switch (this) {
    AccountAvatarCode.avatar01 =>
      'assets/icons/account/account_avatar_option_01.png',
    AccountAvatarCode.avatar02 =>
      'assets/icons/account/account_avatar_option_02.png',
    AccountAvatarCode.avatar03 =>
      'assets/icons/account/account_avatar_option_03.png',
    AccountAvatarCode.avatar04 =>
      'assets/icons/account/account_avatar_option_04.png',
    AccountAvatarCode.avatar05 =>
      'assets/icons/account/account_avatar_option_05.png',
    AccountAvatarCode.avatar06 =>
      'assets/icons/account/account_avatar_option_06.png',
    AccountAvatarCode.avatar07 =>
      'assets/icons/account/account_avatar_option_07.png',
    AccountAvatarCode.avatar08 =>
      'assets/icons/account/account_avatar_option_08.png',
  };
}
