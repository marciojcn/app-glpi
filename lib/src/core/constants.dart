class GlpiConstants {
  GlpiConstants._();

  static const String apiPath = '/api.php';

  static const String apiVersion = 'v2.3';

  static const String pathToken = '$apiPath/token';

  static const String oauthGrantPassword = 'password';

  static const String oauthGrantRefresh = 'refresh_token';

  static const String resourceComputer = 'Assets/Computer';

  static const String resourcePhone = 'Assets/Phone';

  static const int paginaTamanhoPadrao = 30;

  static const Duration timeoutHttp = Duration(seconds: 20);

  static const String prefAllowUntrusted = 'glpi_allow_untrusted';
  static const String prefLastUsername = 'glpi_last_username';
  static const String prefImpressoraRedeHost = 'glpi_impressora_rede_host';
  static const String prefImpressoraRedePorta = 'glpi_impressora_rede_porta';

  static const String secBaseUrl = 'glpi_base_url';
  static const String secClientId = 'glpi_client_id';
  static const String secClientSecret = 'glpi_client_secret';
  static const String secScope = 'glpi_scope';
}
