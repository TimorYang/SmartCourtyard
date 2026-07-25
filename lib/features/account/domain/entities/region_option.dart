/// A selectable account region displayed on the Region settings page.
class RegionOption {
  const RegionOption({required this.code});

  /// Stable region identifier used for selection state and future persistence.
  final String code;
}
