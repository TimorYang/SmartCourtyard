import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Optional local QA font; tests remain portable without a system font.
Future<void> loadSkinQaFont() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  const path = String.fromEnvironment('SKIN_QA_FONT');
  if (path.isEmpty) return;
  final font = FontLoader('Roboto')
    ..addFont(
      File(path).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
  await font.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> captureSkinQa(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  if (!const bool.fromEnvironment('SKIN_QA')) return;
  // Let file-backed images finish decoding before capturing their first frame.
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      final context = tester.element(find.byWidget(image).first);
      await precacheImage(image.image, context, onError: (_, _) {});
    }
  });
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/skin_qa');
      await directory.create(recursive: true);
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}
