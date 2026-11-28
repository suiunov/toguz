// Game state for the whole app: board, animation, computer turns, tasks, settings.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/ai.dart';
import 'engine/rules.dart';
import 'engine/tasks.dart';
import 'i18n.dart';
import 'sound.dart';

/// [ms per stone, pause between turns (computer vs computer), pause before the computer answers]
const speeds = [
  [650, 3000, 1500],
  [380, 2000, 1100],
  [200, 1200, 800],
  [70, 1000, 450],
  [0, 700, 400],
];

/// A stone flying from one place to another. [from]/[to] are hole indexes 0..17,
/// or 100 / 101 for the kazan of player 0 / 1.
class Flight {
  final int from, to;
  final int startMs, durMs;
  Flight(this.from, this.to, this.startMs, this.durMs);
}

class TaskRun {
  final int i;
  bool done = false, ok = false, hint = false, best = false, summary = false;
  int gain = 0;
  TaskRun(this.i);
}

class GameController extends ChangeNotifier {
  late SharedPreferences _prefs;
  GameState s = GameState.start();
  final List<GameState> hist = [];
  String mode = 'ai'; // ai, 2p, cc
  int level = 4;
  int speed = 1;
  String lang = 'ky';
  bool sound = true, vibrate = true, aimOn = true, showNums = true;
  bool busy = false, paused = false, thinking = false;
  int last = -1, land = -1, aimFrom = -1;
  final List<String> bubble = ['', '']; // last move text per player
  int bubbleOwner = -1;
  TaskRun? task;
  List<bool> solved = List<bool>.filled(tasks.length, false);
  final List<Flight> flights = [];
  int _moveId = 0;
  Timer? _ai, _anim;
  bool overShown = true;

