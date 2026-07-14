import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Builds the BLE authentication token from the server-provided AES key.
String buildBleAuthenticationToken(String aesKeyHex) {
  final normalizedKey = aesKeyHex.trim();
  if (!RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(normalizedKey)) {
    throw const FormatException(
      'The device AES key must be 32 hexadecimal characters.',
    );
  }

  final keyBytes = Uint8List.fromList(
    List<int>.generate(
      normalizedKey.length ~/ 2,
      (index) => int.parse(
        normalizedKey.substring(index * 2, index * 2 + 2),
        radix: 16,
      ),
    ),
  );
  final digest = MD5Digest().process(keyBytes);
  return digest
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();
}
