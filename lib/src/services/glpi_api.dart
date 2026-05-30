import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/glpi_exception.dart';

/// Cliente HTTP de baixo nível da HL API v2 do GLPI.
///
/// Não conhece os recursos em detalhe — apenas monta a URL, injeta o
/// `Authorization: Bearer`, decodifica JSON e lança [GlpiException].
///
/// Recebe via construtor callbacks (e não valores fixos) porque a base URL e
/// o token mudam em runtime (login/logout, refresh):
/// - [baseUrl]: raiz do GLPI já normalizada (ex.: `http://host:8080`).
/// - [tokenProvider]: devolve um access token válido (renova se preciso).
class GlpiApi {
  final String Function()        baseUrl;
  final Future<String> Function() tokenProvider;

  GlpiApi({required this.baseUrl, required this.tokenProvider});

  // ── API pública ─────────────────────────────────────────────────────────

  /// GET autenticado em `/api.php/v2/{recurso}` — devolve só o corpo.
  Future<dynamic> v2Get(String recurso, {Map<String, String>? query}) async {
    final (body, _) = await _enviar('GET', _pathV2(recurso),
        query: query, autenticado: true);
    return body;
  }

  /// GET autenticado devolvendo corpo **e** headers (para ler `Content-Range`
  /// nas listagens paginadas).
  Future<({dynamic body, Map<String, String> headers})> v2GetComHeaders(
    String recurso, {
    Map<String, String>? query,
  }) async {
    final (body, headers) = await _enviar('GET', _pathV2(recurso),
        query: query, autenticado: true);
    return (body: body, headers: headers);
  }

  /// POST `application/x-www-form-urlencoded` SEM Bearer — usado no endpoint
  /// OAuth (`/api.php/token`) para obter/renovar o token.
  Future<dynamic> postForm(String path, Map<String, String> campos) async {
    final (body, _) = await _enviar('POST', path,
        formFields: campos, autenticado: false);
    return body;
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  String _pathV2(String recurso) {
    final r = recurso.startsWith('/') ? recurso.substring(1) : recurso;
    return '${GlpiConstants.apiPath}/${GlpiConstants.apiVersion}/$r';
  }

  Future<(dynamic, Map<String, String>)> _enviar(
    String metodo,
    String path, {
    Map<String, String>? query,
    Map<String, String>? formFields,
    bool autenticado = true,
  }) async {
    final base = baseUrl().trim();
    if (base.isEmpty) {
      throw const GlpiException('Servidor GLPI não configurado.', statusCode: 400);
    }

    final uri = _montarUri(base, path, query);
    final headers = <String, String>{'Accept': 'application/json'};

    if (autenticado) {
      final token = await tokenProvider();
      headers['Authorization'] = 'Bearer $token';
    }
    if (formFields != null) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    }

    final http.Response res;
    try {
      res = switch (metodo) {
        'POST' => await http
            .post(uri, headers: headers, body: formFields)
            .timeout(GlpiConstants.timeoutHttp),
        _ => await http
            .get(uri, headers: headers)
            .timeout(GlpiConstants.timeoutHttp),
      };
    } on GlpiException {
      rethrow;
    } on TimeoutException {
      throw const GlpiException(
        'O servidor demorou para responder. Tente novamente.',
        statusCode: 408,
      );
    } catch (_) {
      throw const GlpiException(
        'Não foi possível conectar ao servidor GLPI. Verifique a URL e a rede.',
      );
    }

    return (_processar(res), res.headers);
  }

  /// Monta a URI final. Usa `replace(queryParameters:)`, que faz o
  /// percent-encoding correto dos valores RSQL (`==`, `*`, aspas) — o PHP
  /// decodifica de volta no servidor.
  Uri _montarUri(String base, String path, Map<String, String>? query) {
    final caminho = path.startsWith('/') ? path : '/$path';
    final url = Uri.parse('$base$caminho');
    if (query == null || query.isEmpty) return url;
    return url.replace(queryParameters: {...url.queryParameters, ...query});
  }

  dynamic _processar(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    final corpo = _safeJson(res.body);
    if (ok) return corpo;
    throw GlpiException.traduzir(statusCode: res.statusCode, body: corpo);
  }

  dynamic _safeJson(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }
}
