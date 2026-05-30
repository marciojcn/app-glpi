import 'package:flutter/material.dart';

import '../../app_glpi.dart';
import '../models/label_config.dart';
import '../services/auth_service.dart';
import '../widgets/widgets.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  LabelConfig _config = LabelConfig();
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final c = await LabelConfig.carregar();
    if (!mounted) return;
    setState(() {
      _config = c;
      _carregando = false;
    });
  }

  Future<void> _salvar() async {
    await _config.salvar();
    if (!mounted) return;
    GlpiSnackbar.sucesso(context, 'Configurações salvas.');
  }

  Future<void> _restaurar() async {
    await _config.resetar();
    if (!mounted) return;
    setState(() {});
    GlpiSnackbar.info(context, 'Layout restaurado para o padrão.');
  }

  Future<void> _sair() async {
    final ok = await GlpiDialog.confirmar(
      context,
      titulo: 'Sair',
      mensagem: 'Deseja encerrar a sessão?',
      labelConfirmar: 'SAIR',
      destrutivo: true,
      icone: Icons.logout_rounded,
    );
    if (!ok || !mounted) return;
    AuthService.instance.logout();
    Navigator.pushAndRemoveUntil(
      context,
      transicaoPadrao(const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            tooltip: 'Salvar',
            onPressed: _carregando ? null : _salvar,
          ),
        ],
      ),
      body: SafeArea(
        child: _carregando
            ? const GlpiLoadingSpinner(mensagem: 'Carregando…')
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _cardDimensoes(),
                  const SizedBox(height: 12),
                  _cardCampos(),
                  const SizedBox(height: 16),
                  GlpiButton(
                    label: 'SALVAR',
                    icon: Icons.save_rounded,
                    onPressed: _salvar,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: GlpiTextButton(
                      label: 'Restaurar padrão',
                      icon: Icons.restart_alt_rounded,
                      onPressed: _restaurar,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _cardConta(),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'GLPI Inventário · v1.0.0 · Unifeob',
                      style: TextStyle(
                          fontSize: 12, color: GlpiTheme.glpiTextDisabled),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _cardDimensoes() {
    return GlpiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tituloSecao(Icons.straighten_rounded, 'Dimensões da etiqueta'),
          _slider(
            rotulo: 'Largura',
            valor: _config.larguraMm.toDouble(),
            min: 20,
            max: 100,
            onChanged: (v) => setState(() => _config.larguraMm = v.round()),
          ),
          _slider(
            rotulo: 'Altura',
            valor: _config.alturaMm.toDouble(),
            min: 15,
            max: 80,
            onChanged: (v) => setState(() => _config.alturaMm = v.round()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.copy_all_rounded,
                  size: 18, color: GlpiTheme.glpiTextSecondary),
              const SizedBox(width: 8),
              const Expanded(
                  child:
                      Text('Cópias por item', style: TextStyle(fontSize: 14))),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: GlpiTheme.glpiPrimary,
                onPressed: _config.copiasPorItem <= 1
                    ? null
                    : () => setState(() => _config.copiasPorItem--),
              ),
              Text('${_config.copiasPorItem}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: GlpiTheme.glpiPrimary,
                onPressed: _config.copiasPorItem >= 99
                    ? null
                    : () => setState(() => _config.copiasPorItem++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardCampos() {
    return GlpiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tituloSecao(Icons.tune_rounded, 'Campos na etiqueta'),
          _switch('QR code', _config.mostrarQrCode,
              (v) => _config.mostrarQrCode = v),
          _switch('Hostname', _config.mostrarHostname,
              (v) => _config.mostrarHostname = v),
          _switch('Usuário', _config.mostrarUsuario,
              (v) => _config.mostrarUsuario = v),
          _switch('Departamento', _config.mostrarDepartamento,
              (v) => _config.mostrarDepartamento = v),
          _switch('Inventário', _config.mostrarInventario,
              (v) => _config.mostrarInventario = v),
          _switch('Serial (S/N)', _config.mostrarSerial,
              (v) => _config.mostrarSerial = v),
          _switch('AnyDesk', _config.mostrarAnydesk,
              (v) => _config.mostrarAnydesk = v),
        ],
      ),
    );
  }

  Widget _cardConta() {
    final usuario = AuthService.instance.usuarioAtual;
    return GlpiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tituloSecao(Icons.account_circle_outlined, 'Conta'),
          if (usuario.isNotEmpty)
            GlpiDetailRow('Usuário', usuario,
                icone: Icons.person_outline_rounded),
          const SizedBox(height: 10),
          GlpiDestructiveButton(
            label: 'SAIR',
            icon: Icons.logout_rounded,
            height: 46,
            onPressed: _sair,
          ),
        ],
      ),
    );
  }

  Widget _tituloSecao(IconData icone, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icone, size: 18, color: GlpiTheme.glpiPrimary),
          const SizedBox(width: 8),
          Text(texto,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _slider({
    required String rotulo,
    required double valor,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(rotulo,
              style: const TextStyle(
                  fontSize: 13, color: GlpiTheme.glpiTextSecondary)),
        ),
        Expanded(
          child: Slider(
            value: valor.clamp(min, max),
            min: min,
            max: max,
            divisions: (max - min).round(),
            activeColor: GlpiTheme.glpiPrimary,
            label: '${valor.round()} mm',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text('${valor.round()} mm',
              textAlign: TextAlign.right,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _switch(String rotulo, bool valor, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      value: valor,
      title: Text(rotulo, style: const TextStyle(fontSize: 14)),
      onChanged: (v) => setState(() => onChanged(v)),
    );
  }
}
