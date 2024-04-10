import 'package:audioplayers/audioplayers.dart';

class Player {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> play(String src) async {
    // if (_player.state == PlayerState.STOPPED) {
      await _player.play(AssetSource(src));
    // } else if (_player.state == PlayerState.PAUSED) {
    //   await _player.resume();
    // } else {
      // Handle cases when player is already playing
      // You may choose to stop and play again or handle it differently
    // }
  }

  static Future<void> pause() async {
    // if (_player.state == PlayerState.PLAYING) {
      await _player.stop();
    // }
  }

  static Future<void> resume() async {
    // if (_player.state == PlayerState.PAUSED) {
      await _player.resume();
    // }
  }
}
