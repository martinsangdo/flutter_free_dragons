import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles all audio. Sound effects (block-slide "tok", win chime) and the
/// ambient background music track are toggled independently and both settings
/// are persisted via [SharedPreferences] so they survive app restarts.
///
/// All audio is generated procedurally at runtime (no bundled asset files), so
/// there are no copyright concerns and nothing to download.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _sfxKey = 'sfx_enabled';
  static const _musicKey = 'music_enabled';

  AudioPool? _tokPool;
  AudioPlayer? _winPlayer;
  AudioPlayer? _musicPlayer;

  bool _sfxEnabled = true;
  bool _musicEnabled = false;

  bool get sfxEnabled => _sfxEnabled;
  bool get musicEnabled => _musicEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _sfxEnabled = prefs.getBool(_sfxKey) ?? true;
    _musicEnabled = prefs.getBool(_musicKey) ?? false;

    _tokPool = await AudioPool.create(
      source: BytesSource(_tokWav()),
      maxPlayers: 4,
    );
    _winPlayer = AudioPlayer();
    await _winPlayer!.setReleaseMode(ReleaseMode.stop);
    await _winPlayer!.setSource(BytesSource(_chimeWav()));

    _musicPlayer = AudioPlayer();
    await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer!.setSource(BytesSource(_ambientWav()));
    await _musicPlayer!.setVolume(0.25);
    if (_musicEnabled) await _musicPlayer!.resume();
  }

  /// Short "tok" played whenever a block slides one cell.
  Future<void> playMove() async {
    if (!_sfxEnabled || _tokPool == null) return;
    await _tokPool!.start(volume: 0.9);
  }

  /// Rising chime played when the key is freed.
  Future<void> playWin() async {
    if (!_sfxEnabled || _winPlayer == null) return;
    await _winPlayer!.seek(Duration.zero);
    await _winPlayer!.resume();
  }

  Future<void> setSfxEnabled(bool value) async {
    _sfxEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxKey, value);
  }

  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, value);
    if (_musicPlayer == null) return;
    if (value) {
      await _musicPlayer!.resume();
    } else {
      await _musicPlayer!.pause();
    }
  }

  void dispose() {
    _winPlayer?.dispose();
    _musicPlayer?.dispose();
  }

  // ── Procedural audio generation ───────────────────────────────────────────

  Uint8List _tokWav() {
    return _wav((t) {
      final env = math.exp(-80.0 * t);
      return env *
          (0.6 * math.sin(2 * math.pi * 900 * t) +
              0.4 * math.sin(2 * math.pi * 1800 * t));
    }, durationMs: 70);
  }

  Uint8List _chimeWav() {
    // Two ascending notes (C6 → E6-ish) with a soft decay.
    return _wav((t) {
      final freq = t < 0.12 ? 1046.5 : 1318.5;
      final local = t < 0.12 ? t : t - 0.12;
      final env = math.exp(-6.0 * local);
      return 0.5 *
          env *
          (math.sin(2 * math.pi * freq * t) +
              0.3 * math.sin(2 * math.pi * freq * 2 * t));
    }, durationMs: 500);
  }

  Uint8List _ambientWav() {
    // A slow, low-volume pad built from a soft chord with gentle tremolo.
    const freqs = [110.0, 164.81, 220.0]; // A2, E3, A3
    return _wav((t) {
      final tremolo = 0.85 + 0.15 * math.sin(2 * math.pi * 0.15 * t);
      double v = 0;
      for (final f in freqs) {
        v += math.sin(2 * math.pi * f * t);
      }
      return 0.18 * tremolo * v / freqs.length;
    }, durationMs: 4000);
  }

  /// Renders [sample] (t in seconds → amplitude in [-1, 1]) into a 16-bit mono
  /// PCM WAV byte buffer.
  Uint8List _wav(double Function(double t) sample, {required int durationMs}) {
    const sampleRate = 44100;
    final numSamples = sampleRate * durationMs ~/ 1000;
    final samples = Int16List(numSamples);
    for (int i = 0; i < numSamples; i++) {
      final v = sample(i / sampleRate);
      samples[i] = (v * 28000).round().clamp(-32768, 32767);
    }

    final dataSize = numSamples * 2;
    final buf = ByteData(44 + dataSize);
    void setStr(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        buf.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    setStr(0, 'RIFF');
    buf.setUint32(4, 36 + dataSize, Endian.little);
    setStr(8, 'WAVE');
    setStr(12, 'fmt ');
    buf.setUint32(16, 16, Endian.little);
    buf.setUint16(20, 1, Endian.little); // PCM
    buf.setUint16(22, 1, Endian.little); // mono
    buf.setUint32(24, sampleRate, Endian.little);
    buf.setUint32(28, sampleRate * 2, Endian.little);
    buf.setUint16(32, 2, Endian.little);
    buf.setUint16(34, 16, Endian.little);
    setStr(36, 'data');
    buf.setUint32(40, dataSize, Endian.little);
    for (int i = 0; i < numSamples; i++) {
      buf.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return buf.buffer.asUint8List();
  }
}
