import 'dart:typed_data';

class HomeDoorCoverImage {
  const HomeDoorCoverImage({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}
