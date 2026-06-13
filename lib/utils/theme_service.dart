import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题服务：管理主题颜色的保存和读取
class ThemeService {
  static const String _themeColorKey = 'theme_color';

  /// 保存主题颜色
  static Future<void> saveThemeColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeColorKey, color.toARGB32());
  }

  /// 读取主题颜色
  static Future<Color?> getThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_themeColorKey);
    if (colorValue != null) {
      return Color(colorValue);
    }
    return null;
  }
}
