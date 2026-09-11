import 'dart:convert';
import 'dart:io';

import 'package:flinx/app/theme/app_skin_catalog.dart';
import 'package:flinx/features/appearance/domain/entities/app_skin_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'every skin asset slot has a bundled directory or explicit pending name',
    () async {
      final declared = RegExp(r'^\s+- (assets/.+/)$', multiLine: true)
          .allMatches(File('pubspec.yaml').readAsStringSync())
          .map((match) => match[1]!)
          .toSet();
      final originals = [
        for (final root in ['assets/icons', 'assets/images'])
          for (final file in Directory(
            root,
          ).listSync(recursive: true).whereType<File>())
            if (RegExp(r'\.(png|webp|jpg|jpeg)$').hasMatch(file.path) &&
                !RegExp(r'/(skins|[23]\.0x)/').hasMatch(file.path))
              file.path,
      ]..sort();
      final inventory = <Map<String, Object>>[];
      for (final skin in AppSkinId.values) {
        final assets = AppSkinAssets(skin);
        final paths = {
          for (final original in originals) original: assets.resolve(original),
          'theme_preview': assets.themePreview,
        };
        for (final entry in paths.entries) {
          final file = File(entry.value);
          final exists = await file.exists();
          expect(
            declared,
            contains('${file.parent.path}/'),
            reason: entry.value,
          );
          if (!exists) {
            expect(entry.value, contains('_placeholder.'), reason: entry.value);
          }
          inventory.add({
            'skin': skin.storageValue,
            'original': entry.key,
            'path': entry.value,
            'available': exists,
            'shared': entry.key == entry.value,
          });
        }
      }
      if (const bool.fromEnvironment('SKIN_QA')) {
        final file = File('build/skin_qa/asset_inventory.json');
        await file.parent.create(recursive: true);
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(inventory),
        );
      }
    },
  );
}
