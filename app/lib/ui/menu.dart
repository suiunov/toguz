import 'package:flutter/material.dart';

import '../controller.dart';
import '../engine/ai.dart';
import '../engine/tasks.dart';
import 'common.dart';

/// Side menu: game mode, difficulty, speed, tasks, rules, settings, about.
class MenuDrawer extends StatefulWidget {
  final GameController c;
  final String startView;
  const MenuDrawer(this.c, {super.key, this.startView = 'main'});
  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  late String view = widget.startView;

  GameController get c => widget.c;

  @override
  Widget build(BuildContext context) {
    final t = c.t;
    final titles = {'main': t.menu, 'tasks': t.tasks, 'rules': t.rules, 'settings': t.settings, 'about': t.about};
    return Drawer(
      width: MediaQuery.of(context).size.width * .86 > 360 ? 360 : MediaQuery.of(context).size.width * .86,
      backgroundColor: C.drawer,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) => Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .08)))),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: view == 'main'
                          ? null
                          : IconButton(
                              tooltip: t.back,
                              icon: const Icon(Icons.chevron_left, color: C.ink),
                              onPressed: () => setState(() => view = 'main')),
                    ),
                    Expanded(
                      child: Text(titles[view]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: C.ink)),
                    ),
                    SizedBox(
                      width: 44,
                      child: IconButton(
                          tooltip: t.close,
                          icon: const Icon(Icons.close, color: C.ink),
                          onPressed: () => Navigator.of(context).pop()),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
                  children: switch (view) {
                    'tasks' => _tasks(context),
                    'rules' => _rules(),
                    'settings' => _settings(),
                    'about' => _about(),
                    _ => _main(context),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lbl(String s) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
        child: Text(s, style: const TextStyle(fontSize: 14, color: C.soft)),
      );

  Widget _item(IconData ic, String text, VoidCallback onTap, {String? trailing}) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(ic, color: C.gold, size: 22),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: C.ink))),
                if (trailing != null) Text(trailing, style: const TextStyle(fontSize: 14, color: C.soft)),
              ],
            ),
          ),
        ),
      );

  List<Widget> _main(BuildContext context) {
    final t = c.t;
    return [
      _item(Icons.add_circle_outline, t.newGame, () {
        Navigator.of(context).pop();
        c.newGame();
      }),
      _lbl(t.mode),
      Seg<String>(
        values: const ['ai', '2p', 'cc'],
        value: c.mode,
        perRow: 1,
        label: (v) => t.modes[v]!,
        sub: (v) => t.modeSub[v]!,
        onChanged: c.setMode,
      ),
      if (c.mode != '2p') ...[
        _lbl(t.level),
        Seg<int>(
          values: [for (final l in levels) l.id],
          value: c.level,
          perRow: 3,
          label: (v) => t.levels[v]!,
          onChanged: c.setLevel,
        ),
      ],
      _lbl(t.speed),
      Seg<int>(
        values: const [0, 1, 2, 3, 4],
        value: c.speed,
        label: (v) => t.speeds[v],
        onChanged: c.setSpeed,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Divider(color: Colors.white.withValues(alpha: .1), height: 1),
      ),
      _item(Icons.star_border_rounded, t.tasks, () => setState(() => view = 'tasks'),
          trailing: '${c.solvedCount}/${tasks.length}'),
      _item(Icons.menu_book_outlined, t.rules, () => setState(() => view = 'rules')),
      _item(Icons.settings_outlined, t.settings, () => setState(() => view = 'settings')),
      _item(Icons.info_outline, t.about, () => setState(() => view = 'about')),
    ];
  }

  List<Widget> _tasks(BuildContext context) {
    final t = c.t;
    return [
      for (var i = 0; i < tasks.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.black.withValues(alpha: .2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                  color: c.task != null && !c.task!.summary && c.task!.i == i ? C.gold : Colors.white.withValues(alpha: .1)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).pop();
                c.startTask(i);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${i + 1}. ${t.names[i]}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: C.ink)),
                          Text('${t.lv[tasks[i].level]} · ${t.task[tasks[i].kind]![0]}',
                              style: const TextStyle(fontSize: 13, color: C.soft)),
                        ],
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.solved[i] ? C.gold : null,
                        border: Border.all(color: c.solved[i] ? C.gold : Colors.white.withValues(alpha: .25), width: 2),
                      ),
                      child: c.solved[i] ? const Icon(Icons.check, size: 16, color: C.goldInk) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _rules() => [
        for (var i = 0; i < c.t.rulesL.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: 24,
                    child: Text('${i + 1}.', style: const TextStyle(fontSize: 16, color: C.gold, fontWeight: FontWeight.w700))),
                Expanded(child: Text(c.t.rulesL[i], style: const TextStyle(fontSize: 16, color: C.soft, height: 1.5))),
              ],
            ),
          ),
      ];

  List<Widget> _settings() {
    final t = c.t;
    return [
      _lbl(t.language),
      Seg<String>(
          values: const ['ky', 'en'], value: c.lang, label: (v) => v == 'ky' ? 'Кыргызча' : 'English', onChanged: c.setLang),
      _lbl(t.sound),
      Seg<bool>(values: const [true, false], value: c.sound, label: (v) => v ? t.on : t.off, onChanged: c.setSound),
      _lbl(t.vibration),
      Seg<bool>(values: const [true, false], value: c.vibrate, label: (v) => v ? t.on : t.off, onChanged: c.setVibrate),
      _lbl(t.preview),
      Seg<bool>(values: const [true, false], value: c.aimOn, label: (v) => v ? t.on : t.off, onChanged: c.setAimOn),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
        child: Text(t.previewSub, style: const TextStyle(fontSize: 13, color: C.soft, height: 1.4)),
      ),
      _lbl(t.taskProgress),
      _item(Icons.delete_outline, t.resetProgress, () {
        c.resetProgress();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.resetDone)));
      }),
    ];
  }

  List<Widget> _about() => [
        const SizedBox(height: 12),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset('assets/icon.png', width: 96, height: 96),
          ),
        ),
        const SizedBox(height: 12),
        Text(c.t.aboutT, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: C.soft, height: 1.55)),
      ];
}
