class AuthTokenEntity {
  final String accessToken;
  final String refreshToken;

  const AuthTokenEntity({
    required this.accessToken,
    required this.refreshToken,
  });
}
