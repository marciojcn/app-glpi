import '_helpers.dart';
import 'asset_tipo.dart';

/// Ativo de inventário (Computer ou Phone) lido da HL API.
///
/// Modelo **unificado**: os campos comuns aos dois tipos ficam aqui, e o
/// [tipo] diferencia. Campos específicos (ex.: `uuid` do computador) são
/// expostos por getters que leem o [raw].
///
/// `fromJson` é resiliente: tenta o nome amigável da API v2 (`manufacturer`)
/// e cai para o `*_id` legado, aceitando tanto string quanto objeto aninhado
/// (ver [ModelHelpers.texto]).
class Asset {
  final int        id;
  final AssetTipo  tipo;
  final String     nome;
  final String     serial;
  final String     inventario;     // otherserial (nº de patrimônio)
  final String     fabricante;
  final String     modelo;
  final String     tipoEquipamento; // ComputerType / PhoneType
  final String     localizacao;
  final String     estado;          // status / states_id
  final String     usuario;         // responsável
  final String     grupo;           // departamento
  final String     entidade;
  final String     comentario;
  final String     contato;
  final DateTime?  dataCriacao;
  final DateTime?  dataModificacao;

  /// Map cru retornado pela API — usado na tela de detalhe para exibir
  /// campos não mapeados (uuid, sistema operacional, IMEI…).
  final Map<String, dynamic> raw;

  const Asset({
    required this.id,
    required this.tipo,
    required this.nome,
    required this.serial,
    required this.inventario,
    required this.fabricante,
    required this.modelo,
    required this.tipoEquipamento,
    required this.localizacao,
    required this.estado,
    required this.usuario,
    required this.grupo,
    required this.entidade,
    required this.comentario,
    required this.contato,
    this.dataCriacao,
    this.dataModificacao,
    this.raw = const {},
  });

  factory Asset.fromJson(Map<String, dynamic> json, AssetTipo tipo) => Asset(
        id:              ModelHelpers.asInt(json['id']),
        tipo:            tipo,
        nome:            ModelHelpers.texto(json, ['name']),
        serial:          ModelHelpers.texto(json, ['serial']),
        inventario:      ModelHelpers.texto(json, ['otherserial']),
        fabricante:      ModelHelpers.texto(json, ['manufacturer', 'manufacturers_id']),
        modelo: ModelHelpers.texto(json, [
          'model', 'computermodel', 'phonemodel',
          'computermodels_id', 'phonemodels_id', 'models_id',
        ]),
        tipoEquipamento: ModelHelpers.texto(json, [
          'type', 'computertype', 'phonetype',
          'computertypes_id', 'phonetypes_id', 'types_id',
        ]),
        localizacao:     ModelHelpers.texto(json, ['location', 'locations_id']),
        estado:          ModelHelpers.texto(json, ['state', 'status', 'states_id']),
        usuario:         ModelHelpers.texto(json, ['user', 'users_id', 'users_id_tech']),
        grupo:           ModelHelpers.texto(json, ['group', 'groups_id', 'groups_id_tech']),
        entidade:        ModelHelpers.texto(json, ['entity', 'entities_id']),
        comentario:      ModelHelpers.texto(json, ['comment']),
        contato:         ModelHelpers.texto(json, ['contact']),
        dataCriacao:     ModelHelpers.asDateTime(json['date_creation']),
        dataModificacao: ModelHelpers.asDateTime(json['date_mod']),
        raw:             ModelHelpers.imutavel(json),
      );

  // ── Campos específicos (lidos do raw quando presentes) ─────────────────────

  /// UUID do computador (vazio para celular ou quando ausente).
  String get uuid => ModelHelpers.texto(raw, ['uuid']);

  /// Sistema operacional, quando a API o devolve embutido.
  String get sistemaOperacional => ModelHelpers.texto(raw, [
        'operatingsystem', 'operatingsystems_id', 'os',
      ]);

  /// IMEI do aparelho (celular). Vazio quando ausente.
  String get imei => ModelHelpers.texto(raw, ['imei', 'imei_1', 'imei1']);

  /// Data do último inventário. Tenta os campos do inventário nativo do GLPI e
  /// cai para a última modificação (`date_mod`), que reflete a última sincronização.
  DateTime? get dataInventario =>
      ModelHelpers.asDateTime(raw['last_inventory_update']) ??
      ModelHelpers.asDateTime(raw['last_inventory']) ??
      dataModificacao;

  /// Conteúdo padrão do QR code: o nome (hostname). Cai para o serial.
  String get qrPayload => nome.isNotEmpty ? nome : serial;

  /// Título amigável para listas: nome → serial → "#id".
  String get titulo {
    if (nome.isNotEmpty)   return nome;
    if (serial.isNotEmpty) return serial;
    return '#$id';
  }
}
