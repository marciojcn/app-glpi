// lib/src/services/label_print_service.dart

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

/// Dados que vão na etiqueta de identificação de um ativo.
///
/// O layout de impressão é configurável (ver [LabelConfig]) — basta passar os
/// campos preenchidos. Campos vazios viram `—` na etiqueta.
class AssetLabelData {
  final String hostname;
  final String usuario;
  final String departamento;
  final String inventario;
  final String serial;
  final String anydesk;

  /// Conteúdo do QR code (default: o próprio hostname para escaneamento
  /// rápido em campo).
  final String qrPayload;

  /// Rótulo da 1ª linha: "Hostname:" para computador, "Nome:" para celular.
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

/// Service de impressão de etiquetas. Suporta 3 caminhos:
///
/// 1. **Bluetooth** — descoberta + conexão + envio de TSPL (XD210, Zebra
///    em modo TSPL, XPrinter etc.).
/// 2. **Rede** — TCP RAW na porta 9100 (padrão de impressoras Zebra/ZPL/TSPL
///    compartilhadas no escritório).
/// 3. **PDF** — gera o arquivo no tamanho exato e abre o diálogo nativo de
///    impressão / compartilhamento.
class LabelPrintService {
  LabelPrintService._();

  // ─────────────────────────────────────────────────────────────────────
  //  BLUETOOTH
  // ─────────────────────────────────────────────────────────────────────

  static final BlueThermalPrinter _bt = BlueThermalPrinter.instance;

  /// Lista as impressoras Bluetooth pareadas no aparelho. Não dispara
  /// descoberta ativa — basta ter pareado pelo menu do Android antes.
  static Future<List<BluetoothDevice>> dispositivosPareados() async {
    try {
      return await _bt.getBondedDevices();
    } catch (_) {
      throw const GlpiException('Falha ao listar impressoras pareadas.');
    }
  }

  static Future<bool> bluetoothLigado()    async => (await _bt.isOn) ?? false;
  static Future<bool> bluetoothConectado() async => (await _bt.isConnected) ?? false;

  /// Conecta na impressora (faz disconnect defensivo antes).
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

  /// Imprime uma etiqueta via Bluetooth (impressora deve estar conectada
  /// — chame [bluetoothConectar] antes).
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

