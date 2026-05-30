import '../core/constants.dart';
import '../core/glpi_exception.dart';
import '../core/secure_http.dart';
import '../models/auth_config.dart';
import '../models/auth_token.dart';
import 'glpi_api.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  AuthConfig _config = const AuthConfig();
  TokenOAuth? _token;
  String _username = '';

  late final GlpiApi api = GlpiApi(
    baseUrl: () => _config.baseNormalizada,
    tokenProvider: tokenValido,
  );

  AuthConfig get config => _config;
  String get usuarioAtual => _username;
  bool get autenticado => _token != null && !_token!.vazio;

  Future<void> carregarConfig() async {
    _config = await AuthConfig.carregar();
    SecureHttpOverrides.atualizarHostConfiavel(_config.baseNormalizada);
  }

  Future<void> salvarConfig(AuthConfig novo) async {
    _config = novo;
    await novo.salvar();
    SecureHttpOverrides.atualizarHostConfiavel(novo.baseNormalizada);
  }

  Future<void> login({required String usuario, required String senha}) async {
    if (!_config.completo) {
      throw const GlpiException(
        'Configure o servidor e o client OAuth antes de entrar.',
        statusCode: 400,
      );
    }
    final body = await api.postForm(GlpiConstants.pathToken, {
      'grant_type': GlpiConstants.oauthGrantPassword,
      'client_id': _config.clientId,
      'client_secret': _config.clientSecret,
      'username': usuario,
      'password': senha,
      'scope': _config.scope.isNotEmpty ? _config.scope : 'api',
    });
    _token = _tokenDe(body);
    _username = usuario;
  }

  Future<String> tokenValido() async {
    final t = _token;
    if (t == null || t.vazio) {
      throw const GlpiException(
        'Sessão não iniciada. Faça login.',
        statusCode: 401,
        codigo: 'invalid_token',
      );
    }
    if (t.expirado && t.refreshToken.isNotEmpty) {
      await _renovar(t.refreshToken);
      return _token!.accessToken;
    }
    return t.accessToken;
  }

  Future<void> _renovar(String refresh) async {
    final body = await api.postForm(GlpiConstants.pathToken, {
      'grant_type': GlpiConstants.oauthGrantRefresh,
      'client_id': _config.clientId,
      'client_secret': _config.clientSecret,
      'refresh_token': refresh,
      'scope': _config.scope.isNotEmpty ? _config.scope : 'api',
    });
    _token = _tokenDe(body);
  }

  Future<void> testarConfig(AuthConfig cfg) async {
    if (!cfg.completo) {
      throw const GlpiException('Preencha URL, Client ID e Client Secret.',
          statusCode: 400);
    }
    final probe = GlpiApi(
      baseUrl: () => cfg.baseNormalizada,
      tokenProvider: () async => '',
    );
    try {
      await probe.postForm(GlpiConstants.pathToken, {
        'grant_type': GlpiConstants.oauthGrantPassword,
        'client_id': cfg.clientId,
        'client_secret': cfg.clientSecret,
        'username': '__probe__',
        'password': '__probe__',
        'scope': cfg.scope.isNotEmpty ? cfg.scope : 'api',
      });
    } on GlpiException catch (e) {
      switch (e.codigo) {
        case 'invalid_grant':
        case 'invalid_request':
          return;
        case 'invalid_client':
          throw const GlpiException('Client ID ou Client Secret inválidos.',
              codigo: 'invalid_client');
        case 'unsupported_grant_type':
        case 'unauthorized_client':
          throw const GlpiException(
              "Servidor acessível, mas habilite a concessão 'Senha' no client OAuth do GLPI.",
              codigo: 'grant');
      }

      final sc = e.statusCode;
      if (sc != null && sc >= 400 && sc < 500) return;
      rethrow;
    }
  }

  void logout() {
    _token = null;
    _username = '';
  }

  TokenOAuth _tokenDe(dynamic body) {
    if (body is Map && body['access_token'] != null) {
      return TokenOAuth.fromJson(Map<String, dynamic>.from(body));
    }
    throw const GlpiException(
      'Resposta de autenticação inválida do servidor.',
      statusCode: 502,
    );
  }
}
