import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_glpi.dart';
import 'src/core/constants.dart';
import 'src/core/secure_http.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Frota corporativa usa só retrato.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // SSL auto-assinado: default FALSE (segurança). O usuário liga no Login se o
  // servidor for HTTPS com certificado próprio — e, mesmo ligado, só vale para
  // o host do GLPI configurado (ver SecureHttpOverrides).
  final prefs = await SharedPreferences.getInstance();
  SecureHttpOverrides.allowUntrusted =
      prefs.getBool(GlpiConstants.prefAllowUntrusted) ?? false;
  HttpOverrides.global = SecureHttpOverrides();

  // Status bar transparente, ícones claros (combina com a AppBar indigo Unifeob).
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:                    Colors.transparent,
    statusBarIconBrightness:           Brightness.light,
    systemNavigationBarColor:          Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const AppGlpi());
}
