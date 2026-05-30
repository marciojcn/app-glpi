import 'package:flutter/material.dart';

import 'src/pages/login_page.dart';
import 'src/widgets/widgets.dart';

/// Raiz do app: `MaterialApp` com o tema Unifeob e a tela inicial de login.
class AppGlpi extends StatelessWidget {
  const AppGlpi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GLPI Inventário',
      debugShowCheckedModeBanner: false,
      theme: GlpiTheme.themeData,
      home: const LoginPage(),
    );
  }
}

/// Transição padrão de navegação: slide 4% + fade-in (300ms).
///
/// Todos os `Navigator.push` do app usam isto para um movimento consistente.
Route<T> transicaoPadrao<T>(Widget pagina) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => pagina,
    transitionsBuilder: (_, animation, __, child) {
      final curva = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curva,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end:   Offset.zero,
          ).animate(curva),
          child: child,
        ),
      );
    },
  );
}
