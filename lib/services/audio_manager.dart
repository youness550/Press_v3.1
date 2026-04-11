import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple audio manager to centralize background music and SFX usage.
class AudioManager {
  AudioManager._private();
  static final AudioManager _instance = AudioManager._private();
  factory AudioManager() => _instance;

  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool musicEnabled = true;
  bool soundEnabled = true;

  static const _prefMusicKey = 'pref_music_enabled';
  static const _prefSoundKey = 'pref_sound_enabled';

  Future<void> init() async {
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(0.35);
      // Load persisted settings
      final prefs = await SharedPreferences.getInstance();
      musicEnabled = prefs.getBool(_prefMusicKey) ?? true;
      soundEnabled = prefs.getBool(_prefSoundKey) ?? true;
    } catch (e) {
      debugPrint('AudioManager init error: $e');
    }
  }

  Future<void> playBackground(String assetPath) async {
    try {
      if (!musicEnabled) return;
      // Ensure restart on rapid calls
      try { await _bgPlayer.stop(); } catch (_) {}
      await _bgPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Failed to play background: $assetPath -> $e');
    }
  }

  Future<void> resumeBackground() async {
    try { await _bgPlayer.resume(); } catch (_) {}
  }

  Future<void> pauseBackground() async {
    try { await _bgPlayer.pause(); } catch (_) {}
  }

  Future<void> stopBackground() async {
    try { await _bgPlayer.stop(); } catch (_) {}
  }

  Future<void> playSfx(String assetFileName) async {
    try {
      if (!soundEnabled) return;
      // Prevent overlapping on rapid clicks by stopping/rewinding first
      try { await _sfxPlayer.stop(); } catch (_) {}
      await _sfxPlayer.play(AssetSource('sounds/$assetFileName'));
    } catch (e) {
      debugPrint('SFX play failed ($assetFileName): $e');
    }
  }

  Future<void> setMusicEnabled(bool enabled) async {
    musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefMusicKey, enabled);
    if (!enabled) {
      try { await stopBackground(); } catch (_) {}
    } else {
      // if enabled, caller may restart background as needed
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSoundKey, enabled);
  }

  Future<void> dispose() async {
    try { await _bgPlayer.dispose(); } catch (_) {}
    try { await _sfxPlayer.dispose(); } catch (_) {}
  }
}

/// Lightweight convenience function used by UI code that doesn't hold the manager instance.
Future<void> playSfxAsset(String assetFileName) async {
  try {
    final m = AudioManager();
    await m.playSfx(assetFileName);
  } catch (e) {
    debugPrint('Global SFX failed: $e');
  }
}
