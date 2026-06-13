import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 签到数据持久化工具类
///
/// 两套天数：
///   1. 连续打开天数（自动追踪）— app 启动时自动记录，零点后新一天自动+1
///   2. 手动签到天数 — 用户点击签到按钮才累加
///
/// 存储内容：
///   - sign_last_date: 上次手动签到日期
///   - sign_consecutive_days: 手动连续签到天数
///   - sign_auto_last_date: 上次自动记录日期
///   - sign_auto_consecutive_days: 连续打开天数
///   - sign_my_posts: 用户发布的日签帖子列表（JSON）
class SignStorage {
  // 手动签到相关
  static const String _keyLastSignDate = 'sign_last_date';
  static const String _keyConsecutiveDays = 'sign_consecutive_days';

  // 自动连续打开天数相关
  static const String _keyAutoLastDate = 'sign_auto_last_date';
  static const String _keyAutoConsecutiveDays = 'sign_auto_consecutive_days';

  // 用户发布的日签帖子
  static const String _keyMyPosts = 'sign_my_posts';

  /// App 启动时调用：自动记录今天打开过 app，更新连续天数
  ///
  /// 逻辑：
  ///   - 首次使用 → 连续 1 天
  ///   - 昨天打开过 → 连续 +1
  ///   - 今天已记录过 → 不变
  ///   - 超过 1 天没打开 → 重新从 1 开始
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _formatDate(now);

    final lastDateStr = prefs.getString(_keyAutoLastDate);

    if (lastDateStr == null) {
      // 首次使用，从今天开始计
      await prefs.setString(_keyAutoLastDate, todayStr);
      await prefs.setInt(_keyAutoConsecutiveDays, 1);
      return;
    }

    final lastDate = DateTime.parse(lastDateStr);
    final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(lastDay).inDays;

    if (diff == 0) {
      // 今天已经记录过了，不处理
      return;
    } else if (diff == 1) {
      // 昨天打开过，连续 +1
      final current = prefs.getInt(_keyAutoConsecutiveDays) ?? 0;
      await prefs.setInt(_keyAutoConsecutiveDays, current + 1);
      await prefs.setString(_keyAutoLastDate, todayStr);
    } else {
      // 超过 1 天没打开，重新从 1 开始
      await prefs.setInt(_keyAutoConsecutiveDays, 1);
      await prefs.setString(_keyAutoLastDate, todayStr);
    }
  }

  /// 读取签到数据（包含自动连续天数 + 手动签到状态）
  static Future<SignData> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // 自动连续打开天数
    final autoConsecutive = prefs.getInt(_keyAutoConsecutiveDays) ?? 0;

    // 手动签到相关
    final lastSignStr = prefs.getString(_keyLastSignDate);
    final consecutiveDays = prefs.getInt(_keyConsecutiveDays) ?? 0;

    if (lastSignStr == null) {
      return SignData(
        isSignedToday: false,
        consecutiveDays: consecutiveDays,
        autoConsecutiveDays: autoConsecutive,
        lastSignDate: null,
      );
    }

    final lastSignDate = DateTime.parse(lastSignStr);
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(lastSignDate.year, lastSignDate.month, lastSignDate.day);
    final diff = todayDate.difference(lastDate).inDays;

    if (diff == 0) {
      return SignData(
        isSignedToday: true,
        consecutiveDays: consecutiveDays,
        autoConsecutiveDays: autoConsecutive,
        lastSignDate: lastDate,
      );
    } else if (diff == 1) {
      return SignData(
        isSignedToday: false,
        consecutiveDays: consecutiveDays,
        autoConsecutiveDays: autoConsecutive,
        lastSignDate: lastDate,
      );
    } else {
      // 断签了，手动连续天数归零
      return SignData(
        isSignedToday: false,
        consecutiveDays: 0,
        autoConsecutiveDays: autoConsecutive,
        lastSignDate: lastDate,
      );
    }
  }

  /// 手动签到（点击签到按钮时调用）
  static Future<void> saveSign(int consecutiveDays) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _formatDate(now);

    await prefs.setString(_keyLastSignDate, todayStr);
    await prefs.setInt(_keyConsecutiveDays, consecutiveDays);
  }

  /// 保存用户发布的日签帖子列表
  static Future<void> saveMyPosts(List<Map<String, dynamic>> posts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMyPosts, jsonEncode(posts));
  }

  /// 读取用户发布的日签帖子列表
  /// 返回 List<Map>，每个 Map 包含 content, createdAt, userName, likes, comments
  static Future<List<Map<String, dynamic>>> loadMyPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMyPosts);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// 格式化日期为 "yyyy-MM-dd"
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 签到数据封装
class SignData {
  final bool isSignedToday;       // 今天是否手动签到过
  final int consecutiveDays;      // 手动连续签到天数
  final int autoConsecutiveDays;  // 连续打开天数（自动追踪）
  final DateTime? lastSignDate;

  const SignData({
    required this.isSignedToday,
    required this.consecutiveDays,
    required this.autoConsecutiveDays,
    this.lastSignDate,
  });
}
