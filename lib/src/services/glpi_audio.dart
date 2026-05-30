import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GlpiAudio {
  GlpiAudio._();

  static Future<void> beep() => play('sounds/beep.mp3');

  static Future<void> sucesso() => play('sounds/check.mp3');

  static Future<void> erro() => play('sounds/error_beep.mp3', isError: true);

  static Future<void> play(String asset, {bool isError = false}) async {
    try {
      if (isError) {
        HapticFeedback.vibrate();
      } else {
        HapticFeedback.mediumImpact();
      }
    } catch (_) {}

    AudioPlayer? player;
    var liberado = false;
    void liberar() {
      if (liberado) return;
      liberado = true;
      player?.dispose();
    }

    try {
      player = AudioPlayer();
      player.onPlayerComplete.listen((_) => liberar());
      await player.play(AssetSource(asset));
    } catch (e) {
      liberar();
      if (kDebugMode) debugPrint('GlpiAudio.play($asset): $e');
    }
  }
}
