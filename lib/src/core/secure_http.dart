import 'dart:io';

class SecureHttpOverrides extends HttpOverrides {
  static bool allowUntrusted = false;

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
