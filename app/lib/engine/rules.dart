// Toguz Korgool rules. Same rules as the web version (index.html).
// Holes 0..8 belong to player 0 (bottom), 9..17 to player 1 (top).
// Sowing goes 0 -> 17 and wraps around (counter-clockwise on the board).

class GameState {
  List<int> b; // stones in each of the 18 holes
  List<int> k; // kazan of each player
  List<int> t; // tuzdyk hole owned by each player, -1 = none
  int turn; // 0 or 1
  int? winner; // null = game goes on, 0 / 1 = winner, -1 = draw

  GameState(this.b, this.k, this.t, this.turn, this.winner);

  factory GameState.start() =>
      GameState(List<int>.filled(18, 9), [0, 0], [-1, -1], 0, null);

  bool get over => winner != null;

  GameState copy() =>
      GameState(List<int>.of(b), List<int>.of(k), List<int>.of(t), turn, winner);

  Map<String, dynamic> toJson() => {'b': b, 'k': k, 't': t, 'turn': turn, 'w': winner};

  static GameState fromJson(Map<String, dynamic> j) => GameState(
      List<int>.from(j['b'] as List), List<int>.from(j['k'] as List),
      List<int>.from(j['t'] as List), j['turn'] as int, j['w'] as int?);

  String key() => '${b.join(',')}|${k[0]}|${t[0]}|${t[1]}|$turn';
}

/// What happened at the end of a move.
class MoveEvent {
  final String type; // 'cap' or 'tuz'
  final int n; // stones captured (cap)
  final int hole; // hole number 1..9 on the opponent's side (tuz)
  const MoveEvent(this.type, {this.n = 0, this.hole = 0});
}

/// One step of the sowing animation: the board after a stone lands at [pos].
class Frame {
  final GameState s;
  final int pos;
  const Frame(this.s, this.pos);
}

List<int> legalMoves(GameState s) {
  final o = s.turn * 9;
  return [for (var i = o; i < o + 9; i++) if (s.b[i] > 0) i];
}

void _drop(GameState s, int pos) {
  if (s.t[0] == pos) {
    s.k[0]++;
  } else if (s.t[1] == pos) {
    s.k[1]++;
  } else {
    s.b[pos]++;
  }
}

/// Plays hole [i] for the player to move. Changes [s] in place.
/// If [frames] is given, a snapshot is added after every stone.
MoveEvent? applyMove(GameState s, int i, [List<Frame>? frames]) {
  final p = s.turn, n = s.b[i];
  s.b[i] = 0;
  var pos = i;
  MoveEvent? ev;
  void snap(int q) => frames?.add(Frame(s.copy(), q));
  if (n == 1) {
    pos = (i + 1) % 18;
    _drop(s, pos);
    snap(pos);
  } else {
    _drop(s, i);
    snap(i);
    for (var j = 1; j < n; j++) {
      pos = (pos + 1) % 18;
      _drop(s, pos);
      snap(pos);
    }
  }
  final side = pos >= 9 ? 1 : 0;
  if (side != p && s.t[0] != pos && s.t[1] != pos) {
    final c = s.b[pos];
    if (c % 2 == 0) {
      s.k[p] += c;
      s.b[pos] = 0;
      ev = MoveEvent('cap', n: c);
    } else if (c == 3 &&
        s.t[p] < 0 &&
        pos % 9 != 8 &&
        !(s.t[1 - p] >= 0 && s.t[1 - p] % 9 == pos % 9)) {
      s.t[p] = pos;
      s.k[p] += 3;
      s.b[pos] = 0;
      ev = MoveEvent('tuz', hole: pos % 9 + 1);
    }
  }
  s.turn = 1 - p;
  if (s.k[p] > 81) {
    s.winner = p;
  } else if (legalMoves(s).isEmpty) {
    final o = p * 9;
    for (var j = o; j < o + 9; j++) {
      s.k[p] += s.b[j];
      s.b[j] = 0;
    }
    s.winner = s.k[0] > s.k[1] ? 0 : (s.k[1] > s.k[0] ? 1 : -1);
  }
  snap(pos);
  return ev;
}

/// Where the last stone of hole [i] will land.
int landingHole(GameState s, int i) {
  final n = s.b[i];
  return n == 1 ? (i + 1) % 18 : (i + n - 1) % 18;
}
