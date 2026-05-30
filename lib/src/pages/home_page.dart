import 'package:flutter/material.dart';

import '../../app_glpi.dart';
import '../models/asset_tipo.dart';
import '../services/auth_service.dart';
import '../widgets/widgets.dart';
import 'inventory/asset_list_page.dart';
import 'login_page.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _sair(BuildContext context) async {
    final ok = await GlpiDialog.confirmar(
      context,
      titulo: 'Sair',
      mensagem: 'Deseja encerrar a sessão?',
      labelConfirmar: 'SAIR',
      destrutivo: true,
      icone: Icons.logout_rounded,
    );
    if (!ok || !context.mounted) return;
    AuthService.instance.logout();
    Navigator.pushAndRemoveUntil(
      context,
      transicaoPadrao(const LoginPage()),
      (_) => false,
    );
  }

  void _abrir(BuildContext context, AssetTipo tipo) {
    Navigator.push(context, transicaoPadrao(AssetListPage(tipo: tipo)));
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.instance.usuarioAtual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GLPI Inventário'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () =>
                Navigator.push(context, transicaoPadrao(const SettingsPage())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
            onPressed: () => _sair(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              usuario.isEmpty ? 'Olá!' : 'Olá, $usuario',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            const Text(
              'Selecione um inventário para consultar e imprimir etiquetas.',
              style:
                  TextStyle(fontSize: 13, color: GlpiTheme.glpiTextSecondary),
            ),
            const SizedBox(height: 20),
            _CardInventario(
              titulo: 'Computadores',
              subtitulo: 'Desktops e notebooks',
              icone: Icons.computer_rounded,
              onTap: () => _abrir(context, AssetTipo.computador),
            ),
            const SizedBox(height: 12),
            _CardInventario(
              titulo: 'Celulares',
              subtitulo: 'Smartphones corporativos',
              icone: Icons.smartphone_rounded,
              onTap: () => _abrir(context, AssetTipo.celular),
            ),
            const SizedBox(height: 40),
            const Center(
                child:
                    UnifeobLogo(height: 28, cor: GlpiTheme.glpiTextDisabled)),
          ],
        ),
      ),
    );
  }
}

class _CardInventario extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final VoidCallback onTap;

  const _CardInventario({
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlpiCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GlpiTheme.glpiPrimary.withAlpha(28),
              borderRadius: BorderRadius.circular(GlpiTheme.borderRadius),
            ),
            child: Icon(icone, color: GlpiTheme.glpiPrimary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: GlpiTheme.glpiTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GlpiTheme.glpiTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: GlpiTheme.glpiTextSecondary),
        ],
      ),
    );
  }
}
