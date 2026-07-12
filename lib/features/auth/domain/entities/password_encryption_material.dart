class PasswordEncryptionMaterial {
  const PasswordEncryptionMaterial({
    required this.keyId,
    required this.algorithm,
    required this.publicKeyBase64,
    required this.nonce,
    required this.expiresIn,
    required this.requestId,
    required this.issuedAt,
  });

  static const rsaOaepSha256 = 'RSA-OAEP-256';

  final String keyId;
  final String algorithm;
  final String publicKeyBase64;
  final String nonce;
  final Duration expiresIn;
  final String requestId;
  final DateTime issuedAt;

  DateTime get expiresAt => issuedAt.toUtc().add(expiresIn);

  bool isExpiredAt(DateTime time) => !expiresAt.isAfter(time.toUtc());
}
