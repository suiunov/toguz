import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../controller.dart';
import 'common.dart';

/// The wooden board: 2 rows of 9 holes, the two kazans in the middle,
/// and a layer on top where stones jump between holes.
class BoardView extends StatefulWidget {
  final GameController c;
  const BoardView(this.c, {super.key});
  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  final stackKey = GlobalKey();
  final holeKeys = List.generate(18, (_) => GlobalKey());
  final kazanKeys = List.generate(2, (_) => GlobalKey());

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final top = [for (var i = 17; i >= 9; i--) i];
    final bot = [for (var i = 0; i < 9; i++) i];
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
            begin: Alignment(-.3, -1), end: Alignment(.3, 1), colors: [C.wood1, C.wood2, C.wood3], stops: [0, .55, 1]),
        border: Border.all(color: const Color(0xFF43250F), width: 3),
        boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 30, offset: Offset(0, 16))],
      ),
      child: Stack(
        key: stackKey,
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              _nums(top.map((i) => '${i - 8}').toList()),
              _row(c, top, true),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _Kazan(c, 1, kazanKeys[1])),
                  const SizedBox(width: 8),
                  Expanded(child: _Kazan(c, 0, kazanKeys[0])),
                ],
              ),
              const SizedBox(height: 8),
              _row(c, bot, false),
              _nums(bot.map((i) => '${i + 1}').toList()),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(child: _FlightLayer(c, stackKey, holeKeys, kazanKeys)),
          ),
        ],
      ),
    );
  }

  Widget _nums(List<String> l) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            for (final s in l)
              Expanded(
                child: Text(s,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFF6E2C4))),
              ),
          ],
        ),
      );

  Widget _row(GameController c, List<int> idx, bool isTop) {
    final dim = !c.s.over && c.task == null && c.s.turn != (isTop ? 1 : 0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final i in idx)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: dim ? .5 : 1,
                child: _HoleCell(c, i, isTop, holeKeys[i]),
              ),
            ),
          ),
      ],
    );
  }
}

/// One hole with its count badge outside it (toward the kazans).
class _HoleCell extends StatelessWidget {
  final GameController c;
  final int i;
  final bool isTop;
  final GlobalKey holeKey;
  const _HoleCell(this.c, this.i, this.isTop, this.holeKey);

  @override
  Widget build(BuildContext context) {
    final own = c.s.t[0] == i ? 0 : (c.s.t[1] == i ? 1 : -1);
    final n = c.s.b[i];
    final badge = own >= 0
        ? SizedBox(
            height: 20,
            child: Text(c.t.tz,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: own == 1 ? C.blue : C.gold)),
          )
        : Container(
            height: 20,
            constraints: const BoxConstraints(minWidth: 26),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF6CF62), C.goldDark]),
              borderRadius: BorderRadius.circular(99),
              boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 2))],
            ),
            child: Text('$n',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: C.goldInk, height: 1.1)),
          );
    final hole = _Hole(c, i, own, holeKey);
    return Column(
      children: isTop
          ? [hole, const SizedBox(height: 5), badge]
          : [badge, const SizedBox(height: 5), hole],
    );
  }
}

