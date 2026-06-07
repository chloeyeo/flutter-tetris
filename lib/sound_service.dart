import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playSound(String? assetPath) async {
    if (assetPath == null) return;

    try {
      // Play the sound from assets
      await _player.stop(); // Stop current sound to allow rapid replay
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      // Silently fail if file is missing, so the game doesn't crash
      debugPrint("Audio play failed: $e. Make sure $assetPath exists in assets.");
    }
  }

  void dispose() {
    _player.dispose();
  }
}
