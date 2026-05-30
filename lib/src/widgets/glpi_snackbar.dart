import 'package:flutter/material.dart';

import 'glpi_theme.dart';

/// Helper de SnackBar padronizado.
///
/// - Floating, 12px de raio.
/// - Sempre 1 por vez (chama `hideCurrentSnackBar` antes).
/// - Cor depende do tipo: sucesso (verde), erro (vermelho), aviso (laranja),
///   info (azul).
class GlpiSnackbar {
  GlpiSnackbar._();

  static void sucesso(BuildContext context, String mensagem) =>
      _exibir(context, mensagem,
          fundo: GlpiTheme.glpiSuccess, icone: Icons.check_circle_rounded);

  static void erro(BuildContext context, String mensagem) =>
      _exibir(context, mensagem,
          fundo: GlpiTheme.glpiError, icone: Icons.error_rounded);

  static void aviso(BuildContext context, String mensagem) =>
      _exibir(context, mensagem,
          fundo: GlpiTheme.glpiWarning, icone: Icons.warning_amber_rounded);

  static void info(BuildContext context, String mensagem) =>
      _exibir(context, mensagem,
          fundo: GlpiTheme.glpiInfo, icone: Icons.info_outline_rounded);

  static void _exibir(
    BuildContext context,
    String mensagem, {
    required Color    fundo,
    required IconData icone,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: fundo,
        behavior:        SnackBarBehavior.floating,
        margin:          const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlpiTheme.borderRadius),
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icone, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
