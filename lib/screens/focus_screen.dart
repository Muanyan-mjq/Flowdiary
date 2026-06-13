import 'dart:math';
import 'package:flutter/material.dart';
import '../models/focus_task.dart';
import '../utils/focus_storage.dart';
import '../utils/smooth_route.dart';
import '../main.dart';
import '../widgets/responsive_app_bar.dart';
import 'timer_screen.dart';

/// 专注页面 — 待办列表
class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  List<FocusTask> _tasks = [];
  bool _loading = true;
  Color get _tc => ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final t = await FocusStorage.loadAll();
    if (mounted) setState(() { _tasks = t; _loading = false; });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 6) return '夜深了';
    if (h < 9) return '早安';
    if (h < 12) return '上午好';
    if (h < 14) return '中午好';
    if (h < 18) return '下午好';
    if (h < 22) return '晚上好';
    return '夜深了';
  }

  String get _timeStr {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}';
  }

  String get _motivation {
    if (_tasks.isEmpty) return '';
    final done = _tasks.where((t) => t.isDoneToday).length;
    if (done == _tasks.length) return '🎉 全部完成，今天超棒！';
    if (done > 0) return '🔥 已完成 $done/${_tasks.length}，继续加油';
    return '💪 新的一天，从第一个专注开始';
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = ResponsiveAppBar.safeTop(context);
    return Scaffold(
      backgroundColor: appBgColor(context),
      body: Column(children: [
        SizedBox(height: safeTop),
        _buildHeader(),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty ? _buildEmpty() : _buildList()),
      ]),
    );
  }

  // ═══ 头部 ═══
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('$_greeting，$_timeStr', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const Spacer(),
          _btn(Icons.pie_chart_outline, _showStats),
          const SizedBox(width: 8),
          _btn(Icons.add, _showAddDialog),
        ]),
        if (_motivation.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(_motivation, style: TextStyle(fontSize: 13, color: _tc)),
        ],
      ]),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
      child: Icon(icon, size: 22, color: const Color(0xFF1A1A1A))),
  );

  // ═══ 空状态 ═══
  Widget _buildEmpty() {
    return Center(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 100, height: 100,
          decoration: BoxDecoration(color: _tc.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(50)),
          child: Icon(Icons.timer_outlined, size: 44, color: _tc.withValues(alpha: 0.4))),
        const SizedBox(height: 24),
        const Text('还没有待办', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
        const SizedBox(height: 8),
        const Text('点击右上角 + 创建专注任务', style: TextStyle(fontSize: 14, color: Color(0xFFBBBBBB))),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _showAddDialog,
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: const Color(0xFF1A1A1A).withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))]),
            child: const Text('创建第一个待办', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))),
        ),
      ]),
    ));
  }

  // ═══ 列表 ═══
  Widget _buildList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: _tasks.length,
      onReorder: (oldI, newI) async {
        final adjNew = oldI < newI ? newI - 1 : newI;
        setState(() { final item = _tasks.removeAt(oldI); _tasks.insert(adjNew, item); });
        // 更新 sortOrder 并保存到本地
        for (int i = 0; i < _tasks.length; i++) { _tasks[i].sortOrder = i; }
        await FocusStorage.saveAll(_tasks);
        // 重新加载确保同步
        await _load();
      },
      proxyDecorator: (child, _, animation) => AnimatedBuilder(animation: animation, builder: (_, child) => Transform.scale(scale: 1.03, child: child), child: child),
      itemBuilder: (_, i) => _buildCard(_tasks[i], key: ValueKey(_tasks[i].id)),
    );
  }

  Widget _buildCard(FocusTask task, {Key? key}) {
    final c = task.bgColors;
    final done = task.isDoneToday;
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: () => _showEditDialog(task),
        child: Container(
          decoration: BoxDecoration(color: Color(c.bg), borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Color(c.bg).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (done) ...[
                    Icon(Icons.check_circle_rounded, size: 18, color: Colors.white.withValues(alpha: 0.6)),
                    const SizedBox(width: 6),
                  ],
                  Expanded(child: Text(task.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: done ? Colors.white.withValues(alpha: 0.55) : Colors.white))),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text(task.modeLabel, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.55))),
                  if (done) ...[const SizedBox(width: 8), Text('✓ ${task.completedToday} 次', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)))],
                ]),
              ])),
              GestureDetector(
                onTap: () async { await Navigator.push(context, SmoothRoute(builder: (_) => TimerScreen(task: task))); _load(); },
                child: Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(done ? Icons.replay_rounded : Icons.play_arrow_rounded, size: 24, color: Colors.white)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ═══ 添加弹窗 ═══
  void _showAddDialog() {
    final name = TextEditingController();
    FocusMode mode = FocusMode.pomodoro;
    int mins = 25;
    final custom = TextEditingController();
    int colorI = Random().nextInt(cardColors.length);

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDlg) => Dialog(
      backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
        child: SingleChildScrollView(physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 24),
            const Text('新建待办', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 20),
            // 名称
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(controller: name, autofocus: true,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                decoration: InputDecoration(hintText: '例如：深度学习、刷算法题...', hintStyle: TextStyle(fontSize: 14, color: Colors.grey[350]),
                  filled: true, fillColor: appBgColor(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)))),
            const SizedBox(height: 20),
            // 模式
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('计时模式', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(14)),
                  child: Row(children: List.generate(3, (i) => Expanded(child: GestureDetector(
                    onTap: () => setDlg(() => mode = FocusMode.values[i]),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: mode == FocusMode.values[i] ? const Color(0xFF1A1A1A) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      child: Column(children: [
                        Icon([Icons.timer, Icons.hourglass_bottom, Icons.trending_up][i], size: 20, color: mode == FocusMode.values[i] ? Colors.white : const Color(0xFFAAAAAA)),
                        const SizedBox(height: 4),
                        Text(['番茄钟', '倒计时', '正计时'][i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mode == FocusMode.values[i] ? Colors.white : const Color(0xFFAAAAAA))),
                      ])),
                  )))),
                ),
              ])),
            if (mode != FocusMode.stopwatch) ...[
              const SizedBox(height: 20),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('专注时长', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    ...[15, 25, 35, 45, 60].map((v) => GestureDetector(
                      onTap: () => setDlg(() { mins = v; custom.clear(); }),
                      child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: mins == v && custom.text.isEmpty ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20)),
                        child: Text('$v 分钟', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: mins == v && custom.text.isEmpty ? Colors.white : const Color(0xFF999999))))),
                    ),
                    SizedBox(height: 36, child: TextField(controller: custom, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                      onChanged: (v) { final n = int.tryParse(v); if (n != null && n > 0) mins = n; },
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(hintText: '自定义', hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        filled: true, fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), isDense: true))),
                  ]),
                ])),
            ],
            const SizedBox(height: 20),
            // 颜色
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('卡片配色', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: List.generate(cardColors.length, (i) => GestureDetector(
                  onTap: () => setDlg(() => colorI = i),
                  child: Container(width: 28, height: 28, margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: Color(cardColors[i].bg), shape: BoxShape.circle,
                      border: i == colorI ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: i == colorI ? [BoxShadow(color: Color(cardColors[i].bg).withValues(alpha: 0.5), blurRadius: 6)] : null),
                    child: i == colorI ? const Icon(Icons.check, size: 14, color: Colors.white) : null),
                ))),
              ])),
            const SizedBox(height: 24),
            Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final n = name.text.trim(); if (n.isEmpty) return;
                    final task = FocusTask(id: DateTime.now().millisecondsSinceEpoch.toString(), name: n, mode: mode, durationMinutes: mins, bgColorIndex: colorI, timerStyle: await FocusStorage.getGlobalStyle());
                    await FocusStorage.add(task); Navigator.pop(ctx); _load();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: const Text('创建待办', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              )),
          ]),
        ),
      ),
    )));
  }

  // ═══ 编辑弹窗 ═══
  void _showEditDialog(FocusTask task) {
    final name = TextEditingController(text: task.name);
    int bgIdx = task.bgColorIndex >= 0 ? task.bgColorIndex : (task.id.hashCode.abs() % cardColors.length);
    FocusMode mode = task.mode;
    int dur = task.durationMinutes;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDlg) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: TextField(controller: name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 计时模式
        const Text('计时模式', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
        const SizedBox(height: 6),
        Row(children: List.generate(3, (i) => Expanded(child: GestureDetector(
          onTap: () => setDlg(() => mode = FocusMode.values[i]),
          child: Container(padding: const EdgeInsets.symmetric(vertical: 8), margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
            decoration: BoxDecoration(color: mode == FocusMode.values[i] ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(8)),
            child: Text(['番茄钟', '倒计时', '正计时'][i], textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mode == FocusMode.values[i] ? Colors.white : const Color(0xFF999999)))),)))),
        const SizedBox(height: 16),
        // 时长
        if (mode != FocusMode.stopwatch) ...[
          const Text('时长 (分钟)', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
          const SizedBox(height: 6),
          Row(children: [15, 25, 35, 45, 60].map((v) => GestureDetector(
            onTap: () => setDlg(() => dur = v),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(color: dur == v ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(16)),
              child: Text('$v', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dur == v ? Colors.white : const Color(0xFF999999)))))).toList()),
          const SizedBox(height: 16),
        ],
        // 颜色
        const Text('卡片背景', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: List.generate(cardColors.length, (i) {
          final sel = i == bgIdx;
          return GestureDetector(onTap: () => setDlg(() => bgIdx = i),
            child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Color(cardColors[i].bg), shape: BoxShape.circle,
              border: sel ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: sel ? [BoxShadow(color: Color(cardColors[i].bg).withValues(alpha: 0.5), blurRadius: 6)] : null),
              child: sel ? const Icon(Icons.check, size: 14, color: Colors.white) : null));
        })),
        const SizedBox(height: 20),
        _info('今日已专注', '${task.completedToday} 次'),
        _info('总计', '${task.totalCompletions} 次'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () { Navigator.pop(ctx); _moveDialog(task); },
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF666666), side: const BorderSide(color: Color(0xFFDDDDDD)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('排序', style: TextStyle(fontSize: 13)))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('删除待办'), content: Text('确定删除「${task.name}」？'),
                actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('删除', style: TextStyle(color: Color(0xFFFF3B30))))]));
              if (ok == true) { await FocusStorage.delete(task.id); _load(); }
            },
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF3B30), side: const BorderSide(color: Color(0xFFFFCDD2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('删除', style: TextStyle(fontSize: 13)))),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Color(0xFF999999)))),
        ElevatedButton(onPressed: () async {
          final n = name.text.trim(); if (n.isEmpty) return;
          task.name = n; task.bgColorIndex = bgIdx; task.mode = mode; task.durationMinutes = dur;
          await FocusStorage.update(task); Navigator.pop(ctx); _load();
        }, style: ElevatedButton.styleFrom(backgroundColor: _tc, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('保存')),
      ],
    )));
  }

  Widget _info(String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [Text(l, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))), const Spacer(), Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)))]));

  void _moveDialog(FocusTask task) {
    showDialog(context: context, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('移动到', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(width: 220,
        child: ListView(shrinkWrap: true, children: List.generate(_tasks.length, (i) {
          final t = _tasks[i];
          return GestureDetector(
            onTap: () async {
              Navigator.pop(c);
              final oldI = _tasks.indexWhere((x) => x.id == task.id);
              if (oldI != -1 && oldI != i) {
                setState(() { final item = _tasks.removeAt(oldI); _tasks.insert(i, item); });
                await FocusStorage.reorder(oldI, i); _load();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(color: i == _tasks.indexWhere((x) => x.id == task.id) ? _tc.withValues(alpha: 0.08) : const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Text('第 ${i + 1} 位', style: TextStyle(fontSize: 14, fontWeight: t.id == task.id ? FontWeight.w700 : FontWeight.w400, color: t.id == task.id ? _tc : const Color(0xFF666666))),
                const Spacer(), Expanded(child: Text(t.name, style: TextStyle(fontSize: 13, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),
          );
        })),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消'))],
    ));
  }

  // ═══ 统计 ═══
  void _showStats() async {
    final total = await FocusStorage.getTodayTotal();
    final minutes = await FocusStorage.getTodayMinutes();
    final stats = await FocusStorage.getStatsByTask();
    if (!mounted) return;

    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('今日统计', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _sItem('$total', '专注次数'), _sItem('$minutes', '总分钟数'), _sItem('${stats.length}', '任务数'),
          ]),
          const SizedBox(height: 24),
          if (stats.isNotEmpty) ...[
            SizedBox(height: 180, child: CustomPaint(painter: _PiePainter(stats), size: const Size(180, 180))),
            const SizedBox(height: 16),
            ...stats.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: _pieColor(stats.keys.toList().indexOf(e.key)), shape: BoxShape.circle)),
                const SizedBox(width: 8), Text(e.key, style: const TextStyle(fontSize: 13)),
                const Spacer(), Text('${e.value} 次', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ]))),
          ],
        ]),
      ),
    );
  }

  Widget _sItem(String v, String l) => Column(children: [Text(v, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))), const SizedBox(height: 4), Text(l, style: TextStyle(fontSize: 13, color: Colors.grey[500]))]);
}

Color _pieColor(int i) {
  const cs = [Color(0xFF5B8DEF), Color(0xFFE17055), Color(0xFF00B894), Color(0xFFE84393), Color(0xFFFDCB6E), Color(0xFF6C5CE7), Color(0xFF0984E3), Color(0xFF2ECC71)];
  return cs[i % cs.length];
}

class _PiePainter extends CustomPainter {
  final Map<String, int> data;
  _PiePainter(this.data);
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final total = data.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    double startAngle = -pi / 2;
    final entries = data.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final sweep = (entries[i].value / total) * 2 * pi;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, true, Paint()..color = _pieColor(i)..style = PaintingStyle.fill);
      startAngle += sweep;
    }
    canvas.drawCircle(center, radius * 0.42, Paint()..color = Colors.white);
  }
  @override
  bool shouldRepaint(_PiePainter old) => old.data != data;
}
