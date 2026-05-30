import 'package:barcode_widget/barcode_widget.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/glpi_exception.dart';
import '../models/asset.dart';
import '../models/asset_tipo.dart';
import '../models/label_config.dart';
import '../services/asset_service.dart';
import '../services/label_print_service.dart';
import '../widgets/widgets.dart';

/// Tela de impressão de etiqueta com QR code via impressora Bluetooth.
///
/// Mostra um preview da etiqueta, deixa escolher a impressora Bluetooth
/// pareada, e imprime (TSPL). Como alternativa, gera/compartilha um PDF no
/// mesmo tamanho. O layout (campos e dimensões) vem de [LabelConfig], editável
/// em Configurações.
class EtiquetaPage extends StatefulWidget {
  final Asset asset;
  const EtiquetaPage({super.key, required this.asset});

  @override
  State<EtiquetaPage> createState() => _EtiquetaPageState();
}

class _EtiquetaPageState extends State<EtiquetaPage> {
  final _anydeskCtrl = TextEditingController();

  LabelConfig            _config       = LabelConfig();
  List<BluetoothDevice>  _impressoras  = [];
  BluetoothDevice?       _selecionada;
  bool _conectada            = false;
  bool _carregandoImpressoras = false;
  bool _ocupado              = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _anydeskCtrl.dispose();
    super.dispose();
  }

  // ── Dados ───────────────────────────────────────────────────────────────

  Future<void> _carregar() async {
    _config = await LabelConfig.carregar();
    if (!mounted) return;
    setState(() {});
    await _carregarImpressoras();
  }

  Future<bool> _garantirPermissao() async {
    final res = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
    // Em Android < 12 essas permissões já vêm concedidas (install-time).
    return res.values.every((s) => s.isGranted || s.isLimited || s.isRestricted);
  }

  Future<void> _carregarImpressoras() async {
    setState(() => _carregandoImpressoras = true);
    try {
      final permitido = await _garantirPermissao();
      if (!permitido) {
        if (!mounted) return;
        GlpiSnackbar.aviso(context, 'Permissão de Bluetooth necessária para imprimir.');
        return;
      }
      if (!await LabelPrintService.bluetoothLigado()) {
        if (!mounted) return;
        GlpiSnackbar.aviso(context, 'Ligue o Bluetooth para listar impressoras.');
      }
      final lista     = await LabelPrintService.dispositivosPareados();
      final conectada = await LabelPrintService.bluetoothConectado();
      if (!mounted) return;
      setState(() {
        _impressoras = lista;
        _selecionada ??= lista.isNotEmpty ? lista.first : null;
        _conectada   = conectada;
      });
    } on GlpiException catch (e) {
      if (!mounted) return;
      GlpiSnackbar.erro(context, e.mensagem);
    } catch (e) {
      if (kDebugMode) debugPrint('EtiquetaPage._carregarImpressoras: $e');
    } finally {
      if (mounted) setState(() => _carregandoImpressoras = false);
    }
  }

  AssetLabelData _dados() {
    final a = widget.asset;
    final ehCelular = a.tipo == AssetTipo.celular;
    // QR = "URL do ativo" do GLPI → ao escanear, abre o item por id (sem
    // ambiguidade de nome). Cai para o hostname só se o servidor não estiver
    // configurado.
    final urlQr = AssetService.urlAtivo(a.tipo, a.id);
    return AssetLabelData(
      hostname:     a.nome,
      usuario:      a.usuario,
      departamento: a.grupo,
      // Data do último inventário no padrão BR (dd/MM/aaaa).
      inventario:   LabelPrintService.formatarDataBR(a.dataInventario),
      // S/N = etiqueta de serviço (Dell/Lenovo); no celular, cai para o IMEI.
      serial:       a.serial.isNotEmpty ? a.serial : a.imei,
      anydesk:      _anydeskCtrl.text.trim(),
      qrPayload:    urlQr.isNotEmpty ? urlQr : a.qrPayload,
      rotuloHost:   ehCelular ? 'Nome:' : 'Hostname:',
    );
  }

  Future<void> _imprimirBluetooth() async {
    if (_selecionada == null) {
      GlpiSnackbar.aviso(context, 'Selecione uma impressora Bluetooth pareada.');
      return;
    }
    setState(() => _ocupado = true);
    try {
      if (!await LabelPrintService.bluetoothConectado()) {
        await LabelPrintService.bluetoothConectar(_selecionada!);
      }
      if (!mounted) return;
      setState(() => _conectada = true);
      await LabelPrintService.imprimirBluetooth(_dados(), config: _config);
      if (!mounted) return;
      GlpiSnackbar.sucesso(
        context,
        _config.copiasPorItem > 1
            ? '${_config.copiasPorItem} etiquetas enviadas.'
            : 'Etiqueta enviada para impressão.',
      );
    } on GlpiException catch (e) {
      if (!mounted) return;
      setState(() => _conectada = false);
      GlpiSnackbar.erro(context, e.mensagem);
    } catch (e) {
      if (kDebugMode) debugPrint('EtiquetaPage._imprimirBluetooth: $e');
      if (!mounted) return;
      GlpiSnackbar.erro(context, 'Falha ao imprimir. Verifique a impressora.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _imprimirPdf() async {
    setState(() => _ocupado = true);
    try {
      await LabelPrintService.imprimirPdf(_dados(), config: _config);
    } catch (e) {
      if (kDebugMode) debugPrint('EtiquetaPage._imprimirPdf: $e');
      if (!mounted) return;
      GlpiSnackbar.erro(context, 'Não foi possível gerar o PDF.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _compartilharPdf() async {
    setState(() => _ocupado = true);
    try {
      await LabelPrintService.compartilharPdf(_dados(), config: _config);
    } catch (e) {
      if (kDebugMode) debugPrint('EtiquetaPage._compartilharPdf: $e');
      if (!mounted) return;
      GlpiSnackbar.erro(context, 'Não foi possível compartilhar o PDF.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Imprimir etiqueta')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _preview(),
            const SizedBox(height: 16),
            GlpiTextField(
              controller:  _anydeskCtrl,
              labelText:   'ID AnyDesk (opcional)',
              prefixIcon:  Icons.support_agent_rounded,
              keyboardType: TextInputType.number,
              onChanged:   (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _cardCopias(),
            const SizedBox(height: 16),
            _cardImpressora(),
            const SizedBox(height: 20),
            GlpiButton(
              label:     'IMPRIMIR (BLUETOOTH)',
              icon:      Icons.print_rounded,
              loading:   _ocupado,
              onPressed: _ocupado ? null : _imprimirBluetooth,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GlpiOutlinedButton(
                    label:     'PDF',
                    icon:      Icons.picture_as_pdf_outlined,
                    height:    46,
                    onPressed: _ocupado ? null : _imprimirPdf,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlpiOutlinedButton(
                    label:     'COMPARTILHAR',
                    icon:      Icons.share_outlined,
                    height:    46,
                    onPressed: _ocupado ? null : _compartilharPdf,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview() {
    final d = _dados();
    final linhas = <Widget>[
      if (_config.mostrarHostname)     _linhaPreview(d.rotuloHost, d.hostname),
      if (_config.mostrarUsuario)      _linhaPreview('Usuário:', d.usuario),
      if (_config.mostrarDepartamento) _linhaPreview('Depto.', d.departamento),
      if (_config.mostrarInventario)   _linhaPreview('Inventário:', d.inventario),
      if (_config.mostrarSerial)       _linhaPreview('S/N:', d.serial),
    ];
    final anydesk = d.anydesk;

    return GlpiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: UnifeobLogo(height: 20)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border:       Border.all(color: GlpiTheme.glpiBorderStrong),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_config.mostrarQrCode) ...[
                  BarcodeWidget(
                    barcode:  Barcode.qrCode(),
                    data:     d.qrPayload.isEmpty ? '—' : d.qrPayload,
                    width:    78,
                    height:   78,
                    drawText: false,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:  MainAxisAlignment.center,
                    children: linhas.isEmpty
                        ? [const Text('—')]
                        : linhas,
                  ),
                ),
              ],
            ),
          ),
          if (_config.mostrarAnydesk) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                anydesk.isEmpty
                    ? 'SEM ANYDESK'
                    : 'ANYDESK: ${LabelPrintService.formatarAnydesk(anydesk)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16,
                  color: GlpiTheme.glpiTextPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Pré-visualização · ${_config.larguraMm}×${_config.alturaMm} mm',
              style: const TextStyle(
                fontSize: 11, color: GlpiTheme.glpiTextDisabled,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaPreview(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: GlpiTheme.glpiTextPrimary),
          children: [
            TextSpan(text: rotulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: ' ${valor.trim().isEmpty ? '—' : valor}'),
          ],
        ),
      ),
    );
  }

  Widget _cardCopias() {
    return GlpiCard(
      child: Row(
        children: [
          const Icon(Icons.copy_all_rounded, color: GlpiTheme.glpiPrimary, size: 20),
          const SizedBox(width: 10),
          const Expanded(child: Text('Cópias por etiqueta', style: TextStyle(fontSize: 14))),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: GlpiTheme.glpiPrimary,
            onPressed: _config.copiasPorItem <= 1
                ? null
                : () => setState(() => _config.copiasPorItem--),
          ),
          Text(
            '${_config.copiasPorItem}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: GlpiTheme.glpiPrimary,
            onPressed: _config.copiasPorItem >= 99
                ? null
                : () => setState(() => _config.copiasPorItem++),
          ),
        ],
      ),
    );
  }

  Widget _cardImpressora() {
    return GlpiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.bluetooth_rounded, color: GlpiTheme.glpiPrimary, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Impressora Bluetooth', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              if (_conectada)
                const _ChipStatus(texto: 'Conectada', cor: GlpiTheme.glpiSuccess)
              else
                const _ChipStatus(texto: 'Desconectada', cor: GlpiTheme.glpiTextSecondary),
              IconButton(
                icon: _carregandoImpressoras
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.refresh_rounded),
                tooltip: 'Atualizar lista',
                onPressed: _carregandoImpressoras ? null : _carregarImpressoras,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_impressoras.isEmpty)
            const Text(
              'Nenhuma impressora pareada. Pareie a impressora pelo Bluetooth do Android e toque em atualizar.',
              style: TextStyle(fontSize: 12, color: GlpiTheme.glpiTextSecondary),
            )
          else
            DropdownButtonFormField<BluetoothDevice>(
              initialValue: _selecionada,
              isExpanded:   true,
              decoration: const InputDecoration(
                labelText: 'Selecione a impressora',
                prefixIcon: Icon(Icons.print_outlined),
              ),
              items: _impressoras
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(
                          d.name?.isNotEmpty == true ? d.name! : (d.address ?? 'Impressora'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (d) => setState(() {
                _selecionada = d;
                _conectada   = false;
              }),
            ),
        ],
      ),
    );
  }
}

class _ChipStatus extends StatelessWidget {
  final String texto;
  final Color  cor;
  const _ChipStatus({required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        cor.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cor),
      ),
    );
  }
}
