class ModelHelpers {
  ModelHelpers._();

  static String asString(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is num) return v.toString();
    if (v is Map) return nomeDeMap(v);
    return v.toString();
  }

  static int asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is Map) return asInt(v['id']);
    return 0;
  }

  static bool asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  static DateTime? asDateTime(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty || s.startsWith('0000')) return null;
    return DateTime.tryParse(s.replaceAll(' ', 'T'));
  }

  static String nomeDeMap(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is num) return v.toString();
    if (v is Map) {
      for (final k in const ['completename', 'name', 'title', 'label']) {
        final val = v[k];
        if (val is String && val.trim().isNotEmpty) return val;
      }

      final sobrenome = (v['realname'] ?? '').toString().trim();
      final nome = (v['firstname'] ?? '').toString().trim();
      final completo = [sobrenome, nome].where((s) => s.isNotEmpty).join(' ');
      if (completo.isNotEmpty) return completo;
      final login = (v['name'] ?? '').toString().trim();
      if (login.isNotEmpty) return login;
    }
    return '';
  }

  static String texto(Map<String, dynamic> json, List<String> chaves) {
    for (final k in chaves) {
      if (!json.containsKey(k)) continue;
      final s = nomeDeMap(json[k]);
      if (s.trim().isNotEmpty) return s;
    }
    return '';
  }

  static Map<String, dynamic> imutavel(Map<String, dynamic> json) =>
      Map<String, dynamic>.unmodifiable(json);
}