class _Hole extends StatelessWidget {
  final GameController c;
  final int i, own;
  final GlobalKey holeKey;
  const _Hole(this.c, this.i, this.own, this.holeKey);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final s = max(4.0, (w - 9) / 2), p = s + 1.3;
      final h = p * 8 + s + w * .14 + 12;
      final can = c.canTap(i), hint = c.isHint(i), aim = c.aimTo == i;
      final isLast = c.last == i;
      Color? ring;
      double ringW = 0;
      List<BoxShadow> glow = const [];
      if (aim) {
        ring = const Color(0xFF62E08D);
        ringW = 3;
        glow = const [BoxShadow(color: Color(0x9962E08D), blurRadius: 14)];
      } else if (hint) {
        ring = C.gold;
        ringW = 4;
        glow = const [BoxShadow(color: Color(0x99F4C247), blurRadius: 16)];
      } else if (isLast) {
        ring = C.gold;
        ringW = 3;
        glow = const [BoxShadow(color: Color(0x73F4C247), blurRadius: 12)];
      } else if (can) {
        ring = const Color(0x99FFECC8);
        ringW = 2;
      }
      Widget inner;
      BoxDecoration deco;
      if (own >= 0) {
        final tc = own == 1 ? C.blue : C.gold;
        deco = BoxDecoration(
          borderRadius: BorderRadius.circular(w / 2),
          gradient: RadialGradient(
              colors: own == 1
                  ? const [Color(0xFF1D4F78), Color(0xFF122C44), Color(0xFF0D1A28)]
                  : const [Color(0xFF7A5413), Color(0xFF3A2209), Color(0xFF24140A)],
              stops: const [0, .6, 1]),
          border: Border.all(color: tc, width: 2.5),
          boxShadow: [BoxShadow(color: tc.withValues(alpha: .35), blurRadius: 12)],
        );
        inner = Padding(
          padding: EdgeInsets.symmetric(vertical: h * .12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: w * .62, height: w * .52, child: CustomPaint(painter: CrownPainter(tc))),
              Text(c.t.tuzLbl,
                  style: TextStyle(color: tc, fontWeight: FontWeight.w800, fontSize: min(12.0, w * .3), letterSpacing: .6)),
              Icon(Icons.star_rounded, color: tc, size: w * .5),
            ],
          ),
        );
      } else {
        deco = BoxDecoration(
          borderRadius: BorderRadius.circular(w / 2),
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF140A04), Color(0xFF24130A), Color(0xFF3A2312)],
              stops: [0, .45, 1]),
          border: ring != null ? Border.all(color: ring, width: ringW) : null,
          boxShadow: glow,
        );
        inner = Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: w * .14),
            child: _Stones(c.s.b[i], s, p, fresh: c.land == i),
          ),
        );
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => c.tapHole(i),
        onLongPressStart: (_) {
          if (can) c.setAim(i);
        },
        onLongPressEnd: (_) => c.setAim(-1),
        onLongPressCancel: () => c.setAim(-1),
        child: Container(key: holeKey, height: h, decoration: deco, child: inner),
      );
    });
  }
}

/// Stones in a hole: 2 columns x 9 rows; stones 19+ settle into the gap between the columns.
class _Stones extends StatelessWidget {
  final int n;
  final double s, p;
  final bool fresh;
  const _Stones(this.n, this.s, this.p, {this.fresh = false});

  @override
  Widget build(BuildContext context) {
    final m = min(n, 54);
    final kids = <Widget>[];
    for (var k = 0; k < m; k++) {
      double x, y;
      var layer = 0;
      if (k < 18) {
        x = (k % 2).toDouble();
        y = (k >> 1).toDouble();
      } else if (k < 27) {
        layer = 1;
        x = .5;
        y = (k - 18) + .5;
      } else if (k < 45) {
        layer = 2;
        final q = k - 27;
        x = (q % 2).toDouble();
        y = (q >> 1) + .3;
      } else {
        layer = 3;
        x = .5;
        y = (k - 45) + .8;
      }
      if (y > 8.3) y = 8.3;
      Widget ball = Ball(s, raised: layer > 0);
      if (fresh && k == m - 1) {
        ball = TweenAnimationBuilder<double>(
          key: ValueKey('new$n'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 380),
          curve: const Interval(.55, 1, curve: Curves.easeOutBack),
          builder: (_, v, child) => Opacity(opacity: v.clamp(0.0, 1.0).toDouble(), child: Transform.scale(scale: .3 + .7 * v, child: child)),
          child: ball,
        );
      }
      kids.add(Positioned(left: x * (s + 1.8), bottom: y * p, child: ball));
    }
    return SizedBox(width: s * 2 + 1.8, height: p * 8 + s, child: Stack(clipBehavior: Clip.none, children: kids));
  }
}

/// A kazan: ram-horn ornament, number, name, and 9 squares of 9 stones.
class _Kazan extends StatelessWidget {
  final GameController c;
  final int p;
  final GlobalKey squaresKey;
  const _Kazan(this.c, this.p, this.squaresKey);

