import 'package:flutter/material.dart';

import 'glpi_theme.dart';

/// Spinner com mensagem opcional ao centro.
class GlpiLoadingSpinner extends StatelessWidget {
  final String? mensagem;

  const GlpiLoadingSpinner({super.key, this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36, height: 36,
            child: CircularProgressIndicator(strokeWidth: 3, color: GlpiTheme.glpiPrimary),
          ),
          if (mensagem != null) ...[
            const SizedBox(height: 14),
            Text(
              mensagem!,
              style: const TextStyle(color: GlpiTheme.glpiTextSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

/// Barra fina de loading horizontal.
class GlpiLinearLoading extends StatelessWidget {
  const GlpiLinearLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: const LinearProgressIndicator(
        minHeight:       4,
        backgroundColor: GlpiTheme.glpiBorderLight,
        valueColor:      AlwaysStoppedAnimation(GlpiTheme.glpiPrimary),
      ),
    );
  }
}

// ─── Skeletons ────────────────────────────────────────────────────────────

/// Card "fantasma" com pulse de opacidade — usado no loading inicial.
class GlpiSkeletonCard extends StatefulWidget {
  final double height;
  const GlpiSkeletonCard({super.key, this.height = 78});

  @override
  State<GlpiSkeletonCard> createState() => _GlpiSkeletonCardState();
}

class _GlpiSkeletonCardState extends State<GlpiSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = 0.3 + 0.4 * _ctrl.value; // 0.3 ↔ 0.7
        return Opacity(
          opacity: t,
          child: Container(
            height: widget.height,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color:        GlpiTheme.glpiBorderLight,
              borderRadius: BorderRadius.circular(GlpiTheme.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

/// Lista de N skeleton cards. Use no loading inicial de listas.
class GlpiSkeletonList extends StatelessWidget {
  final int  quantidade;
  final bool expandir;

  const GlpiSkeletonList({
    super.key,
    this.quantidade = 6,
    this.expandir   = true,
  });

  @override
  Widget build(BuildContext context) {
    final lista = ListView.builder(
      padding:     const EdgeInsets.all(16),
      itemCount:   quantidade,
      itemBuilder: (_, __) => const GlpiSkeletonCard(),
    );
    return expandir ? lista : SizedBox(height: 360, child: lista);
  }
}
