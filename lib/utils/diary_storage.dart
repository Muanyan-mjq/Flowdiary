import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_entry.dart';
import '../services/cloud_sync_service.dart';

/// 日记持久化存储服务
/// 使用 SharedPreferences 存储日记列表，支持云端同步
class DiaryStorage {
  static const String _keyDiaries = 'diaries';

  /// 保存一篇日记
  static Future<void> save(DiaryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadAll();

    // 如果已存在同 ID 的日记，替换它；否则插入开头
    final existingIndex = list.indexWhere((e) => e.id == entry.id);
    if (existingIndex >= 0) {
      list[existingIndex] = entry;
    } else {
      list.insert(0, entry);
    }

    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_keyDiaries, jsonEncode(jsonList));

    // 后台异步同步到云端（保存后自动同步，用户无需手动操作）
    _syncToCloud();
  }

  /// 读取所有日记（按时间倒序）
  static Future<List<DiaryEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyDiaries);
    if (str == null) return [];
    final jsonList = jsonDecode(str) as List;
    return jsonList
        .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 按年月筛选日记
  static Future<List<DiaryEntry>> loadByMonth(int year, int month) async {
    final all = await loadAll();
    return all.where((e) =>
      e.createdAt.year == year && e.createdAt.month == month
    ).toList();
  }

  /// 获取某年每月有日记的天数（供月度视图进度条使用）
  static Future<List<int>> loadCountsForYear(int year) async {
    final all = await loadAll();
    return List.generate(12, (i) {
      final month = i + 1;
      final days = <int>{};
      for (final e in all) {
        if (e.createdAt.year == year && e.createdAt.month == month) {
          days.add(e.createdAt.day);
        }
      }
      return days.length;
    });
  }

  /// 删除一篇日记
  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadAll();
    list.removeWhere((e) => e.id == id);
    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_keyDiaries, jsonEncode(jsonList));

    // 后台异步同步删除
    _syncToCloud();
  }

  /// 替换全部日记（用于从云端恢复数据）
  static Future<void> replaceAll(List<DiaryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_keyDiaries, jsonEncode(jsonList));
  }

  /// 后台异步同步到云端（静默失败，不打扰用户）
  static Future<void> _syncToCloud() async {
    try {
      final diaries = await loadAll();
      await CloudSyncService.instance.pushDiaries(diaries);
    } catch (e) {
      // 静默：云同步失败不影响本地使用
      debugPrint('[日记存储] 后台同步失败: $e');
    }
  }

  /// debugPrint 包装
  static void debugPrint(String message) {
    if (!const bool.fromEnvironment('dart.vm.product')) {
      final now = DateTime.now();
      final ts = '${now.hour}:${now.minute}:${now.second}';
      // ignore: avoid_print
      print('[$ts] $message');
    }
  }
}
