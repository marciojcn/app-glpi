import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo da Unifeob renderizada do SVG vetorial (`assets/images/unifeob.svg`).
///
/// Por padrão usa as cores originais (wordmark escuro + ponto azul), ideal sobre
/// fundo claro. Passe [cor] para tingir tudo de uma cor só (ex.: branco sobre
/// fundo indigo).
class UnifeobLogo extends StatelessWidget {
  final double  height;
  final Color?  cor;

  const UnifeobLogo({super.key, this.height = 40, this.cor});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/unifeob.svg',
      height: height,
      colorFilter:
          cor == null ? null : ColorFilter.mode(cor!, BlendMode.srcIn),
      placeholderBuilder: (_) => SizedBox(height: height),
    );
  }
}
