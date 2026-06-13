import 'package:flutter/material.dart';
import '../widgets/diary_card.dart';
import '../utils/weather_service.dart';
import '../utils/smooth_route.dart';
import '../widgets/responsive_app_bar.dart';
import '../utils/diary_storage.dart';
import '../utils/draft_storage.dart';
import '../models/diary_entry.dart';
import '../main.dart';
import 'diary_wizard_screen.dart';
import 'diary_detail_screen.dart';

class DiaryHomePage extends StatefulWidget {
  /// 外层传入的打开侧边栏回调
  final VoidCallback? onOpenDrawer;

  const DiaryHomePage({super.key, this.onOpenDrawer});

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  Color get _tc => ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
  late PageController _pageController;
  double _currentPage = 0;
  WeatherData? _weather;
  List<DiaryEntry> _recentDiaries = [];
  bool _hasDrafts = false; // 草稿红点

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.80);
    _pageController.addListener(_onScroll);
    _loadWeather();
    _loadDiaries();
    _loadDrafts();
    // 每次 build 后刷新草稿红点（用户可能从侧边栏进入草稿箱后返回）
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDrafts());
  }

  Future<void> _loadDrafts() async {
    final unseen = await DraftStorage.hasUnseen();
    if (mounted) setState(() => _hasDrafts = unseen);
  }

  Future<void> _loadWeather() async {
    final weather = await WeatherService.getWeather();
    if (mounted) setState(() => _weather = weather);
  }

  Future<void> _loadDiaries() async {
    final all = await DiaryStorage.loadAll();
    if (mounted) setState(() => _recentDiaries = all.take(3).toList());
  }

  /// 点击标题日期选择器 — 跳转到指定日期的日记
  Future<void> _onTitleTap() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2024, 1, 1),
      lastDate: now,
      helpText: '选择日期查看日记',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked == null || !mounted) return;

    // 查找该日期的日记
    final all = await DiaryStorage.loadAll();
    final match = all.where((e) {
      final d = e.createdAt;
      return d.year == picked.year && d.month == picked.month && d.day == picked.day;
    }).toList();

    if (match.isNotEmpty) {
      Navigator.push(
        context,
        SmoothRoute(builder: (_) => DiaryDetailScreen(entry: match.first)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${picked.month}月${picked.day}日 还没有日记'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onScroll() {
    setState(() {
      _currentPage = _pageController.page ?? 0;
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = ResponsiveAppBar.safeTop(context);

    return Scaffold(
      backgroundColor: appBgColor(context),
      body: Column(
        children: [
          // 顶部安全距离
          SizedBox(height: safeTop),
          // 顶部导航栏（Stack 布局，标题屏幕居中）
          SizedBox(
            height: 56,
            child: Stack(
              children: [
                // 标题 — 屏幕居中（不受左右按钮宽度影响）
                // 点击弹出日期选择器，查看指定日期的日记
                Center(
                  child: GestureDetector(
                    onTap: () => _onTitleTap(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '日记本',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
                // 左侧汉堡菜单 + 红点
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, size: 26, color: Color(0xFF1A1A1A)),
                          onPressed: widget.onOpenDrawer,
                        ),
                        if (_hasDrafts)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // 右侧写日记按钮
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: Icon(Icons.edit_outlined, size: 24, color: Colors.grey[600]),
                      onPressed: () {
                        Navigator.push(
                          context,
                          SmoothRoute(builder: (_) => const DiaryWizardScreen()),
                        ).then((_) { _loadDiaries(); _loadDrafts(); });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildCardFlow()),
        ],
      ),
    );
  }

  /// 卡片流（带滑动缩放动画，新笔记在左边）
  /// BouncingScrollPhysics 提供 iOS 风格弹性回弹，适配小屏防溢出
  Widget _buildCardFlow() {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: 2 + _recentDiaries.length, // 新笔记 + 日记卡片 + 默认日记
        itemBuilder: (context, index) {
          final diff = (index - _currentPage).abs();
          final scale = 1.0 - (diff * 0.05).clamp(0.0, 0.05);

          Widget card;
          if (index == 0) {
            // 新笔记（最左边）
            card = DiaryCard(index: 1, isDefault: false, weather: _weather, onDiarySaved: _loadDiaries);
          } else if (index < 1 + _recentDiaries.length) {
            final entry = _recentDiaries[index - 1];
            card = DiaryCard(index: 2, isDefault: false, weather: _weather, savedEntry: entry);
          } else {
            // 默认日记（最右边）
            card = DiaryCard(index: 0, isDefault: true, weather: _weather);
          }

          return AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: card,
          );
        },
      ),
    );
  }

}
