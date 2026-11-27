import 'package:flutter/material.dart';

import '../controller.dart';
import '../engine/tasks.dart';
import 'common.dart';

const _lvColors = [Color(0xFF2F7D4F), Color(0xFF2F6A9E), Color(0xFFA0611C), Color(0xFF7A2BB0)];

class TaskPanel extends StatelessWidget {
  final GameController c;
  final VoidCallback openList;
  const TaskPanel(this.c, {super.key, required this.openList});

  @override
  Widget build(BuildContext context) {
    final tr = c.task!, t = c.t;
    final buttons = <Widget>[];
    String step, title, text;
    Widget? extra;
    int? lv;
    if (tr.summary) {
      step = t.tasksDone;
      title = t.summary(tasks.length, c.solvedCount);
      text = c.solvedCount == tasks.length ? t.allSolved : t.someSolved;
      buttons.addAll([
        Btn(t.restart, main: true, onTap: () => c.startTask(0)),
        Btn(t.toGame, onTap: c.newGame),
      ]);
    } else {
      final tk = tasks[tr.i];
      lv = tk.level;
      step = t.stepLbl(tr.i + 1, tasks.length);
      title = t.names[tr.i];
      if (!tr.done) {
        text = tr.best ? t.bestPre + c.explainBest() + t.tapGlow : t.task[tk.kind]![1].replaceAll('{k}', '${tk.k[0]}') + t.tapAny;
      } else {
        text = c.taskResultText();
      }
      if (tr.hint && !tr.done && !tr.best) {
        extra = Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x2462E08D),
            border: Border.all(color: const Color(0x7362E08D)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(c.hintText(), style: const TextStyle(fontSize: 15, color: C.ink)),
        );
      }
      if (tr.best) {
        extra = Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final e in c.bestList())
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: e.value ? C.gold : Colors.black.withValues(alpha: .25), borderRadius: BorderRadius.circular(99)),
                child: Text(e.key,
                    style: TextStyle(
                        fontSize: 14,
                        color: e.value ? C.goldInk : C.soft,
                        fontWeight: e.value ? FontWeight.w700 : FontWeight.w400)),
              ),
          ],
        );
        extra = Padding(padding: const EdgeInsets.only(bottom: 12), child: extra);
      }
      if (tr.done) {
        buttons.add(Btn(tr.i + 1 < tasks.length ? t.nextTask : t.results, main: true, onTap: () => c.startTask(tr.i + 1)));
        if (!tr.ok) buttons.add(Btn(t.retry, onTap: () => c.startTask(tr.i)));
      }
      if (!tr.done && !tr.best && !tr.hint) buttons.add(Btn(t.hintBtn, onTap: c.showHint));
      if (!tr.ok) buttons.add(Btn(t.bestBtn, onTap: c.showBest));
      buttons.add(Btn(t.allTasks, onTap: openList));
      buttons.add(Btn(t.exit, onTap: c.newGame));
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .24), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(step, style: const TextStyle(fontSize: 13, color: C.soft)),
              if (lv != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _lvColors[lv], borderRadius: BorderRadius.circular(99)),
                  child: Text(t.lv[lv], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
              if (!tr.summary && c.solved[tr.i]) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle, color: C.gold, size: 18),
              ],
              const Spacer(),
              if (!tr.summary) ...[
                _nav(Icons.chevron_left, tr.i > 0 ? () => c.startTask(tr.i - 1) : null),
                const SizedBox(width: 6),
                _nav(Icons.chevron_right, () => c.startTask(tr.i + 1)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: C.ink, height: 1.2)),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(fontSize: 16, color: C.ink, height: 1.4)),
          const SizedBox(height: 12),
          if (extra != null) extra,
          Wrap(spacing: 8, runSpacing: 8, children: buttons),
        ],
      ),
    );
  }

  Widget _nav(IconData ic, VoidCallback? onTap) => Opacity(
        opacity: onTap == null ? .35 : 1,
        child: Material(
          color: Colors.black.withValues(alpha: .22),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox(width: 38, height: 38, child: Icon(ic, color: C.ink)),
          ),
        ),
      );
}
