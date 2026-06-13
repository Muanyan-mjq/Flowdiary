// 中国农历 + 节假日工具
// 2026年数据，覆盖常用范围

// 农历日名称
const _lunarDayNames = [
  '', '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
  '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
  '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十',
];

/// 农历月名称
const _lunarMonthNames = [
  '', '正月', '二月', '三月', '四月', '五月', '六月',
  '七月', '八月', '九月', '十月', '冬月', '腊月',
];

/// 2026年农历每月初一对应的公历日期
/// 格式: (月, 日) — 表示农历该月初一 = 公历该日期
const _lunarMonthStarts2026 = [
  (0, 0),   // 占位
  (2, 17),  // 正月初一 = 公历2月17日（春节）
  (3, 19),  // 二月初一
  (4, 17),  // 三月初一
  (5, 16),  // 四月初一
  (6, 15),  // 五月初一
  (7, 14),  // 六月初一
  (8, 13),  // 七月初一
  (9, 11),  // 八月初一
  (10, 11), // 九月初一
  (11, 9),  // 十月初一
  (12, 9),  // 冬月初一
];

/// 2027年农历每月初一对应的公历日期（用于2026年腊月跨年）
const _lunarMonthStarts2027 = [
  (0, 0),   // 占位
  (1, 7),   // 正月初一(2027)
  (2, 6),   // 二月初一
];

/// 2026年法定节假日
const _holidays2026 = {
  // 元旦
  '2026-01-01': '元旦',
  // 春节（除夕到初六）
  '2026-02-16': '除夕',
  '2026-02-17': '春节',
  '2026-02-18': '春节',
  '2026-02-19': '春节',
  '2026-02-20': '春节',
  '2026-02-21': '春节',
  '2026-02-22': '春节',
  '2026-02-23': '春节',
  // 清明节
  '2026-04-05': '清明',
  // 劳动节
  '2026-05-01': '劳动节',
  '2026-05-02': '劳动节',
  '2026-05-03': '劳动节',
  '2026-05-04': '劳动节',
  '2026-05-05': '劳动节',
  // 端午节
  '2026-06-19': '端午',
  // 中秋节
  '2026-09-25': '中秋',
  // 国庆节
  '2026-10-01': '国庆节',
  '2026-10-02': '国庆节',
  '2026-10-03': '国庆节',
  '2026-10-04': '国庆节',
  '2026-10-05': '国庆节',
  '2026-10-06': '国庆节',
  '2026-10-07': '国庆节',
};

/// 传统节日（非法定假日）
const _traditionalFestivals2026 = {
  '2026-02-16': '除夕',
  '2026-03-03': '元宵节',
  '2026-08-19': '七夕',
  '2026-09-24': '重阳节',
  '2026-11-14': '下元节',
  '2026-12-21': '冬至',
};

/// 农历特殊日（腊月二十三过小年等）
const _specialDays2026 = {
  '2026-02-10': '小年',
};

/// 获取某天的农历信息
LunarInfo getLunarInfo(int year, int month, int day) {
  final dateKey = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  // 检查节假日
  final holiday = _holidays2026[dateKey];
  final traditional = _traditionalFestivals2026[dateKey];
  final special = _specialDays2026[dateKey];

  // 计算农历
  int lunarMonth = 0;
  int lunarDay = 0;

  final target = DateTime(year, month, day);

  // 在2026年范围内查找
  for (int m = 1; m <= 11; m++) {
    final start = DateTime(2026, _lunarMonthStarts2026[m].$1, _lunarMonthStarts2026[m].$2);
    final nextStart = m < 11
        ? DateTime(2026, _lunarMonthStarts2026[m + 1].$1, _lunarMonthStarts2026[m + 1].$2)
        : DateTime(2027, _lunarMonthStarts2027[1].$1, _lunarMonthStarts2027[1].$2);

    if (!target.isBefore(start) && target.isBefore(nextStart)) {
      lunarMonth = m;
      lunarDay = target.difference(start).inDays + 1;
      break;
    }
  }

  // 处理2026年1月到2月16日（属于上年腊月，即2025年农历十二月）
  if (lunarMonth == 0 && target.isBefore(DateTime(2026, 2, 17))) {
    // 2025年腊月初一 ≈ 2026年1月19日
    // 腊月每月长短：简化处理，用固定偏移
    final lastMonthStart = DateTime(2026, 1, 19); // 2025腊月初一约等于2026年1月19日
    if (!target.isBefore(lastMonthStart)) {
      lunarMonth = 12;
      lunarDay = target.difference(lastMonthStart).inDays + 1;
    } else {
      // 2025年冬月（十一月）初一 ≈ 2025年12月20日
      final prevMonthStart = DateTime(2025, 12, 20);
      if (!target.isBefore(prevMonthStart)) {
        lunarMonth = 11;
        lunarDay = target.difference(prevMonthStart).inDays + 1;
      }
    }
  }

  final lunarDayName = lunarDay > 0 && lunarDay <= 30 ? _lunarDayNames[lunarDay] : '';
  final lunarMonthName = lunarMonth > 0 && lunarMonth <= 12 ? _lunarMonthNames[lunarMonth] : '';

  return LunarInfo(
    lunarDayName: lunarDayName,
    lunarMonthName: lunarMonthName,
    holiday: holiday ?? traditional ?? special,
    isHoliday: holiday != null,
    isTraditional: traditional != null,
  );
}

class LunarInfo {
  final String lunarDayName;
  final String lunarMonthName;
  final String? holiday;
  final bool isHoliday;
  final bool isTraditional;

  const LunarInfo({
    required this.lunarDayName,
    required this.lunarMonthName,
    this.holiday,
    this.isHoliday = false,
    this.isTraditional = false,
  });
}
