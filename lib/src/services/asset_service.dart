import '../core/constants.dart';
import '../models/_helpers.dart';
import '../models/asset.dart';
import '../models/asset_tipo.dart';
import 'auth_service.dart';
import 'glpi_api.dart';

class PaginaAssets {
  final List<Asset> itens;
  final int total;
  final int start;
  final int limit;

  const PaginaAssets({
    required this.itens,
    required this.total,
    required this.start,
    required this.limit,
  });

  bool get temMais => (start + itens.length) < total;

  int get proximoStart => start + itens.length;

  factory PaginaAssets.fromResposta(
    dynamic body,
    Map<String, String> headers,
    AssetTipo tipo, {
    required int start,
    required int limit,
  }) {
    List<dynamic> listaRaw = const [];
    int total = 0;
    bool achouTotal = false;

    if (body is Map) {
      final results = body['results'] ?? body['data'] ?? body['items'];
      if (results is List) listaRaw = results;
      if (body['total'] != null) {
        total = ModelHelpers.asInt(body['total']);
        achouTotal = true;
      }
    } else if (body is List) {
      listaRaw = body;
    }

    final itens = listaRaw
        .whereType<Map>()
        .map((m) => Asset.fromJson(Map<String, dynamic>.from(m), tipo))
        .toList();

    if (!achouTotal) {
      total = _totalContentRange(headers, fallback: start + itens.length);
    }

    if (total < start + itens.length) total = start + itens.length;

    return PaginaAssets(itens: itens, total: total, start: start, limit: limit);
  }

  static int _totalContentRange(Map<String, String> headers,
      {required int fallback}) {
    final cr = headers['content-range'];
    if (cr == null) return fallback;
    final m = RegExp(r'/\s*(\d+)\s*$').firstMatch(cr);
    return m != null ? (int.tryParse(m.group(1)!) ?? fallback) : fallback;
  }
}

class AssetService {
  AssetService._();

  static GlpiApi get _api => AuthService.instance.api;

  static Future<PaginaAssets> listar(
    AssetTipo tipo, {
    int start = 0,
    int limit = GlpiConstants.paginaTamanhoPadrao,
    String busca = '',
  }) async {
    final query = <String, String>{
      'start': '$start',
      'limit': '$limit',
    };
    final filtro = _filtroBusca(busca);
    if (filtro.isNotEmpty) query['filter'] = filtro;

    final r = await _api.v2GetComHeaders(tipo.recurso, query: query);
    return PaginaAssets.fromResposta(r.body, r.headers, tipo,
        start: start, limit: limit);
  }

  static Future<Asset> detalhe(AssetTipo tipo, int id) async {
    final body = await _api.v2Get('${tipo.recurso}/$id');
    final map =
        body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
    return Asset.fromJson(map, tipo);
  }

  static ({AssetTipo tipo, int id})? parseUrlAtivo(String codigo) {
    final s = codigo.trim();
    final m = RegExp(r'/([a-zA-Z]+)\.form\.php\?').firstMatch(s);
    if (m == null) return null;

    final tipo = switch (m.group(1)!.toLowerCase()) {
      'computer' => AssetTipo.computador,
      'phone' => AssetTipo.celular,
      _ => null,
    };
    if (tipo == null) return null;

    int? id;
    try {
      id = int.tryParse(Uri.parse(s).queryParameters['id'] ?? '');
    } catch (_) {}
    id ??= int.tryParse(RegExp(r'[?&]id=(\d+)').firstMatch(s)?.group(1) ?? '');
    if (id == null || id <= 0) return null;

    return (tipo: tipo, id: id);
  }

  static String urlAtivo(AssetTipo tipo, int id) {
    if (id <= 0) return '';
    final base = AuthService.instance.config.baseNormalizada;
    return '$base/front/${tipo.formularioGlpi}?id=$id';
  }

  static String _filtroBusca(String q) {
    final limpo = q.replaceAll(RegExp(r'["();,]'), '').trim();
    if (limpo.isEmpty) return '';
    const campos = ['name', 'serial', 'otherserial'];
    return campos.map((c) => '$c=="*$limpo*"').join(',');
  }
}
