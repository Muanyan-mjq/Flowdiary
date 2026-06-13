import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/responsive_app_bar.dart';
import '../utils/feedback_storage.dart';
import '../main.dart';

// TODO: 发布前替换为自己的 Formspree 端点
// 免费创建: https://formspree.io
const _formspreeEndpoint = 'https://formspree.io/f/meedqzqj';

/// 类型颜色
const _typeColors = {
  FeedbackType.feature: Color(0xFF4CAF50),
  FeedbackType.bug: Color(0xFFFF9800),
  FeedbackType.other: Color(0xFF9E9E9E),
};

/// 状态颜色
const _statusColors = {
  FeedbackStatus.pending: Color(0xFFFF9800),
  FeedbackStatus.reviewed: Color(0xFF2196F3),
  FeedbackStatus.resolved: Color(0xFF4CAF50),
};

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _selectedType = 0;
  int _currentTab = 0;
  final _descriptionCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  bool _submitting = false;
  List<FeedbackEntry> _history = [];

  static const _maxDescLen = 500;
  static const _types = ['功能建议', '问题反馈', '其他'];

  Color get _tc => ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final h = await FeedbackStorage.loadAll();
    if (mounted) setState(() => _history = h);
  }

  Future<void> _submit() async {
    final desc = _descriptionCtrl.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写反馈内容')));
      return;
    }

    setState(() => _submitting = true);

    try {
      FeedbackType t;
      switch (_selectedType) { case 0: t = FeedbackType.feature; case 1: t = FeedbackType.bug; default: t = FeedbackType.other; }

      final entry = FeedbackEntry(id: DateTime.now().millisecondsSinceEpoch.toString(), type: t, description: desc, contact: _contactCtrl.text.trim(), createdAt: DateTime.now());
      await FeedbackStorage.save(entry);

      // Formspree（离线静默失败）
      bool ok = false;
      try {
        final res = await http.post(Uri.parse(_formspreeEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'type': entry.typeLabel, 'description': desc, 'contact': entry.contact, 'platform': 'Flutter App'}),
        ).timeout(const Duration(seconds: 10));
        ok = res.statusCode == 200;
      } catch (_) {}

      _descriptionCtrl.clear();
      _contactCtrl.clear();
      setState(() { _submitting = false; _selectedType = 0; });
      await _loadHistory();
      setState(() => _currentTab = 1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? '感谢反馈！' : '反馈已保存（离线）'),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提交失败: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _fmt(DateTime t) => '${t.month.toString().padLeft(2,'0')}-${t.day.toString().padLeft(2,'0')} ${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  // ═══════════════ Build ═══════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor(context),
      body: Column(
        children: [
          ResponsiveAppBar(
            backgroundColor: appBgColor(context),
            titleAlignment: CrossAxisAlignment.center,
            left: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF757575)), onPressed: () => Navigator.pop(context)),
            center: const Text('意见反馈', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
          ),
          // Tab 栏
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Expanded(child: _chip(0, '写反馈')),
              Expanded(child: _chip(1, '我的反馈', badge: _history.isEmpty ? null : '${_history.length}')),
            ]),
          ),
          // 内容区
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: [_buildWrite(), _buildHistory()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(int i, String label, {String? badge}) {
    final sel = _currentTab == i;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: sel ? _tc : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? Colors.white : Colors.grey[600])),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: sel ? Colors.white.withValues(alpha: 0.3) : _tc.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: Text(badge, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? Colors.white : _tc)),
            ),
          ],
        ]),
      ),
    );
  }

  // ═══ 写反馈 ═══

  Widget _buildWrite() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sec('反馈类型'),
        const SizedBox(height: 10),
        Row(children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedType == i ? _tc : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
              ),
              child: Text(_types[i], style: TextStyle(fontSize: 14, color: _selectedType == i ? Colors.white : const Color(0xFF1A1A1A), fontWeight: _selectedType == i ? FontWeight.w600 : FontWeight.normal)),
            ),
          ),
        ))),
        const SizedBox(height: 20),
        _buildDescField(),
        const SizedBox(height: 20),
        _sec('联系方式（选填）'),
        const SizedBox(height: 10),
        Container(
          decoration: _card(),
          child: TextField(controller: _contactCtrl, decoration: const InputDecoration(hintText: '手机号/邮箱（方便我们联系你）', hintStyle: TextStyle(color: Color(0xFFBDBDBD)), border: InputBorder.none, contentPadding: EdgeInsets.all(16))),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey[400], padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: _submitting ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('提交反馈', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _buildDescField() {
    final rem = _maxDescLen - _descriptionCtrl.text.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _sec('详细描述'),
        const Spacer(),
        Text('$rem', style: TextStyle(fontSize: 13, color: rem < 50 ? const Color(0xFFFF3B30) : Colors.grey[400], fontWeight: rem < 50 ? FontWeight.w600 : FontWeight.normal)),
      ]),
      const SizedBox(height: 12),
      Container(
        decoration: _card(),
        child: TextField(
          controller: _descriptionCtrl, maxLines: 6, maxLength: _maxDescLen,
          buildCounter: (_, {required currentLength, required maxLength, required isFocused}) => null,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: '请详细描述你的问题或建议...\n\n例如：\n- 你希望增加什么功能？\n- 遇到了什么 bug？如何复现？', hintStyle: TextStyle(color: Color(0xFFBDBDBD), height: 1.6), border: InputBorder.none, contentPadding: EdgeInsets.all(16)),
        ),
      ),
    ]);
  }

  // ═══ 我的反馈 ═══

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.feedback_outlined, size: 72, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('暂无反馈记录', style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('提出你的第一条建议吧', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      ]));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _history.length,
      itemBuilder: (_, i) {
        final e = _history[i];
        final tc = _typeColors[e.type] ?? const Color(0xFF9E9E9E);
        final sc = _statusColors[e.status] ?? const Color(0xFFFF9800);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: tc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Text(e.typeLabel, style: TextStyle(fontSize: 12, color: tc, fontWeight: FontWeight.w500))),
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: sc, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(e.statusLabel, style: TextStyle(fontSize: 12, color: sc)),
              const Spacer(),
              Text(_fmt(e.createdAt), style: const TextStyle(fontSize: 12, color: Color(0xFFBDBDBD))),
            ]),
            const SizedBox(height: 12),
            Text(e.description, style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A), height: 1.5), maxLines: 4, overflow: TextOverflow.ellipsis),
            if (e.contact.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [const Icon(Icons.mail_outline, size: 14, color: Color(0xFFBDBDBD)), const SizedBox(width: 4), Text(e.contact, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)))]),
            ],
          ]),
        );
      },
    );
  }

  // ═══ 工具 ═══

  Widget _sec(String t) => Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)));

  static BoxDecoration _card() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))]);
}
