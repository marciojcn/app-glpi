import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../core/glpi_exception.dart';
import '../core/secure_http.dart';
import '../models/auth_config.dart';
import '../services/auth_service.dart';
import '../widgets/widgets.dart';

/// Configuração da conexão com o GLPI (API v2 / OAuth2).
///
/// Separada do login: aqui ficam URL do servidor, Client ID/Secret do client
/// OAuth e o scope. Os dados são gravados no `flutter_secure_storage` via
/// [AuthService.salvarConfig]. Há um "Testar conexão" que valida servidor +
/// client sem precisar logar.
class ApiConfigPage extends StatefulWidget {
  const ApiConfigPage({super.key});

  @override
  State<ApiConfigPage> createState() => _ApiConfigPageState();
}

class _ApiConfigPageState extends State<ApiConfigPage> {
  final _urlCtrl          = TextEditingController();
  final _clientIdCtrl     = TextEditingController();
  final _clientSecretCtrl = TextEditingController();
  final _scopeCtrl        = TextEditingController();

  bool _aceitarSsl    = false;
  bool _ocultarSecret = true;
  bool _testando      = false;
  bool _salvando      = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _clientIdCtrl.dispose();
    _clientSecretCtrl.dispose();
    _scopeCtrl.dispose();
    super.dispose();
  }

  // ── Dados ───────────────────────────────────────────────────────────────

  Future<void> _carregar() async {
    await AuthService.instance.carregarConfig();
    final cfg   = AuthService.instance.config;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _urlCtrl.text          = cfg.baseUrl;
      _clientIdCtrl.text     = cfg.clientId;
      _clientSecretCtrl.text = cfg.clientSecret;
      _scopeCtrl.text        = cfg.scope.isNotEmpty ? cfg.scope : 'api';
      _aceitarSsl = prefs.getBool(GlpiConstants.prefAllowUntrusted) ?? false;
    });
  }

  AuthConfig _montar() => AuthConfig(
        baseUrl:      _urlCtrl.text.trim(),
        clientId:     _clientIdCtrl.text.trim(),
        clientSecret: _clientSecretCtrl.text.trim(),
        scope:        _scopeCtrl.text.trim(),
      );

  Future<void> _salvar() async {
    FocusScope.of(context).unfocus();
    final cfg = _montar();
    if (!cfg.completo) {
      GlpiSnackbar.aviso(context, 'Preencha URL, Client ID e Client Secret.');
      return;
    }
    setState(() => _salvando = true);
    SecureHttpOverrides.allowUntrusted = _aceitarSsl;
    try {
      await AuthService.instance.salvarConfig(cfg);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(GlpiConstants.prefAllowUntrusted, _aceitarSsl);
      if (!mounted) return;
      GlpiSnackbar.sucesso(context, 'Configuração salva.');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (kDebugMode) debugPrint('ApiConfigPage._salvar: $e');
      if (!mounted) return;
      GlpiSnackbar.erro(context, 'Não foi possível salvar.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _testar() async {
    FocusScope.of(context).unfocus();
    final cfg = _montar();
    if (!cfg.completo) {
      GlpiSnackbar.aviso(context, 'Preencha URL, Client ID e Client Secret.');
      return;
    }
    setState(() => _testando = true);
    SecureHttpOverrides.allowUntrusted = _aceitarSsl;
    try {
      await AuthService.instance.testarConfig(cfg);
      if (!mounted) return;
      GlpiSnackbar.sucesso(context, 'Servidor e client OK. Já pode fazer login.');
    } on GlpiException catch (e) {
      if (!mounted) return;
      GlpiSnackbar.erro(context, e.mensagem);
    } catch (e) {
      if (kDebugMode) debugPrint('ApiConfigPage._testar: $e');
      if (!mounted) return;
      GlpiSnackbar.erro(context, 'Não foi possível conectar. Verifique a URL e a rede.');
    } finally {
      if (mounted) setState(() => _testando = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações da API')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Conexão OAuth2 (API v2)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Informe a URL do GLPI e o client OAuth (criado em '
                'Configurar → Clientes OAuth).',
                style: TextStyle(fontSize: 13, color: GlpiTheme.glpiTextSecondary),
              ),
              const SizedBox(height: 24),

              GlpiTextField(
                controller:   _urlCtrl,
                labelText:    'URL do servidor GLPI',
                hintText:     'http://137.131.162.82:8080',
                helperText:   'Raiz do GLPI (sem /api.php)',
                prefixIcon:   Icons.link_rounded,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              GlpiTextField(
                controller: _clientIdCtrl,
                labelText:  'Client ID (OAuth)',
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),
              GlpiTextField(
                controller:  _clientSecretCtrl,
                labelText:   'Client Secret (OAuth)',
                prefixIcon:  Icons.vpn_key_outlined,
                obscureText: _ocultarSecret,
                suffixIcon: IconButton(
                  icon: Icon(
                    _ocultarSecret
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: GlpiTheme.glpiTextSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _ocultarSecret = !_ocultarSecret),
                ),
              ),
              const SizedBox(height: 16),
              GlpiTextField(
                controller: _scopeCtrl,
                labelText:  'Scope',
                hintText:   'api',
                helperText: 'Use "api" para ler os inventários (necessário).',
                prefixIcon: Icons.tune_rounded,
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value:    _aceitarSsl,
                onChanged: (v) => setState(() => _aceitarSsl = v),
                title:    const Text('Aceitar SSL auto-assinado', style: TextStyle(fontSize: 14)),
                subtitle: const Text(
                  'Só para HTTPS com certificado próprio',
                  style: TextStyle(fontSize: 12, color: GlpiTheme.glpiTextSecondary),
                ),
              ),

              const SizedBox(height: 12),
              if (_testando) ...[
                const GlpiLinearLoading(),
                const SizedBox(height: 14),
              ],

              GlpiButton(
                label:     'SALVAR',
                icon:      Icons.save_rounded,
                loading:   _salvando,
                onPressed: _salvando ? null : _salvar,
              ),
              const SizedBox(height: 10),
              GlpiOutlinedButton(
                label:     'TESTAR CONEXÃO',
                icon:      Icons.wifi_tethering_rounded,
                height:    46,
                onPressed: _testando ? null : _testar,
              ),

              const SizedBox(height: 20),
              _dica(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dica() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        GlpiTheme.glpiInfoBackground,
        borderRadius: BorderRadius.circular(GlpiTheme.borderRadius),
        border:       Border.all(color: GlpiTheme.glpiInfo.withAlpha(50)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 18, color: GlpiTheme.glpiInfo),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'No client OAuth do GLPI: habilite a concessão "Senha" (login por '
              'usuário/senha). O Scope "api" é obrigatório para ler os inventários.',
              style: TextStyle(fontSize: 12, color: GlpiTheme.glpiTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
