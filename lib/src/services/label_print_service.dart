import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../core/glpi_exception.dart';
import '../models/label_config.dart';

class AssetLabelData {
  final String hostname;
  final String usuario;
  final String departamento;
  final String inventario;
  final String serial;
  final String anydesk;

  final String qrPayload;

  final String rotuloHost;

  const AssetLabelData({
    required this.hostname,
    required this.usuario,
    required this.departamento,
    required this.inventario,
    required this.serial,
    required this.anydesk,
    required this.qrPayload,
    this.rotuloHost = 'Hostname:',
  });
}

class LabelPrintService {
  LabelPrintService._();

  static final BlueThermalPrinter _bt = BlueThermalPrinter.instance;

  static Future<List<BluetoothDevice>> dispositivosPareados() async {
    try {
      return await _bt.getBondedDevices();
    } catch (_) {
      throw const GlpiException('Falha ao listar impressoras pareadas.');
    }
  }

  static Future<bool> bluetoothLigado() async => (await _bt.isOn) ?? false;
  static Future<bool> bluetoothConectado() async =>
      (await _bt.isConnected) ?? false;

  static Future<void> bluetoothConectar(BluetoothDevice device) async {
    try {
      if (await bluetoothConectado()) {
        await _bt.disconnect();
      }
      await _bt.connect(device);
    } catch (_) {
      throw const GlpiException('Falha ao conectar à impressora.');
    }
  }

  static Future<void> bluetoothDesconectar() async {
    try {
      await _bt.disconnect();
    } catch (_) {}
  }

  static Future<void> imprimirBluetooth(
    AssetLabelData d, {
    LabelConfig? config,
  }) async {
    if (!await bluetoothConectado()) {
      throw const GlpiException('Impressora Bluetooth não está conectada.');
    }
    final tspl = await _gerarTSPL(d, config ?? LabelConfig());
    try {
      await _bt.writeBytes(tspl);
    } catch (_) {
      throw const GlpiException('Falha ao enviar à impressora.');
    }
  }

  static Future<void> imprimirBluetoothLote({
    required List<AssetLabelData> dados,
    LabelConfig? config,
    void Function(int impressas, int total)? onProgresso,
  }) async {
    if (!await bluetoothConectado()) {
      throw const GlpiException('Impressora Bluetooth não está conectada.');
    }
    final cfg = config ?? LabelConfig();
    final total = dados.length * cfg.copiasPorItem;
    var impressas = 0;

    try {
      for (final d in dados) {
        final tspl = await _gerarTSPL(d, cfg);
        for (var i = 0; i < cfg.copiasPorItem; i++) {
          await _bt.writeBytes(tspl);

          await Future<void>.delayed(const Duration(milliseconds: 350));
          impressas++;
          onProgresso?.call(impressas, total);
        }
      }
    } catch (_) {
      throw const GlpiException(
        'Falha durante a impressão em lote. Verifique a impressora.',
      );
    }
  }

