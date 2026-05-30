import '_helpers.dart';
import 'asset_tipo.dart';

class Asset {
  final int id;
  final AssetTipo tipo;
  final String nome;
  final String serial;
  final String inventario;
  final String fabricante;
  final String modelo;
  final String tipoEquipamento;
  final String localizacao;
  final String estado;
  final String usuario;
  final String grupo;
  final String entidade;
  final String comentario;
  final String contato;
  final DateTime? dataCriacao;
  final DateTime? dataModificacao;

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
        id: ModelHelpers.asInt(json['id']),
        tipo: tipo,
        nome: ModelHelpers.texto(json, ['name']),
        serial: ModelHelpers.texto(json, ['serial']),
        inventario: ModelHelpers.texto(json, ['otherserial']),
        fabricante:
            ModelHelpers.texto(json, ['manufacturer', 'manufacturers_id']),
        modelo: ModelHelpers.texto(json, [
          'model',
          'computermodel',
          'phonemodel',
          'computermodels_id',
          'phonemodels_id',
          'models_id',
        ]),
        tipoEquipamento: ModelHelpers.texto(json, [
          'type',
          'computertype',
          'phonetype',
          'computertypes_id',
          'phonetypes_id',
          'types_id',
        ]),
        localizacao: ModelHelpers.texto(json, ['location', 'locations_id']),
        estado: ModelHelpers.texto(json, ['state', 'status', 'states_id']),
        usuario:
            ModelHelpers.texto(json, ['user', 'users_id', 'users_id_tech']),
        grupo:
            ModelHelpers.texto(json, ['group', 'groups_id', 'groups_id_tech']),
        entidade: ModelHelpers.texto(json, ['entity', 'entities_id']),
        comentario: ModelHelpers.texto(json, ['comment']),
        contato: ModelHelpers.texto(json, ['contact']),
        dataCriacao: ModelHelpers.asDateTime(json['date_creation']),
        dataModificacao: ModelHelpers.asDateTime(json['date_mod']),
        raw: ModelHelpers.imutavel(json),
      );

  String get uuid => ModelHelpers.texto(raw, ['uuid']);

  String get sistemaOperacional => ModelHelpers.texto(raw, [
        'operatingsystem',
        'operatingsystems_id',
        'os',
      ]);

  String get imei => ModelHelpers.texto(raw, ['imei', 'imei_1', 'imei1']);

  DateTime? get dataInventario =>
      ModelHelpers.asDateTime(raw['last_inventory_update']) ??
      ModelHelpers.asDateTime(raw['last_inventory']) ??
      dataModificacao;

  String get qrPayload => nome.isNotEmpty ? nome : serial;

  String get titulo {
    if (nome.isNotEmpty) return nome;
    if (serial.isNotEmpty) return serial;
    return '#$id';
  }
}
