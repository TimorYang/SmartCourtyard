class HomeScene {
  const HomeScene({
    required this.id,
    required this.name,
    required this.doorCount,
    required this.isDefault,
  });

  final int id;
  final String name;
  final int doorCount;
  final bool isDefault;
}