  static Future<void> imprimirRede({
    required String host,
    int porta = 9100,
    Duration timeout = const Duration(seconds: 10),
    required AssetLabelData dados,
    LabelConfig? config,
  }) async {
    if (!hostValido(host)) {
      throw const GlpiException(
        'Host inválido. Informe um IP (ex: 192.168.0.50) ou hostname.',
      );
    }
    if (!portaValida(porta)) {
      throw const GlpiException(
        'Porta inválida ou reservada. Use entre 1 e 65535, evite portas '
        'de serviços comuns (22/80/443/etc.) — padrão Zebra é 9100.',
      );
    }

    final tspl = await _gerarTSPL(dados, config ?? LabelConfig());
    Socket? socket;
    try {
      socket = await Socket.connect(host, porta, timeout: timeout);
      socket.add(tspl);
      await socket.flush().timeout(timeout);
    } on SocketException catch (e) {
      throw GlpiException(
        'Não foi possível conectar à impressora $host:$porta — ${e.message}',
      );
    } on TimeoutException {
      throw GlpiException('Tempo esgotado ao conectar em $host:$porta.');
    } catch (_) {
      throw const GlpiException('Falha ao imprimir pela rede.');
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  static bool hostValido(String host) {
    final h = host.trim();
    if (h.isEmpty || h.length > 253) return false;
    final ipv4 = RegExp(
      r'^(25[0-5]|2[0-4]\d|[01]?\d?\d)'
      r'(\.(25[0-5]|2[0-4]\d|[01]?\d?\d)){3}$',
    );
    if (ipv4.hasMatch(h)) return true;
    final hostname = RegExp(
      r'^(?=.{1,253}$)'
      r'([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)'
      r'(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    return hostname.hasMatch(h);
  }

  static const Set<int> _portasReservadas = {
    22,
    23,
    25,
    53,
    80,
    110,
    143,
    443,
    445,
    465,
    587,
    993,
    995,
    1433,
    1521,
    2049,
    3306,
    3389,
    5432,
    5900,
    6379,
    8080,
    8443,
    27017,
  };

  static bool portaValida(int porta) {
    if (porta < 1 || porta > 65535) return false;
    if (_portasReservadas.contains(porta)) return false;
    return true;
  }

  static Future<void> salvarUltimaImpressoraRede(String host, int porta) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GlpiConstants.prefImpressoraRedeHost, host.trim());
    await prefs.setInt(GlpiConstants.prefImpressoraRedePorta, porta);
  }

  static Future<({String host, int porta})> ultimaImpressoraRede() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      host: prefs.getString(GlpiConstants.prefImpressoraRedeHost) ?? '',
      porta: prefs.getInt(GlpiConstants.prefImpressoraRedePorta) ?? 9100,
    );
  }

  static Future<Uint8List> gerarPdf(
    AssetLabelData d, {
    LabelConfig? config,
  }) async {
    final cfg = config ?? LabelConfig();
    final doc = pw.Document(
      title: 'Etiqueta ${d.hostname}',
      creator: 'GLPI Inventário',
    );

    final formato = PdfPageFormat(
      cfg.larguraMm * PdfPageFormat.mm,
      cfg.alturaMm * PdfPageFormat.mm,
      marginAll: 1.5 * PdfPageFormat.mm,
    );

    final logoBytes = await _carregarLogoPng();

    for (var i = 0; i < cfg.copiasPorItem; i++) {
      doc.addPage(
        pw.Page(
          pageFormat: formato,
          build: (_) => _layoutPdf(d, cfg, logoBytes),
        ),
      );
    }

    return doc.save();
  }

  static Future<void> imprimirPdf(
    AssetLabelData d, {
    LabelConfig? config,
  }) async {
    final bytes = await gerarPdf(d, config: config);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'etiqueta_${_safeFilename(d.hostname)}',
    );
  }

  static Future<void> compartilharPdf(
    AssetLabelData d, {
    LabelConfig? config,
  }) async {
    final bytes = await gerarPdf(d, config: config);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'etiqueta_${_safeFilename(d.hostname)}.pdf',
    );
  }

  static String _safeFilename(String raw) {
    var s = raw.trim().isEmpty ? 'etiqueta' : raw.trim();
    s = s.replaceAll(RegExp(r'[\x00-\x1F\x7F/\\:*?"<>|]'), '_');
    if (s.length > 60) s = s.substring(0, 60);
    return s;
  }

  static pw.Widget _layoutPdf(
    AssetLabelData d,
    LabelConfig cfg,
    Uint8List? logoBytes,
  ) {
    pw.Widget linha(String rotulo, String valor) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 0.6),
          child: pw.RichText(
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            text: pw.TextSpan(children: [
              pw.TextSpan(
                text: rotulo,
                style:
                    pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(
                text: ' ${valor.trim().isEmpty ? '—' : valor}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ]),
          ),
        );

    final linhas = <pw.Widget>[
      if (cfg.mostrarHostname) linha(d.rotuloHost, d.hostname),
      if (cfg.mostrarUsuario) linha('Usuário:', d.usuario),
      if (cfg.mostrarDepartamento) linha('Depto.', d.departamento),
      if (cfg.mostrarInventario) linha('Inventário:', d.inventario),
      if (cfg.mostrarSerial) linha('S/N:', d.serial),
    ];

    final textoAny = d.anydesk.trim().isEmpty
        ? 'SEM ANYDESK'
        : 'ANYDESK: ${formatarAnydesk(d.anydesk)}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (logoBytes != null)
          pw.Center(
            child: pw.SizedBox(
              height: cfg.alturaMm * 0.16 * PdfPageFormat.mm,
              child:
                  pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
            ),
          )
        else
          pw.Center(
            child: pw.Text(
              'UNIFEOB',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.3,
              ),
            ),
          ),
        pw.SizedBox(height: 2),
        pw.Expanded(
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 1.0),
              borderRadius: pw.BorderRadius.circular(2),
            ),
            padding: const pw.EdgeInsets.all(3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (cfg.mostrarQrCode) ...[
                  pw.SizedBox(
                    width: cfg.alturaMm * 0.36 * PdfPageFormat.mm,
                    height: cfg.alturaMm * 0.36 * PdfPageFormat.mm,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: d.qrPayload.isEmpty
                          ? (d.hostname.isEmpty ? '—' : d.hostname)
                          : d.qrPayload,
                      drawText: false,
                    ),
                  ),
                  pw.SizedBox(width: 4),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: linhas,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (cfg.mostrarAnydesk) ...[
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              child: pw.Text(
                textoAny,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static Future<Uint8List> _gerarTSPL(
    AssetLabelData d,
    LabelConfig cfg,
  ) async {
    final largDots = cfg.larguraMm * 8;
    final altDots = cfg.alturaMm * 8;
    const margem = 12;
    final areaUtil = largDots - margem * 2;

    final out = BytesBuilder();
    void txt(String s) => out.add(utf8.encode('$s\r\n'));

    txt('SIZE ${cfg.larguraMm} mm,${cfg.alturaMm} mm');
    txt('GAP 2 mm,0 mm');
    txt('DENSITY 8');
    txt('SPEED 4');
    txt('DIRECTION 0');
    txt('REFERENCE 0,0');
    txt('CLS');

    final logoAltAlvo = (altDots * 0.13).round().clamp(20, 40);
    int yPos = margem ~/ 2;
    final logo = await _carregarLogoTspl(alturaDots: logoAltAlvo);
    if (logo != null && logo.widthDots <= largDots) {
      final logoX = ((largDots - logo.widthDots) ~/ 2).clamp(0, largDots);
      txt('BITMAP $logoX,$yPos,${logo.widthBytes},${logo.heightDots},0,');
      out.add(logo.bytes);
      txt('');
      yPos += logo.heightDots + 4;
    } else {
      txt('TEXT $margem,$yPos,"3",0,1,1,"UNIFEOB"');
      yPos += 28;
    }

    final temAny = cfg.mostrarAnydesk;
    final faixaAny = temAny ? (altDots * 0.16).round().clamp(28, 48) : 0;
    final anyTopo = altDots - margem - faixaAny;

    final boxY1 = yPos;
    final boxY2 = temAny ? anyTopo - 4 : altDots - margem;
    const boxX1 = margem;
    final boxX2 = largDots - margem;
    final boxAlt = boxY2 - boxY1;

    if (boxAlt >= 36 && boxX2 > boxX1) {
      txt('BOX $boxX1,$boxY1,$boxX2,$boxY2,2');
      const padIn = 6;

      int xTexto = boxX1 + padIn;
      if (cfg.mostrarQrCode) {
        final qrCell = areaUtil >= 320 ? 3 : 2;
        final qrLado = (boxAlt - padIn * 2).clamp(48, qrCell * 40);
        txt('QRCODE ${boxX1 + padIn},${boxY1 + padIn},M,$qrCell,A,0,'
            '"${_escTSPL(d.qrPayload.isEmpty ? d.hostname : d.qrPayload, maxLen: 300)}"');
        xTexto = boxX1 + padIn + qrLado + 8;
      }

      final rotHost =
          d.rotuloHost.toLowerCase().startsWith('host') ? 'Host:' : 'Nome:';
      final linhas = <(String, String)>[
        if (cfg.mostrarHostname) (rotHost, d.hostname),
        if (cfg.mostrarUsuario) ('User:', d.usuario),
        if (cfg.mostrarDepartamento) ('Depto:', d.departamento),
        if (cfg.mostrarInventario) ('Inv:', d.inventario),
        if (cfg.mostrarSerial) ('S/N:', d.serial),
      ];

      if (linhas.isNotEmpty) {
        const charW = 12, fontH = 20;
        final maxChars = ((boxX2 - xTexto - 4) ~/ charW).clamp(6, 60);
        final dy = ((boxAlt - 6) ~/ linhas.length).clamp(fontH + 2, fontH + 10);
        var yLin =
            boxY1 + ((boxAlt - dy * linhas.length) ~/ 2).clamp(4, boxAlt);
        for (final l in linhas) {
          final valor = l.$2.trim().isEmpty ? '-' : l.$2;
          txt('TEXT $xTexto,$yLin,"2",0,1,1,'
              '"${_escTSPL('${l.$1} $valor', maxLen: maxChars)}"');
          yLin += dy;
        }
      }
    }

    if (temAny) {
      final textoAny = d.anydesk.trim().isEmpty
          ? 'SEM ANYDESK'
          : 'ANYDESK: ${formatarAnydesk(d.anydesk)}';

      final presets = <({String font, int w, int h})>[
        (font: '4', w: 24, h: 32),
        (font: '3', w: 16, h: 24),
        (font: '2', w: 12, h: 20),
      ];
      final esc = presets.firstWhere(
        (p) => textoAny.length * p.w <= areaUtil && p.h <= faixaAny,
        orElse: () => presets.last,
      );
      final xAny = ((largDots - textoAny.length * esc.w) ~/ 2)
          .clamp(margem, largDots - margem);
      final yAny = anyTopo + ((faixaAny - esc.h) ~/ 2).clamp(0, faixaAny);
      txt('TEXT $xAny,$yAny,"${esc.font}",0,1,1,"${_escTSPL(textoAny, maxLen: 40)}"');
    }

    txt('PRINT 1,1');
    return out.toBytes();
  }

  static String _escTSPL(String s, {int maxLen = 60}) {
    final ascii = _asciiFold(s);
    final semControle = ascii.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ');
    final truncado = semControle.length > maxLen
        ? semControle.substring(0, maxLen)
        : semControle;
    return truncado.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  }

  static String _asciiFold(String s) {
    const mapa = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'å': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
      'ý': 'y',
      'ÿ': 'y',
      'Á': 'A',
      'À': 'A',
      'Â': 'A',
      'Ã': 'A',
      'Ä': 'A',
      'Å': 'A',
      'É': 'E',
      'È': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'Í': 'I',
      'Ì': 'I',
      'Î': 'I',
      'Ï': 'I',
      'Ó': 'O',
      'Ò': 'O',
      'Ô': 'O',
      'Õ': 'O',
      'Ö': 'O',
      'Ú': 'U',
      'Ù': 'U',
      'Û': 'U',
      'Ü': 'U',
      'Ç': 'C',
      'Ñ': 'N',
    };
    final sb = StringBuffer();
    for (final ch in s.split('')) {
      final m = mapa[ch];
      if (m != null) {
        sb.write(m);
      } else {
        final code = ch.codeUnitAt(0);
        sb.write(code >= 32 && code < 127 ? ch : ' ');
      }
    }
    return sb.toString();
  }

  static String formatarDataBR(DateTime? d) {
    if (d == null) return '';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year}';
  }

  static String formatarAnydesk(String id) {
    final s = id.replaceAll(RegExp(r'\s+'), '');
    if (s.isEmpty) return '—';
    final partes = <String>[];
    var resto = s;
    while (resto.length > 3) {
      partes.insert(0, resto.substring(resto.length - 3));
      resto = resto.substring(0, resto.length - 3);
    }
    if (resto.isNotEmpty) partes.insert(0, resto);
    return partes.join(' ');
  }

  static const String _logoAsset = 'assets/images/unifeob_label.png';

  static Uint8List? _logoPngCache;
  static final Map<int, _LogoTspl> _logoTsplCache = {};

  static Future<Uint8List?> _carregarLogoPng() async {
    if (_logoPngCache != null) return _logoPngCache;
    try {
      final byteData = await rootBundle.load(_logoAsset);
      _logoPngCache = byteData.buffer.asUint8List();
      return _logoPngCache;
    } catch (_) {
      return null;
    }
  }

  static Future<_LogoTspl?> _carregarLogoTspl({required int alturaDots}) async {
    if (_logoTsplCache.containsKey(alturaDots)) {
      return _logoTsplCache[alturaDots];
    }

    final pngBytes = await _carregarLogoPng();
    if (pngBytes == null) return null;

    img.Image? src;
    try {
      src = img.decodeImage(pngBytes);
    } catch (_) {
      return null;
    }
    if (src == null) return null;

    final novaLargura = (src.width * alturaDots / src.height).round();
    final resized = img.copyResize(
      src,
      width: novaLargura,
      height: alturaDots,
      interpolation: img.Interpolation.cubic,
    );

    final w = resized.width;
    final h = resized.height;
    final widthBytes = (w + 7) ~/ 8;
    final bytes = Uint8List(widthBytes * h);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0xFF;
    }

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = resized.getPixel(x, y);
        final lum = (p.r + p.g + p.b) / 3;
        final isDark = p.a > 128 && lum < 128;
        if (isDark) {
          final byteIdx = y * widthBytes + (x ~/ 8);
          final bitIdx = 7 - (x % 8);
          bytes[byteIdx] &= ~(1 << bitIdx);
        }
      }
    }

    final cache = _LogoTspl(
      bytes: bytes,
      widthBytes: widthBytes,
      widthDots: w,
      heightDots: h,
    );
    _logoTsplCache[alturaDots] = cache;
    return cache;
  }
}

class _LogoTspl {
  final Uint8List bytes;
  final int widthBytes;
  final int widthDots;
  final int heightDots;

  const _LogoTspl({
    required this.bytes,
    required this.widthBytes,
    required this.widthDots,
    required this.heightDots,
  });
}
