import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_glpi.dart';
import '../core/constants.dart';
import '../core/glpi_exception.dart';
import '../core/secure_http.dart';
import '../services/auth_service.dart';
import '../widgets/widgets.dart';
import 'api_config_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  bool _carregando = false;
  bool _configOk = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    await AuthService.instance.carregarConfig();
    final prefs = await SharedPreferences.getInstance();
    SecureHttpOverrides.allowUntrusted =
        prefs.getBool(GlpiConstants.prefAllowUntrusted) ?? false;
    if (!mounted) return;
    setState(() {
      _userCtrl.text = prefs.getString(GlpiConstants.prefLastUsername) ?? '';
      _configOk = AuthService.instance.config.completo;
    });
  }

  Future<void> _abrirConfig() async {
    await Navigator.push(context, transicaoPadrao(const ApiConfigPage()));
    await _carregar();
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();

    if (!AuthService.instance.config.completo) {
      GlpiSnackbar.aviso(context, 'Configure o servidor antes de entrar.');
      _abrirConfig();
      return;
    }
    final user = _userCtrl.text.trim();
    final senha = _senhaCtrl.text;
    if (user.isEmpty || senha.isEmpty) {
      GlpiSnackbar.aviso(context, 'Informe usuário e senha.');
      return;
    }

    setState(() => _carregando = true);
    try {
      await AuthService.instance.login(usuario: user, senha: senha);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(GlpiConstants.prefLastUsername, user);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      Navigator.pushReplacement(context, transicaoPadrao(const HomePage()));
    } on GlpiException catch (e) {
      if (!mounted) return;
      GlpiSnackbar.erro(context, e.mensagem);
    } catch (e) {
      if (kDebugMode) debugPrint('LoginPage._entrar: $e');
      if (!mounted) return;
      GlpiSnackbar.erro(context, 'Não foi possível entrar. Verifique a rede.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final altura = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: altura * 0.08),
                  const Center(child: UnifeobLogo(height: 58)),
                  const SizedBox(height: 30),
                  Text(
                    'Inventário',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Entre com seu usuário e senha do GLPI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: GlpiTheme.glpiTextSecondary),
                  ),
                  const SizedBox(height: 36),
                  GlpiTextField(
                    controller: _userCtrl,
                    labelText: 'Usuário',
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  GlpiPasswordField(
                    controller: _senhaCtrl,
                    onSubmitted: (_) => _entrar(),
                  ),
                  const SizedBox(height: 28),
                  GlpiButton(
                    label: 'ENTRAR',
                    icon: Icons.login_rounded,
                    loading: _carregando,
                    onPressed: _entrar,
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: GlpiTextButton(
                      label: 'Configurações da API',
                      icon: Icons.settings_outlined,
                      onPressed: _abrirConfig,
                    ),
                  ),
                  if (!_configOk) _avisoSemConfig(),
                  const SizedBox(height: 20),
                  const Text(
                    'API REST v2 (OAuth2) · Unifeob',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: GlpiTheme.glpiTextDisabled),
                  ),
                  SizedBox(height: altura * 0.04),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avisoSemConfig() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GlpiTheme.glpiWarningBackground,
        borderRadius: BorderRadius.circular(GlpiTheme.borderRadius),
        border: Border.all(color: GlpiTheme.glpiWarning.withAlpha(60)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: GlpiTheme.glpiWarning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Servidor ainda não configurado. Toque em "Configurações da API".',
              style: TextStyle(fontSize: 12, color: GlpiTheme.glpiWarning),
            ),
          ),
        ],
      ),
    );
  }
}
