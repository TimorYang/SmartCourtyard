class CreateHomeSceneRequestDto {
  const CreateHomeSceneRequestDto({required this.name});

  final String name;

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}
