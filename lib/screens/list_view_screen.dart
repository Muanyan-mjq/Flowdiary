import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../utils/diary_storage.dart';
import '../utils/chinese_calendar.dart';
import '../main.dart';
import '../utils/smooth_route.dart';
import '../utils/favorite_storage.dart';
import '../widgets/responsive_app_bar.dart';
import '../widgets/staggered_entrance.dart';
import 'diary_wizard_screen.dart';
import 'diary_detail_screen.dart';

class ListViewScreen extends StatefulWidget {
  final int? initialYear;
  final int? initialMonth;
  final ScrollController? scrollController;

  const ListViewScreen({super.key, this.initialYear, this.initialMonth, this.scrollController});

  @override
  State<ListViewScreen> createState() => _ListViewScreenState();
}

class _ListViewScreenState extends State<ListViewScreen> {
  late int _selectedYear;
  late int _selectedMonth;
  int? _selectedDay;
  bool _isCalendarExpanded = true;
  int _displayWeek = 0; // 折叠时显示的周索引
  List<DiaryEntry> _dayDiaries = [];
  bool _isLoadingDiaries = false;
  Set<int> _daysWithDiary = {};
  Set<String> _favoriteIds = {}; // 收藏的日记 ID

  double _dragStartX = 0;
  double _dragTotalY = 0; // 累计纵向位移
  bool _isOverlayOpen = false;
  late int _overlayYear;
  late ScrollController _yearScrollController;
  late final ScrollController _listScrollController;
  static int get _minYear => DateTime.now().year - 30;

