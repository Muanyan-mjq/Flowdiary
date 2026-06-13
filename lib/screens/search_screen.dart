import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../utils/diary_storage.dart';
import '../utils/smooth_route.dart';
import '../widgets/responsive_app_bar.dart';
import 'diary_detail_screen.dart';

/// 日记搜索页面
///
/// 搜索全部日记的标题和正文内容，实时过滤结果。
/// 点击结果跳转到日记详情页。
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<DiaryEntry> _allDiaries = [];
  List<DiaryEntry> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadDiaries() async {
    final all = await DiaryStorage.loadAll();
    if (mounted) setState(() { _allDiaries = all; _loading = false; });
  }

  /// 实时搜索过滤
  void _onSearch(String keyword) {
    final kw = keyword.trim().toLowerCase();
    if (kw.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final filtered = _allDiaries.where((d) {
      return d.content.toLowerCase().contains(kw);
    }).toList();
    setState(() => _results = filtered);
  }

  /// 跳转日记详情
  void _openDetail(DiaryEntry entry) {
    Navigator.push(context, SmoothRoute(builder: (_) => DiaryDetailScreen(entry: entry)));
  }

  /// 高亮关键词的文本片段
  String _snippet(String content, String keyword) {
    final lower = content.toLowerCase();
    final idx = lower.indexOf(keyword.toLowerCase());
    if (idx < 0) {
      return content.length > 60 ? '${content.substring(0, 60)}...' : content;
    }
    final start = (idx - 15).clamp(0, content.length);
    final end = (idx + keyword.length + 30).clamp(0, content.length);
    var s = content.substring(start, end);
    if (start > 0) s = '...$s';
    if (end < content.length) s = '$s...';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = ResponsiveAppBar.safeTop(context);
    final hasQuery = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(children: [
        SizedBox(height: safeTop + 8),
        // 搜索栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF666666)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  onChanged: _onSearch,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '搜索日记标题、正文...',
                    hintStyle: TextStyle(color: Colors.grey[350], fontSize: 15),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 22),
                    suffixIcon: hasQuery
                        ? GestureDetector(
                            onTap: () { _controller.clear(); _onSearch(''); },
                            child: Icon(Icons.close, size: 18, color: Colors.grey[400]))
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // 结果列表
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty && hasQuery
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.search_off, size: 56, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('没有找到相关日记', style: TextStyle(fontSize: 15, color: Colors.grey[400])),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _results.length,
                      itemBuilder: (_, i) => _buildResultCard(_results[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _buildResultCard(DiaryEntry entry) {
    final content = entry.content;
    // 提取标题：第一个 # 标题行，或第一行
    String title;
    if (content.startsWith('# ')) {
      title = content.split('\n').first.replaceFirst('# ', '');
    } else if (content.startsWith('## ')) {
      title = content.split('\n').first.replaceFirst('## ', '');
    } else {
      title = content.split('\n').first;
    }
    if (title.length > 30) title = '${title.substring(0, 30)}...';

    final snippet = _snippet(content, _controller.text.trim());
    final dateStr = '${entry.createdAt.month}月${entry.createdAt.day}日';

    return GestureDetector(
      onTap: () => _openDetail(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ]),
          const SizedBox(height: 8),
          Text(snippet, style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF888888)), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (entry.weather.isNotEmpty || entry.mood.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              if (entry.weather.isNotEmpty)
                _chip(entry.weather, const Color(0xFF87CEEB)),
              if (entry.mood.isNotEmpty) ...[
                const SizedBox(width: 6),
                _chip(entry.mood, const Color(0xFFFF9800)),
              ],
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}
