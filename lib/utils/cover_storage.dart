import 'package:shared_preferences/shared_preferences.dart';

/// 月份封面持久化存储
class CoverStorage {
  static const _keyPrefix = 'month_cover_';

  /// 保存某年某月的自定义封面路径
  static Future<void> saveCover(int year, int month, String assetPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix${year}_$month', assetPath);
  }

  /// 读取某年某月的自定义封面路径（null = 使用默认封面）
  static Future<String?> getCover(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyPrefix${year}_$month');
  }

  /// 重置某年某月封面为默认
  static Future<void> resetCover(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix${year}_$month');
  }
}
