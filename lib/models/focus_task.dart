import 'dart:math';

/// 计时模式
enum FocusMode { pomodoro, countdown, stopwatch }

/// 计时器样式
enum TimerStyle { circular, card, flip, minimal, dashboard }

/// 专注任务模型
class FocusTask {
  final String id;
  String name;
  FocusMode mode;
  int durationMinutes;      // 番茄钟/倒计时 的分钟数
  TimerStyle timerStyle;
  int bgColorIndex;         // 卡片背景色索引
  int completedToday;       // 今日完成次数
  DateTime? lastCompleted;  // 上次完成日期
  int totalCompletions;     // 总完成次数
  DateTime createdAt;
  int sortOrder;            // 排序顺序，越小越靠前

  FocusTask({
    required this.id,
    required this.name,
    this.mode = FocusMode.pomodoro,
    this.durationMinutes = 25,
    this.timerStyle = TimerStyle.circular,
    this.bgColorIndex = -1, // -1 表示自动分配
    this.completedToday = 0,
    this.lastCompleted,
    this.totalCompletions = 0,
    DateTime? createdAt,
    this.sortOrder = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 今日是否已完成过（需要划线）
  bool get isDoneToday {
    if (lastCompleted == null) return false;
    final now = DateTime.now();
    return lastCompleted!.year == now.year &&
        lastCompleted!.month == now.month &&
        lastCompleted!.day == now.day &&
        completedToday > 0;
  }

  /// 默认时长（秒）
  int get durationSeconds => durationMinutes * 60;

  /// 模式中文名
  String get modeLabel {
    switch (mode) {
      case FocusMode.pomodoro: return '番茄钟';
      case FocusMode.countdown: return '倒计时';
      case FocusMode.stopwatch: return '正计时';
    }
  }

  /// 卡片背景渐变色（白色文字专用，深色底）
  ColorPair get bgColors {
    if (bgColorIndex >= 0 && bgColorIndex < cardColors.length) {
      return cardColors[bgColorIndex];
    }
    // 自动分配
    final i = id.hashCode.abs() % cardColors.length;
    return cardColors[i];
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'mode': mode.index,
    'durationMinutes': durationMinutes, 'timerStyle': timerStyle.index,
    'bgColorIndex': bgColorIndex, 'completedToday': completedToday,
    'lastCompleted': lastCompleted?.toIso8601String(),
    'totalCompletions': totalCompletions,
    'createdAt': createdAt.toIso8601String(), 'sortOrder': sortOrder,
  };

  factory FocusTask.fromJson(Map<String, dynamic> j) => FocusTask(
    id: j['id'] as String,
    name: j['name'] as String,
    mode: FocusMode.values[j['mode'] as int? ?? 0],
    durationMinutes: j['durationMinutes'] as int? ?? 25,
    timerStyle: TimerStyle.values[j['timerStyle'] as int? ?? 0],
    bgColorIndex: j['bgColorIndex'] as int? ?? -1,
    completedToday: j['completedToday'] as int? ?? 0,
    lastCompleted: j['lastCompleted'] != null ? DateTime.tryParse(j['lastCompleted'] as String) : null,
    totalCompletions: j['totalCompletions'] as int? ?? 0,
    createdAt: j['createdAt'] != null ? DateTime.parse(j['createdAt'] as String) : DateTime.now(),
    sortOrder: j['sortOrder'] as int? ?? 0,
  );
}

/// 颜色对（背景色，色条色）
class ColorPair {
  final int bg;    // 背景色 ARGB
  final int bar;   // 左侧色条 ARGB
  const ColorPair(this.bg, this.bar);
}

/// 16 种卡片配色（深色底 + 白色文字）
const cardColors = [
  ColorPair(0xFF5B8DEF, 0xFF3A6FD8), // 蓝
  ColorPair(0xFF6C5CE7, 0xFF4A3FD4), // 紫
  ColorPair(0xFFE17055, 0xFFD0523A), // 橙红
  ColorPair(0xFF00B894, 0xFF00997A), // 绿
  ColorPair(0xFFE84393, 0xFFD03080), // 粉
  ColorPair(0xFF0984E3, 0xFF0770C9), // 深蓝
  ColorPair(0xFFA29BFE, 0xFF837DE8), // 浅紫
  ColorPair(0xFFFD79A8, 0xFFE06090), // 玫红
  ColorPair(0xFF00CEC9, 0xFF00B0AB), // 青
  ColorPair(0xFFFDCB6E, 0xFFE0B04A), // 金
  ColorPair(0xFF636E72, 0xFF4A5458), // 灰
  ColorPair(0xFF9B59B6, 0xFF7D3C98), // 深紫
  ColorPair(0xFF2ECC71, 0xFF20A858), // 翠绿
  ColorPair(0xFFE74C3C, 0xFFCC3328), // 红
  ColorPair(0xFF1ABC9C, 0xFF0E9E80), // 碧绿
  ColorPair(0xFF3498DB, 0xFF217DBB), // 亮蓝
];

/// 励志文案池
const _motivations = [
  '专注是最高级的自律',
  '每一分钟都在成为更好的自己',
  '心流时刻，万物俱寂',
  '沉下去，才能浮上来',
  '你今天的时间花在哪，未来就在哪',
  '安静下来，世界会给你答案',
  '不积硅步，无以至千里',
  '专注当下，未来自来',
  '比别人多一点执着，你就会创造奇迹',
  '不要让噪音淹没你内心的声音',
  '每一次专注，都是对未来的投资',
  '水滴石穿，不是力量大，是功夫深',
  '你专注的样子，很美',
  '做难事必有所得',
  '当你在凝望深渊时，深渊也在凝望你',
  '行者常至，为者常成',
  '心之所向，素履以往',
  '坚持是一件很酷的事',
  '要么出众，要么出局',
  '别让懒惰限制了你的想象力',
];

/// 随机获取一条励志文案
String randomMotivation() {
  return _motivations[Random().nextInt(_motivations.length)];
}
