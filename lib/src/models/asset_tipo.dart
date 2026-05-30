import '../core/constants.dart';

/// Tipos de ativo suportados nesta versão do app: computador e celular.
///
/// Cada tipo conhece o **recurso da API** que o lista
/// (`Assets/Computer` ou `Assets/Phone`) e seus rótulos PT-BR. Adicionar
/// um novo inventário no futuro = acrescentar um membro aqui + a rota.
enum AssetTipo {
  computador,
  celular;

  /// Rótulo no plural (títulos de tela e cards da home).
  String get rotulo => switch (this) {
        AssetTipo.computador => 'Computadores',
        AssetTipo.celular    => 'Celulares',
      };

  /// Rótulo no singular (detalhe, mensagens).
  String get rotuloSingular => switch (this) {
        AssetTipo.computador => 'Computador',
        AssetTipo.celular    => 'Celular',
      };

  /// Caminho do recurso na HL API, relativo a `/api.php/v2/`.
  String get recurso => switch (this) {
        AssetTipo.computador => GlpiConstants.resourceComputer,
        AssetTipo.celular    => GlpiConstants.resourcePhone,
      };

  /// Formulário web do GLPI deste tipo (usado na "URL do ativo" gravada no QR
  /// da etiqueta, ex.: `computer.form.php`). Espelha o reconhecido por
  /// `AssetService.parseUrlAtivo`.
  String get formularioGlpi => switch (this) {
        AssetTipo.computador => 'computer.form.php',
        AssetTipo.celular    => 'phone.form.php',
      };
}
