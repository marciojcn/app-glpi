import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glpi_theme.dart';

/// Container base padrão. Todos os cards do app usam este como raiz.
class GlpiCard extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color?             borderColor;
  final VoidCallback?      onTap;
  final Widget             child;

  const GlpiCard({
    super.key,
    this.padding = const EdgeInsets.all(GlpiTheme.cardPaddingDefault),
    this.margin  = const EdgeInsets.only(bottom: 8),
    this.borderColor,
    this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cor = borderColor ?? GlpiTheme.glpiBorderLight;

    return Container(
      margin:  margin,
      padding: onTap != null ? EdgeInsets.zero : padding,
      decoration: BoxDecoration(
        color:        GlpiTheme.glpiSurface,
        borderRadius: BorderRadius.circular(GlpiTheme.borderRadius),
        border:       Border.all(color: cor),
      ),
      child: onTap == null
          ? child
          : Material(
              color:        Colors.transparent,
              borderRadius: BorderRadius.circular(GlpiTheme.borderRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(GlpiTheme.borderRadius),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
                child: Padding(padding: padding, child: child),
              ),
            ),
    );
  }
}

/// Linha rótulo:valor para detalhe de item.
class GlpiDetailRow extends StatelessWidget {
  final String    rotulo;
  final String    valor;
  final bool      destaque;
  final IconData? icone;

  const GlpiDetailRow(
    this.rotulo,
    this.valor, {
    super.key,
    this.destaque = false,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 16, color: GlpiTheme.glpiTextSecondary),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 120,
            child: Text(
              rotulo,
              style: const TextStyle(
                fontSize:   13,
                color:      GlpiTheme.glpiTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor.isEmpty ? '—' : valor,
              style: TextStyle(
                fontSize:   destaque ? 15 : 14,
                fontWeight: destaque ? FontWeight.w600 : FontWeight.w400,
                color:      GlpiTheme.glpiTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de seção com título e lista de [GlpiDetailRow].
class GlpiSectionCard extends StatelessWidget {
  final String       titulo;
  final IconData?    icone;
  final List<Widget> linhas;

  const GlpiSectionCard({
    super.key,
    required this.titulo,
    this.icone,
    required this.linhas,
  });

  @override
  Widget build(BuildContext context) {
    return GlpiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icone != null) ...[
                Icon(icone, size: 18, color: GlpiTheme.glpiPrimary),
                const SizedBox(width: 8),
              ],
              Text(
                titulo,
                style: const TextStyle(
                  fontSize:   15,
                  fontWeight: FontWeight.w600,
                  color:      GlpiTheme.glpiTextPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 18, thickness: 1, color: GlpiTheme.glpiBorderLight),
          ...linhas,
        ],
      ),
    );
  }
}

/// Cabeçalho destacado de detalhe de ativo (gradiente indigo Unifeob).
class GlpiAssetHeaderCard extends StatelessWidget {
  final String   nome;
  final String   tipo;
  final String?  serial;
  final String?  status;
  final String?  localizacao;
  final String?  usuario;
  final IconData icone;

  const GlpiAssetHeaderCard({
    super.key,
    required this.nome,
    required this.tipo,
    this.serial,
    this.status,
    this.localizacao,
    this.usuario,
    this.icone = Icons.devices_other_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [GlpiTheme.glpiPrimary, GlpiTheme.glpiPrimaryDark],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(GlpiTheme.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:        Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      tipo,
                      style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (status != null && status!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:        Colors.white.withAlpha(60),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status!,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (serial != null || localizacao != null || usuario != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing:    14,
              runSpacing: 6,
              children: [
                if (serial != null && serial!.isNotEmpty)
                  _info(Icons.confirmation_number_outlined, serial!),
                if (localizacao != null && localizacao!.isNotEmpty)
                  _info(Icons.location_on_outlined, localizacao!),
                if (usuario != null && usuario!.isNotEmpty)
                  _info(Icons.person_outline_rounded, usuario!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _info(IconData ic, String txt) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ic, color: Colors.white.withAlpha(220), size: 14),
          const SizedBox(width: 4),
          Text(txt, style: TextStyle(color: Colors.white.withAlpha(230), fontSize: 12)),
        ],
      );
}
