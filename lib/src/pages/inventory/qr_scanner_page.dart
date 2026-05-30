import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/glpi_audio.dart';

class QrScannerPage extends StatefulWidget {
  final String titulo;

  const QrScannerPage({super.key, this.titulo = 'Escanear etiqueta'});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with SingleTickerProviderStateMixin {
  final _controller = MobileScannerController();

  bool _detectado = false;
  bool _lanterna = false;
  String? _ultimoCodigo;

  late AnimationController _animController;
  late Animation<double> _opacidadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _opacidadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_detectado) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final codigo = barcodes.first.rawValue ?? '';
    if (codigo.isEmpty) return;

    _detectado = true;
    _ultimoCodigo = codigo;

    GlpiAudio.beep();
    await _animController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (mounted) Navigator.pop(context, codigo);
  }

  Future<void> _toggleLanterna() async {
    HapticFeedback.selectionClick();
    await _controller.toggleTorch();
    if (mounted) setState(() => _lanterna = !_lanterna);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanWindow = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: size.width * 0.72,
      height: size.width * 0.45,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.titulo,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _lanterna
                  ? Icons.flashlight_on_rounded
                  : Icons.flashlight_off_rounded,
              color: _lanterna ? Colors.yellow : Colors.white70,
            ),
            tooltip: _lanterna ? 'Apagar lanterna' : 'Acender lanterna',
            onPressed: _toggleLanterna,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            scanWindow: scanWindow,
            onDetect: _onDetect,
          ),
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withAlpha(179),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Positioned(
                  left: scanWindow.left,
                  top: scanWindow.top,
                  width: scanWindow.width,
                  height: scanWindow.height,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: scanWindow.left,
            top: scanWindow.top,
            width: scanWindow.width,
            height: scanWindow.height,
            child: AnimatedBuilder(
              animation: _opacidadeAnim,
              builder: (_, __) {
                final cor = Color.lerp(
                  Colors.white,
                  Colors.green.shade400,
                  _opacidadeAnim.value,
                )!;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cor, width: _detectado ? 4 : 2.5),
                    color: _detectado
                        ? Colors.green.withAlpha(30)
                        : Colors.transparent,
                  ),
                );
              },
            ),
          ),
          if (!_detectado) _LinhaScanAnimada(scanWindow: scanWindow),
          Positioned(
            top: scanWindow.bottom + 28,
            left: 24,
            right: 24,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _detectado
                  ? Column(
                      key: const ValueKey('ok'),
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.green.shade400, size: 36),
                        const SizedBox(height: 10),
                        Text(
                          _ultimoCodigo ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Código lido com sucesso!',
                            style: TextStyle(
                                color: Colors.green.shade300, fontSize: 13)),
                      ],
                    )
                  : Column(
                      key: const ValueKey('aguardando'),
                      children: [
                        Text(
                          'Aponte para o QR code da etiqueta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withAlpha(220),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Apenas o que estiver dentro do quadro é lido',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withAlpha(120), fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ),
          Positioned(
            bottom: 48 + MediaQuery.of(context).viewPadding.bottom,
            left: 32,
            right: 32,
            child: TextButton.icon(
              onPressed: _digitarManualmente,
              icon: const Icon(Icons.keyboard_rounded, color: Colors.white70),
              label: const Text(
                'Digitar código manualmente',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _digitarManualmente() async {
    HapticFeedback.selectionClick();
    final editController = TextEditingController();

    final codigo = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Digitar código',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Conteúdo da etiqueta',
            prefixIcon: Icon(Icons.qr_code_rounded),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(dialogCtx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogCtx, editController.text.trim()),
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );

    editController.dispose();
    if (codigo != null && codigo.isNotEmpty && mounted) {
      Navigator.pop(context, codigo);
    }
  }
}

class _LinhaScanAnimada extends StatefulWidget {
  final Rect scanWindow;
  const _LinhaScanAnimada({required this.scanWindow});

  @override
  State<_LinhaScanAnimada> createState() => _LinhaScanAnimadaState();
}

class _LinhaScanAnimadaState extends State<_LinhaScanAnimada>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final y =
            widget.scanWindow.top + _anim.value * widget.scanWindow.height;
        return Positioned(
          left: widget.scanWindow.left + 12,
          top: y,
          width: widget.scanWindow.width - 24,
          height: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.green.shade400.withAlpha(200),
                  Colors.green.shade400,
                  Colors.green.shade400.withAlpha(200),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }
}
