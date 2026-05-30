/// Helpers de desserialização resilientes para os JSON da API GLPI.
///
/// A HL API (v2) expande os "dropdowns" (fabricante, modelo, localização…)
/// como **objetos aninhados** (`{"id": 1, "name": "Dell"}`), enquanto a API
/// antiga devolvia só o id (`manufacturers_id: 1`). Estes helpers absorvem as
/// duas formas — e qualquer valor faltando vira string vazia, nunca crash.
class ModelHelpers {
  ModelHelpers._();

  /// Converte qualquer valor escalar em string ("" se nulo).
  static String asString(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is num)    return v.toString();
    if (v is Map)    return nomeDeMap(v);
    return v.toString();
  }

  static int asInt(dynamic v) {
    if (v is int)    return v;
    if (v is num)    return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is Map)    return asInt(v['id']);
    return 0;
  }

  static bool asBool(dynamic v) {
    if (v is bool)   return v;
    if (v is num)    return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  /// Faz parse de uma data ISO/SQL do GLPI. Trata `null`, vazio e o
  /// sentinela `0000-00-00`. Aceita `2026-01-15 10:00:00` (com espaço).
  static DateTime? asDateTime(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty || s.startsWith('0000')) return null;
    return DateTime.tryParse(s.replaceAll(' ', 'T'));
  }

  /// Extrai um nome legível de um valor que pode ser String, num ou Map
  /// (dropdown expandido: `{id, name, completename, realname, ...}`).
  static String nomeDeMap(dynamic v) {
    if (v == null)   return '';
    if (v is String) return v;
    if (v is num)    return v.toString();
    if (v is Map) {
      for (final k in const ['completename', 'name', 'title', 'label']) {
        final val = v[k];
        if (val is String && val.trim().isNotEmpty) return val;
      }
      // Usuário: combina sobrenome (realname) + nome (firstname).
      final sobrenome = (v['realname']  ?? '').toString().trim();
      final nome      = (v['firstname'] ?? '').toString().trim();
      final completo  = [sobrenome, nome].where((s) => s.isNotEmpty).join(' ');
      if (completo.isNotEmpty) return completo;
      final login = (v['name'] ?? '').toString().trim();
      if (login.isNotEmpty) return login;
    }
    return '';
  }

  /// Primeiro valor não-vazio dentre [chaves] — tenta o nome amigável da HL
  /// API e cai para o `*_id` legado. Ex.:
  /// `texto(json, ['manufacturer', 'manufacturers_id'])`.
  static String texto(Map<String, dynamic> json, List<String> chaves) {
    for (final k in chaves) {
      if (!json.containsKey(k)) continue;
      final s = nomeDeMap(json[k]);
      if (s.trim().isNotEmpty) return s;
    }
    return '';
  }

  /// Cópia imutável defensiva do map cru (para guardar em `raw`).
  static Map<String, dynamic> imutavel(Map<String, dynamic> json) =>
      Map<String, dynamic>.unmodifiable(json);
}