  /// Imprime várias etiquetas em sequência via Bluetooth com **conexão única**.
  ///
  /// [onProgresso] é chamado após cada etiqueta com `(impressas, total)`.
  /// O total é `dados.length * config.copiasPorItem`.
  static Future<void> imprimirBluetoothLote({
    required List<AssetLabelData> dados,
    LabelConfig? config,
    void Function(int impressas, int total)? onProgresso,
  }) async {
    if (!await bluetoothConectado()) {
      throw const GlpiException('Impressora Bluetooth não está conectada.');
    }
    final cfg   = config ?? LabelConfig();
    final total = dados.length * cfg.copiasPorItem;
    var impressas = 0;

    try {
      for (final d in dados) {
        final tspl = await _gerarTSPL(d, cfg);
        for (var i = 0; i < cfg.copiasPorItem; i++) {
          await _bt.writeBytes(tspl);
          // Aguarda a impressora processar — sem isso, jobs encavalam.
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

  // ─────────────────────────────────────────────────────────────────────
  //  REDE (TCP RAW :9100)
  // ─────────────────────────────────────────────────────────────────────

  /// Envia TSPL para uma impressora compartilhada na rede via TCP RAW.
  static Future<void> imprimirRede({
    required String host,
    int porta            = 9100,
    Duration timeout     = const Duration(seconds: 10),
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
      try { await socket?.close(); } catch (_) {}
    }
  }

  /// Valida um host como IPv4 dotted-quad ou hostname RFC1123 simples.
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

  /// Portas reservadas para serviços comuns — bloqueadas para evitar usar o
  /// app como vetor de envio de payload TSPL a serviços que não são
  /// impressoras (web, SSH, DB, etc.).
  static const Set<int> _portasReservadas = {
    22, 23, 25, 53, 80, 110, 143, 443, 445, 465, 587, 993, 995,
    1433, 1521, 2049, 3306, 3389, 5432, 5900, 6379, 8080, 8443,
    27017,
  };

  static bool portaValida(int porta) {
    if (porta < 1 || porta > 65535) return false;
    if (_portasReservadas.contains(porta)) return false;
    return true;
  }

  /// Persiste o último host/porta usado, pra UX.
  static Future<void> salvarUltimaImpressoraRede(String host, int porta) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GlpiConstants.prefImpressoraRedeHost, host.trim());
    await prefs.setInt(GlpiConstants.prefImpressoraRedePorta,   porta);
  }

  static Future<({String host, int porta})> ultimaImpressoraRede() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      host:  prefs.getString(GlpiConstants.prefImpressoraRedeHost) ?? '',
      porta: prefs.getInt(GlpiConstants.prefImpressoraRedePorta)  ?? 9100,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  PDF
  // ─────────────────────────────────────────────────────────────────────

  /// Gera os bytes de um PDF da etiqueta no tamanho definido em [config].
  static Future<Uint8List> gerarPdf(
    AssetLabelData d, {
    LabelConfig? config,
  }) async {
    final cfg = config ?? LabelConfig();
    final doc = pw.Document(
      title:   'Etiqueta ${d.hostname}',
      creator: 'GLPI Inventário',
    );

    final formato = PdfPageFormat(
      cfg.larguraMm * PdfPageFormat.mm,
      cfg.alturaMm  * PdfPageFormat.mm,
      marginAll:     1.5 * PdfPageFormat.mm,
    );

    final logoBytes = await _carregarLogoPng();

    // Uma página por cópia para que o diálogo do Android imprima o lote certo.
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

  /// Abre o diálogo nativo de impressão (Wi-Fi Direct, Cloud Print, salvar PDF…).
  static Future<void> imprimirPdf(
    AssetLabelData d, {
    LabelConfig? config,
  }) async {
    final bytes = await gerarPdf(d, config: config);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name:     'etiqueta_${_safeFilename(d.hostname)}',
    );
  }

  /// Compartilha o PDF (WhatsApp, email, salvar arquivo etc.).
  static Future<void> compartilharPdf(
    AssetLabelData d, {
    LabelConfig? config,
  }) async {
    final bytes = await gerarPdf(d, config: config);
    await Printing.sharePdf(
      bytes:    bytes,
      filename: 'etiqueta_${_safeFilename(d.hostname)}.pdf',
    );
  }

  /// Sanitiza um hostname para uso seguro em nome de arquivo PDF.
  static String _safeFilename(String raw) {
    var s = raw.trim().isEmpty ? 'etiqueta' : raw.trim();
    s = s.replaceAll(RegExp(r'[\x00-\x1F\x7F/\\:*?"<>|]'), '_');
    if (s.length > 60) s = s.substring(0, 60);
    return s;
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Helpers de geração
  // ─────────────────────────────────────────────────────────────────────

  /// Layout do PDF — espelha o layout TSPL: logo no topo, caixa com QR +
  /// linhas textuais, e AnyDesk em destaque no rodapé.
  static pw.Widget _layoutPdf(
    AssetLabelData d,
    LabelConfig    cfg,
    Uint8List?     logoBytes,
  ) {
    pw.Widget linha(String rotulo, String valor) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 0.6),
          child: pw.RichText(
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            text: pw.TextSpan(children: [
              pw.TextSpan(
                text:  rotulo,
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(
                text:  ' ${valor.trim().isEmpty ? '—' : valor}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ]),
          ),
        );

    final linhas = <pw.Widget>[
      if (cfg.mostrarHostname)     linha(d.rotuloHost,  d.hostname),
      if (cfg.mostrarUsuario)      linha('Usuário:',    d.usuario),
      if (cfg.mostrarDepartamento) linha('Depto.',      d.departamento),
      if (cfg.mostrarInventario)   linha('Inventário:', d.inventario),
      if (cfg.mostrarSerial)       linha('S/N:',        d.serial),
    ];

    final textoAny = d.anydesk.trim().isEmpty
        ? 'SEM ANYDESK'
        : 'ANYDESK: ${formatarAnydesk(d.anydesk)}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // ── 1. Logo no topo (centralizada) ──
        if (logoBytes != null)
          pw.Center(
            child: pw.SizedBox(
              height: cfg.alturaMm * 0.22 * PdfPageFormat.mm,
              child:  pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
            ),
          )
        else
          pw.Center(
            child: pw.Text(
              'UNIFEOB',
              style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold, letterSpacing: 1.3,
              ),
            ),
          ),

        pw.SizedBox(height: 2),

        // ── 2. Caixa com borda: QR + linhas textuais ──
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
                    width:  cfg.alturaMm * 0.36 * PdfPageFormat.mm,
                    height: cfg.alturaMm * 0.36 * PdfPageFormat.mm,
                    child: pw.BarcodeWidget(
                      barcode:  pw.Barcode.qrCode(),
                      data:     d.qrPayload.isEmpty
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
                    mainAxisAlignment:  pw.MainAxisAlignment.center,
                    children: linhas,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── 3. ANYDESK em destaque, fora da caixa ──
        if (cfg.mostrarAnydesk) ...[
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              child: pw.Text(
                textoAny,
                style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Monta o pacote TSPL (bytes) para impressoras térmicas a 203 dpi
  /// (8 dots/mm). Layout: logo gráfica no topo, caixa com QR + texto, e
  /// AnyDesk em fonte grande no rodapé.
  ///
  /// Retorna `Uint8List` (não `String`) porque o comando `BITMAP` da logo
  /// envia bytes binários puros — passar por `utf8.encode` corromperia a imagem.
  static Future<Uint8List> _gerarTSPL(
    AssetLabelData d,
    LabelConfig    cfg,
  ) async {
    final largDots = cfg.larguraMm * 8;
    final altDots  = cfg.alturaMm  * 8;
    const margem   = 16;
    final areaUtil = largDots - (margem * 2);

    final out = BytesBuilder();
    void txt(String s) => out.add(utf8.encode('$s\r\n'));

    txt('SIZE ${cfg.larguraMm} mm,${cfg.alturaMm} mm');
    txt('GAP 2 mm,0 mm');
    txt('DENSITY 8');
    txt('SPEED 4');
    txt('DIRECTION 0');
    txt('REFERENCE 0,0');
    txt('CLS');

    // ── 1. Logo gráfica (centralizada no topo) ──
    final logoLarguraAlvo = (areaUtil * 0.80).toInt();
    final logo = await _carregarLogoTspl(larguraDots: logoLarguraAlvo);
    int yPos = margem ~/ 2;
    if (logo != null) {
      final logoX = ((largDots - logo.widthDots) ~/ 2).clamp(0, largDots);
      txt('BITMAP $logoX,$yPos,${logo.widthBytes},${logo.heightDots},0,');
      out.add(logo.bytes);
      txt('');
      yPos += logo.heightDots + 8;
    } else {
      const txtCab = 'UNIFEOB';
      final xCab = ((largDots - txtCab.length * 24) ~/ 2).clamp(margem, largDots);
      txt('TEXT $xCab,$yPos,"5",0,1,1,"$txtCab"');
      yPos += 38;
    }

    // ── 2. Caixa com borda: QR à esquerda + texto à direita ──
    final yRodapeAny = cfg.mostrarAnydesk ? altDots - 56 : altDots - margem;
    final boxY1 = yPos;
    final boxY2 = yRodapeAny - 6;
    const boxX1 = margem;
    final boxX2 = largDots - margem;

    final boxAltura = boxY2 - boxY1;
    final temEspacoMiolo = boxAltura >= 40 && boxX2 > boxX1;

    if (temEspacoMiolo) {
      txt('BOX $boxX1,$boxY1,$boxX2,$boxY2,2');

      const padIn  = 8;
      final qrAlvo = (boxAltura - 16).clamp(60, 200);
      final qrCell = (qrAlvo ~/ 25).clamp(3, 8);

      int xTexto = boxX1 + padIn;
      if (cfg.mostrarQrCode) {
        txt('QRCODE ${boxX1 + padIn},${boxY1 + padIn},M,$qrCell,A,0,'
            '"${_escTSPL(d.qrPayload.isEmpty ? d.hostname : d.qrPayload, maxLen: 300)}"');
        xTexto = boxX1 + qrAlvo + padIn + 8;
      }

      final linhasVisiveis = <(String, String)>[
        if (cfg.mostrarHostname)     (d.rotuloHost,  d.hostname),
        if (cfg.mostrarUsuario)      ('Usuário:',    d.usuario),
        if (cfg.mostrarDepartamento) ('Depto.',      d.departamento),
        if (cfg.mostrarInventario)   ('Inventário:', d.inventario),
        if (cfg.mostrarSerial)       ('S/N:',        d.serial),
      ];

      if (linhasVisiveis.isNotEmpty) {
        const fontHeight = 24;
        final dyDesejado = (boxAltura - 16) ~/ linhasVisiveis.length;
        final dy = dyDesejado.clamp(fontHeight + 2, fontHeight + 14);
        var yLin = boxY1 + ((boxAltura - dy * linhasVisiveis.length) ~/ 2) + 2;
        for (final l in linhasVisiveis) {
          final valor = l.$2.trim().isEmpty ? '—' : l.$2;
          txt('TEXT $xTexto,$yLin,"3",0,1,1,"${_escTSPL('${l.$1} $valor')}"');
          yLin += dy;
        }
      }
    }

    // ── 3. ANYDESK em fonte grande (centralizado, fora da caixa) ──
    if (cfg.mostrarAnydesk) {
      final textoAny = d.anydesk.trim().isEmpty
          ? 'SEM ANYDESK'
          : 'ANYDESK: ${formatarAnydesk(d.anydesk)}';
      final presets = <({String font, int mag, int charW, int charH})>[
        (font: '5', mag: 2, charW: 48, charH: 64),
        (font: '5', mag: 1, charW: 24, charH: 32),
        (font: '4', mag: 1, charW: 12, charH: 18),
        (font: '3', mag: 1, charW: 16, charH: 24),
      ];
      final escolhida = presets.firstWhere(
        (p) => textoAny.length * p.charW <= areaUtil,
        orElse: () => presets.last,
      );
      final xAny = ((largDots - textoAny.length * escolhida.charW) ~/ 2)
          .clamp(margem, largDots - margem);
      final yAny = boxY2 + 6;
      txt('TEXT $xAny,$yAny,"${escolhida.font}",0,'
          '${escolhida.mag},${escolhida.mag},'
          '"${_escTSPL(textoAny)}"');
    }

    txt('PRINT 1,1');
    return out.toBytes();
  }

  /// Sanitiza string para uso dentro de TSPL `"..."`.
  ///
  /// O TSPL é orientado a linhas: `\r`/`\n` no meio de um valor fecha o
  /// comando atual e abre outro. Sem essa proteção, um hostname malicioso
  /// poderia injetar comandos na impressora. Estratégia: remove controles,
  /// trunca em 60 e escapa `\` e `"`.
  static String _escTSPL(String s, {int maxLen = 60}) {
    final semControle = s.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ');
    final truncado = semControle.length > maxLen
        ? semControle.substring(0, maxLen)
        : semControle;
    return truncado.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  }

  /// Formata uma data no padrão brasileiro `dd/MM/aaaa` (vazio → "").
  static String formatarDataBR(DateTime? d) {
    if (d == null) return '';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year}';
  }

  /// Formata um ID do AnyDesk em grupos de 3 dígitos (`928375646` →
  /// `928 375 646`). `''` → `—`.
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

  // ─────────────────────────────────────────────────────────────────────
  //  Logo (assets/images/Logo_preta.png)
  // ─────────────────────────────────────────────────────────────────────

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

  /// Lê a logo, redimensiona para [larguraDots] e converte para bitmap
  /// monocromático no formato do comando `BITMAP` do TSPL (0 = preto/imprime,
  /// 1 = branco; 8 pixels por byte, MSB-first).
  static Future<_LogoTspl?> _carregarLogoTspl({required int larguraDots}) async {
    if (_logoTsplCache.containsKey(larguraDots)) {
      return _logoTsplCache[larguraDots];
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

    final novaAltura = (src.height * larguraDots / src.width).round();
    final resized = img.copyResize(
      src,
      width:         larguraDots,
      height:        novaAltura,
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
        final p   = resized.getPixel(x, y);
        final lum = (p.r + p.g + p.b) / 3;
        final isDark = p.a > 128 && lum < 128;
        if (isDark) {
          final byteIdx = y * widthBytes + (x ~/ 8);
          final bitIdx  = 7 - (x % 8);
          bytes[byteIdx] &= ~(1 << bitIdx);
        }
      }
    }

    final cache = _LogoTspl(
      bytes:      bytes,
      widthBytes: widthBytes,
      widthDots:  w,
      heightDots: h,
    );
    _logoTsplCache[larguraDots] = cache;
    return cache;
  }
}

/// Bitmap monocromático pronto para o comando `BITMAP` do TSPL.
class _LogoTspl {
  final Uint8List bytes;
  final int       widthBytes;
  final int       widthDots;
  final int       heightDots;

  const _LogoTspl({
    required this.bytes,
    required this.widthBytes,
    required this.widthDots,
    required this.heightDots,
  });
}
