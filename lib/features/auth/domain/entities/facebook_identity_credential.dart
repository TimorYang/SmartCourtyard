enum FacebookTokenKind { accessToken, authenticationToken }

class FacebookIdentityCredential {
  const FacebookIdentityCredential({
    required this.kind,
    required this.tokenString,
  });

  final FacebookTokenKind kind;
  final String tokenString;
}
