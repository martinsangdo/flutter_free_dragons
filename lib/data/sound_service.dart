import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _muteKey = 'sound_muted';

  AudioPool? _pool;
  bool _muted = false;

  bool get isMuted => _muted;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _muted = prefs.getBool(_muteKey) ?? false;

    final bytes = _generateTokWav();
    _pool = await AudioPool.create(
      source: BytesSource(bytes),
      maxPlayers: 4,
    );
  }

  Future<void> play() async {
    if (_muted || _pool == null) return;
    await _pool!.start(volume: 0.9);
  }

  Future<void> toggleMute() async {
    _muted = !_muted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_muteKey, _muted);
  }

  // Two decaying sine waves mixed — gives a wooden "tok" timbre.
  Uint8List _generateTokWav() {
    const sampleRate = 44100;
    const numSamples = sampleRate * 70 ~/ 1000; // 70 ms

    final samples = Int16List(numSamples);
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final env = math.exp(-80.0 * t);
      final v = env *
          (0.6 * math.sin(2 * math.pi * 900 * t) +
              0.4 * math.sin(2 * math.pi * 1800 * t));
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
