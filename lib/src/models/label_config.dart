import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LabelConfig {
  int larguraMm;

  int alturaMm;

  bool mostrarHostname;

  bool mostrarUsuario;

  bool mostrarDepartamento;

  bool mostrarInventario;

  bool mostrarSerial;

  bool mostrarAnydesk;

  bool mostrarQrCode;

  int copiasPorItem;

  LabelConfig({
    this.larguraMm = 60,
    this.alturaMm = 40,
    this.mostrarHostname = true,
    this.mostrarUsuario = true,
    this.mostrarDepartamento = true,
    this.mostrarInventario = true,
    this.mostrarSerial = true,
    this.mostrarAnydesk = true,
    this.mostrarQrCode = true,
    this.copiasPorItem = 1,
  });

  Map<String, dynamic> toJson() => {
        'larguraMm': larguraMm,
        'alturaMm': alturaMm,
        'mostrarHostname': mostrarHostname,
        'mostrarUsuario': mostrarUsuario,
        'mostrarDepartamento': mostrarDepartamento,
        'mostrarInventario': mostrarInventario,
        'mostrarSerial': mostrarSerial,
        'mostrarAnydesk': mostrarAnydesk,
        'mostrarQrCode': mostrarQrCode,
        'copiasPorItem': copiasPorItem,
      };

  factory LabelConfig.fromJson(Map<String, dynamic> json) {
    return LabelConfig(
      larguraMm: _parseInt(json['larguraMm'], 60).clamp(20, 200),
      alturaMm: _parseInt(json['alturaMm'], 40).clamp(15, 200),
      mostrarHostname: json['mostrarHostname'] as bool? ?? true,
      mostrarUsuario: json['mostrarUsuario'] as bool? ?? true,
      mostrarDepartamento: json['mostrarDepartamento'] as bool? ?? true,
      mostrarInventario: json['mostrarInventario'] as bool? ?? true,
      mostrarSerial: json['mostrarSerial'] as bool? ?? true,
      mostrarAnydesk: json['mostrarAnydesk'] as bool? ?? true,
      mostrarQrCode: json['mostrarQrCode'] as bool? ?? true,
      copiasPorItem: _parseInt(json['copiasPorItem'], 1).clamp(1, 99),
    );
  }

  static int _parseInt(dynamic valor, int fallback) {
    if (valor is int) return valor;
    if (valor is double) return valor.toInt();
    if (valor is String) return int.tryParse(valor) ?? fallback;
    return fallback;
  }

  static const String _key = 'glpi_label_config';

  static Future<LabelConfig> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return LabelConfig();
    try {
      return LabelConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LabelConfig.carregar: erro ao decodificar - $e');
      }
      return LabelConfig();
    }
  }

  Future<void> salvar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(toJson()));
  }

  Future<void> resetar() async {
    larguraMm = 60;
    alturaMm = 40;
    mostrarHostname = true;
    mostrarUsuario = true;
    mostrarDepartamento = true;
    mostrarInventario = true;
    mostrarSerial = true;
    mostrarAnydesk = true;
    mostrarQrCode = true;
    copiasPorItem = 1;
    await salvar();
  }

  LabelConfig copyWith({
    int? larguraMm,
    int? alturaMm,
    bool? mostrarHostname,
    bool? mostrarUsuario,
    bool? mostrarDepartamento,
    bool? mostrarInventario,
    bool? mostrarSerial,
    bool? mostrarAnydesk,
    bool? mostrarQrCode,
    int? copiasPorItem,
  }) =>
      LabelConfig(
        larguraMm: larguraMm ?? this.larguraMm,
        alturaMm: alturaMm ?? this.alturaMm,
        mostrarHostname: mostrarHostname ?? this.mostrarHostname,
        mostrarUsuario: mostrarUsuario ?? this.mostrarUsuario,
        mostrarDepartamento: mostrarDepartamento ?? this.mostrarDepartamento,
        mostrarInventario: mostrarInventario ?? this.mostrarInventario,
        mostrarSerial: mostrarSerial ?? this.mostrarSerial,
        mostrarAnydesk: mostrarAnydesk ?? this.mostrarAnydesk,
        mostrarQrCode: mostrarQrCode ?? this.mostrarQrCode,
        copiasPorItem: copiasPorItem ?? this.copiasPorItem,
      );

  @override
  String toString() =>
      'LabelConfig(${larguraMm}x${alturaMm}mm, cópias: $copiasPorItem)';
}
