import 'package:flutter/material.dart';

/// 步骤三：选择今天做了什么
class EventStep extends StatefulWidget {
  final String? currentMood;
  final Set<String> selectedEvents;
  final Function(String) onEventToggled;
  final VoidCallback? onBack;
  final VoidCallback? onConfirm;

  const EventStep({super.key, this.currentMood, required this.selectedEvents,
    required this.onEventToggled, this.onBack, this.onConfirm});

  @override
  State<EventStep> createState() => _EventStepState();
}

class _EventStepState extends State<EventStep> with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _page = 0;
  String? _pressed;

  late final AnimationController _in;
  late final Animation<double> _inFade;
  late final Animation<Offset> _inSlide;

  static const _icons = {
    '追剧': Icons.live_tv_rounded, '美食': Icons.restaurant_rounded,
    '健身': Icons.fitness_center_rounded, '游戏': Icons.sports_esports_rounded,
    '购物': Icons.shopping_bag_rounded, '上网': Icons.wifi_rounded,
    '宠物': Icons.pets_rounded, '摸鱼': Icons.grid_view_rounded,
    '吃瓜': Icons.emoji_food_beverage_rounded, '学习': Icons.school_rounded,
    '工作': Icons.work_rounded, '阅读': Icons.menu_book_rounded,
    '音乐': Icons.music_note_rounded, '旅行': Icons.flight_rounded,
    '绘画': Icons.brush_rounded, '摄影': Icons.camera_alt_rounded,
    '咖啡': Icons.coffee_rounded, '动漫': Icons.animation_rounded,
    '睡觉': Icons.bed_rounded, '运动': Icons.sports_basketball_rounded,
    '聚会': Icons.groups_rounded, '约会': Icons.favorite_rounded,
    '独处': Icons.self_improvement_rounded, '生病': Icons.sick_rounded,
    '看病': Icons.local_hospital_rounded, '爱豆': Icons.star_rounded,
    '庆祝': Icons.celebration_rounded,
  };

  final _pages = [
    ['追剧', '美食', '健身', '游戏', '购物', '上网', '宠物', '摸鱼', '吃瓜'],
    ['学习', '工作', '阅读', '音乐', '旅行', '绘画', '摄影', '咖啡', '动漫'],
    ['睡觉', '运动', '聚会', '约会', '独处', '生病', '看病', '爱豆', '庆祝'],
  ];

  bool get _has => widget.selectedEvents.isNotEmpty;

  String _q() {
    final m = widget.currentMood;
    if (m == null || m.isEmpty) return '是什么事情让你印象最深呐';
    return '是什么事情让你感到$m呐';
  }

  @override
  void initState() {
    super.initState();
    _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _inFade = CurvedAnimation(parent: _in, curve: const Interval(0, 0.7, curve: Curves.easeOut));
    _inSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _in, curve: Curves.easeOutCubic));
    _in.forward();
  }

  @override
  void dispose() { _in.dispose(); _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final gridW = sw * 0.84;

    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(children: [
        SizedBox(height: sh * 0.04 + 6),
        Padding(padding: const EdgeInsets.only(left: 15),
          child: Row(children: [
            GestureDetector(
              onTap: widget.onBack, behavior: HitTestBehavior.opaque,
              child: Row(children: [
                Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.grey[400]),
                const SizedBox(width: 2),
                Text('返回', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
              ]),
            ),
          ]),
        ),
        const Spacer(flex: 1),
        AnimatedBuilder(animation: _in, builder: (_, c) => Opacity(opacity: _inFade.value, child: Transform.translate(offset: Offset(0, _inSlide.value.dy * sh * 0.3), child: c)),
          child: Padding(padding: const EdgeInsets.only(left: 24),
            child: Text.rich(TextSpan(children: [
              const TextSpan(text: '那么  ', style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: Color(0xFF1A1A1A))),
              TextSpan(text: _q(), style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: Color(0xFF1A1A1A))),
            ])),
          ),
        ),
        const Spacer(flex: 2),
        Center(child: SizedBox(width: gridW, height: 260,
          child: PageView.builder(controller: _pageCtrl, itemCount: _pages.length, onPageChanged: (p) => setState(() => _page = p), itemBuilder: (_, i) => _grid(_pages[i])))),
        const Spacer(flex: 1),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_pages.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 3), width: i == _page ? 16 : 6, height: 6, decoration: BoxDecoration(color: i == _page ? const Color(0xFF1A1A1A) : const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(3))))),
        const SizedBox(height: 14),
        Center(child: GestureDetector(onTap: _has ? widget.onConfirm : null,
          child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14), decoration: BoxDecoration(color: _has ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(30)),
            child: Text('继续写', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _has ? Colors.white : const Color(0xFFBBBBBB)))))),
        const Spacer(),
      ]),
    );
  }

  Widget _grid(List<String> items) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (var r = 0; r < 3; r++)
        Padding(padding: EdgeInsets.only(top: r > 0 ? 12.0 : 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (c) => _btn(items[r * 3 + c])))),
    ]);
  }

  Widget _btn(String label) {
    final sel = widget.selectedEvents.contains(label);
    final pressed = _pressed == label;
    final icon = _icons[label] ?? Icons.circle;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = label),
      onTapUp: (_) => setState(() => _pressed = null),
      onTapCancel: () => setState(() => _pressed = null),
      onTap: () => widget.onEventToggled(label),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(scale: pressed ? 0.93 : 1.0, duration: const Duration(milliseconds: 100), curve: Curves.easeOutCubic,
        child: AnimatedContainer(duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic,
          width: 76, height: 74,
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: sel ? Colors.white : const Color(0xFF888888))),
            const SizedBox(height: 4),
            Icon(icon, size: 28, color: sel ? Colors.white : const Color(0xFF666666)),
          ]),
        ),
      ),
    );
  }
}
