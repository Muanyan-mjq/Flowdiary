import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../utils/user_service.dart';
import '../utils/diary_storage.dart';
import '../utils/stats_storage.dart';
import '../models/diary_entry.dart';
import '../widgets/responsive_app_bar.dart';
import '../utils/smooth_route.dart';
import 'theme_screen.dart';
import 'diary_detail_screen.dart';

const _bgPresets = [null, 0xFFF5F0E8, 0xFFF0F0F0, 0xFFE8F5E9, 0xFFFFF0F5, 0xFF1A1A2E];
const _bgLabels = ['默认白', '暖米', '浅灰', '护眼绿', '樱花粉', '暗黑'];

class _LC { final String t; final Color c, bg; const _LC(this.t, this.c, this.bg); }
const _lvls = [
  _LC('萌新出窝', Color(0xFF999999), Color(0xFFF0F0F0)),
  _LC('拆家小将', Color(0xFFFFB347), Color(0xFFFFF3E0)),
  _LC('汪汪达人', Color(0xFFFF8C00), Color(0xFFFFE0B2)),
  _LC('忠诚伙伴', Color(0xFF87CEEB), Color(0xFFE3F2FD)),
  _LC('天使耶', Color(0xFFDA70D6), Color(0xFFF3E5F5)),
  _LC('耶中之王', Color(0xFFFFD700), Color(0xFFFFFDE7)),
];

class PersonalSpaceScreen extends StatefulWidget {
  const PersonalSpaceScreen({super.key});
  @override State<PersonalSpaceScreen> createState() => _S();
}

