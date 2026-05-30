import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants.dart';

/// Configuração de conexão OAuth2 com o servidor GLPI.
///
/// A API v2 exige um **client OAuth** criado no GLPI (Configurar → Clients
/// OAuth), que fornece o [clientId] e o [clientSecret]. Esses dados são
/// sensíveis e ficam no `flutter_secure_storage` (Android KeyStore) — nunca
/// em `SharedPreferences` em texto puro.
///
/// [baseUrl] é a raiz do GLPI (ex.: `http://137.131.162.82:8080`). O app
/// monta os endpoints `/api.php/token` e `/api.php/v2/...` a partir dela.
class AuthConfig {
  final String baseUrl;
  final String clientId;
  final String clientSecret;

  /// Escopos OAuth solicitados (separados por espaço). Opcional — muitos
  /// servidores concedem o acesso padrão com escopo vazio.
  final String scope;

  const AuthConfig({
    this.baseUrl      = '',
    this.clientId     = '',
    this.clientSecret = '',
    this.scope        = '',
  });

  /// `true` quando há dados suficientes para tentar autenticar.
  bool get completo =>
      baseUrl.isNotEmpty && clientId.isNotEmpty && clientSecret.isNotEmpty;

  /// Raiz do servidor normalizada: sem barra final e sem `/api.php`
  /// duplicado (caso o usuário cole a URL completa por engano).
  String get baseNormalizada {
    var u = baseUrl.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (u.toLowerCase().endsWith('/api.php')) {
      u = u.substring(0, u.length - '/api.php'.length);
    }
    return u;
  }

  /// Host (para o controle de certificado auto-assinado em `main.dart`).
  String get host {
    try {
      return Uri.parse(baseNormalizada).host;
    } catch (_) {
      return '';
    }
  }

  // ── Persistência segura ─────────────────────────────────────────────────────

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<AuthConfig> carregar() async {
    final all = await _storage.readAll();
    return AuthConfig(
      baseUrl:      all[GlpiConstants.secBaseUrl]      ?? '',
      clientId:     all[GlpiConstants.secClientId]     ?? '',
      clientSecret: all[GlpiConstants.secClientSecret] ?? '',
      scope:        all[GlpiConstants.secScope]        ?? '',
    );
  }

  Future<void> salvar() async {
    await _storage.write(key: GlpiConstants.secBaseUrl,      value: baseUrl.trim());
    await _storage.write(key: GlpiConstants.secClientId,     value: clientId.trim());
    await _storage.write(key: GlpiConstants.secClientSecret, value: clientSecret.trim());
    await _storage.write(key: GlpiConstants.secScope,        value: scope.trim());
  }

  static Future<void> limpar() async {
    await _storage.delete(key: GlpiConstants.secBaseUrl);
    await _storage.delete(key: GlpiConstants.secClientId);
    await _storage.delete(key: GlpiConstants.secClientSecret);
    await _storage.delete(key: GlpiConstants.secScope);
  }

  AuthConfig copyWith({
    String? baseUrl,
    String? clientId,
    String? clientSecret,
    String? scope,
  }) =>
      AuthConfig(
        baseUrl:      baseUrl      ?? this.baseUrl,
        clientId:     clientId     ?? this.clientId,
        clientSecret: clientSecret ?? this.clientSecret,
        scope:        scope        ?? this.scope,
      );
}
