// Short sound effects (files in assets/sfx, made to match the web version's tones).
import 'package:audioplayers/audioplayers.dart';

class Sfx {
  static bool enabled = true;
  static const _names = ['drop', 'cap', 'tuz', 'win', 'lose', 'ok', 'bad'];
  static final Map<String, List<AudioPlayer>> _pool = {};
  static final Map<String, int> _next = {};

  static Future<void> init() async {
    for (final n in _names) {
      final players = <AudioPlayer>[];
      for (var i = 0; i < (n == 'drop' ? 4 : 2); i++) {
        final p = AudioPlayer();
        try {
          await p.setPlayerMode(PlayerMode.lowLatency);
          await p.setReleaseMode(ReleaseMode.stop);
          await p.setSource(AssetSource('sfx/$n.wav'));
        } catch (_) {}
        players.add(p);
      }
      _pool[n] = players;
      _next[n] = 0;
    }
  }

  static void play(String n) {
    if (!enabled) return;
    final ps = _pool[n];
    if (ps == null || ps.isEmpty) return;
    final i = _next[n]! % ps.length;
    _next[n] = i + 1;
    final p = ps[i];
    try {
      p.stop().then((_) => p.play(AssetSource('sfx/$n.wav'))).catchError((_) {});
    } catch (_) {}
  }
}
