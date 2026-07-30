enum AccountAvatarCode {
  avatar01('AVATAR_01'),
  avatar02('AVATAR_02'),
  avatar03('AVATAR_03'),
  avatar04('AVATAR_04'),
  avatar05('AVATAR_05'),
  avatar06('AVATAR_06'),
  avatar07('AVATAR_07'),
  avatar08('AVATAR_08');

  const AccountAvatarCode(this.wireValue);
  final String wireValue;
  static AccountAvatarCode? fromWireValue(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim();
    for (final avatarCode in values) {
      if (avatarCode.wireValue == normalized) return avatarCode;
    }
    return null;
  }
}
