/// 用户在设备添加流程开始前填写的门与场景归属信息。
class AddDoorDraft {
  const AddDoorDraft({
    required this.name,
    required this.sceneId,
    required this.sceneName,
  });

  final String name;
  final int sceneId;
  final String sceneName;
}
