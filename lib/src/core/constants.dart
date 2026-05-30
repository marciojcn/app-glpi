/// Constantes da API REST v2 (High-Level) do GLPI e chaves de persistência.
///
/// Não é instanciável — apenas namespace estático.
///
/// A API nova (v2) é totalmente diferente da antiga (`apirest.php`):
/// autentica via **OAuth2** (Bearer token) e expõe rotas RESTful sob
/// `/api.php/v2/...`. Ver [docs/api.md] para o mapeamento completo.
class GlpiConstants {
  GlpiConstants._();

  // ── Endpoints da API v2 ───────────────────────────────────────────────────

  /// Caminho da raiz da API (relativo à base URL do servidor GLPI).
  static const String apiPath = '/api.php';

  /// Versão da API. Fixada em `v2.3` para casar exatamente com o servidor da
  /// apresentação (`http://137.131.162.82:8080/api.php/v2.3`). Troque por `v2`
  /// para acompanhar automaticamente a última minor/patch do servidor.
  static const String apiVersion = 'v2.3';

  /// Endpoint do token OAuth2 (sem versão): `{base}/api.php/token`.
  static const String pathToken = '$apiPath/token';

  /// Grant type usado no login (usuário/senha + client_id/secret).
  static const String oauthGrantPassword = 'password';

  /// Grant type para renovar o access token expirado.
  static const String oauthGrantRefresh = 'refresh_token';

  // ── Recursos (rotas relativas a `/api.php/v2/`) ───────────────────────────

  /// Lista/lê computadores: `/api.php/v2/Assets/Computer[/{id}]`.
  static const String resourceComputer = 'Assets/Computer';

  /// Lista/lê celulares: `/api.php/v2/Assets/Phone[/{id}]`.
  static const String resourcePhone = 'Assets/Phone';

  // ── Paginação ─────────────────────────────────────────────────────────────

  /// Tamanho de página padrão das listagens (parâmetro `limit`).
  static const int paginaTamanhoPadrao = 30;

  // ── Timeout HTTP ──────────────────────────────────────────────────────────
  static const Duration timeoutHttp = Duration(seconds: 20);

  // ── SharedPreferences (dados não sensíveis) ───────────────────────────────
  static const String prefAllowUntrusted      = 'glpi_allow_untrusted';
  static const String prefLastUsername        = 'glpi_last_username';
  static const String prefImpressoraRedeHost  = 'glpi_impressora_rede_host';
  static const String prefImpressoraRedePorta = 'glpi_impressora_rede_porta';

  // ── flutter_secure_storage (config OAuth — sensível) ──────────────────────
  static const String secBaseUrl      = 'glpi_base_url';
  static const String secClientId     = 'glpi_client_id';
  static const String secClientSecret = 'glpi_client_secret';
  static const String secScope        = 'glpi_scope';
}