  @override
  Widget build(BuildContext context) {
    final k = c.s.k[p];
    final on = !c.s.over && c.s.turn == p;
    final name = c.names[p];
    final kc = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 54, height: 12, child: CustomPaint(painter: HornPainter(on ? C.gold : C.nameGold))),
        Text('$k',
            style: TextStyle(
                fontSize: 34,
                height: 1.05,
                fontWeight: FontWeight.w800,
                color: p == 1 ? C.blue : C.ink,
                shadows: const [Shadow(color: Color(0x73000000), offset: Offset(0, 2))])),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 86),
          child: Text(name,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: on ? C.gold : C.nameGold, height: 1.15)),
        ),
        if (k > 81)
          Text('+${k - 81}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.gold)),
      ],
    );
    final squares = _Squares(k, p == 1, key: squaresKey);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const RadialGradient(center: Alignment(0, -.6), radius: 1.2, colors: [Color(0xFF3A2311), Color(0xFF1D0F06)]),
        border: Border.all(color: on ? C.gold : Colors.transparent, width: 2),
        boxShadow: on ? const [BoxShadow(color: Color(0x59F4C247), blurRadius: 16)] : const [],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: p == 1 ? [kc, const SizedBox(width: 10), squares] : [squares, const SizedBox(width: 10), kc],
        ),
      ),
    );
  }
}

class _Squares extends StatelessWidget {
  final int n;
  final bool blue;
  const _Squares(this.n, this.blue, {super.key});
  @override
  Widget build(BuildContext context) {
    final dot = MediaQuery.of(context).size.width < 380 ? 5.0 : 6.0;
    Widget square(int g) {
      final f = max(0, min(9, n - 9 * g));
      return Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: f == 9 ? C.gold.withValues(alpha: .4) : Colors.white.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(4),
          boxShadow: f == 9 ? const [BoxShadow(color: Color(0x59F4C247), blurRadius: 6)] : const [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < 3; r++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var cc = 0; cc < 3; cc++)
                    Padding(
                      padding: const EdgeInsets.all(.5),
                      child: r * 3 + cc < f
                          ? Ball(dot, blue: blue)
                          : Container(
                              width: dot,
                              height: dot,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .1)),
                            ),
                    ),
                ],
              ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < 3; r++)
          Padding(
            padding: const EdgeInsets.all(1.5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var cc = 0; cc < 3; cc++)
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: square(blue ? r * 3 + (2 - cc) : r * 3 + cc)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Draws the stones that are flying in an arc between holes and kazans.
class _FlightLayer extends StatefulWidget {
  final GameController c;
  final GlobalKey stackKey;
  final List<GlobalKey> holeKeys, kazanKeys;
  const _FlightLayer(this.c, this.stackKey, this.holeKeys, this.kazanKeys);
  @override
  State<_FlightLayer> createState() => _FlightLayerState();
}

class _FlightLayerState extends State<_FlightLayer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  List<_Fly> _now = const [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    widget.c.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.c.removeListener(_onChange);
    _ticker.dispose();
    super.dispose();
  }

  void _onChange() {
    if (widget.c.flights.isNotEmpty && !_ticker.isActive) _ticker.start();
  }

  Offset? _spot(int t) {
    final stack = widget.stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null) return null;
    final key = t >= 100 ? widget.kazanKeys[t - 100] : widget.holeKeys[t];
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final local = t >= 100 ? box.size.center(Offset.zero) : Offset(box.size.width / 2, box.size.height * .78);
    return box.localToGlobal(local, ancestor: stack);
  }

  double _ballSize() {
    final box = widget.holeKeys[0].currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return 12;
    return max(6.0, (box.size.width - 9) / 2);
  }

  void _tick(Duration _) {
    final c = widget.c;
    c.removeFinishedFlights();
    final now = c.nowMs;
    final out = <_Fly>[];
    for (final f in c.flights) {
      if (now < f.startMs) continue;
      final a = _spot(f.from), b = _spot(f.to);
      if (a == null || b == null) continue;
      final t = ((now - f.startMs) / max(1, f.durMs)).clamp(0.0, 1.0).toDouble();
      final e = Curves.easeInOut.transform(t);
      final d = b - a;
      final hgt = 22 + min(60.0, d.distance * .25);
      final pos = a + d * e - Offset(0, hgt * 4 * e * (1 - e));
      out.add(_Fly(pos, 1 + .4 * sin(pi * e)));
    }
    if (c.flights.isEmpty) _ticker.stop();
    setState(() => _now = out);
  }

  @override
  Widget build(BuildContext context) {
    final s = _ballSize();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final f in _now)
          Positioned(
            left: f.pos.dx - s * f.scale / 2,
            top: f.pos.dy - s * f.scale / 2,
            child: Ball(s * f.scale, raised: true),
          ),
      ],
    );
  }
}

class _Fly {
  final Offset pos;
  final double scale;
  const _Fly(this.pos, this.scale);
}
