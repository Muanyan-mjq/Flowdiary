import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../utils/diary_storage.dart';
import '../widgets/responsive_app_bar.dart';
import '../main.dart';

/// 心情颜色映射
const Map<String, Color> moodColors = {
  '开心': Color(0xFFFFD700),
  '难过': Color(0xFF6495ED),
  '平静': Color(0xFF6BCB77),
  '惊喜': Color(0xFFFF69B4),
  '生气': Color(0xFFFF6B6B),
};

/// 心情 emoji 映射
const Map<String, String> moodEmojis = {
  '开心': '😊',
  '难过': '😢',
  '平静': '😌',
  '惊喜': '🤩',
  '生气': '😤',
};

/// 心情日历页面
/// 月历视图，每天按心情着色，点击查看当日日记
class MoodCalendarScreen extends StatefulWidget {
  const MoodCalendarScreen({super.key});

  @override
  State<MoodCalendarScreen> createState() => _MoodCalendarScreenState();
}

class _MoodCalendarScreenState extends State<MoodCalendarScreen> {
  late int _year;
  late int _month;

  /// day → mood 映射
  Map<int, List<DiaryEntry>> _dayEntries = {};
  bool _isLoading = true;

  Color get _themeColor =>
      ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _loadMonthData();
  }

  /// 加载指定月份的日记数据
  Future<void> _loadMonthData() async {
    setState(() => _isLoading = true);
    final entries = await DiaryStorage.loadByMonth(_year, _month);

    // 按天分组
    final grouped = <int, List<DiaryEntry>>{};
    for (final entry in entries) {
      final day = entry.createdAt.day;
      grouped.putIfAbsent(day, () => []).add(entry);
    }

    if (mounted) {
      setState(() {
        _dayEntries = grouped;
        _isLoading = false;
      });
    }
  }

  /// 切换到上个月
  void _goToPrevMonth() {
    setState(() {
      if (_month == 1) {
        _year--;
        _month = 12;
      } else {
        _month--;
      }
    });
    _loadMonthData();
  }

  /// 切换到下个月
  void _goToNextMonth() {
    final now = DateTime.now();
    // 不能超过当前月份
    if (_year == now.year && _month >= now.month) return;

    setState(() {
      if (_month == 12) {
        _year++;
        _month = 1;
      } else {
        _month++;
      }
    });
    _loadMonthData();
  }

  /// 点击某天 → 弹出日记详情
  void _onDayTap(int day) {
    final entries = _dayEntries[day];
    if (entries == null || entries.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildDayDetailSheet(day, entries),
    );
  }

  /// 判断是否为今天
  bool _isToday(int day) {
    final now = DateTime.now();
    return _year == now.year && _month == now.month && day == now.day;
  }

  /// 判断是否可切换到下个月
  bool get _canGoNext {
    final now = DateTime.now();
    return _year < now.year || (_year == now.year && _month < now.month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor(context),
      body: Column(
        children: [
          // 顶部导航
          ResponsiveAppBar(
            backgroundColor: appBgColor(context),
            titleAlignment: CrossAxisAlignment.center,
            left: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 22, color: Color(0xFF1A1A1A)),
              onPressed: () => Navigator.pop(context),
            ),
            center: const Text(
              '心情日历',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
            ),
            right: const SizedBox(width: 44), // 占位，保持标题居中
          ),
          // 内容
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF87CEEB)))
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Column(
                      children: [
                        _buildMonthSelector(),
                        const SizedBox(height: 20),
                        _buildCalendarGrid(),
                        const SizedBox(height: 24),
                        _buildLegend(),
                        const SizedBox(height: 20),
                        _buildStats(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 月份选择器：← 2026年6月 →
  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final isCurrentMonth = _year == now.year && _month == now.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 左箭头
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28, color: Color(0xFF666666)),
            onPressed: _goToPrevMonth,
          ),
          // 年月文字
          Column(
            children: [
              Text(
                '$_year年$_month月',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (isCurrentMonth)
                Text(
                  '本月',
                  style: TextStyle(fontSize: 12, color: _themeColor, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          // 右箭头（当前月则灰掉）
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              size: 28,
              color: _canGoNext ? const Color(0xFF666666) : Colors.grey[300],
            ),
            onPressed: _canGoNext ? _goToNextMonth : null,
          ),
        ],
      ),
    );
  }

  /// 日历网格
  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final firstWeekday = DateTime(_year, _month, 1).weekday; // 1=Mon, 7=Sun
    final startCol = firstWeekday % 7; // 0=Sun, 1=Mon, ..., 6=Sat
    final totalCells = startCol + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    const weekHeaders = ['日', '一', '二', '三', '四', '五', '六'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 星期头
          Row(
            children: weekHeaders.map((h) {
              final isWeekend = h == '日' || h == '六';
              return Expanded(
                child: Center(
                  child: Text(
                    h,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isWeekend ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // 日期行
          ...List.generate(totalRows, (row) {
            return SizedBox(
              height: 52,
              child: Row(
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  final day = cellIndex - startCol + 1;

                  // 不在本月范围内
                  if (day < 1 || day > daysInMonth) {
                    return const Expanded(child: SizedBox.shrink());
                  }

                  final entries = _dayEntries[day];
                  final hasDiary = entries != null && entries.isNotEmpty;
                  final mood = hasDiary ? entries.first.mood : null;
                  final today = _isToday(day);

                  return Expanded(
                    child: GestureDetector(
                      onTap: hasDiary ? () => _onDayTap(day) : null,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: hasDiary
                              ? (moodColors[mood] ?? const Color(0xFFE0E0E0)).withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: today
                              ? Border.all(color: _themeColor, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: today ? FontWeight.w700 : FontWeight.w400,
                                color: today
                                    ? _themeColor
                                    : const Color(0xFF1A1A1A),
                              ),
                            ),
                            if (hasDiary)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: moodColors[mood] ?? const Color(0xFFCCCCCC),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 心情颜色图例
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '心情图例',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: moodColors.entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: e.value,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${moodEmojis[e.key] ?? ''} ${e.key}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 月度统计
  Widget _buildStats() {
    final totalDays = _dayEntries.length;
    final totalEntries = _dayEntries.values.fold<int>(0, (sum, list) => sum + list.length);

    // 统计各心情天数
    final moodCounts = <String, int>{};
    for (final entries in _dayEntries.values) {
      final mood = entries.first.mood;
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    // 找出最多心情
    String? dominantMood;
    int maxCount = 0;
    for (final e in moodCounts.entries) {
      if (e.value > maxCount) {
        maxCount = e.value;
        dominantMood = e.key;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 统计数字
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('$totalDays', '记录天数'),
              Container(width: 1, height: 30, color: const Color(0xFFEEEEEE)),
              _buildStatItem('$totalEntries', '日记篇数'),
              Container(width: 1, height: 30, color: const Color(0xFFEEEEEE)),
              _buildStatItem(dominantMood != null ? moodEmojis[dominantMood] ?? '—' : '—', '最多心情'),
            ],
          ),
          if (dominantMood != null) ...[
            const SizedBox(height: 16),
            // 心情分布条
            ...moodCounts.entries.map((e) {
              final ratio = totalDays > 0 ? e.value / totalDays : 0.0;
              final color = moodColors[e.key] ?? Colors.grey;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        moodEmojis[e.key] ?? e.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: const Color(0xFFF0F0F0),
                          color: color,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${e.value}天',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  /// 点击某天弹出的详情底部弹窗
  Widget _buildDayDetailSheet(int day, List<DiaryEntry> entries) {
    final first = entries.first;
    final moodColor = moodColors[first.mood] ?? const Color(0xFFCCCCCC);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽条
          const SizedBox(height: 12),
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // 日期 + 心情
          Row(
            children: [
              const SizedBox(width: 24),
              Text(
                '$_month月$day日',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: moodColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${moodEmojis[first.mood] ?? ''} ${first.mood}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: moodColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 日记列表
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              shrinkWrap: true,
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final entry = entries[i];
                final hour = entry.createdAt.hour.toString().padLeft(2, '0');
                final minute = entry.createdAt.minute.toString().padLeft(2, '0');

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: appBgColor(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$hour:$minute',
                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.weather,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                          const Spacer(),
                          Icon(
                            _weatherIcon(entry.weather),
                            size: 14,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF333333)),
                      ),
                      if (entry.events.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: entry.events.map((e) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(e, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _weatherIcon(String weather) {
    switch (weather) {
      case '晴': return Icons.wb_sunny;
      case '多云': return Icons.cloud;
      case '雨': return Icons.grain;
      case '雪': return Icons.ac_unit;
      case '风': return Icons.air;
      default: return Icons.wb_sunny;
    }
  }
}
