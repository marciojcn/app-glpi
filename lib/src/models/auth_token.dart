class TokenOAuth {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final DateTime? expiraEm;

  const TokenOAuth({
    required this.accessToken,
    this.refreshToken = '',
    this.tokenType = 'Bearer',
    this.expiraEm,
  });

  factory TokenOAuth.fromJson(Map<String, dynamic> json) {
    final segundos = (json['expires_in'] as num?)?.toInt() ?? 3600;
    return TokenOAuth(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'Bearer',
      expiraEm: DateTime.now().add(Duration(seconds: segundos)),
    );
  }

  bool get vazio => accessToken.isEmpty;

  bool get expirado {
    final e = expiraEm;
    if (e == null) return false;
    return DateTime.now().isAfter(e.subtract(const Duration(seconds: 30)));
  }

  String get authorization => '$tokenType $accessToken';
}
