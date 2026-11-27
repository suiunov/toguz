// The computer player. Evaluation weights were trained by self-play
// (see tools/tune.js in the repository). Same engine as the web version.
import 'dart:isolate';
import 'dart:math';

import 'rules.dart';

const List<double> aiWeights = [1, 22.5322, 0.1131, 1.1662, 0.8574, 0.3164];

/// Difficulty levels: Easy, Medium, Hard, Master, Grandmaster.
class Level {
  final int id;
  final int? depth;
  final int? timeMs;
  final double random;
  const Level(this.id, {this.depth, this.timeMs, this.random = 0});
}

const levels = <Level>[
  Level(1, depth: 2, random: .3),
  Level(4, depth: 4),
  Level(8, timeMs: 600),
  Level(99, timeMs: 1500),
  Level(100, timeMs: 3500),
];

Level levelById(int id) => levels.firstWhere((l) => l.id == id, orElse: () => levels[1]);

/// Best stones side [x] could capture with one move right now (cheap estimate).
int threat(GameState s, int x) {
  var best = 0;
  final o = x * 9;
  for (var i = o; i < o + 9; i++) {
    final n = s.b[i];
    if (n == 0) continue;
    final land = n == 1 ? (i + 1) % 18 : (i + n - 1) % 18;
    if ((land >= 9 ? 1 : 0) == x || s.t[0] == land || s.t[1] == land) continue;
    final c = s.b[land] + 1 + (n - 1) ~/ 18;
    if (c % 2 == 0) {
      if (c > best) best = c;
    } else if (c == 3 &&
        s.t[x] < 0 &&
        land % 9 != 8 &&
        !(s.t[1 - x] >= 0 && s.t[1 - x] % 9 == land % 9)) {
      if (6 > best) best = 6;
    }
  }
  return best;
}

double evaluate(GameState s, int me, List<double> w) {
  final op = 1 - me, b = s.b;
  var bm = 0, bo = 0, mm = 0, mo = 0;
  for (var i = 0; i < 9; i++) {
    final x = b[me * 9 + i], y = b[op * 9 + i];
    bm += x;
    bo += y;
    if (x > 0) mm++;
    if (y > 0) mo++;
  }
  final left = (bm + bo) / 162;
  final tz = ((s.t[me] >= 0 ? 1 : 0) - (s.t[op] >= 0 ? 1 : 0)) * left;
  final mover = s.turn;
  final tMove = threat(s, mover), tWait = threat(s, 1 - mover);
  final sg = mover == me ? 1 : -1;
  return w[0] * (s.k[me] - s.k[op]) +
      w[1] * tz +
      w[2] * (bm - bo) +
      w[3] * (mm - mo) +
      sg * (w[4] * tMove - w[5] * tWait);
}

class _Stop implements Exception {}

class _Entry {
  final int d;
  final double v;
  final int f; // 0 exact, 1 lower bound, 2 upper bound
  final int m;
  _Entry(this.d, this.v, this.f, this.m);
}

/// Finds a move for the player to move in [s].
/// Fixed [depth], or [timeMs] with deeper and deeper searches until time is up.
int searchMove(GameState s, {int? depth, int? timeMs, List<double> w = aiWeights}) {
  final me = s.turn;
  final end = timeMs != null ? DateTime.now().millisecondsSinceEpoch + timeMs : 0;
  var nodes = 0;
  final tt = <String, _Entry>{};

  List<int> ordered(GameState x, int ttm) {
    final ms = legalMoves(x);
    if (ms.length < 2) return ms;
    final sc = <List<int>>[];
    for (final m in ms) {
      final n = x.b[m], land = n == 1 ? (m + 1) % 18 : (m + n - 1) % 18;
      var v = 0;
      if ((land >= 9 ? 1 : 0) != x.turn && x.t[0] != land && x.t[1] != land) {
        final c = x.b[land] + 1;
        if (c % 2 == 0) {
          v = c;
        } else if (c == 3) {
          v = 4;
        }
      }
      if (m == ttm) v += 1000;
      sc.add([m, v]);
    }
    sc.sort((a, b) => b[1].compareTo(a[1]));
    return [for (final z in sc) z[0]];
  }

  double sr(GameState x, int d, double a, double bt) {
    if (timeMs != null && (++nodes & 1023) == 0 && DateTime.now().millisecondsSinceEpoch > end) {
      throw _Stop();
    }
    if (x.over) {
      final wn = x.winner!;
      return wn == me ? 1e5 + d : (wn < 0 ? 0.0 : -1e5 - d);
    }
    if (d == 0) return evaluate(x, me, w);
    final key = x.key();
    var ttm = -1;
    final e = tt[key];
    if (e != null) {
      if (e.d >= d) {
        if (e.f == 0) return e.v;
        if (e.f == 1 && e.v >= bt) return e.v;
        if (e.f == 2 && e.v <= a) return e.v;
      }
      ttm = e.m;
    }
    final a0 = a, b0 = bt, isMax = x.turn == me;
    var v = isMax ? -1e9 : 1e9;
    var bm = -1;
    for (final m in ordered(x, ttm)) {
      final c = x.copy();
      applyMove(c, m);
      final y = sr(c, d - 1, a, bt);
      if (isMax) {
        if (y > v) {
          v = y;
          bm = m;
        }
        if (v > a) a = v;
      } else {
        if (y < v) {
          v = y;
          bm = m;
        }
        if (v < bt) bt = v;
      }
      if (a >= bt) break;
    }
    tt[key] = _Entry(d, v, v <= a0 ? 2 : (v >= b0 ? 1 : 0), bm);
    if (tt.length > 300000) tt.clear();
    return v;
  }

  final root = legalMoves(s);
  if (root.isEmpty) return -1;
  var best = root.first;
  if (root.length == 1) return best;
  final maxD = depth ?? 40;
  var order = ordered(s, -1);
  for (var d = timeMs != null ? 2 : maxD; d <= maxD; d++) {
    final sc = <MapEntry<int, double>>[];
    var a = -1e9;
    var bm = order.first;
    try {
      for (final m in order) {
        final c = s.copy();
        applyMove(c, m);
        final v = sr(c, d - 1, a, 1e9);
        sc.add(MapEntry(m, v));
        if (v > a) {
          a = v;
          bm = m;
        }
      }
    } on _Stop {
      break;
    }
    best = bm;
    sc.sort((x, y) => y.value.compareTo(x.value));
    order = [for (final e in sc) e.key];
    if (timeMs == null) break;
    if (a >= 1e5 || DateTime.now().millisecondsSinceEpoch > end - timeMs * .55) break;
  }
  return best;
}

final _rnd = Random();

/// Chooses the computer's move for [levelId]. Runs in a background isolate
/// so the screen stays smooth while it thinks.
Future<int> thinkMove(GameState s, int levelId) async {
  final lv = levelById(levelId);
  final ms = legalMoves(s);
  if (ms.isEmpty) return -1;
  if (lv.random > 0 && _rnd.nextDouble() < lv.random) return ms[_rnd.nextInt(ms.length)];
  final j = s.toJson();
  final depth = lv.depth, time = lv.timeMs;
  try {
    return await Isolate.run(() => searchMove(GameState.fromJson(j), depth: depth, timeMs: time));
  } catch (_) {
    return searchMove(GameState.fromJson(j), depth: depth, timeMs: time);
  }
}
