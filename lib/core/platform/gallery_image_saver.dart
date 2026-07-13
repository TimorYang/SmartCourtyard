import 'dart:typed_data';

import 'package:gal/gal.dart';

enum GalleryImageSaveFailure {
  accessDenied,
  notEnoughSpace,
  unsupported,
  failed,
}

class GalleryImageSaveException implements Exception {
  const GalleryImageSaveException(this.failure);

  final GalleryImageSaveFailure failure;
}

class GalleryImageSaver {
  const GalleryImageSaver._();

  static Future<void> savePngBytes(Uint8List bytes) async {
    try {
      final hasAccess = await Gal.hasAccess();
      final granted = hasAccess || await Gal.requestAccess();
      if (!granted) {
        throw const GalleryImageSaveException(
          GalleryImageSaveFailure.accessDenied,
        );
      }

      await Gal.putImageBytes(bytes, name: _reportImageName());
    } on GalleryImageSaveException {
      rethrow;
    } on GalException catch (error) {
      throw GalleryImageSaveException(_mapGalFailure(error.type));
    } catch (_) {
      throw const GalleryImageSaveException(GalleryImageSaveFailure.failed);
    }
  }

  static GalleryImageSaveFailure _mapGalFailure(GalExceptionType type) {
    return switch (type) {
      GalExceptionType.accessDenied => GalleryImageSaveFailure.accessDenied,
      GalExceptionType.notEnoughSpace => GalleryImageSaveFailure.notEnoughSpace,
      GalExceptionType.notSupportedFormat =>
        GalleryImageSaveFailure.unsupported,
      GalExceptionType.unexpected => GalleryImageSaveFailure.failed,
    };
  }

  static String _reportImageName() {
    return 'flinx_full_report_${DateTime.now().millisecondsSinceEpoch}';
  }
}
