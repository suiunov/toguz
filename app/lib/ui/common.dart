import 'dart:math';

import 'package:flutter/material.dart';

class C {
  static const felt = Color(0xFF8C1C24);
  static const feltDark = Color(0xFF5C111A);
  static const drawer = Color(0xFF4D0E16);
  static const ink = Color(0xFFFFF7EE);
  static const soft = Color(0xFFFFD9CF);
  static const gold = Color(0xFFF4C247);
  static const goldDark = Color(0xFFE1A62B);
  static const goldInk = Color(0xFF3B1D05);
  static const blue = Color(0xFF7CC7FF);
  static const wood1 = Color(0xFFAD743C);
  static const wood2 = Color(0xFF7C4B22);
  static const wood3 = Color(0xFF5C3517);
  static const hole = Color(0xFF1F1007);
  static const nameGold = Color(0xFFD9B45A);
}

const goldButton = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF8D36A), Color(0xFFE9AE2C)]);

/// A shiny round stone. [blue] for the top player's stones in the kazan.
class Ball extends StatelessWidget {
  final double size;
  final bool blue;
  final bool raised;
  const Ball(this.size, {super.key, this.blue = false, this.raised = false});

  @override
  Widget build(BuildContext context) {
    final colors = blue
        ? const [Color(0xFFF2FAFF), Color(0xFF9DD5FF), Color(0xFF5A9FD6), Color(0xFF34709F)]
        : const [Color(0xFFFBF8F1), Color(0xFFEBE5D8), Color(0xFFC7BFAE), Color(0xFF8F8676)];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
            center: const Alignment(-.24, -.32), radius: .75, colors: colors, stops: const [0, .38, .74, 1]),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: raised ? .75 : .6),
              offset: Offset(.5, raised ? 2.5 : 1.5),
              blurRadius: raised ? 3 : 2),
        ],
      ),
      child: size < 6
          ? null
          : Align(
              alignment: const Alignment(-.42, -.48),
              child: Container(
                width: size * .34,
                height: size * .3,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Colors.white, Color(0xD9FFFFFF), Color(0x00FFFFFF)], stops: [0, .45, 1]),
                ),
              ),
            ),
    );
  }
}

/// Ram-horn ornament (кочкор мүйүз) above the kazan number.
class HornPainter extends CustomPainter {
  final Color color;
  HornPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 64, sy = size.height / 14;
    final p = Path()
      ..moveTo(32 * sx, 13 * sy)
      ..cubicTo(28 * sx, 3 * sy, 16 * sx, 1 * sy, 14 * sx, 8 * sy)
      ..relativeCubicTo(-1 * sx, 4 * sy, 8 * sx, 6 * sy, 7 * sx, 1 * sy)
      ..moveTo(32 * sx, 13 * sy)
      ..cubicTo(36 * sx, 3 * sy, 48 * sx, 1 * sy, 50 * sx, 8 * sy)
      ..relativeCubicTo(1 * sx, 4 * sy, -8 * sx, 6 * sy, -7 * sx, 1 * sy);
    canvas.drawPath(
        p,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * sx
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(HornPainter o) => o.color != color;
}

/// Crown for the tuzdyk mark.
class CrownPainter extends CustomPainter {
  final Color color;
  CrownPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 24, sy = size.height / 20;
    final paint = Paint()..color = color;
    final p = Path()
      ..moveTo(2 * sx, 6 * sy)
      ..lineTo(6 * sx, 15 * sy)
      ..lineTo(18 * sx, 15 * sy)
      ..lineTo(22 * sx, 6 * sy)
      ..lineTo(16 * sx, 10.5 * sy)
      ..lineTo(12 * sx, 1 * sy)
      ..lineTo(8 * sx, 10.5 * sy)
      ..close();
    canvas.drawPath(p, paint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(5 * sx, 16.5 * sy, 14 * sx, 2.5 * sy), Radius.circular(sx)), paint);
  }

  @override
  bool shouldRepaint(CrownPainter o) => o.color != color;
}

/// Soft shyrdak pattern on the red felt background.
class FeltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: .13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const step = 96.0;
    for (var y = 0.0; y < size.height + step; y += step) {
      for (var x = 0.0; x < size.width + step; x += step) {
        final p = Path()
          ..moveTo(x + 48, y + 30)
          ..cubicTo(x + 38, y + 18, x + 20, y + 22, x + 20, y + 36)
          ..cubicTo(x + 20, y + 50, x + 36, y + 50, x + 38, y + 42)
          ..moveTo(x + 48, y + 30)
          ..cubicTo(x + 58, y + 18, x + 76, y + 22, x + 76, y + 36)
          ..cubicTo(x + 76, y + 50, x + 60, y + 50, x + 58, y + 42)
          ..moveTo(x + 48, y + 30)
          ..lineTo(x + 48, y + 52)
          ..moveTo(x + 48, y + 52)
          ..lineTo(x + 40, y + 60)
          ..lineTo(x + 48, y + 68)
          ..lineTo(x + 56, y + 60)
          ..close();
        canvas.drawPath(p, paint);
      }
    }
  }

  @override
  bool shouldRepaint(FeltPainter o) => false;
}

/// Row of choice buttons; the chosen one is gold.
class Seg<T> extends StatelessWidget {
  final List<T> values;
  final T value;
  final String Function(T) label;
  final String Function(T)? sub;
  final ValueChanged<T> onChanged;
  final int perRow;
  const Seg(
      {super.key,
      required this.values,
      required this.value,
      required this.label,
      required this.onChanged,
      this.sub,
      this.perRow = 99});

  @override
  Widget build(BuildContext context) {
    final rows = <List<T>>[];
    for (var i = 0; i < values.length; i += min(perRow, values.length)) {
      rows.add(values.sublist(i, min(i + perRow, values.length)));
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .28), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          for (final r in rows)
            Row(
              children: [
                for (final v in r)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => onChanged(v),
                          child: Ink(
                            decoration: BoxDecoration(
                                gradient: v == value ? goldButton : null, borderRadius: BorderRadius.circular(10)),
                            child: Container(
                              constraints: BoxConstraints(minHeight: sub != null ? 54 : 44),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(label(v),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: v == value ? FontWeight.w700 : FontWeight.w500,
                                          color: v == value ? C.goldInk : C.ink)),
                                  if (sub != null)
                                    Text(sub!(v),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 12, color: (v == value ? C.goldInk : C.ink).withValues(alpha: .8))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Gold or plain rounded button.
class Btn extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool main;
  const Btn(this.text, {super.key, this.onTap, this.main = false});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: main ? goldButton : null,
            color: main ? null : Colors.black.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: main ? C.gold : Colors.white.withValues(alpha: .35), width: 2),
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(text,
                    style: TextStyle(
                        fontSize: 15, fontWeight: main ? FontWeight.w700 : FontWeight.w500, color: main ? C.goldInk : C.ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
