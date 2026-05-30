import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/glpi_exception.dart';

class GlpiApi {
  final String Function() baseUrl;
  final Future<String> Function() tokenProvider;

  GlpiApi({required this.baseUrl, required this.tokenProvider});

  Future<dynamic> v2Get(String recurso, {Map<String, String>? query}) async {
    final (body, _) =
        await _enviar('GET', _pathV2(recurso), query: query, autenticado: true);
    return body;
  }

  Future<({dynamic body, Map<String, String> headers})> v2GetComHeaders(
    String recurso, {
    Map<String, String>? query,
  }) async {
    final (body, headers) =
        await _enviar('GET', _pathV2(recurso), query: query, autenticado: true);
    return (body: body, headers: headers);
  }

  Future<dynamic> postForm(String path, Map<String, String> campos) async {
    final (body, _) =
        await _enviar('POST', path, formFields: campos, autenticado: false);
    return body;
  }

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
      throw const GlpiException('Servidor GLPI não configurado.',
          statusCode: 400);
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
