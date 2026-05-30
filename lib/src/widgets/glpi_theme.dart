import 'package:flutter/material.dart';

/// Tema visual do app — **Identidade Visual da Unifeob** (projeto customizado).
///
/// Paleta:
/// - Azul elétrico (#0018FE): cor-assinatura (o ponto da logo)
/// - Indigo profundo (#241C84): áreas escuras / AppBar (fundo do hero)
/// - Amarelo (#FFE000): destaque (Vestiba Day / fita "X")
/// - Magenta (#FF1F5A): ação de destaque (CTA do site)
///
/// Border radius padrão: 12px. Botões Glpi*: 54px de altura.
class GlpiTheme {
  GlpiTheme._();

  // ── Identidade Visual Unifeob ───────────────────────────────────────────
  /// Azul elétrico Unifeob (cor principal da marca — o ponto da logo).
  static const Color unifeobAzul    = Color(0xFF0018FE);
  /// Indigo profundo (fundo do hero / AppBar).
  static const Color unifeobIndigo  = Color(0xFF241C84);
  /// Amarelo Unifeob (destaque).
  static const Color unifeobAmarelo = Color(0xFFFFE000);
  /// Magenta/rosa Unifeob (ação de destaque).
  static const Color unifeobRosa    = Color(0xFFFF1F5A);
  /// Cinza muito claro (apoio).
  static const Color unifeobCinza   = Color(0xFFEEF0FB);

  // ── Primárias ───────────────────────────────────────────────────────────
  static const Color glpiPrimary      = unifeobAzul;
  static const Color glpiPrimaryDark  = unifeobIndigo;
  static const Color glpiPrimaryLight = Color(0xFF5B6BFF);
  static const Color glpiAccent       = unifeobRosa;

  // ── Status ──────────────────────────────────────────────────────────────
  static const Color glpiSuccess           = Color(0xFF2E7D32);
  static const Color glpiSuccessBackground = Color(0xFFE8F5E9);
  static const Color glpiWarning           = Color(0xFFEF6C00);
  static const Color glpiWarningBackground = Color(0xFFFFF3E0);
  static const Color glpiError             = Color(0xFFC62828);
  static const Color glpiErrorBackground   = Color(0xFFFFEBEE);
  static const Color glpiInfo              = unifeobAzul;
  static const Color glpiInfoBackground    = Color(0xFFE7E9FF);

  // ── Superfícies ─────────────────────────────────────────────────────────
  static const Color glpiBackground = Color(0xFFF2F3FC);
  static const Color glpiSurface    = Color(0xFFFFFFFF);

  // ── Bordas ──────────────────────────────────────────────────────────────
  static const Color glpiBorder       = Color(0xFFCFD3E8);
  static const Color glpiBorderStrong = Color(0xFF9AA0C4);
  static const Color glpiBorderLight  = Color(0xFFE6E8F5);

  // ── Texto ───────────────────────────────────────────────────────────────
  static const Color glpiTextPrimary   = Color(0xFF1B1B1B);
  static const Color glpiTextSecondary = Color(0xFF5B5E73);
  static const Color glpiTextDisabled  = Color(0xFF9DA0B5);
  static const Color glpiTextLink      = unifeobAzul;

  // ── Tokens ──────────────────────────────────────────────────────────────
  static const double borderRadius       = 12;
  static const double buttonHeight       = 54;
  static const double cardPaddingDefault = 16;

  // ── ThemeData ───────────────────────────────────────────────────────────

  static ThemeData get themeData {
    final base = ThemeData.light(useMaterial3: false);

    return base.copyWith(
      primaryColor:            glpiPrimary,
      scaffoldBackgroundColor: glpiBackground,
      colorScheme: base.colorScheme.copyWith(
        primary:   glpiPrimary,
        secondary: glpiAccent,
        surface:   glpiSurface,
        error:     glpiError,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor:  glpiPrimaryDark,
        foregroundColor:  Colors.white,
        elevation:        0,
        centerTitle:      true,
        titleTextStyle:   TextStyle(
          fontSize:   18,
          fontWeight: FontWeight.w600,
          color:      Colors.white,
        ),
        iconTheme:        IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:         true,
        fillColor:      glpiSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide:   const BorderSide(color: glpiBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide:   const BorderSide(color: glpiBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide:   const BorderSide(color: glpiPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide:   const BorderSide(color: glpiError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide:   const BorderSide(color: glpiError, width: 2),
        ),
        labelStyle: const TextStyle(color: glpiTextSecondary),
        hintStyle:  const TextStyle(color: glpiTextDisabled),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: glpiPrimary,
          foregroundColor: Colors.white,
          minimumSize:     const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: glpiPrimary,
          minimumSize:     const Size.fromHeight(44),
          side:            const BorderSide(color: glpiPrimary, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: glpiPrimary,
          textStyle:       const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color:     glpiSurface,
        elevation: 0,
        margin:    const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side:         const BorderSide(color: glpiBorderLight),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: glpiAccent,
        foregroundColor: Colors.white,
        elevation:       2,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? glpiPrimary : glpiBorderStrong),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? glpiPrimary.withAlpha(76)
                : glpiBorderLight),
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: glpiPrimary,
        thumbColor:       glpiPrimary,
      ),

      dividerColor: glpiBorderLight,
      iconTheme:    const IconThemeData(color: glpiTextSecondary),

      textTheme: base.textTheme.copyWith(
        headlineLarge:  const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: glpiTextPrimary),
        headlineMedium: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: glpiTextPrimary),
        headlineSmall:  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: glpiTextPrimary),
        titleLarge:     const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: glpiTextPrimary),
        titleMedium:    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: glpiTextPrimary),
        bodyLarge:      const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: glpiTextPrimary),
        bodyMedium:     const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: glpiTextPrimary),
        bodySmall:      const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: glpiTextSecondary),
        labelLarge:     const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  /// Cor de destaque para um estado/status de ativo (heurística por nome,
  /// já que a HL API devolve o rótulo textual do `State`).
  static Color corDoEstado(String estado) {
    final e = estado.toLowerCase();
    if (e.contains('uso') || e.contains('ativ') || e.contains('produ')) {
      return glpiSuccess;
    }
    if (e.contains('estoque') || e.contains('novo') || e.contains('dispon')) {
      return glpiInfo;
    }
    if (e.contains('manut') || e.contains('reparo') || e.contains('pend')) {
      return glpiWarning;
    }
    if (e.contains('baixa') || e.contains('descart') || e.contains('inativ')) {
      return glpiError;
    }
    return glpiTextSecondary;
  }
}
