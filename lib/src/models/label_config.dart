import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuração da etiqueta térmica TSPL (XD210, Zebra GK, XPrinter,
/// PT-260 e compatíveis).
///
/// Controla dimensões, elementos visíveis e quantidade de cópias —
/// persistida em [SharedPreferences] via [carregar] e [salvar] para
/// que o usuário não precise reconfigurar a cada impressão.
class LabelConfig {
  // ── Dimensões ───────────────────────────────────────────────────────────

  /// Largura da etiqueta em milímetros (20–200).
  int larguraMm;

  /// Altura da etiqueta em milímetros (15–200).
  int alturaMm;

  // ── Elementos visíveis ──────────────────────────────────────────────────

  /// Exibe o hostname (nome do equipamento) na etiqueta.
  bool mostrarHostname;

  /// Exibe o usuário responsável pelo ativo.
  bool mostrarUsuario;

  /// Exibe o departamento (Group) do usuário.
  bool mostrarDepartamento;

  /// Exibe o número de inventário (`otherserial`).
  bool mostrarInventario;

  /// Exibe o serial number (S/N) do equipamento.
  bool mostrarSerial;

  /// Exibe o ID do AnyDesk em destaque no rodapé.
  bool mostrarAnydesk;

  /// Exibe o QR code (hostname codificado).
  bool mostrarQrCode;

  // ── Impressão ───────────────────────────────────────────────────────────

  /// Quantidade de cópias impressas por item (1–99).
  int copiasPorItem;

  LabelConfig({
    this.larguraMm           = 60,
    this.alturaMm            = 40,
    this.mostrarHostname     = true,
    this.mostrarUsuario      = true,
    this.mostrarDepartamento = true,
    this.mostrarInventario   = true,
    this.mostrarSerial       = true,
    this.mostrarAnydesk      = true,
    this.mostrarQrCode       = true,
    this.copiasPorItem       = 1,
  });

  // ── Serialização ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'larguraMm':           larguraMm,
        'alturaMm':            alturaMm,
        'mostrarHostname':     mostrarHostname,
        'mostrarUsuario':      mostrarUsuario,
        'mostrarDepartamento': mostrarDepartamento,
        'mostrarInventario':   mostrarInventario,
        'mostrarSerial':       mostrarSerial,
        'mostrarAnydesk':      mostrarAnydesk,
        'mostrarQrCode':       mostrarQrCode,
        'copiasPorItem':       copiasPorItem,
      };

  factory LabelConfig.fromJson(Map<String, dynamic> json) {
    // Campos antigos/desconhecidos são ignorados — JSON segue compatível
    // com versões prévias persistidas no aparelho.
    return LabelConfig(
      larguraMm:           _parseInt(json['larguraMm'], 60).clamp(20, 200),
      alturaMm:            _parseInt(json['alturaMm'],  40).clamp(15, 200),
      mostrarHostname:     json['mostrarHostname']     as bool? ?? true,
      mostrarUsuario:      json['mostrarUsuario']      as bool? ?? true,
      mostrarDepartamento: json['mostrarDepartamento'] as bool? ?? true,
      mostrarInventario:   json['mostrarInventario']   as bool? ?? true,
      mostrarSerial:       json['mostrarSerial']       as bool? ?? true,
      mostrarAnydesk:      json['mostrarAnydesk']      as bool? ?? true,
      mostrarQrCode:       json['mostrarQrCode']       as bool? ?? true,
      copiasPorItem:       _parseInt(json['copiasPorItem'], 1).clamp(1, 99),
    );
  }

  static int _parseInt(dynamic valor, int fallback) {
    if (valor is int)    return valor;
    if (valor is double) return valor.toInt();
    if (valor is String) return int.tryParse(valor) ?? fallback;
    return fallback;
  }

  // ── Persistência ────────────────────────────────────────────────────────

  static const String _key = 'glpi_label_config';

  static Future<LabelConfig> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_key);
    if (raw == null) return LabelConfig();
    try {
      return LabelConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) debugPrint('LabelConfig.carregar: erro ao decodificar — $e');
      return LabelConfig();
    }
  }

  Future<void> salvar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(toJson()));
  }

  Future<void> resetar() async {
    larguraMm           = 60;
    alturaMm            = 40;
    mostrarHostname     = true;
    mostrarUsuario      = true;
    mostrarDepartamento = true;
    mostrarInventario   = true;
    mostrarSerial       = true;
    mostrarAnydesk      = true;
    mostrarQrCode       = true;
    copiasPorItem       = 1;
    await salvar();
  }

  // ── Cópia imutável ──────────────────────────────────────────────────────

  LabelConfig copyWith({
    int?  larguraMm,
    int?  alturaMm,
    bool? mostrarHostname,
    bool? mostrarUsuario,
    bool? mostrarDepartamento,
    bool? mostrarInventario,
    bool? mostrarSerial,
    bool? mostrarAnydesk,
    bool? mostrarQrCode,
    int?  copiasPorItem,
  }) =>
      LabelConfig(
        larguraMm:           larguraMm           ?? this.larguraMm,
        alturaMm:            alturaMm            ?? this.alturaMm,
        mostrarHostname:     mostrarHostname     ?? this.mostrarHostname,
        mostrarUsuario:      mostrarUsuario      ?? this.mostrarUsuario,
        mostrarDepartamento: mostrarDepartamento ?? this.mostrarDepartamento,
        mostrarInventario:   mostrarInventario   ?? this.mostrarInventario,
        mostrarSerial:       mostrarSerial       ?? this.mostrarSerial,
        mostrarAnydesk:      mostrarAnydesk      ?? this.mostrarAnydesk,
        mostrarQrCode:       mostrarQrCode       ?? this.mostrarQrCode,
        copiasPorItem:       copiasPorItem       ?? this.copiasPorItem,
      );

  @override
  String toString() =>
      'LabelConfig(${larguraMm}x${alturaMm}mm, cópias: $copiasPorItem)';
}
