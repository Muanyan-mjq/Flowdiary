import 'package:flutter/material.dart';
import '../models/monthly_card_model.dart';
import '../screens/diary_wizard_screen.dart';
import '../screens/list_view_screen.dart';
import '../utils/diary_storage.dart';
import '../utils/cover_storage.dart';
import '../widgets/monthly_card_slider.dart';
import '../utils/smooth_route.dart';
import '../widgets/responsive_app_bar.dart';
import '../main.dart';

/// 月度视图页面
class MonthlyViewScreen extends StatefulWidget {
  const MonthlyViewScreen({super.key});

  @override
  State<MonthlyViewScreen> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends State<MonthlyViewScreen> {
  Color get _tc => ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
  late int _selectedYear;
  late int _currentMonthIndex;
  late List<MonthlyCardModel> _cards;

  late final int _minYear;
  late final int _maxYear;

  bool _isOverlayOpen = false;
  late int _overlayYear; // overlay中选中的年份
  late ScrollController _yearScrollController;
  final _sliderKey = GlobalKey<MonthlyCardSliderState>();

  // 入场动画：从第1月滑到当前月
  bool _hasPlayedEntrance = false;

  // 打开overlay前的年月，用于取消时恢复
  late int _prevYear;
  late int _prevMonthIndex;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _currentMonthIndex = now.month - 1;
    _overlayYear = _selectedYear; // 初始化为当前年份
    _minYear = now.year - 30;
    _maxYear = now.year;
    _cards = _generateCards(_selectedYear);

    _yearScrollController = ScrollController();
    // 异步加载当年每月实际日记数
    _loadDiaryCounts(_selectedYear);
    // 入场动画：进入即滑动，两阶段精准着陆
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToYear(_selectedYear);
      if (_currentMonthIndex > 0) {
        // 总时长 = 每月350ms + 800ms基础（含两阶段过渡）
        final totalMs = _currentMonthIndex * 350 + 800;
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _sliderKey.currentState?.animateToPage(
              _currentMonthIndex,
              duration: Duration(milliseconds: totalMs),
            );
            Future.delayed(
              Duration(milliseconds: totalMs + 300),
              () {
                if (mounted) setState(() => _hasPlayedEntrance = true);
              },
            );
          }
        });
      } else {
        _hasPlayedEntrance = true;
      }
    });
  }

  @override
  void dispose() {
    _yearScrollController.dispose();
    super.dispose();
  }

  void _scrollToYear(int year) {
    if (!_yearScrollController.hasClients) return;

    final index = year - _minYear;
    // 每个年份按钮宽度64 + 间距8 = 72
    // 目标：让选中年份居中显示
    final screenWidth = MediaQuery.sizeOf(context).width;
    final targetOffset = (index * 72.0) - (screenWidth / 2) + 32;
    _yearScrollController.animateTo(
      targetOffset.clamp(0.0, _yearScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToSelectedYear() {
    _scrollToYear(_overlayYear);
  }

  void _openOverlay() {
    // 保存当前状态，取消时可恢复
    _prevYear = _selectedYear;
    _prevMonthIndex = _currentMonthIndex;
    setState(() {
      _isOverlayOpen = true;
      // 保持当前选择的年月，不重置
      _overlayYear = _selectedYear;
      _cards = _generateCards(_overlayYear);
    });
    _loadDiaryCounts(_overlayYear);
    // 延迟确保ListView已创建，再滚动到选定年份
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted && _isOverlayOpen) {
        _scrollToSelectedYear();
      }
    });
  }

  void _closeOverlay() {
    // 没选月份就关闭，恢复到打开前的状态
    setState(() {
      _isOverlayOpen = false;
      _selectedYear = _prevYear;
      _currentMonthIndex = _prevMonthIndex;
      _cards = _generateCards(_selectedYear);
    });
    // 跳转到对应的月份卡片
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _sliderKey.currentState?.animateToPage(_currentMonthIndex);
      }
    });
  }

  void _selectYear(int year) {
    setState(() {
      _overlayYear = year;
      _cards = _generateCards(year);
    });
    _scrollToSelectedYear();
    _loadDiaryCounts(year);
  }

  void _selectMonth(int month) {
    setState(() {
      _isOverlayOpen = false;
      _selectedYear = _overlayYear;
      _currentMonthIndex = month - 1;
    });
    // 延迟加载，避免卡顿
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _loadDiaryCounts(_selectedYear);
        _sliderKey.currentState?.animateToPage(_currentMonthIndex);
      }
    });
  }

  /// 生成12个月份卡片数据（默认日记数为 0，异步加载后再刷新）
  List<MonthlyCardModel> _generateCards(int year) {
    return List.generate(12, (i) {
      return MonthlyCardModel.fromMonth(
        year: year,
        month: i + 1,
        currentProgress: 0,
      );
    });
  }

  /// 异步加载当年每月实际日记数 + 自定义封面，刷新卡片
  Future<void> _loadDiaryCounts(int year) async {
    final counts = await DiaryStorage.loadCountsForYear(year);
    if (!mounted) return;
    // 加载自定义封面
    final covers = <int, String>{};
    for (int m = 1; m <= 12; m++) {
      final custom = await CoverStorage.getCover(year, m);
      if (custom != null) covers[m] = custom;
    }
    if (!mounted) return;
    setState(() {
      _cards = List.generate(12, (i) {
        final month = i + 1;
        return MonthlyCardModel.fromMonth(
          year: year,
          month: month,
          currentProgress: counts[i],
        ).copyWith(assetPath: covers[month]); // 用 copyWith：有自定义则覆盖，无则保持默认
      });
    });
  }

  String _getTitle() => '$_selectedYear年${_currentMonthIndex + 1}月';

  /// 回到当前月份
  void _goToCurrentMonth() {
    final now = DateTime.now();
    final newYear = now.year;
    final newMonth = now.month - 1;

    // 如果已经是当前月份，不执行
    if (_selectedYear == newYear && _currentMonthIndex == newMonth) return;

    setState(() {
      _selectedYear = newYear;
      _currentMonthIndex = newMonth;
      _overlayYear = _selectedYear;
    });
    _loadDiaryCounts(_selectedYear);
    _sliderKey.currentState?.animateToPage(_currentMonthIndex);
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = ResponsiveAppBar.safeTop(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
          children: [
            // 主内容
            Column(
              children: [
                SizedBox(height: safeTop),
                // 顶部栏 — Stack 让标题屏幕居中
                SizedBox(
                  height: 56,
                  child: Stack(
                    children: [
                      // 标题 — 屏幕居中
                      Center(
                        child: GestureDetector(
                          onTap: _openOverlay,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getTitle(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _isOverlayOpen
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 22,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 左侧返回
                      Positioned(
                        left: 16, top: 0, bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.grey[600]),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                      // 右侧添加
                      Positioned(
                        right: 16, top: 0, bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: Icon(Icons.edit_outlined, size: 22, color: Colors.grey[600]),
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).push(
                                SmoothRoute(builder: (_) => const DiaryWizardScreen()),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _goToCurrentMonth,
                    behavior: HitTestBehavior.translucent,
                    child: Center(
                      child: SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.52,
                        child: MonthlyCardSlider(
                          key: _sliderKey,
                          cards: _cards,
                          year: _selectedYear,
                          initialIndex: _hasPlayedEntrance ? _currentMonthIndex : 0,
                          onPageChanged: (index) {
                            setState(() => _currentMonthIndex = index);
                          },
                          onCoverChanged: (year, month, path) {
                            setState(() {
                              _cards = _cards.map((c) =>
                                c.monthNumber == month ? c.copyWith(assetPath: path) : c
                              ).toList();
                            });
                          },
                          onCardTap: (index) {
                            final year = _selectedYear;
                            final month = index + 1;
                            // 丝滑推入该年该月的列表视图
                            Navigator.of(context, rootNavigator: true).push(
                              SmoothRoute(
                                builder: (_) => ListViewScreen(
                                  initialYear: year,
                                  initialMonth: month,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // 覆盖层
            if (_isOverlayOpen) _buildOverlay(),
          ],
        ),
      );
  }

  /// 覆盖层（背景灰暗 + 顶部面板）
  Widget _buildOverlay() {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final panelHeight = screenHeight * 0.42;

    return Positioned.fill(
      child: GestureDetector(
        onTap: _closeOverlay,
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {},
                child: SizedBox(
                  height: panelHeight,
                  width: double.infinity,
                  child: _buildPanelContent(),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  /// 面板内容
  Widget _buildPanelContent() {
    // 顶部安全距离 + 额外间距避免与状态栏冲突
    final safeTop = ResponsiveAppBar.safeTop(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: safeTop + 20, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 拖拽指示条
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // 年份横向滑动
          _buildYearSelector(),
          const SizedBox(height: 20),
          // 月份网格（Expanded 填满剩余空间）
          Expanded(child: _buildMonthGrid()),
        ],
      ),
    );
  }

  /// 年份横向滑动选择器
  Widget _buildYearSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        controller: _yearScrollController,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _maxYear - _minYear + 1,
        itemBuilder: (context, index) {
          final year = _minYear + index;
          final isSelected = year == _overlayYear;
          return GestureDetector(
            onTap: () => _selectYear(year),
            child: Container(
              width: 64,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1A1A1A) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$year',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[400],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 月份网格（4列 × 3行，Expanded 填满面板剩余高度）
  Widget _buildMonthGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          // 判断是否选中：当前overlay年份和主视图年份相同，且月份匹配
          final isSelected = _overlayYear == _selectedYear && month == _currentMonthIndex + 1;
          return GestureDetector(
            onTap: () => _selectMonth(month),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? _tc.withValues(alpha: 0.12)
                    : appBgColor(context),
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? Border.all(color: _tc, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$month月',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_cards[index].currentProgress}篇',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? _tc
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
