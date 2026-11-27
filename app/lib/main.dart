import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';
import 'i18n.dart';
import 'ui/board.dart';
import 'ui/common.dart';
import 'ui/menu.dart';
import 'ui/task_panel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: C.feltDark,
  ));
  runApp(const ToguzApp());
}

class ToguzApp extends StatefulWidget {
  const ToguzApp({super.key});
  @override
  State<ToguzApp> createState() => _ToguzAppState();
}

class _ToguzAppState extends State<ToguzApp> {
  final c = GameController();
  bool ready = false;

  @override
  void initState() {
    super.initState();
    c.load().then((_) => setState(() => ready = true));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => MaterialApp(
        title: c.t.title,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: C.felt,
          colorScheme: ColorScheme.fromSeed(seedColor: C.felt, brightness: Brightness.dark, primary: C.gold),
        ),
        home: ready ? GameScreen(c) : const Scaffold(backgroundColor: C.felt),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final GameController c;
  const GameScreen(this.c, {super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String drawerView = 'main';
  GameController get c => widget.c;

  @override
  void initState() {
    super.initState();
    c.addListener(_checkOver);
  }

  @override
  void dispose() {
    c.removeListener(_checkOver);
    super.dispose();
  }

  void _checkOver() {
    if (c.s.over && !c.overShown && c.task == null) {
      c.overShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOver());
    }
  }

  void _showOver() {
    final t = c.t, w = c.s.winner!, nm = c.names;
    final title = w < 0 ? t.drawT : (c.mode == 'ai' ? (w == 0 ? t.youWin : t.compWins) : t.wins(nm[w]));
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF9A6634), Color(0xFF6D4220)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 40, offset: Offset(0, 20))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: C.ink, height: 1.1)),
              const SizedBox(height: 8),
              Text('${nm[0]} ${c.s.k[0]} – ${c.s.k[1]} ${nm[1]}',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: C.ink)),
              const SizedBox(height: 18),
              Btn(t.playAgain, main: true, onTap: () {
                Navigator.of(ctx).pop();
                c.newGame();
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _openMenu(String v) {
    setState(() => drawerView = v);
    WidgetsBinding.instance.addPostFrameCallback((_) => scaffoldKey.currentState?.openDrawer());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final t = c.t;
        return Scaffold(
          key: scaffoldKey,
          drawer: MenuDrawer(c, key: ValueKey('menu-$drawerView'), startView: drawerView),
          onDrawerChanged: (open) {
            if (!open && drawerView != 'main') setState(() => drawerView = 'main');
          },
          body: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: FeltPainter())),
              SafeArea(
                child: Column(
                  children: [
                    _topBar(t),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Column(
                              children: [
                                _bubbles(),
                                _players(),
                                if (c.task != null) TaskPanel(c, openList: () => _openMenu('tasks')),
                                BoardView(c),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _iconBtn(IconData ic, String tip, VoidCallback? onTap, {bool gold = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: gold ? C.gold.withValues(alpha: .9) : Colors.black.withValues(alpha: .22),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Tooltip(
              message: tip,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(ic, color: gold ? C.goldInk : (onTap == null ? C.ink.withValues(alpha: .35) : C.ink)),
              ),
            ),
          ),
        ),
      );

  Widget _topBar(Tx t) {
    final sub = c.task != null ? t.tasks : '${t.modes[c.mode]}${c.mode == '2p' ? '' : ' · ${t.levels[c.level]}'}';
    final canUndo = !c.busy && c.hist.isNotEmpty && c.task == null;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xB8460A12),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .08))),
      ),
      child: Row(
        children: [
          _iconBtn(Icons.menu, t.menu, () => _openMenu('main')),
          Expanded(
            child: Column(
              children: [
                Text(t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.ink, letterSpacing: .2)),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: C.soft)),
              ],
            ),
          ),
          if (c.mode != 'cc') _iconBtn(Icons.undo, t.undo, canUndo ? c.undo : null),
          if (c.mode == 'cc' && c.task == null)
            _iconBtn(c.paused ? Icons.play_arrow_rounded : Icons.pause_rounded, c.paused ? t.play : t.pause, c.togglePause,
                gold: true),
          _iconBtn(Icons.refresh, t.newGame, c.newGame),
        ],
      ),
    );
  }

  Widget _bubbles() {
    Widget one(int p, bool right) {
      final txt = c.bubble[p];
      if (txt.isEmpty) return const SizedBox(height: 64);
      final old = c.bubbleOwner != p;
      return Align(
        alignment: right ? Alignment.bottomRight : Alignment.bottomLeft,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: old ? .5 : 1,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: p == 1 ? const Color(0xFFE6F4FF) : const Color(0xFFFFF7EE),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: Text(txt,
                textAlign: right ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: p == 1 ? const Color(0xFF0D3B66) : const Color(0xFF3A1A08),
                    height: 1.3)),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 74),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: one(1, false)),
          const SizedBox(width: 12),
          Expanded(child: one(0, true)),
        ],
      ),
    );
  }

  Widget _players() {
    Widget card(int p, bool right) {
      final on = c.task != null ? p == 0 : ((!c.s.over && c.s.turn == p) || (c.s.over && c.s.winner == p));
      final av = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-.3, -.4),
            colors: p == 1
                ? const [Color(0xFFF2FAFF), C.blue, Color(0xFF3D86C2)]
                : const [Colors.white, Color(0xFFF6ECD8), Color(0xFFB9A98A)],
          ),
          border: on ? Border.all(color: C.gold, width: 3) : null,
          boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 6, offset: Offset(0, 3))],
        ),
      );
      final txt = Expanded(
        child: Column(
          crossAxisAlignment: right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(c.names[p],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.ink)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: right ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(c.status(p),
                  maxLines: 1,
                  style: TextStyle(fontSize: 13, color: on ? C.gold : C.soft, fontWeight: on ? FontWeight.w500 : FontWeight.w400)),
            ),
          ],
        ),
      );
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: on ? 1 : .7,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: on ? .34 : .22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: on ? C.gold : Colors.white.withValues(alpha: .08), width: 2),
          ),
          child: Row(
            children: right ? [txt, const SizedBox(width: 10), av] : [av, const SizedBox(width: 10), txt],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: card(1, false)),
          const SizedBox(width: 12),
          Expanded(child: card(0, true)),
        ],
      ),
    );
  }
}
