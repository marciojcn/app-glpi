import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glpi_theme.dart';

/// Diálogos padronizados.
class GlpiDialog {
  GlpiDialog._();

  /// Diálogo de confirmação. Retorna `true` se o usuário confirmou.
  static Future<bool> confirmar(
    BuildContext context, {
    required String titulo,
    required String mensagem,
    String labelConfirmar = 'CONFIRMAR',
    String labelCancelar  = 'CANCELAR',
    bool   destrutivo     = false,
    IconData? icone,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlpiTheme.borderRadius),
        ),
        title: Row(
          children: [
            Icon(
              icone ??
                  (destrutivo
                      ? Icons.warning_amber_rounded
                      : Icons.help_outline_rounded),
              color: destrutivo ? GlpiTheme.glpiError : GlpiTheme.glpiPrimary,
              size:  22,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(titulo, style: const TextStyle(fontSize: 17))),
          ],
        ),
        content: Text(mensagem, style: const TextStyle(fontSize: 14, height: 1.4)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(ctx, false);
            },
            child: Text(labelCancelar),
          ),
          if (destrutivo)
            ElevatedButton.icon(
              icon:  const Icon(Icons.logout_rounded, size: 18),
              label: Text(labelConfirmar),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlpiTheme.glpiError,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GlpiTheme.borderRadius),
                ),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx, true);
              },
            )
          else
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx, true);
              },
              child: Text(labelConfirmar),
            ),
        ],
      ),
    );
    return ok ?? false;
  }
}
