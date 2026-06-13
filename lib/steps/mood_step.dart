import 'package:flutter/material.dart';
import '../utils/user_service.dart';

// ==================== 心情数据 ====================

class _MoodItem {
  final String id;
  final String label;
  const _MoodItem(this.id, this.label);
}

const _moodList = [
  _MoodItem('happy', '开心'),
  _MoodItem('fulfilled', '充实'),
  _MoodItem('excited', '惊喜'),
  _MoodItem('proud', '得意'),
  _MoodItem('warm', '暖心'),
  _MoodItem('calm', '平静'),
  _MoodItem('sad', '难过'),
  _MoodItem('irritated', '烦躁'),
  _MoodItem('lost', '迷惘'),
  _MoodItem('lonely', '孤独'),
  _MoodItem('angry', '生气'),
  _MoodItem('awkward', '尴尬'),
  _MoodItem('wronged', '委屈'),
  _MoodItem('sweet', '甜蜜'),
  _MoodItem('dreamy', '梦境'),
  _MoodItem('tired', '疲惫'),
  _MoodItem('escaping', '逃避'),
  _MoodItem('unknown', '不知道'),
];

// ==================== MoodStep ====================

class MoodStep extends StatefulWidget {
  final String? selectedMood;
  final Function(String) onMoodSelected;
  final VoidCallback? onBack;
  final VoidCallback? onConfirm;

  const MoodStep({
    super.key,
    this.selectedMood,
    required this.onMoodSelected,
    this.onBack,
    this.onConfirm,
  });

  @override
  State<MoodStep> createState() => _MoodStepState();
}

class _MoodStepState extends State<MoodStep>
    with TickerProviderStateMixin {
  String? _selectedId;

  late AnimationController _entranceController;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;

  late PageController _pageController;
  int _currentPage = 0;
  String? _pressedId;

  /// 18 个心情分 3 页，每页 6 个（3×2）
  List<List<_MoodItem>> get _pages => [
        _moodList.sublist(0, 6),
        _moodList.sublist(6, 12),
        _moodList.sublist(12, 18),
      ];

  String get _nickname =>
      UserService.instance.nickname.isNotEmpty
          ? UserService.instance.nickname
          : '小萨摩';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _entranceController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.7, curve: Curves.easeOut));
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController, curve: Curves.easeOutCubic));

    _entranceController.forward();

    if (widget.selectedMood != null && widget.selectedMood!.isNotEmpty) {
      final item = _moodList.cast<_MoodItem?>().firstWhere(
            (m) => m?.label == widget.selectedMood,
            orElse: () => null);
      if (item != null) {
        _selectedId = item.id;
        _entranceController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onMoodTap(_MoodItem item) {
    setState(() => _selectedId = item.id);
    widget.onMoodSelected(item.label);
  }

  String _selectedLabel() {
    if (_selectedId == null) return '';
    return _moodList.firstWhere((m) => m.id == _selectedId).label;
  }

  // ═══════════════════════════════════════════ Build ═══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final safeArea = screenHeight * 0.04;
    final gridWidth = screenWidth * 0.80;

    return Container(
      color: const Color(0xFFFFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        SizedBox(height: safeArea + 6),
        // ── 返回按钮 ──
        Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.onBack,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.grey[400]),
                    const SizedBox(width: 2),
                    Text('返回', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        // ── 问候语（左对齐，入场动画）──
        AnimatedBuilder(
          animation: _entranceController,
          builder: (context, child) => Opacity(
            opacity: _entranceFade.value,
            child: Transform.translate(
              offset: Offset(0, _entranceSlide.value.dy * MediaQuery.sizeOf(context).height * 0.3),
              child: child,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 第一行：那么  昵称
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '那么  ',
                        style: TextStyle(fontSize: 17, fontStyle: FontStyle.italic, color: Color(0xFF1A1A1A)),
                      ),
                      TextSpan(
                        text: _nickname,
                        style: const TextStyle(fontSize: 17, fontStyle: FontStyle.italic, color: Color(0xFF1A1A1A)),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 第二行：这一天的心情是怎么样的呢
                const Text(
                  '这一天的心情是怎么样的呢',
                  style: TextStyle(fontSize: 17, fontStyle: FontStyle.italic, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
          ),
        ),
        // ── 选中后图片（动态弹入）──
        if (_selectedId != null)
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 16, bottom: 8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - value)),
                  child: Transform.scale(
                    scale: 0.7 + 0.3 * value,
                    child: child,
                  ),
                ),
              ),
              child: Image.asset(
                'assets/images/moods/$_selectedId.png',
                width: 290,
                height: 250,
                fit: BoxFit.contain,
              ),
            ),
          ),
        // ── 心情按钮：3×2 翻页 ──
        Center(
          child: SizedBox(
            width: gridWidth,
            height: 190,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              pageSnapping: true,
              onPageChanged: (p) => setState(() => _currentPage = p),
              itemBuilder: (_, i) => _buildGrid(_pages[i]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── 翻页指示 ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_pages.length, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1A1A1A) : const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        // ── 确认按钮（居中，自适应宽度）──
        Center(
          child: GestureDetector(
            onTap: _selectedId != null ? widget.onConfirm : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
              decoration: BoxDecoration(
                color: _selectedId != null ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _selectedId != null ? '是${_selectedLabel()}啊' : '是这样',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _selectedId != null ? Colors.white : const Color(0xFFBBBBBB),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      ),
    );
  }

  // ═══════════════════════════════════════════ Sub-widgets ═══════════════════════════════════════════

  Widget _buildGrid(List<_MoodItem> items) {
    final top = items.sublist(0, 3);
    final bot = items.sublist(3, 6);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: top.map((m) => _buildButton(m, _selectedId == m.id)).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: bot.map((m) => _buildButton(m, _selectedId == m.id)).toList(),
        ),
      ],
    );
  }

  Widget _buildButton(_MoodItem item, bool isSelected) {
    final pressed = _pressedId == item.id;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedId = item.id),
      onTapUp: (_) => setState(() => _pressedId = null),
      onTapCancel: () => setState(() => _pressedId = null),
      onTap: () => _onMoodTap(item),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: 80,
          height: 60,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: isSelected ? null : Border.all(color: const Color(0xFFEEEEEE), width: 1),
          ),
          child: Center(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF666666),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
