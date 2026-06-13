import 'dart:ui';

/// 月份卡片数据模型
class MonthlyCardModel {
  final String id;
  final int monthNumber;
  final String monthName;
  final String? assetPath;
  final int currentProgress;
  final int totalDays;
  final Color themeColor;

  const MonthlyCardModel({
    required this.id,
    required this.monthNumber,
    required this.monthName,
    this.assetPath,
    required this.currentProgress,
    required this.totalDays,
    this.themeColor = const Color(0xFF87CEEB),
  });

  double get progress =>
      totalDays > 0 ? (currentProgress / totalDays).clamp(0.0, 1.0) : 0.0;

  String get progressText => '$currentProgress/$totalDays';

  static const List<String> monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// 快速构造：根据年月和进度创建（自动关联封面图 + 正确天数）
  factory MonthlyCardModel.fromMonth({
    required int year,
    required int month,
    required int currentProgress,
    Color? themeColor,
  }) {
    assert(month >= 1 && month <= 12, 'month must be 1~12, got $month');
    return MonthlyCardModel(
      id: '${year}_$month',
      monthNumber: month,
      monthName: monthNames[month - 1],
      assetPath: 'assets/images/monthly/${month.toString().padLeft(2, '0')}.jpg',
      currentProgress: currentProgress,
      totalDays: _daysInMonth(year, month),
      themeColor: themeColor ?? _defaultThemeColor(month),
    );
  }

  /// 计算当月天数（传入年份，正确处理闰年）
  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static Color _defaultThemeColor(int month) {
    const colors = [
      Color(0xFF87CEEB), Color(0xFFFFB7C5), Color(0xFF98D8C8),
      Color(0xFFF7C59F), Color(0xFFB8D4E3), Color(0xFFE8D5B7),
      Color(0xFFB5EAD7), Color(0xFFC7CEEA), Color(0xFFFFDAC1),
      Color(0xFFD4A59A), Color(0xFFB8C0FF), Color(0xFFF3D5C9),
    ];
    return colors[(month - 1) % 12];
  }

  /// 复制并修改指定字段
  MonthlyCardModel copyWith({String? assetPath}) {
    return MonthlyCardModel(
      id: id,
      monthNumber: monthNumber,
      monthName: monthName,
      assetPath: assetPath ?? this.assetPath,
      currentProgress: currentProgress,
      totalDays: totalDays,
      themeColor: themeColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyCardModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
