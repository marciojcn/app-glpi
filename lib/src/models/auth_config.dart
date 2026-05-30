import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants.dart';

class AuthConfig {
  final String baseUrl;
  final String clientId;
  final String clientSecret;

  final String scope;

  const AuthConfig({
    this.baseUrl = '',
    this.clientId = '',
    this.clientSecret = '',
    this.scope = '',
  });

  bool get completo =>
      baseUrl.isNotEmpty && clientId.isNotEmpty && clientSecret.isNotEmpty;

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

  String get host {
    try {
      return Uri.parse(baseNormalizada).host;
    } catch (_) {
      return '';
    }
  }

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<AuthConfig> carregar() async {
    final all = await _storage.readAll();
    return AuthConfig(
      baseUrl: all[GlpiConstants.secBaseUrl] ?? '',
      clientId: all[GlpiConstants.secClientId] ?? '',
      clientSecret: all[GlpiConstants.secClientSecret] ?? '',
      scope: all[GlpiConstants.secScope] ?? '',
    );
  }

  Future<void> salvar() async {
    await _storage.write(key: GlpiConstants.secBaseUrl, value: baseUrl.trim());
    await _storage.write(
        key: GlpiConstants.secClientId, value: clientId.trim());
    await _storage.write(
        key: GlpiConstants.secClientSecret, value: clientSecret.trim());
    await _storage.write(key: GlpiConstants.secScope, value: scope.trim());
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
        baseUrl: baseUrl ?? this.baseUrl,
        clientId: clientId ?? this.clientId,
        clientSecret: clientSecret ?? this.clientSecret,
        scope: scope ?? this.scope,
      );
}
