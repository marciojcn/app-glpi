import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app_glpi.dart';
import '../../core/constants.dart';
import '../../core/glpi_exception.dart';
import '../../models/asset.dart';
import '../../models/asset_tipo.dart';
import '../../services/asset_service.dart';
import '../../widgets/widgets.dart';
import 'asset_detail_page.dart';
import 'qr_scanner_page.dart';

/// Lista paginada de ativos de um [AssetTipo] (computador ou celular).
///
/// Genérica: a mesma tela serve aos dois inventários, mudando só o [tipo].
/// Tem busca textual (filtro RSQL no servidor), scroll infinito e
/// pull-to-refresh.
class AssetListPage extends StatefulWidget {
  final AssetTipo tipo;
  const AssetListPage({super.key, required this.tipo});

  @override
  State<AssetListPage> createState() => _AssetListPageState();
}

class _AssetListPageState extends State<AssetListPage> {
  final _buscaCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const int _limit = GlpiConstants.paginaTamanhoPadrao;

  final List<Asset> _itens = [];
  int    _total             = 0;
  bool   _carregandoInicial = true;
  bool   _carregandoMais    = false;
  bool   _ultimaPaginaCheia = false;
  bool   _erro              = false;
  String _mensagemErro      = '';
  String _busca             = '';

  bool get _temMais => _ultimaPaginaCheia;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _recarregar();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _buscaCtrl.dispose();
    super.dispose();
  }

  // ── Dados ───────────────────────────────────────────────────────────────

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 320) {
      _carregarMais();
    }
  }

  Future<void> _recarregar({bool abrirSeUnico = false}) async {
    setState(() {
      _carregandoInicial = true;
      _erro = false;
    });
    await _carregarPagina(reset: true, abrirSeUnico: abrirSeUnico);
  }

  Future<void> _carregarMais() async {
    if (_carregandoMais || _carregandoInicial || !_temMais) return;
    setState(() => _carregandoMais = true);
    await _carregarPagina();
  }

  Future<void> _carregarPagina({bool reset = false, bool abrirSeUnico = false}) async {
    final start = reset ? 0 : _itens.length;
    try {
      final pagina = await AssetService.listar(
        widget.tipo,
        start: start,
        limit: _limit,
        busca: _busca,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _itens.clear();
        _itens.addAll(pagina.itens);
        _total             = pagina.total;
        _ultimaPaginaCheia = pagina.itens.length >= _limit;
        _carregandoInicial = false;
        _carregandoMais    = false;
        _erro              = false;
      });
      // Vindo do scanner: se a busca caiu em exatamente 1 item, abre o detalhe.
      if (reset && abrirSeUnico && _itens.length == 1) {
        _abrirDetalhe(_itens.first);
      }
    } on GlpiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro              = true;
        _mensagemErro      = e.mensagem;
        _carregandoInicial = false;
        _carregandoMais    = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('AssetListPage._carregarPagina: $e');
      if (!mounted) return;
      setState(() {
        _erro              = true;
        _mensagemErro      = 'Não foi possível carregar a lista.';
        _carregandoInicial = false;
        _carregandoMais    = false;
      });
    }
  }

  void _buscar(String q, {bool abrirSeUnico = false}) {
    _busca = q.trim();
    _recarregar(abrirSeUnico: abrirSeUnico);
  }

  /// Abre o scanner; o QR lido vira o termo de busca. Se cair em 1 resultado,
  /// abre o detalhe automaticamente (mesmo fluxo do STOX).
  Future<void> _abrirScanner() async {
    final codigo = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerPage(
          titulo: 'Escanear ${widget.tipo.rotuloSingular.toLowerCase()}',
        ),
      ),
    );
    if (codigo == null || codigo.trim().isEmpty || !mounted) return;

    // QR nativo do GLPI ("URL do ativo") → abre o ativo direto pelo id.
    final ref = AssetService.parseUrlAtivo(codigo);
    if (ref != null) {
      Navigator.push(
        context,
        transicaoPadrao(AssetDetailPage(
          tipo:  ref.tipo,
          asset: Asset.fromJson(<String, dynamic>{'id': ref.id}, ref.tipo),
        )),
      );
      return;
    }

    // QR da nossa etiqueta (hostname) ou texto livre → busca textual.
    _buscaCtrl.text = codigo.trim();
    _buscar(codigo.trim(), abrirSeUnico: true);
  }

  void _abrirDetalhe(Asset a) {
    Navigator.push(
      context,
      transicaoPadrao(AssetDetailPage(tipo: widget.tipo, asset: a)),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tipo.rotulo)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: GlpiSearchBar(
                controller: _buscaCtrl,
                onSearch:   _buscar,
                onScanner:  _abrirScanner,
              ),
            ),
            if (!_carregandoInicial && !_erro && _itens.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_itens.length} de $_total',
                    style: const TextStyle(
                      fontSize: 12, color: GlpiTheme.glpiTextSecondary,
                    ),
                  ),
                ),
              ),
            Expanded(child: _conteudo()),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    if (_carregandoInicial) {
      return const GlpiSkeletonList(quantidade: 7);
    }
    if (_erro) {
      return _estado(
        icone:    Icons.cloud_off_rounded,
        titulo:   'Erro ao carregar',
        mensagem: _mensagemErro,
        acao:     _recarregar,
      );
    }
    if (_itens.isEmpty) {
      return _estado(
        icone:    Icons.inventory_2_outlined,
        titulo:   'Nada encontrado',
        mensagem: _busca.isEmpty
            ? 'Nenhum ${widget.tipo.rotuloSingular.toLowerCase()} cadastrado.'
            : 'Nenhum resultado para "$_busca".',
        acao:     _recarregar,
      );
    }

    return RefreshIndicator(
      color:     GlpiTheme.glpiPrimary,
      onRefresh: _recarregar,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding:    const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount:  _itens.length + (_temMais ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _itens.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  height: 26, width: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6, color: GlpiTheme.glpiPrimary,
                  ),
                ),
              ),
            );
          }
          return _itemCard(_itens[i]);
        },
      ),
    );
  }

  Widget _itemCard(Asset a) {
    final infos = <String>[
      if (a.serial.isNotEmpty)      'S/N ${a.serial}',
      if (a.usuario.isNotEmpty)     a.usuario,
      if (a.localizacao.isNotEmpty) a.localizacao,
    ];

    return GlpiCard(
      onTap: () => _abrirDetalhe(a),
      child: Row(
        children: [
          Icon(
            widget.tipo == AssetTipo.computador
                ? Icons.computer_rounded
                : Icons.smartphone_rounded,
            color: GlpiTheme.glpiPrimary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: GlpiTheme.glpiTextPrimary,
                  ),
                ),
                if (infos.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    infos.join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12, color: GlpiTheme.glpiTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (a.estado.isNotEmpty)
            Container(
              margin:  const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        GlpiTheme.corDoEstado(a.estado).withAlpha(28),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                a.estado,
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: GlpiTheme.corDoEstado(a.estado),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _estado({
    required IconData icone,
    required String   titulo,
    required String   mensagem,
    required VoidCallback acao,
  }) {
    return LayoutBuilder(
      builder: (_, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: 56, color: GlpiTheme.glpiBorderStrong),
                  const SizedBox(height: 14),
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600,
                      color: GlpiTheme.glpiTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mensagem,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13, color: GlpiTheme.glpiTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GlpiOutlinedButton(
                    label:     'Tentar novamente',
                    icon:      Icons.refresh_rounded,
                    height:    44,
                    onPressed: acao,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
