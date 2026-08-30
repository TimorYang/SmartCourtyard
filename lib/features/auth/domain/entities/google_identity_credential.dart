class GoogleIdentityCredential {
  const GoogleIdentityCredential({
    required this.idToken,
    required this.authorizationCode,
  });

  final String idToken;
  final String authorizationCode;
}
