import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app_glpi.dart';
import '../../core/glpi_exception.dart';
import '../../models/asset.dart';
import '../../models/asset_tipo.dart';
import '../../services/asset_service.dart';
import '../../widgets/widgets.dart';
import '../etiqueta_page.dart';

/// Detalhe de um ativo. Recebe o resumo vindo da lista e busca os campos
/// completos por id; enquanto carrega, já exibe o que tem em mãos.
class AssetDetailPage extends StatefulWidget {
  final AssetTipo tipo;
  final Asset     asset;
  const AssetDetailPage({super.key, required this.tipo, required this.asset});

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  late Asset _asset;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _asset = widget.asset;
    _carregarDetalhe();
  }

  Future<void> _carregarDetalhe() async {
    try {
      final completo = await AssetService.detalhe(widget.tipo, widget.asset.id);
      if (!mounted) return;
      setState(() {
        _asset = completo;
        _carregando = false;
      });
    } on GlpiException catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
      GlpiSnackbar.aviso(context, e.mensagem);
    } catch (e) {
      if (kDebugMode) debugPrint('AssetDetailPage._carregarDetalhe: $e');
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  void _imprimir() {
    Navigator.push(context, transicaoPadrao(EtiquetaPage(asset: _asset)));
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final a = _asset;
    return Scaffold(
      appBar: AppBar(title: Text(widget.tipo.rotuloSingular)),
      body: SafeArea(
        child: Column(
          children: [
            if (_carregando) const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: GlpiLinearLoading(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GlpiAssetHeaderCard(
                    nome:        a.titulo,
                    tipo:        widget.tipo.rotuloSingular,
                    serial:      a.serial,
                    status:      a.estado,
                    localizacao: a.localizacao,
                    usuario:     a.usuario,
                    icone: widget.tipo == AssetTipo.computador
                        ? Icons.computer_rounded
                        : Icons.smartphone_rounded,
                  ),
                  GlpiSectionCard(
                    titulo: 'Identificação',
                    icone:  Icons.badge_outlined,
                    linhas: [
                      GlpiDetailRow('Nome',       a.nome, destaque: true),
                      GlpiDetailRow('Serial',     a.serial),
                      GlpiDetailRow('Inventário', a.inventario),
                      GlpiDetailRow('Tipo',       a.tipoEquipamento),
                      GlpiDetailRow('Modelo',     a.modelo),
                      GlpiDetailRow('Fabricante', a.fabricante),
                    ],
                  ),
                  GlpiSectionCard(
                    titulo: 'Alocação',
                    icone:  Icons.place_outlined,
                    linhas: [
                      GlpiDetailRow('Usuário',      a.usuario),
                      GlpiDetailRow('Departamento', a.grupo),
                      GlpiDetailRow('Localização',  a.localizacao),
                      GlpiDetailRow('Estado',       a.estado),
                      GlpiDetailRow('Entidade',     a.entidade),
                    ],
                  ),
                  if (a.uuid.isNotEmpty || a.sistemaOperacional.isNotEmpty)
                    GlpiSectionCard(
                      titulo: 'Sistema',
                      icone:  Icons.memory_rounded,
                      linhas: [
                        if (a.sistemaOperacional.isNotEmpty)
                          GlpiDetailRow('S.O.', a.sistemaOperacional),
                        if (a.uuid.isNotEmpty)
                          GlpiDetailRow('UUID', a.uuid),
                      ],
                    ),
                  if (a.comentario.isNotEmpty)
                    GlpiSectionCard(
                      titulo: 'Observações',
                      icone:  Icons.notes_rounded,
                      linhas: [GlpiDetailRow('Comentário', a.comentario)],
                    ),
                  GlpiSectionCard(
                    titulo: 'Datas',
                    icone:  Icons.event_outlined,
                    linhas: [
                      GlpiDetailRow('Criação',     _fmtData(a.dataCriacao)),
                      GlpiDetailRow('Modificação', _fmtData(a.dataModificacao)),
                    ],
                  ),
                ],
              ),
            ),
            _barraImprimir(),
          ],
        ),
      ),
    );
  }

  Widget _barraImprimir() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: GlpiTheme.glpiSurface,
        border: Border(top: BorderSide(color: GlpiTheme.glpiBorderLight)),
      ),
      child: GlpiButton(
        label:     'IMPRIMIR ETIQUETA',
        icon:      Icons.qr_code_2_rounded,
        onPressed: _imprimir,
      ),
    );
  }

  String _fmtData(DateTime? d) {
    if (d == null) return '';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} ${dois(d.hour)}:${dois(d.minute)}';
  }
}