  Tx get t => lang == 'en' ? en : ky;
  int get nowMs => DateTime.now().millisecondsSinceEpoch;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    mode = _prefs.getString('mode') ?? 'ai';
    if (!['ai', '2p', 'cc'].contains(mode)) mode = 'ai';
    level = _prefs.getInt('level') ?? 4;
    if (levels.every((l) => l.id != level)) level = 4;
    speed = (_prefs.getInt('speed') ?? 1).clamp(0, 4).toInt();
    lang = _prefs.getString('lang') ?? 'ky';
    sound = _prefs.getBool('sound') ?? true;
    vibrate = _prefs.getBool('vibrate') ?? true;
    aimOn = _prefs.getBool('aim') ?? true;
    showNums = _prefs.getBool('nums') ?? true;
    final sv = _prefs.getString('solved');
    if (sv != null) {
      final l = (jsonDecode(sv) as List).cast<bool>();
      for (var i = 0; i < l.length && i < solved.length; i++) {
        solved[i] = l[i];
      }
    }
    Sfx.enabled = sound;
    await Sfx.init();
    newGame();
  }

  void _save() {
    _prefs.setString('mode', mode);
    _prefs.setInt('level', level);
    _prefs.setInt('speed', speed);
    _prefs.setString('lang', lang);
    _prefs.setBool('sound', sound);
    _prefs.setBool('vibrate', vibrate);
    _prefs.setBool('aim', aimOn);
    _prefs.setBool('nums', showNums);
    _prefs.setString('solved', jsonEncode(solved));
  }

  // ---------- names and status ----------
  List<String> get names {
    if (task != null) return [t.you, t.opponent];
    if (mode == 'ai') return [t.you, t.computer];
    if (mode == 'cc') return [t.comp(1), t.comp(2)];
    return [t.player(1), t.player(2)];
  }

  String status(int p) {
    if (task != null) return p == 0 ? t.taskSt : '';
    if (s.over) return s.winner == p ? t.winner : (s.winner! < 0 ? t.draw : '');
    if (s.turn != p) return t.waiting;
    if (mode == 'cc') return paused ? t.paused : t.thinking;
    if (mode == 'ai') return p == 1 ? t.thinking : t.yourTurn;
    return t.turn;
  }

  bool get computerTurn =>
      !s.over && task == null && ((mode == 'ai' && s.turn == 1) || (mode == 'cc' && !paused));

  bool canTap(int i) {
    if (busy) return false;
    if (task != null) return !task!.done && i < 9 && s.b[i] > 0;
    return !s.over && s.b[i] > 0 && i ~/ 9 == s.turn && mode != 'cc' && !(mode == 'ai' && s.turn == 1);
  }

  bool isHint(int i) => task != null && !task!.done && task!.best && tasks[task!.i].answer == i;

  int get aimTo => aimOn && aimFrom >= 0 && s.b[aimFrom] > 0 ? landingHole(s, aimFrom) : -1;

  // ---------- game flow ----------
  void _stopAll() {
    _ai?.cancel();
    _anim?.cancel();
    _moveId++;
    busy = false;
    land = -1;
    flights.clear();
  }

  void newGame() {
    _stopAll();
    task = null;
    s = GameState.start();
    hist.clear();
    last = -1;
    aimFrom = -1;
    bubble[0] = bubble[1] = '';
    bubbleOwner = -1;
    overShown = true;
    notifyListeners();
    _schedule();
  }

  void _schedule() {
    _ai?.cancel();
    if (!computerTurn) return;
    _ai = Timer(Duration(milliseconds: speeds[speed][mode == 'cc' ? 1 : 2]), _computerMove);
  }

  Future<void> _computerMove() async {
    if (!computerTurn || busy || thinking) return;
    final id = _moveId;
    final snap = s.copy();
    thinking = true;
    notifyListeners();
    final m = await thinkMove(snap, level);
    thinking = false;
    if (id != _moveId || !computerTurn || busy || s.key() != snap.key() || m < 0) {
      notifyListeners();
      _schedule();
      return;
    }
    play(m);
  }

  void tapHole(int i) {
    if (!canTap(i)) return;
    aimFrom = -1;
    if (vibrate) HapticFeedback.selectionClick();
    play(i);
  }

  void setAim(int i) {
    if (!aimOn || aimFrom == i) return;
    aimFrom = i;
    notifyListeners();
  }

  void play(int i) {
    if (busy || s.over) return;
    hist.add(s.copy());
    final before = s;
    final frames = <Frame>[];
    final after = s.copy();
    final p = s.turn;
    final ev = applyMove(after, i, frames);
    final you = (task != null || mode == 'ai') && p == 0;
    final mv = t.played(i % 9 + 1, you);
    last = i;
    busy = true;
    bubble[p] = mv;
    bubbleOwner = p;
    final id = ++_moveId;
    final step = speeds[speed][0];
    final n0 = before.b[i];

    void done() {
      if (id != _moveId) return;
      s = after;
      land = -1;
      busy = false;
      if (ev != null) {
        bubble[p] = '$mv ${ev.type == 'cap' ? t.took(ev.n, you) : t.tuzT(ev.hole, you)}';
        Sfx.play(ev.type == 'cap' ? 'cap' : 'tuz');
        if (vibrate) HapticFeedback.mediumImpact();
        if (step > 0) {
          final q = frames.last.pos, cnt = ev.type == 'cap' ? ev.n : 3;
          for (var j = 0; j < cnt && j < 12; j++) {
            flights.add(Flight(q, 100 + p, nowMs + j * 55, 520));
          }
        }
      }
      if (task != null) {
        task!.done = true;
        task!.gain = s.k[0] - before.k[0];
        task!.ok = taskSolved(tasks[task!.i], i, ev, s);
        if (task!.ok && !task!.best) {
          solved[task!.i] = true;
          _save();
        }
        Sfx.play(task!.ok ? 'ok' : 'bad');
        notifyListeners();
        return;
      }
      if (s.over) {
        overShown = false;
        Sfx.play(s.winner! < 0 ? 'cap' : (mode == 'ai' && s.winner == 1 ? 'lose' : 'win'));
      }
      notifyListeners();
      if (!s.over) _schedule();
    }

    if (step == 0) {
      done();
      return;
    }
    var f = 0;
    void tick() {
      if (id != _moveId) return;
      if (f < frames.length - 1) {
        final fr = frames[f];
        final from = f == 0 ? (n0 == 1 ? i : -1) : frames[f - 1].pos;
        final to = fr.pos;
        s = fr.s;
        land = to;
        if (from >= 0 && from != to) {
          flights.add(Flight(from, to, nowMs, (step * .78).round()));
          final own = fr.s.t[0] == to ? 0 : (fr.s.t[1] == to ? 1 : -1);
          if (own >= 0) flights.add(Flight(to, 100 + own, nowMs + (step * .78).round(), (step * .6).round()));
        }
        Timer(Duration(milliseconds: (step * .75).round()), () {
          if (id == _moveId) Sfx.play('drop');
        });
        notifyListeners();
        f++;
        _anim = Timer(Duration(milliseconds: step), tick);
      } else {
        done();
      }
    }

    tick();
  }

  void undo() {
    if (busy || hist.isEmpty || task != null) return;
    _stopAll();
    s = hist.removeLast();
    if (mode == 'ai') {
      while (s.turn == 1 && hist.isNotEmpty) {
        s = hist.removeLast();
      }
    }
    last = -1;
    bubble[0] = bubble[1] = '';
    overShown = true;
    notifyListeners();
    _schedule();
  }

  void togglePause() {
    paused = !paused;
    notifyListeners();
    _schedule();
  }

  void removeFinishedFlights() {
    final now = nowMs;
    flights.removeWhere((f) => now > f.startMs + f.durMs);
  }

  // ---------- settings ----------
  void setMode(String m) {
    mode = m;
    paused = false;
    _save();
    newGame();
  }

  void setLevel(int l) {
    level = l;
    _save();
    notifyListeners();
  }

  void setSpeed(int v) {
    speed = v;
    _save();
    notifyListeners();
    _schedule();
  }

  void setLang(String l) {
    lang = l;
    _save();
    notifyListeners();
  }

  void setSound(bool v) {
    sound = v;
    Sfx.enabled = v;
    _save();
    notifyListeners();
    Sfx.play('ok');
  }

  void setVibrate(bool v) {
    vibrate = v;
    _save();
    if (v) HapticFeedback.mediumImpact();
    notifyListeners();
  }

  void setAimOn(bool v) {
    aimOn = v;
    aimFrom = -1;
    _save();
    notifyListeners();
  }

  void setShowNums(bool v) {
    showNums = v;
    _save();
    notifyListeners();
  }

  void resetProgress() {
    solved = List<bool>.filled(tasks.length, false);
    _save();
    notifyListeners();
  }

  int get solvedCount => solved.where((x) => x).length;

  // ---------- tasks ----------
  void startTask(int i) {
    _stopAll();
    overShown = true;
    if (i >= tasks.length) {
      task = TaskRun(i)
        ..summary = true
        ..done = true;
      s = GameState.start();
    } else {
      task = TaskRun(i);
      s = tasks[i].start();
    }
    hist.clear();
    last = -1;
    aimFrom = -1;
    bubble[0] = bubble[1] = '';
    notifyListeners();
  }

  void showHint() {
    if (task == null || task!.done) return;
    task!.hint = true;
    notifyListeners();
  }

  void showBest() {
    if (task == null || task!.summary) return;
    final i = task!.i;
    startTask(i);
    task!.best = true;
    notifyListeners();
  }

  String hintText() {
    final tk = tasks[task!.i];
    final ms = taskMoves(tk);
    final b = ms.firstWhere((x) => x.m == tk.answer);
    if (tk.kind == 'usetuz') return t.hintUse(tk.t[0] % 9 + 1);
    final h = b.q % 9 + 1, x = tk.b[b.q];
    return b.tuz ? t.hintTuz(h, x) : t.hintCap(h, x);
  }

  String explainBest() {
    final tk = tasks[task!.i];
    final ms = taskMoves(tk);
    final b = ms.firstWhere((x) => x.m == tk.answer);
    final a = b.m + 1, h = b.q % 9 + 1;
    var r = tk.kind == 'usetuz'
        ? t.exUse(a, b.n, b.gain)
        : b.tuz
            ? t.exTuz(a, b.n, h)
            : b.q >= 9
                ? t.exCap(a, b.n, h, b.c, b.gain)
                : t.exOwn(a, b.gain);
    if (b.win) r += t.exWin(b.k0 + b.gain);
    return r;
  }

  List<MapEntry<String, bool>> bestList() {
    final tk = tasks[task!.i];
    return [
      for (final m in taskMoves(tk))
        MapEntry(t.li(m.m + 1, m.tuz ? t.tuzW : '${m.gain}'), m.m == tk.answer)
    ];
  }

  String taskResultText() {
    final tk = tasks[task!.i];
    if (!task!.ok) return t.wrong(task!.gain, tk.answer + 1);
    final pre = task!.best ? t.correctHelp : t.correct;
    if (tk.kind == 'tuz') return pre + t.madeTuz;
    if (tk.kind == 'win' || tk.kind == 'win2') return pre + t.winWith(s.k[0]);
    return pre + t.tookG(task!.gain);
  }

  @override
  void dispose() {
    _stopAll();
    super.dispose();
  }
}