class _S extends State<PersonalSpaceScreen> {
  Color get _tc => ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
  String _n = '', _bio = ''; int _lv = 1, _dd = 1;
  int? _bg; String? _bgi;
  StatsData? _st; List<DiaryEntry> _rc = []; bool _ld = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _n = UserService.instance.nickname; _bio = p.getString('user_signature') ?? '';
    _bg = p.getInt('space_bg_color'); _bgi = p.getString('space_bg_image');
    final fu = p.getString('stats_first_use_date');
    if (fu != null) _dd = DateTime.now().difference(DateTime.parse(fu)).inDays + 1;
    final st = await StatsStorage.loadData();
    final ds = await DiaryStorage.loadAll();
    final rc = ds.take(3).toList();
    int lv = 1; final c = st.diaryCount;
    if (c >= 200) lv = 6; else if (c >= 100) lv = 5; else if (c >= 50) lv = 4; else if (c >= 20) lv = 3; else if (c >= 5) lv = 2;
    if (mounted) setState(() { _st = st; _rc = rc; _lv = lv; _ld = false; });
  }

  String get _at { if (_dd <= 1) return '初来乍到'; if (_dd < 30) return '认识$_dd天'; if (_dd < 365) return '相伴${_dd ~/ 30}个月'; return '相伴${_dd ~/ 365}年'; }
  _LC get _lc { final i = (_lv - 1).clamp(0, _lvls.length - 1); return _lvls[i]; }

  Future<void> _sb(int? c, String? img) async {
    final p = await SharedPreferences.getInstance();
    if (c != null) await p.setInt('space_bg_color', c); else await p.remove('space_bg_color');
    if (img != null) await p.setString('space_bg_image', img); else await p.remove('space_bg_image');
    setState(() { _bg = c; _bgi = img; });
  }

  void _showBg() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(padding: const EdgeInsets.fromLTRB(20,12,20,24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36,height: 5,decoration: BoxDecoration(color: Colors.grey[300],borderRadius: BorderRadius.circular(3)))),
          const SizedBox(height: 16), const Text('空间背景', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 16),
          Wrap(spacing: 14, runSpacing: 14, children: List.generate(_bgPresets.length, (i) { final c = _bgPresets[i]; final sel = _bg == c && _bgi == null;
            return GestureDetector(onTap: () { Navigator.pop(ctx); _sb(c, null); }, child: Container(width: 48,height: 48,decoration: BoxDecoration(color: c != null ? Color(c) : Colors.white, borderRadius: BorderRadius.circular(14), border: sel ? Border.all(color: _tc, width: 3) : Border.all(color: const Color(0xFFE8E8E8)), boxShadow: sel ? [BoxShadow(color: _tc.withValues(alpha: 0.2), blurRadius: 8)] : null), child: sel ? Icon(Icons.check_rounded, size: 22, color: _tc) : null)); })),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(_bgLabels.length, (i) => SizedBox(width: 48, child: Text(_bgLabels[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey[500]))))),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [TextButton.icon(onPressed: () { Navigator.pop(ctx); _sb(null, null); }, icon: const Icon(Icons.refresh, size: 16), label: const Text('恢复默认'))]),
        ])));
  }

  void _ep() {
    final nc = TextEditingController(text: _n); final bc = TextEditingController(text: _bio);
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(padding: const EdgeInsets.fromLTRB(24,24,24,24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('编辑资料', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 16),
            Center(child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE0E0E0), width: 3)), child: ClipRRect(borderRadius: BorderRadius.circular(36), child: _da(72)))),
            const SizedBox(height: 20),
            TextField(controller: nc, decoration: const InputDecoration(labelText: '昵称', border: OutlineInputBorder())), const SizedBox(height: 16),
            TextField(controller: bc, decoration: const InputDecoration(labelText: '简介', border: OutlineInputBorder()), maxLines: 2), const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async { final nn = nc.text.trim(); if (nn.isNotEmpty) { await UserService.instance.updateNickname(nn); final p = await SharedPreferences.getInstance(); await p.setString('user_signature', bc.text.trim()); setState(() { _n = nn; _bio = bc.text.trim(); }); } if (ctx.mounted) Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
          ]))));
  }

  @override Widget build(BuildContext c) {
    final st = ResponsiveAppBar.safeTop(c);
    if (_ld) return Scaffold(body: Center(child: CircularProgressIndicator()));
    final dk = _bg == 0xFF1A1A2E;
    final t = dk ? Colors.white : const Color(0xFF1A1A1A);
    final s = dk ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF666666);
    final cb = dk ? Colors.white.withValues(alpha: 0.07) : Colors.white;
    Decoration? bg;
    Color bgColor = const Color(0xFFF5F6FA);
    if (_bgi != null) bg = BoxDecoration(image: DecorationImage(image: FileImage(File(_bgi!)), fit: BoxFit.cover));
    else if (_bg != null) { bg = BoxDecoration(color: Color(_bg!)); bgColor = Color(_bg!); }
    // 全局背景：设置状态栏 + Scaffold
    final isDark = _bg == 0xFF1A1A2E;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
    return Scaffold(
      backgroundColor: bgColor,
      body: Container(decoration: bg ?? const BoxDecoration(color: Color(0xFFF5F6FA)),
      child: SafeArea(child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Column(children: [
        SizedBox(height: st),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          GestureDetector(onTap: () => Navigator.pop(c), child: Container(width: 38,height: 38,decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.08),shape: BoxShape.circle),child: const Icon(Icons.arrow_back_ios_new,size: 18,color: Color(0xFF555555)))),
          const Spacer(),
          GestureDetector(onTap: _showBg, child: Container(width: 38,height: 38,decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.08),shape: BoxShape.circle),child: const Icon(Icons.palette_outlined,size: 20,color: Color(0xFF555555)))),
        ])),
        const SizedBox(height: 24),
        Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 5), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6))]),
          child: ClipRRect(borderRadius: BorderRadius.circular(50), child: _da(100))),
        const SizedBox(height: 20),
        Text(_n, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t)),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14,vertical: 6), decoration: BoxDecoration(color: _lc.bg,borderRadius: BorderRadius.circular(16),border: Border.all(color: _lc.c.withValues(alpha: 0.25))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.pets,size: 14,color: _lc.c), const SizedBox(width: 4), Text('Lv$_lv ${_lc.t}', style: TextStyle(fontSize: 12,fontWeight: FontWeight.w600,color: _lc.c))])),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Text(_bio.isEmpty ? '还没有写自我介绍 ~' : _bio, style: TextStyle(fontSize: 14, color: _bio.isEmpty ? Colors.grey[400] : s, height: 1.5), textAlign: TextAlign.center)),
        const SizedBox(height: 28),
        if (_st != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(padding: const EdgeInsets.symmetric(vertical: 24), decoration: BoxDecoration(color: cb,borderRadius: BorderRadius.circular(20),boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),blurRadius: 12,offset: const Offset(0,4))]),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_s('${_st!.diaryCount}','日记'), _s('${_st!.days}','天数'), _s(StatsStorage.formatWords(_st!.totalWords),'字数')]))),
        if (_rc.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('最近日记', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: s.withValues(alpha: 0.7))),
            const SizedBox(height: 10),
            ..._rc.map((e) { final pv = e.content.length > 60 ? '${e.content.substring(0, 60)}...' : e.content;
              return GestureDetector(onTap: () => Navigator.push(c, SmoothRoute(builder: (_) => DiaryDetailScreen(entry: e))),
                child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cb, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))]),
                  child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(pv, style: const TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 6), Text('${e.createdAt.month}月${e.createdAt.day}日', style: TextStyle(fontSize: 11, color: Colors.grey[400]))])), Icon(Icons.chevron_right, size: 16, color: Colors.grey[300])]))); }),
          ])),
        ],
        const SizedBox(height: 20),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
          _b('主题', Icons.color_lens_outlined, () => Navigator.push(c, SmoothRoute(builder: (_) => ThemeScreen(onThemeChanged: (x) { SuiXinYeAppState.of(c)?.updateThemeColor(x); setState(() {}); }))), cb, t),
          const SizedBox(width: 10), _b('资料', Icons.edit_outlined, _ep, cb, t),
          const SizedBox(width: 10), _b('背景', Icons.palette_outlined, _showBg, cb, t),
        ])),
        const SizedBox(height: 60),
      ])))),
    );
  }

  Widget _s(String v, String l) => Column(children: [Text(v, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))), const SizedBox(height: 4), Text(l, style: TextStyle(fontSize: 12, color: Colors.grey[500]))]);
  Widget _da(double s) => ClipRRect(borderRadius: BorderRadius.circular(s / 2), child: Image.asset('assets/images/samoye/default_avatar.png', width: s, height: s, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.pets, size: s * 0.5, color: Colors.grey[400])));
  Widget _b(String l, IconData i, VoidCallback t, Color bg, Color tc) => Expanded(child: GestureDetector(onTap: t, child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))]), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 18, color: tc.withValues(alpha: 0.45)), const SizedBox(width: 6), Text(l, style: TextStyle(fontSize: 14, color: tc.withValues(alpha: 0.6)))]))));
}
