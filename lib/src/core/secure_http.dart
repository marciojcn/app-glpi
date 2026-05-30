import 'dart:io';

/// Override global de HTTP com aceitação CONTROLADA de certificado
/// auto-assinado.
///
/// Cert inválido só é tolerado quando, simultaneamente:
/// 1. O usuário marcou "Aceitar SSL auto-assinado" nas Configurações
///    ([allowUntrusted] == true).
/// 2. O host do request bate com o host do GLPI configurado ([trustedHost]).
///
/// Qualquer outra combinação faz o handshake falhar (default seguro). Isso
/// bloqueia MITM via redes hostis interceptando requests a hosts arbitrários.
class SecureHttpOverrides extends HttpOverrides {
  /// Toggle do usuário. Default `false` — segurança em primeiro lugar.
  static bool allowUntrusted = false;

  /// Host do GLPI atualmente configurado. Apenas requests a este host têm o
  /// cert auto-assinado tolerado.
  static String? trustedHost;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) {
      if (!allowUntrusted) return false;
      final trusted = trustedHost;
      if (trusted == null || trusted.isEmpty) return false;
      return host.toLowerCase() == trusted.toLowerCase();
    };
    return client;
  }

  /// Atualiza o host confiável a partir da base URL configurada
  /// (ex.: `http://137.131.162.82:8080` → `137.131.162.82`).
  static void atualizarHostConfiavel(String? baseUrl) {
    if (baseUrl == null || baseUrl.isEmpty) {
      trustedHost = null;
      return;
    }
    try {
      trustedHost = Uri.parse(baseUrl).host;
    } catch (_) {
      trustedHost = null;
    }
  }
}
