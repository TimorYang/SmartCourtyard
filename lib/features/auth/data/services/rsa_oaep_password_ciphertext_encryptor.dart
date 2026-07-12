import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/export.dart';

import '../../domain/entities/password_encryption_material.dart';
import '../../domain/services/password_ciphertext_encryptor.dart';

class RsaOaepPasswordCiphertextEncryptor
    implements PasswordCiphertextEncryptor {
  RsaOaepPasswordCiphertextEncryptor({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  String encrypt({
    required String plaintext,
    required PasswordEncryptionMaterial material,
  }) {
    if (material.algorithm != PasswordEncryptionMaterial.rsaOaepSha256) {
      throw ArgumentError.value(material.algorithm, 'algorithm');
    }
    final publicKey = _parseSpki(material.publicKeyBase64);
    final payload = utf8.encode(
      jsonEncode({
        'password': plaintext,
        'nonce': material.nonce,
        'timestamp': _clock().millisecondsSinceEpoch,
      }),
    );
    return base64Encode(_encryptOaepSha256(publicKey, payload));
  }

  Uint8List _encryptOaepSha256(RSAPublicKey publicKey, List<int> payload) {
    const hashLength = 32;
    final modulusLength = (publicKey.modulus!.bitLength + 7) ~/ 8;
    final paddingLength = modulusLength - payload.length - (2 * hashLength) - 2;
    if (paddingLength < 0) {
      throw ArgumentError.value(
        payload,
        'plaintext',
        'is too long for RSA-OAEP-256',
      );
    }

    final labelHash = SHA256Digest().process(Uint8List(0));
    final dataBlock = Uint8List(modulusLength - hashLength - 1)
      ..setRange(0, hashLength, labelHash)
      ..[hashLength + paddingLength] = 1
      ..setRange(
        hashLength + paddingLength + 1,
        modulusLength - hashLength - 1,
        payload,
      );
    final seed = _secureRandom().nextBytes(hashLength);
    final dataBlockMask = _mgf1Sha256(seed, dataBlock.length);
    final maskedDataBlock = _xor(dataBlock, dataBlockMask);
    final seedMask = _mgf1Sha256(maskedDataBlock, hashLength);
    final maskedSeed = _xor(seed, seedMask);
    final encodedMessage = Uint8List(modulusLength)
      ..setRange(1, 1 + hashLength, maskedSeed)
      ..setRange(1 + hashLength, modulusLength, maskedDataBlock);

    final engine = RSAEngine()
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    return engine.process(encodedMessage);
  }

  Uint8List _mgf1Sha256(Uint8List seed, int length) {
    final output = Uint8List(length);
    for (var counter = 0, offset = 0; offset < length; counter++) {
      final input = Uint8List(seed.length + 4)
        ..setRange(0, seed.length, seed)
        ..[seed.length] = (counter >> 24) & 0xff
        ..[seed.length + 1] = (counter >> 16) & 0xff
        ..[seed.length + 2] = (counter >> 8) & 0xff
        ..[seed.length + 3] = counter & 0xff;
      final hash = SHA256Digest().process(input);
      final bytesToCopy = (length - offset).clamp(0, hash.length);
      output.setRange(offset, offset + bytesToCopy, hash);
      offset += bytesToCopy;
    }
    return output;
  }

  Uint8List _xor(Uint8List left, Uint8List right) {
    return Uint8List.fromList([
      for (var index = 0; index < left.length; index++)
        left[index] ^ right[index],
    ]);
  }

  RSAPublicKey _parseSpki(String base64Der) {
    final decoded = base64Decode(base64Der.replaceAll(RegExp(r'\s'), ''));
    final outer = ASN1Parser(decoded).nextObject() as ASN1Sequence;
    final bitString = outer.elements[1] as ASN1BitString;
    // A DER BIT STRING starts with its unused-bit count. `contentBytes()`
    // excludes that metadata byte and leaves the embedded RSA key sequence.
    final key =
        ASN1Parser(bitString.contentBytes()).nextObject() as ASN1Sequence;
    final modulus = (key.elements[0] as ASN1Integer).valueAsBigInteger;
    final exponent = (key.elements[1] as ASN1Integer).valueAsBigInteger;
    return RSAPublicKey(modulus, exponent);
  }

  SecureRandom _secureRandom() {
    final random = FortunaRandom();
    final seed = Uint8List(32);
    final source = Random.secure();
    for (var index = 0; index < seed.length; index++) {
      seed[index] = source.nextInt(256);
    }
    random.seed(KeyParameter(seed));
    return random;
  }
}
