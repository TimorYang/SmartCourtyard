enum AppSkinId {
  dark('dark'),
  minimalist('minimalist'),
  technologyWind('technology_wind');

  const AppSkinId(this.storageValue);

  final String storageValue;

  static AppSkinId? fromStorageValue(String? value) {
    for (final skin in values) {
      if (skin.storageValue == value) return skin;
    }
    return null;
  }
}
