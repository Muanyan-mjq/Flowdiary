import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 收藏持久化存储
/// 存储已收藏日记的 ID 列表 + 日签数据
class FavoriteStorage {
  static const String _keyFavorites = 'favorite_ids';
  static const String _keySigns = 'favorite_signs';

  /// 获取所有收藏的日记 ID
  static Future<Set<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyFavorites);
    if (str == null) return {};
    try {
      final list = jsonDecode(str) as List;
      return list.map((e) => e.toString()).toSet();
    } catch (e) {
      return {};
    }
  }

  /// 切换日记收藏状态
  static Future<bool> toggle(String diaryId) async {
    final ids = await getFavoriteIds();
    final isFav = ids.contains(diaryId);
    if (isFav) { ids.remove(diaryId); } else { ids.add(diaryId); }
    await _saveIds(ids);
    return !isFav;
  }

  static Future<bool> isFavorite(String diaryId) async {
    final ids = await getFavoriteIds();
    return ids.contains(diaryId);
  }

  static Future<void> remove(String diaryId) async {
    final ids = await getFavoriteIds();
    ids.remove(diaryId);
    await _saveIds(ids);
  }

  static Future<int> getCount() async {
    final ids = await getFavoriteIds();
    final signs = await getFavoriteSigns();
    return ids.length + signs.length;
  }

  static Future<void> _saveIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFavorites, jsonEncode(ids.toList()));
  }

  // ═══════════════════ 日签收藏 ═══════════════════

  /// 获取收藏的日签列表
  static Future<List<Map<String, dynamic>>> getFavoriteSigns() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keySigns);
    if (str == null) return [];
    try { return List<Map<String, dynamic>>.from(jsonDecode(str)); } catch (_) { return []; }
  }

  /// 生成日签唯一标识
  static String _signKey(String content, String userName) =>
      '${content.hashCode}_${userName.hashCode}';

  /// 切换日签收藏
  static Future<bool> toggleSign(String content, String userName, int likes, int comments, DateTime createdAt) async {
    final signs = await getFavoriteSigns();
    final key = _signKey(content, userName);
    final idx = signs.indexWhere((s) => _signKey(s['content'] as String, s['userName'] as String) == key);
    if (idx >= 0) {
      signs.removeAt(idx);
      await _saveSigns(signs);
      return false;
    } else {
      signs.insert(0, {
        'content': content, 'userName': userName,
        'likes': likes, 'comments': comments,
        'createdAt': createdAt.toIso8601String(),
      });
      await _saveSigns(signs);
      return true;
    }
  }

  /// 检查日签是否已收藏
  static Future<bool> isSignFavored(String content, String userName) async {
    final signs = await getFavoriteSigns();
    final key = _signKey(content, userName);
    return signs.any((s) => _signKey(s['content'] as String, s['userName'] as String) == key);
  }

  /// 取消收藏日签
  static Future<void> removeSign(String content, String userName) async {
    final signs = await getFavoriteSigns();
    final key = _signKey(content, userName);
    signs.removeWhere((s) => _signKey(s['content'] as String, s['userName'] as String) == key);
    await _saveSigns(signs);
  }

  static Future<void> _saveSigns(List<Map<String, dynamic>> signs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySigns, jsonEncode(signs));
  }
}
