// The 10 tasks: positions and answers checked with the game rules (same as the web version).
import 'rules.dart';

class Task {
  final List<int> b, k, t;
  final String kind; // cap, max, tuz, usetuz, win, win2
  final int answer; // hole index 0..8
  final int level; // 0 beginner .. 3 master
  const Task(this.b, this.k, this.t, this.kind, this.answer, this.level);
  GameState start() => GameState(List<int>.of(b), List<int>.of(k), List<int>.of(t), 0, null);
}

const tasks = <Task>[
  Task([10, 4, 0, 6, 7, 4, 10, 13, 6, 10, 5, 9, 5, 6, 8, 4, 5, 1], [18, 31], [-1, 2], 'cap', 4, 0),
  Task([4, 7, 10, 5, 4, 0, 6, 9, 10, 7, 6, 8, 8, 8, 7, 9, 4, 8], [7, 35], [-1, 5], 'cap', 7, 0),
  Task([4, 10, 10, 10, 3, 3, 0, 7, 5, 7, 9, 8, 8, 10, 10, 6, 6, 1], [23, 22], [-1, 6], 'cap', 1, 0),
  Task([6, 7, 9, 7, 9, 17, 7, 13, 9, 9, 7, 5, 7, 9, 4, 6, 8, 7], [9, 7], [-1, -1], 'max', 3, 1),
  Task([8, 8, 7, 8, 11, 6, 6, 8, 8, 9, 6, 10, 4, 4, 3, 7, 3, 8], [26, 12], [-1, -1], 'max', 8, 1),
  Task([12, 9, 5, 6, 4, 9, 6, 3, 11, 5, 10, 6, 11, 2, 2, 13, 6, 6], [10, 26], [-1, -1], 'tuz', 5, 1),
  Task([10, 8, 7, 6, 8, 3, 8, 6, 6, 2, 2, 6, 10, 3, 8, 2, 11, 5], [6, 45], [-1, -1], 'tuz', 0, 2),
  Task([6, 6, 12, 8, 7, 8, 11, 8, 9, 3, 5, 5, 0, 7, 4, 4, 5, 5], [31, 18], [12, -1], 'usetuz', 2, 2),
  Task([1, 1, 2, 3, 1, 7, 1, 0, 1, 1, 1, 5, 2, 1, 5, 1, 0, 3], [76, 50], [-1, -1], 'win', 5, 2),
  Task([0, 0, 4, 1, 1, 3, 1, 3, 3, 5, 2, 1, 5, 3, 2, 2, 0, 2], [76, 48], [-1, 0], 'win2', 7, 3),
];

/// What one possible move in a task gives (for hints and the best-move list).
class MoveInfo {
  final int m, gain, n, q, c, k0;
  final bool tuz, win;
  const MoveInfo(this.m, this.gain, this.tuz, this.win, this.n, this.q, this.c, this.k0);
}

List<MoveInfo> taskMoves(Task t) {
  final s = t.start();
  final out = <MoveInfo>[];
  for (final m in legalMoves(s)) {
    final c = s.copy();
    final fr = <Frame>[];
    final ev = applyMove(c, m, fr);
    final pre = fr.length > 1 ? fr[fr.length - 2] : fr[0];
    out.add(MoveInfo(m, c.k[0] - s.k[0], ev?.type == 'tuz', c.winner == 0, s.b[m], pre.pos,
        pre.s.b[pre.pos], s.k[0]));
  }
  return out;
}

/// Was the move a correct answer to the task?
bool taskSolved(Task t, int move, MoveEvent? ev, GameState after) {
  if (t.kind == 'tuz') return ev?.type == 'tuz';
  if (t.kind == 'win' || t.kind == 'win2') return after.winner == 0;
  return move == t.answer;
}
