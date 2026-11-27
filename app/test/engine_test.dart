import 'package:flutter_test/flutter_test.dart';
import 'package:toguz_korgool/engine/ai.dart';
import 'package:toguz_korgool/engine/rules.dart';
import 'package:toguz_korgool/engine/tasks.dart';

import 'recorded_games.dart';

void main() {
  test('first move from hole 1 sows 9 stones', () {
    final s = GameState.start();
    applyMove(s, 0);
    expect(s.b.sublist(0, 9), [1, 10, 10, 10, 10, 10, 10, 10, 10]);
    expect(s.turn, 1);
    expect(s.k, [0, 0]);
  });

  test('a single stone moves to the next hole', () {
    final s = GameState.start();
    s.b[4] = 1;
    applyMove(s, 4);
    expect(s.b[4], 0);
    expect(s.b[5], 10);
  });

  test('even count in the opponent hole is captured', () {
    final s = GameState(List<int>.filled(18, 4), [0, 0], [-1, -1], 0, null);
    s.b[8] = 2;
    s.b[9] = 5;
    final ev = applyMove(s, 8);
    expect(ev?.type, 'cap');
    expect(ev?.n, 6);
    expect(s.k[0], 6);
    expect(s.b[9], 0);
  });

  test('exactly 3 makes a tuzdyk', () {
    final s = GameState(List<int>.filled(18, 4), [0, 0], [-1, -1], 0, null);
    s.b[8] = 2;
    s.b[9] = 2;
    final ev = applyMove(s, 8);
    expect(ev?.type, 'tuz');
    expect(s.t[0], 9);
    expect(s.k[0], 3);
  });

  test('no tuzdyk on the opponent 9th hole', () {
    final s = GameState(List<int>.filled(18, 4), [0, 0], [-1, -1], 0, null);
    s.b[7] = 11; // last stone lands on hole index 17 (opponent hole 9)
    s.b[17] = 2;
    applyMove(s, 7);
    expect(s.t[0], -1);
  });

  test('rules match the web version over 5 recorded games', () {
    var checked = 0;
    for (final game in recordedGames) {
      final s = GameState.start();
      for (final step in game) {
        final ev = applyMove(s, step[0] as int);
        expect(s.b.join(','), step[1], reason: 'board after move $checked');
        expect(s.k.join(','), step[2]);
        expect(s.t.join(','), step[3]);
        expect(s.turn, step[4]);
        expect(s.winner, step[5]);
        expect(ev?.type ?? '', step[6]);
        checked++;
      }
    }
    expect(checked, greaterThan(500));
  });

  test('every task has exactly the stored answer as its best move', () {
    for (final t in tasks) {
      final ms = taskMoves(t);
      final best = ms.firstWhere((m) => m.m == t.answer);
      if (t.kind == 'tuz') {
        expect(best.tuz, isTrue);
      } else if (t.kind == 'win' || t.kind == 'win2') {
        expect(best.win, isTrue);
        expect(ms.where((m) => m.win).length, 1);
      } else {
        final maxGain = ms.map((m) => m.gain).reduce((a, b) => a > b ? a : b);
        expect(best.gain, maxGain);
      }
    }
  });

  test('computer always returns a legal move and takes an easy capture', () {
    final s = GameState(List<int>.filled(18, 4), [0, 0], [-1, -1], 0, null);
    s.b[8] = 2;
    s.b[9] = 9; // playing hole 9 makes 10 there: capture
    final m = searchMove(s, depth: 4);
    expect(legalMoves(s).contains(m), isTrue);
    final c = s.copy();
    final ev = applyMove(c, m);
    expect(ev?.type, 'cap');
    expect(searchMove(GameState.start(), timeMs: 300) >= 0, isTrue);
  });
}
