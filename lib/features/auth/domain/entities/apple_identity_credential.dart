class AppleIdentityCredential {
  const AppleIdentityCredential({
    required this.identityToken,
    required this.authorizationCode,
    this.givenName,
    this.familyName,
  });

  final String identityToken;
  final String authorizationCode;
  final String? givenName;
  final String? familyName;
}