  Color get _themeColor =>
      ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = widget.initialYear ?? now.year;
    _selectedMonth = widget.initialMonth ?? now.month;
    _overlayYear = _selectedYear;
    _yearScrollController = ScrollController();
    _listScrollController = widget.scrollController ?? ScrollController();
    _loadDiaryDots();
    _loadFavoriteIds();
    _resetDisplayWeek();
  }

  @override
  void dispose() {
    _yearScrollController.dispose();
    if (widget.scrollController == null) _listScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDiaryDots() async {
    final diaries = await DiaryStorage.loadByMonth(_selectedYear, _selectedMonth);
    if (mounted) setState(() => _daysWithDiary = diaries.map((d) => d.createdAt.day).toSet());
  }

  Future<void> _loadFavoriteIds() async {
    final ids = await FavoriteStorage.getFavoriteIds();
    if (mounted) setState(() => _favoriteIds = ids);
  }

  Future<void> _loadDayDiaries(int day) async {
    setState(() { _isLoadingDiaries = true; _selectedDay = day; });
    final all = await DiaryStorage.loadByMonth(_selectedYear, _selectedMonth);
    final targetDate = DateTime(_selectedYear, _selectedMonth, day);
    final dayDiaries = all.where((d) {
      return d.createdAt.year == targetDate.year &&
          d.createdAt.month == targetDate.month &&
          d.createdAt.day == targetDate.day;
    }).toList();
    if (mounted) setState(() { _dayDiaries = dayDiaries; _isLoadingDiaries = false; });
  }

  void _openOverlay() {
    setState(() { _isOverlayOpen = true; _overlayYear = _selectedYear; });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted && _isOverlayOpen) _scrollToSelectedYear();
    });
  }

  void _closeOverlay() => setState(() => _isOverlayOpen = false);

  void _scrollToSelectedYear() {
    if (!_yearScrollController.hasClients) return;
    final index = _overlayYear - _minYear;
    final sw = MediaQuery.sizeOf(context).width;
    _yearScrollController.animateTo(
      ((index * 72.0) - (sw / 2) + 32).clamp(0.0, _yearScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic,
    );
  }

  void _selectMonth(int month) {
    setState(() {
      _selectedYear = _overlayYear; _selectedMonth = month;
      _isOverlayOpen = false; _selectedDay = null; _dayDiaries = [];
    });
    _resetDisplayWeek();
    _loadDiaryDots();
  }

  /// 重置折叠显示的周（当前月则选本周，否则第一周）
  void _resetDisplayWeek() {
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      final firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday;
      final startCol = firstWeekday % 7;
      _displayWeek = (startCol + now.day - 1) ~/ 7;
    } else {
      _displayWeek = 0;
    }
  }

  /// 切换月份：dir = -1(上月) / +1(下月)
  void _goToMonth(int dir) {
    setState(() {
      if (dir < 0) {
        if (_selectedMonth == 1) { _selectedYear--; _selectedMonth = 12; }
        else { _selectedMonth--; }
      } else {
        if (_selectedMonth == 12) { _selectedYear++; _selectedMonth = 1; }
        else { _selectedMonth++; }
      }
      _selectedDay = null;
      _dayDiaries = [];
    });
    _resetDisplayWeek();
    _loadDiaryDots();
  }

  /// 折叠时切换周：dir = -1(上周) / +1(下周)，自动跨月
  void _goToWeek(int dir) {
    final newWeek = _displayWeek + dir;
    if (newWeek < 0) {
      // 到上个月最后一周
      _goToMonth(-1);
      // _goToMonth 中调了 _resetDisplayWeek，这里覆写为上月最后一周
      final tw = _totalWeeks();
      setState(() => _displayWeek = tw > 0 ? tw - 1 : 0);
    } else if (newWeek >= _totalWeeks()) {
      // 到下个月第一周
      _goToMonth(1);
      setState(() => _displayWeek = 0);
    } else {
      setState(() => _displayWeek = newWeek);
    }
  }

  String _getTitle() => '$_selectedYear年$_selectedMonth月';

  // 计算总周数
  int _totalWeeks() {
    final firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday;
    final startCol = firstWeekday % 7;
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    return ((startCol + daysInMonth) / 7).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = ResponsiveAppBar.safeTop(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Listener(
            onPointerDown: (e) {
              _dragStartX = e.position.dx;
              _dragTotalY = 0;
            },
            onPointerMove: (e) {
              _dragTotalY += e.delta.dy;
            },
            onPointerUp: (e) {
              final dx = e.position.dx - _dragStartX;
              final absDx = dx.abs();
              final absDy = _dragTotalY.abs();

              // 左右滑动（阈值10px，极为灵敏）
              if (absDx > absDy && absDx > 10) {
                if (_isCalendarExpanded) {
                  _goToMonth(dx > 0 ? -1 : 1);
                } else {
                  _goToWeek(dx > 0 ? -1 : 1);
                }
              }
              // 垂直滑动 → 展开/折叠（阈值8px）
              else if (absDy > absDx && absDy > 8) {
                if (_dragTotalY > 0 && !_isCalendarExpanded) {
                  setState(() => _isCalendarExpanded = true);
                } else if (_dragTotalY < 0 && _isCalendarExpanded) {
                  setState(() => _isCalendarExpanded = false);
                }
              }
            },
            child: Column(
              children: [
                SizedBox(height: safeTop),
                _buildTopBar(),
                _buildCalendar(),
                if (_selectedDay != null) ...[
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  Expanded(child: _buildDayDiaryList()),
                ] else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
          if (_isOverlayOpen) _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          Center(
            child: GestureDetector(
              onTap: _openOverlay, behavior: HitTestBehavior.opaque,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_getTitle(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                const SizedBox(width: 4),
                Icon(_isOverlayOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 22, color: Colors.grey[600]),
              ]),
            ),
          ),
          Positioned(left: 16, top: 0, bottom: 0,
            child: Center(child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.grey[600]),
              onPressed: () => Navigator.of(context).pop(),
            )),
          ),
          Positioned(right: 16, top: 0, bottom: 0,
            child: Center(child: IconButton(
              icon: Icon(Icons.edit_outlined, size: 22, color: Colors.grey[600]),
              onPressed: () async {
                await Navigator.of(context, rootNavigator: true).push(
                  SmoothRoute(builder: (_) => const DiaryWizardScreen()),
                );
                _loadDiaryDots();
                if (_selectedDay != null) _loadDayDiaries(_selectedDay!);
              },
            )),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 日历
  // ═══════════════════════════════════════════════════════

  Widget _buildCalendar() {
    final now = DateTime.now();
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday;
    final startCol = firstWeekday % 7;
    final totalWeeks = _totalWeeks();

    const weekDays = ['日', '一', '二', '三', '四', '五', '六'];

    // 限制 displayWeek 在有效范围内
    if (_displayWeek >= totalWeeks) _displayWeek = totalWeeks - 1;
    if (_displayWeek < 0) _displayWeek = 0;

    final firstWeek = _isCalendarExpanded ? 0 : _displayWeek;
    final lastWeek = _isCalendarExpanded ? totalWeeks - 1 : _displayWeek;

    return Column(
      children: [
          // 星期头
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: List.generate(7, (i) => Expanded(
                child: Center(child: Text(weekDays[i],
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[500])),
                ),
              )),
            ),
          ),
          // 日期行
          ...List.generate(lastWeek - firstWeek + 1, (w) {
            final week = firstWeek + w;
            return SizedBox(
              height: _isCalendarExpanded ? 52 : 48,
              child: Row(
                children: List.generate(7, (col) {
                  final dayIndex = week * 7 + col - startCol + 1;
                  final isValid = dayIndex >= 1 && dayIndex <= daysInMonth;
                  final isToday = isValid && _selectedYear == now.year &&
                      _selectedMonth == now.month && dayIndex == now.day;
                  final isSelected = isValid && _selectedDay == dayIndex;
                  final isWeekend = col == 0 || col == 6;
                  final hasDiary = isValid && _daysWithDiary.contains(dayIndex);

                  LunarInfo? lunar;
                  if (isValid) lunar = getLunarInfo(_selectedYear, _selectedMonth, dayIndex);

                  return Expanded(
                    child: isValid
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _loadDayDiaries(dayIndex),
                            child: Container(
                              decoration: isSelected
                                  ? BoxDecoration(
                                      color: _themeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    )
                                  : null,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('$dayIndex',
                                    style: TextStyle(
                                      fontSize: _isCalendarExpanded ? 16 : 15,
                                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                                      color: isToday || isSelected
                                          ? _themeColor
                                          : isWeekend ? Colors.grey[380] : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  _buildCalendarSub(hasDiary, lunar),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  );
                }),
              ),
            );
          }),
          // 底部控制栏（整行可点切换）
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isCalendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20, color: Colors.grey[400],
                  ),
                  if (!_isCalendarExpanded) ...[
                    const SizedBox(width: 6),
                    Text('第${_displayWeek + 1}/$totalWeeks周',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildCalendarSub(bool hasDiary, LunarInfo? lunar) {
    if (hasDiary) {
      return Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Container(width: 4, height: 4,
          decoration: BoxDecoration(color: _themeColor, shape: BoxShape.circle)),
      );
    }
    String? text;
    if (lunar != null && lunar.holiday != null && lunar.holiday!.isNotEmpty) {
      text = lunar.holiday;
    } else if (lunar != null && lunar.lunarDayName.isNotEmpty) {
      text = lunar.lunarDayName;
    }
    if (text != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(text, style: TextStyle(fontSize: 9, color: Colors.grey[400]),
          overflow: TextOverflow.ellipsis),
      );
    }
    return const SizedBox(height: 12);
  }

  // ═══════════════════════════════════════════════════════
  // 日记列表
  // ═══════════════════════════════════════════════════════

  Widget _buildDayDiaryList() {
    if (_isLoadingDiaries) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF87CEEB)));
    }
    if (_dayDiaries.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.edit_note_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('$_selectedMonth月$_selectedDay日没有日记', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
        ]),
      );
    }
    return ListView.builder(
      controller: _listScrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _dayDiaries.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: StaggeredEntrance(
          index: index,
          child: _buildDiaryCard(_dayDiaries[index]),
        ),
      ),
    );
  }

  Widget _buildDiaryCard(DiaryEntry entry) {
    final moodIcons = {
      '开心': Icons.sentiment_very_satisfied, '难过': Icons.sentiment_very_dissatisfied,
      '平静': Icons.sentiment_neutral, '惊喜': Icons.emoji_emotions, '生气': Icons.sentiment_dissatisfied,
    };
    final moodColors = {
      '开心': const Color(0xFFFFD700), '难过': const Color(0xFF6495ED),
      '平静': const Color(0xFF90EE90), '惊喜': const Color(0xFFFF69B4), '生气': const Color(0xFFFF6B6B),
    };
    final weatherIcons = {
      '晴': Icons.wb_sunny, '多云': Icons.cloud, '雨': Icons.grain, '雪': Icons.ac_unit, '风': Icons.air,
    };
    final moodIcon = moodIcons[entry.mood] ?? Icons.sentiment_neutral;
    final moodColor = moodColors[entry.mood] ?? const Color(0xFF90EE90);
    final weatherIcon = weatherIcons[entry.weather] ?? Icons.wb_sunny;
    final hour = entry.createdAt.hour.toString().padLeft(2, '0');
    final minute = entry.createdAt.minute.toString().padLeft(2, '0');

    return GestureDetector(
      onTap: () => Navigator.push(context, SmoothRoute(builder: (_) => DiaryDetailScreen(entry: entry))),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: appBgColor(context), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('$hour:$minute', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          const Spacer(),
          // 收藏按钮
          GestureDetector(
            onTap: () async {
              final isNowFav = await FavoriteStorage.toggle(entry.id);
              await _loadFavoriteIds();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isNowFav ? '已收藏' : '已取消收藏')),
                );
              }
            },
            child: Icon(
              _favoriteIds.contains(entry.id) ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: _favoriteIds.contains(entry.id) ? const Color(0xFFFF5252) : Colors.grey[400],
            ),
          ),
          const SizedBox(width: 8),
          Icon(weatherIcon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Icon(moodIcon, size: 16, color: moodColor),
        ]),
        const SizedBox(height: 10),
        Text(entry.content, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF1A1A1A))),
        if (entry.events.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, children: entry.events.map((e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Text(e, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          )).toList()),
        ],
      ]),
    ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 年月选择器
  // ═══════════════════════════════════════════════════════

  Widget _buildOverlay() {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Positioned.fill(
      child: GestureDetector(
        onTap: _closeOverlay,
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Column(children: [
            GestureDetector(onTap: () {}, child: SizedBox(height: screenHeight * 0.42, width: double.infinity, child: _buildPanelContent())),
            const Spacer(),
          ]),
        ),
      ),
    );
  }

  Widget _buildPanelContent() {
    final safeTop = ResponsiveAppBar.safeTop(context);
    return Container(
      width: double.infinity, padding: EdgeInsets.only(top: safeTop + 20, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Container(width: 32, height: 3, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        _buildYearSelector(),
        const SizedBox(height: 20),
        Expanded(child: _buildMonthGrid()),
      ]),
    );
  }

  Widget _buildYearSelector() {
    final maxYear = DateTime.now().year;
    return SizedBox(height: 40, child: ListView.builder(
      controller: _yearScrollController, scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: maxYear - _minYear + 1,
      itemBuilder: (context, index) {
        final year = _minYear + index;
        final isSelected = year == _overlayYear;
        return GestureDetector(
          onTap: () => setState(() => _overlayYear = year),
          child: Container(
            width: 64, margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: isSelected ? const Color(0xFF1A1A1A) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text('$year', style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : Colors.grey[400]))),
          ),
        );
      },
    ));
  }

  Widget _buildMonthGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 1.2, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          final isSelected = month == _selectedMonth && _overlayYear == _selectedYear;
          return GestureDetector(
            onTap: () => _selectMonth(month),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? _themeColor.withValues(alpha: 0.12) : appBgColor(context),
                borderRadius: BorderRadius.circular(14),
                border: isSelected ? Border.all(color: _themeColor, width: 1.5) : null,
              ),
              child: Center(child: Text('$month月', style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey[600]))),
            ),
          );
        },
      ),
    );
  }
}
