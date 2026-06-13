import 'package:flutter/material.dart';
import '../widgets/responsive_app_bar.dart';
import '../widgets/staggered_entrance.dart';
import '../utils/diary_storage.dart';
import '../utils/favorite_storage.dart';
import '../models/diary_entry.dart';
import '../screens/daily_sign_detail_screen.dart';
import '../screens/daily_sign_square_screen.dart';
import '../utils/smooth_route.dart';
import '../main.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<DiaryEntry> _favDiaries = [];
  List<Map<String, dynamic>> _favSigns = [];
  bool _isLoading = true;

  Color get _themeColor => ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final favIds = await FavoriteStorage.getFavoriteIds();
    final allDiaries = await DiaryStorage.loadAll();
    final diar = allDiaries.where((d) => favIds.contains(d.id)).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final signs = await FavoriteStorage.getFavoriteSigns();
    if (mounted) setState(() { _favDiaries = diar; _favSigns = signs; _isLoading = false; });
  }

  Future<void> _unfavDiary(DiaryEntry e) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('取消收藏'), content: const Text('确定取消收藏这篇日记？'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx,false), child: const Text('取消')), TextButton(onPressed: () => Navigator.pop(ctx,true), child: const Text('确定', style: TextStyle(color: Color(0xFFFF3B30))))]));
    if (ok == true) { await FavoriteStorage.remove(e.id); setState(() => _favDiaries.removeWhere((d) => d.id == e.id)); }
  }

  Future<void> _unfavSign(Map<String, dynamic> s) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('取消收藏'), content: const Text('确定取消收藏这条日签？'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx,false), child: const Text('取消')), TextButton(onPressed: () => Navigator.pop(ctx,true), child: const Text('确定', style: TextStyle(color: Color(0xFFFF3B30))))]));
    if (ok == true) { await FavoriteStorage.removeSign(s['content'] as String, s['userName'] as String); setState(() => _favSigns.removeWhere((x) => x['content'] == s['content'] && x['userName'] == s['userName'])); }
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor(context),
      body: Column(
        children: [
          ResponsiveAppBar(
            backgroundColor: appBgColor(context),
            titleAlignment: CrossAxisAlignment.center,
            left: IconButton(
              icon: Icon(Icons.arrow_back_ios, size: 18, color: Colors.grey[600]),
              onPressed: () => Navigator.pop(context),
            ),
            center: const Text(
              '我的收藏',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF87CEEB)))
                : _favDiaries.isEmpty && _favSigns.isEmpty
                    ? _buildEmptyState()
                    : _buildFavList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.favorite_border_rounded, size: 72, color: Colors.grey[300]),
      const SizedBox(height: 16),
      Text('还没有收藏', style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Text('在日记或日签中点击收藏即可添加', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
    ]));
  }

  Widget _buildFavList() {
    final total = _favSigns.length + _favDiaries.length;
    return ListView.builder(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20), itemCount: total,
      itemBuilder: (_, i) {
        if (i < _favSigns.length) {
          return StaggeredEntrance(index: i, child: _buildSignCard(_favSigns[i]));
        }
        final di = i - _favSigns.length;
        return StaggeredEntrance(index: i, child: _buildDiaryCard(_favDiaries[di]));
      });
  }

  Widget _buildSignCard(Map<String, dynamic> s) {
    final content = s['content'] as String;
    final userName = s['userName'] as String;
    final today = DateTime.now();
    final createdAt = s['createdAt'] != null ? DateTime.tryParse(s['createdAt'] as String) ?? today : today;
    return Dismissible(key: Key('sign_${content.hashCode}'), direction: DismissDirection.endToStart,
      background: Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFFFFB800), borderRadius: BorderRadius.circular(16)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24), child: const Icon(Icons.star, color: Colors.white, size: 24)),
      confirmDismiss: (_) async { await _unfavSign(s); return false; },
      child: GestureDetector(
        onTap: () => Navigator.push(context, SmoothRoute(builder: (_) => DailySignDetailScreen(post: DailySignPost(content: content, userName: userName, likes: (s['likes'] as int?) ?? 0, comments: (s['comments'] as int?) ?? 0, createdAt: createdAt)))),
        child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))]),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(content.length > 80 ? '${content.substring(0, 80)}...' : content, style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A), height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)), child: Text('日签', style: TextStyle(fontSize: 11, color: Colors.orange[700], fontWeight: FontWeight.w500))),
                const SizedBox(width: 8),
                Text(userName, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ]),
            ])),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey[300]),
          ])),
      ));
  }

  Widget _buildDiaryCard(DiaryEntry entry) {
    // 构建预览文字
    final preview = entry.content.length > 100
        ? '${entry.content.substring(0, 100)}...'
        : entry.content;

    // 标签
    final tags = <String>[];
    if (entry.weather.isNotEmpty) tags.add(entry.weather);
    if (entry.mood.isNotEmpty) tags.add(entry.mood);
    tags.addAll(entry.events);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9800),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.favorite_border, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        await _unfavDiary(entry);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标签行
            if (tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(fontSize: 12, color: _themeColor, fontWeight: FontWeight.w500),
                  ),
                )).toList(),
              ),
            if (tags.isNotEmpty) const SizedBox(height: 10),
            // 内容预览
            Text(
              preview,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A), height: 1.5),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // 底部信息
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(entry.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
                const Spacer(),
                // 收藏图标
                GestureDetector(
                  onTap: () => _unfavDiary(entry),
                  child: const Icon(Icons.favorite, size: 20, color: Color(0xFFFF5252)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
