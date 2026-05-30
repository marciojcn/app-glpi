/// Exceção de domínio do GLPI (API v2 / OAuth2).
///
/// Encapsula erros HTTP da API REST com:
/// - [mensagem]: texto amigável em PT-BR para exibir ao usuário.
/// - [statusCode]: código HTTP (ex: 401, 404, 500).
/// - [codigo]: identificador de erro retornado pelo GLPI/OAuth no body
///   (ex: `invalid_grant`, `ERROR_ITEM_NOT_FOUND`).
///
/// Use [GlpiException.traduzir] para gerar uma mensagem PT-BR a partir da
/// resposta crua. Cobre os dois formatos que a API nova retorna:
/// - **OAuth2** (`/api.php/token`): `{"error": "...", "error_description": "..."}`
/// - **HL API** (`/api.php/v2/...`): `{"status": "...", "title": "...", "detail": "..."}`
///   e o formato legado em array `["ERROR_CODE", "mensagem"]`.
class GlpiException implements Exception {
  final String  mensagem;
  final int?    statusCode;
  final String? codigo;

  const GlpiException(
    this.mensagem, {
    this.statusCode,
    this.codigo,
  });

  /// `true` quando o erro indica sessão/token inválido — o caller deve
  /// tentar renovar o token ou forçar novo login.
  bool get naoAutenticado =>
      statusCode == 401 ||
      codigo == 'access_denied' ||
      codigo == 'invalid_token';

  @override
  String toString() => 'GlpiException(${codigo ?? statusCode ?? '-'}): $mensagem';

  // ── Factory de tradução ────────────────────────────────────────────────────

  /// Traduz uma resposta crua de erro em uma [GlpiException] amigável.
  factory GlpiException.traduzir({
    required int statusCode,
    dynamic body,
  }) {
    String? codigo;
    String  mensagem;

    if (body is Map) {
      // OAuth2: {error, error_description, hint} | HL API: {status, title, detail, message}
      codigo = (body['error'] ??
              body['status'] ??
              body['code'])
          ?.toString();
      mensagem = (body['error_description'] ??
              body['detail'] ??
              body['message'] ??
              body['title'] ??
              body['hint'] ??
              '')
          .toString();
    } else if (body is List && body.isNotEmpty) {
      // Formato legado: ["ERROR_CODE", "mensagem"].
      codigo   = body[0]?.toString();
      mensagem = body.length > 1 ? body[1].toString() : (codigo ?? '');
    } else if (body is String && body.isNotEmpty) {
      mensagem = body;
    } else {
      mensagem = '';
    }

    return GlpiException(
      _traduzir(codigo, mensagem, statusCode),
      statusCode: statusCode,
      codigo:     codigo,
    );
  }

  /// Tradutor centralizado de código/HTTP → mensagem PT-BR curada.
  static String _traduzir(String? codigo, String original, int status) {
    switch (codigo) {
      // ── OAuth2 ──
      case 'invalid_client':
        return 'Client ID ou Client Secret inválidos. Verifique a configuração da API.';
      case 'invalid_grant':
        return 'Usuário ou senha incorretos.';
      case 'invalid_scope':
        return 'Escopo (scope) inválido para este client OAuth.';
      case 'unsupported_grant_type':
        return 'Tipo de autenticação não suportado pelo servidor.';
      case 'access_denied':
      case 'invalid_token':
        return 'Sessão expirada. Faça login novamente.';
      case 'invalid_request':
        return 'Requisição de autenticação inválida. Confira os dados.';
      // ── HL API ──
      case 'ERROR_ITEM_NOT_FOUND':
        return 'Item não encontrado.';
      case 'ERROR_RIGHT_MISSING':
        return 'Sem permissão para esta ação.';
      case 'ERROR_BAD_ARRAY':
      case 'ERROR_FIELD_NOT_FOUND':
        return 'Filtro ou campo inválido enviado para a API.';
    }

    // Sem código mapeado: traduz pelo HTTP status.
    switch (status) {
      case 400: return 'Requisição inválida. ${_curto(original)}'.trim();
      case 401: return 'Não autorizado. Faça login novamente.';
      case 403: return 'Acesso negado. Verifique suas permissões no GLPI.';
      case 404: return 'Recurso não encontrado.';
      case 405: return 'Método HTTP não permitido nesse recurso.';
      case 408: return 'O servidor demorou para responder. Tente novamente.';
      case 422: return 'Dados não puderam ser processados.';
      case 429: return 'Muitas requisições. Aguarde um instante.';
      case 500: return 'Erro interno no servidor GLPI.';
      case 502:
      case 503:
      case 504: return 'Servidor GLPI indisponível. Tente novamente em instantes.';
    }
    return original.isNotEmpty ? original : 'Erro HTTP $status';
  }

  static String _curto(String s) =>
      s.length > 140 ? '${s.substring(0, 140)}…' : s;
}
