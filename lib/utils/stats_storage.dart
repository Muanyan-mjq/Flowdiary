import 'package:shared_preferences/shared_preferences.dart';

/// 用户统计数据持久化
///
/// 存储内容：
///   - diaryCount: 日记总篇数
///   - totalWords: 累计字数
///   - firstUseDate: 首次使用日期（用于计算天数）
class StatsStorage {
  static const String _keyDiaryCount = 'stats_diary_count';
  static const String _keyTotalWords = 'stats_total_words';
  static const String _keyFirstUseDate = 'stats_first_use_date';

  /// 读取统计数据
  static Future<StatsData> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final diaryCount = prefs.getInt(_keyDiaryCount) ?? 0;
    final totalWords = prefs.getInt(_keyTotalWords) ?? 0;
    final firstUseStr = prefs.getString(_keyFirstUseDate);

    // 计算使用天数
    int days = 0;
    if (firstUseStr != null) {
      final firstUse = DateTime.parse(firstUseStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final firstDay = DateTime(firstUse.year, firstUse.month, firstUse.day);
      days = today.difference(firstDay).inDays + 1; // 包含今天
    } else {
      days = 1; // 首次使用，算第1天
    }

    return StatsData(
      diaryCount: diaryCount,
      days: days,
      totalWords: totalWords,
    );
  }

  /// 新增一篇日记（日记数+1，字数累加 + 按月统计）
  static Future<void> addDiary(int wordCount) async {
    final prefs = await SharedPreferences.getInstance();

    // 日记数+1
    final currentCount = prefs.getInt(_keyDiaryCount) ?? 0;
    await prefs.setInt(_keyDiaryCount, currentCount + 1);

    // 字数累加
    final currentWords = prefs.getInt(_keyTotalWords) ?? 0;
    await prefs.setInt(_keyTotalWords, currentWords + wordCount);

    // 按月统计 +1
    final now = DateTime.now();
    await addDiaryForMonth(now.year, now.month);

    // 记录首次使用日期
    if (!prefs.containsKey(_keyFirstUseDate)) {
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await prefs.setString(_keyFirstUseDate, todayStr);
    }
  }

  /// 按月日记数 +1
  static Future<void> addDiaryForMonth(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'diary_${year}_${month.toString().padLeft(2, '0')}';
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  /// 读取某月日记数
  static Future<int> loadDiaryCountForMonth(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'diary_${year}_${month.toString().padLeft(2, '0')}';
    return prefs.getInt(key) ?? 0;
  }

  /// 读取某年 12 个月的日记数
  static Future<List<int>> loadAllDiaryCountsForYear(int year) async {
    final prefs = await SharedPreferences.getInstance();
    return List.generate(12, (i) {
      final key = 'diary_${year}_${(i + 1).toString().padLeft(2, '0')}';
      return prefs.getInt(key) ?? 0;
    });
  }

  /// 初始化首次使用日期（如果还没记录）
  static Future<void> initFirstUseDate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyFirstUseDate)) {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await prefs.setString(_keyFirstUseDate, todayStr);
    }
  }

  /// 格式化字数显示（如 2300 → "2.3k"）
  static String formatWords(int words) {
    if (words >= 10000) {
      return '${(words / 10000).toStringAsFixed(1)}w';
    } else if (words >= 1000) {
      return '${(words / 1000).toStringAsFixed(1)}k';
    } else {
      return '$words';
    }
  }
}

/// 统计数据封装
class StatsData {
  final int diaryCount; // 日记篇数
  final int days;       // 使用天数
  final int totalWords; // 累计字数

  const StatsData({
    required this.diaryCount,
    required this.days,
    required this.totalWords,
  });
}
