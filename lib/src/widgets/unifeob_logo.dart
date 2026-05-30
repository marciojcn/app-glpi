import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UnifeobLogo extends StatelessWidget {
  final double height;
  final Color? cor;

  const UnifeobLogo({super.key, this.height = 40, this.cor});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/unifeob.svg',
      height: height,
      colorFilter: cor == null ? null : ColorFilter.mode(cor!, BlendMode.srcIn),
      placeholderBuilder: (_) => SizedBox(height: height),
    );
  }
}
