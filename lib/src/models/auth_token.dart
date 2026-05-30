/// Token OAuth2 retornado por `POST /api.php/token`.
///
/// Vive **somente em memória** (no `AuthService`) — por segurança, o app
/// exige novo login a cada abertura (padrão JCN). [expiraEm] é calculado a
/// partir de `expires_in` no momento do recebimento.
class TokenOAuth {
  final String     accessToken;
  final String     refreshToken;
  final String     tokenType;   // normalmente "Bearer"
  final DateTime?  expiraEm;

  const TokenOAuth({
    required this.accessToken,
    this.refreshToken = '',
    this.tokenType    = 'Bearer',
    this.expiraEm,
  });

  factory TokenOAuth.fromJson(Map<String, dynamic> json) {
    final segundos = (json['expires_in'] as num?)?.toInt() ?? 3600;
    return TokenOAuth(
      accessToken:  json['access_token']?.toString()  ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      tokenType:    json['token_type']?.toString()    ?? 'Bearer',
      expiraEm:     DateTime.now().add(Duration(seconds: segundos)),
    );
  }

  bool get vazio => accessToken.isEmpty;

  /// `true` quando está perto de expirar (margem de 30s) — hora de renovar.
  bool get expirado {
    final e = expiraEm;
    if (e == null) return false;
    return DateTime.now().isAfter(e.subtract(const Duration(seconds: 30)));
  }

  /// Cabeçalho `Authorization` pronto.
  String get authorization => '$tokenType $accessToken';
}
