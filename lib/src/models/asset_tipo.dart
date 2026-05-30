import '../core/constants.dart';

enum AssetTipo {
  computador,
  celular;

  String get rotulo => switch (this) {
        AssetTipo.computador => 'Computadores',
        AssetTipo.celular => 'Celulares',
      };

  String get rotuloSingular => switch (this) {
        AssetTipo.computador => 'Computador',
        AssetTipo.celular => 'Celular',
      };

  String get recurso => switch (this) {
        AssetTipo.computador => GlpiConstants.resourceComputer,
        AssetTipo.celular => GlpiConstants.resourcePhone,
      };

  String get formularioGlpi => switch (this) {
        AssetTipo.computador => 'computer.form.php',
        AssetTipo.celular => 'phone.form.php',
      };
}
