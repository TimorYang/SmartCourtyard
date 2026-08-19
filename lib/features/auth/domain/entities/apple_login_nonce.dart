class AppleLoginNonce {
  const AppleLoginNonce({
    required this.nonceId,
    required this.nonce,
    required this.expiresIn,
  });

  final String nonceId;
  final String nonce;
  final Duration expiresIn;
}
