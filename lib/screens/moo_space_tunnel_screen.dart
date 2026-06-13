import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/responsive_app_bar.dart';
import '../utils/stats_storage.dart';
import '../utils/diary_storage.dart';
import '../models/diary_entry.dart';
import '../utils/smooth_route.dart';
import 'diary_detail_screen.dart';

/// 发现页 — 回忆隧道
class MooSpaceTunnelScreen extends StatefulWidget {
  const MooSpaceTunnelScreen({super.key});

  @override
  State<MooSpaceTunnelScreen> createState() => _MooSpaceTunnelScreenState();
}

class _MooSpaceTunnelScreenState extends State<MooSpaceTunnelScreen> {
  StatsData? _stats;
  List<DiaryEntry> _allDiaries = [];
  DiaryEntry? _randomMemory;
  Map<String, List<DiaryEntry>> _timelineGroups = {};
  bool _loading = true;

  Color get _tc => ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final stats = await StatsStorage.loadData();
    final diaries = await DiaryStorage.loadAll();
    final memory = diaries.isEmpty ? null : diaries[Random(DateTime.now().year * 10000 + DateTime.now().month * 100 + DateTime.now().day).nextInt(diaries.length)];
    final groups = <String, List<DiaryEntry>>{};
    for (final d in diaries) {
      final key = '${d.createdAt.year}年${d.createdAt.month}月';
      groups.putIfAbsent(key, () => []).add(d);
    }
    if (mounted) setState(() { _stats = stats; _allDiaries = diaries; _randomMemory = memory; _timelineGroups = groups; _loading = false; });
  }

  String _emoji(String w) { switch (w) { case '晴': return '☀️'; case '多云': return '⛅'; case '阴': return '☁️'; case '雨': return '🌧️'; case '雪': return '❄️'; default: return '🌤️'; } }
  String _fmt(DateTime d) => '${d.month.toString().padLeft(2,'0')}.${d.day.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final safeTop = ResponsiveAppBar.safeTop(context);
    if (_loading) return Scaffold(backgroundColor: Colors.white, body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [SizedBox(height: safeTop), _pulse(), const SizedBox(height: 16), Text('翻阅回忆中...', style: TextStyle(fontSize: 14, color: Colors.grey[400]))])));

    return Scaffold(
      backgroundColor: appBgColor(context),
      body: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        SliverToBoxAdapter(child: SizedBox(height: safeTop)),
        SliverToBoxAdapter(child: _buildHeader()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(child: _buildStats()),
        if (_randomMemory != null) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 22)),
          SliverToBoxAdapter(child: _buildMemoryCard()),
        ],
        if (_allDiaries.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(child: _buildTimelineTitle()),
        ],
        ..._buildTimeline(),
        SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 120)),
      ]),
    );
  }

  // ═══ 顶部 ═══
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('回忆隧道', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          Text('MEMORY TUNNEL', style: TextStyle(fontSize: 11, letterSpacing: 6, color: Colors.grey[400])),
        ]),
        const Spacer(),
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: _tc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.auto_awesome, size: 22, color: _tc)),
      ]),
    );
  }

  Widget _pulse() => TweenAnimationBuilder<double>(tween: Tween(begin: 0.6, end: 1.0), duration: const Duration(milliseconds: 800),
    builder: (_, v, __) => Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: _tc.withValues(alpha: 0.12)),
      child: Center(child: Transform.scale(scale: v, child: Container(width: 18, height: 18, decoration: BoxDecoration(shape: BoxShape.circle, color: _tc))))),
  );

  // ═══ 数据面板 ═══
  Widget _buildStats() {
    final s = _stats!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))]),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _stat(Icons.book_outlined, s.diaryCount, '日记篇数'),
            Container(width: 1, height: 36, color: const Color(0xFFEEEEEE)),
            _stat(Icons.today_outlined, s.days, '使用天数'),
            Container(width: 1, height: 36, color: const Color(0xFFEEEEEE)),
            _stat(Icons.edit_outlined, s.totalWords, '累计字数', formatter: StatsStorage.formatWords),
          ]),
          const SizedBox(height: 20),
          _buildQuote(),
        ]),
      ),
    );
  }

  Widget _stat(IconData icon, int value, String label, {String Function(int)? formatter}) {
    return TweenAnimationBuilder<int>(tween: IntTween(begin: 0, end: value), duration: const Duration(milliseconds: 1200), curve: Curves.easeOutCubic,
      builder: (_, v, __) => Column(children: [
        Icon(icon, size: 20, color: _tc.withValues(alpha: 0.5)),
        const SizedBox(height: 8),
        Text(formatter != null ? formatter(v) : '$v', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _tc)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ]),
    );
  }

  Widget _buildQuote() {
    final rng = Random(DateTime.now().year * 10000 + DateTime.now().month * 100 + DateTime.now().day);
    const q = ['记录即存在，遗忘即消失', '每一天都值得被书写', '回忆是时间的礼物', '写下来，让过去有迹可循', '生活的细节，是未来的宝藏', '文字比记忆更诚实', '平凡的日子也有微光', '笔尖流淌的是生活的温度'];
    return Text('"${q[rng.nextInt(q.length)]}"', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey[400]));
  }

  // ═══ 随机回忆 ═══
  Widget _buildMemoryCard() {
    final e = _randomMemory!;
    final preview = e.content.length > 80 ? '${e.content.substring(0, 80)}...' : e.content;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => Navigator.push(context, SmoothRoute(builder: (_) => DiaryDetailScreen(entry: e))),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFFF8F9FF), const Color(0xFFF0F4FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF8)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _tc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('今日回忆', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _tc))),
              const Spacer(),
              Text('${e.createdAt.year}.${_fmt(e.createdAt)}', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ]),
            const SizedBox(height: 14),
            Text(preview, style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF333333))),
            const SizedBox(height: 12),
            Row(children: [
              if (e.weather.isNotEmpty) ...[
                Text('${_emoji(e.weather)} ${e.weather}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(width: 10),
              ],
              if (e.mood.isNotEmpty) Text('😊 ${e.mood}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const Spacer(),
              Text('查看详情 →', style: TextStyle(fontSize: 12, color: _tc)),
            ]),
          ]),
        ),
      ),
    );
  }

  // ═══ 时间线 ═══
  Widget _buildTimelineTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Row(children: [
        const Text('时间线', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        const SizedBox(width: 8),
        Text('${_allDiaries.length} 篇', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      ]),
    );
  }

  List<Widget> _buildTimeline() {
    int _parse(String k) {
      final p = k.replaceAll(RegExp(r'[^\d]'), ' ').trim().split(RegExp(r'\s+'));
      return (int.tryParse(p[0]) ?? 0) * 100 + (p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0);
    }
    final keys = _timelineGroups.keys.toList()..sort((a, b) => _parse(b).compareTo(_parse(a)));
    final w = <Widget>[];

    for (final key in keys) {
      final entries = _timelineGroups[key]!..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      w.add(SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        child: Text(key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFAAAAAA))))));
      for (final e in entries) {
        final preview = e.content.length > 30 ? '${e.content.substring(0, 30)}…' : e.content;
        w.add(SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTap: () => Navigator.push(context, SmoothRoute(builder: (_) => DiaryDetailScreen(entry: e))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // 时间线圆点
              SizedBox(width: 28, child: Column(children: [
                Container(width: 2, height: 12, color: const Color(0xFFE8E8E8)),
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _tc.withValues(alpha: 0.35))),
              ])),
              // 卡片
              Expanded(child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(preview, style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text(_fmt(e.createdAt), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                    if (e.weather.isNotEmpty) ...[const SizedBox(width: 8), Text('${_emoji(e.weather)} ${e.weather}', style: TextStyle(fontSize: 11, color: Colors.grey[400]))],
                  ]),
                ]),
              )),
            ]),
          ),
        )));
      }
    }
    return w;
  }
}
