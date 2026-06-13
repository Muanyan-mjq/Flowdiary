import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../models/monthly_card_model.dart';
import 'monthly_card_item.dart';

/// 月份卡片横向滑动容器
class MonthlyCardSlider extends StatefulWidget {
  final List<MonthlyCardModel> cards;
  final int year;
  final int initialIndex;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onCardTap;
  /// 封面变化回调
  final void Function(int year, int month, String assetPath)? onCoverChanged;

  const MonthlyCardSlider({
    super.key,
    required this.cards,
    required this.year,
    this.initialIndex = 0,
    this.onPageChanged,
    this.onCardTap,
    this.onCoverChanged,
  });

  @override
  State<MonthlyCardSlider> createState() => MonthlyCardSliderState();
}

class MonthlyCardSliderState extends State<MonthlyCardSlider> {
  late PageController _pageController;
  // 用 ValueNotifier 避免重建整个 PageView
  final ValueNotifier<double> _currentPage = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: widget.initialIndex,
    );
    _currentPage.value = widget.initialIndex.toDouble();
    _pageController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant MonthlyCardSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex &&
        _pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(widget.initialIndex);
        }
      });
    }
  }

  void _onScroll() {
    if (_pageController.hasClients) {
      _currentPage.value = _pageController.page ?? 0;
    }
  }

  /// 公开方法：跳转到指定页
  void animateToPage(int page, {Duration? duration, Curve? curve}) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      page,
      duration: duration ?? const Duration(milliseconds: 280),
      curve: curve ?? Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.cards.length,
      onPageChanged: widget.onPageChanged,
      physics: const _SinglePagePhysics(),
      itemBuilder: (context, index) {
        // ValueListenableBuilder 只重建单个卡片的 transform，不重建整个 PageView
        return ValueListenableBuilder<double>(
          valueListenable: _currentPage,
          builder: (context, currentPage, child) {
            final diff = (index - currentPage).abs();
            final scale = 1.0 - (diff * 0.05).clamp(0.0, 0.05);
            final opacity = 1.0 - (diff * 0.15).clamp(0.0, 0.15);
            final translateY = diff * 3.0;

            return Transform.translate(
              offset: Offset(0, translateY),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              ),
            );
          },
          // child 缓存：MonthlyCardItem 不随滚动重建
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: MonthlyCardItem(
              model: widget.cards[index],
              year: widget.year,
              onTap: () => widget.onCardTap?.call(index),
              onCoverChanged: widget.onCoverChanged,
            ),
          ),
        );
      },
    );
  }
}

/// 单页滑动物理：每次 fling 只翻一页，反应快、动画短
/// 继承 ClampingScrollPhysics，边界处理用默认实现（不会触发路由 pop）
class _SinglePagePhysics extends ClampingScrollPhysics {
  const _SinglePagePhysics({super.parent});

  @override
  _SinglePagePhysics applyTo(ScrollPhysics? ancestor) {
    return _SinglePagePhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // 已经在边界外，交给父类处理弹回
    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    // 当前位置（以页为单位的浮点数）
    final page = position.pixels / position.viewportDimension;
    final maxPage = (position.maxScrollExtent / position.viewportDimension);

    int targetPage;

    if (velocity.abs() < 30) {
      // 慢速/拖拽松手：吸附到最近的整数页
      targetPage = page.round();
    } else {
      // 快速滑动：根据方向只跳一页
      final direction = velocity.sign; // +1 向右, -1 向左
      targetPage = (page + direction).round();
    }

    // 边界保护
    targetPage = targetPage.clamp(0, maxPage.round());
    final targetPixels = targetPage * position.viewportDimension;

    // 已经在目标位置，不需要动画
    if ((targetPixels - position.pixels).abs() < 0.5) return null;

    // 用弹簧动画，速度快、有弹性但不振荡
    return SpringSimulation(
      const SpringDescription(mass: 0.5, stiffness: 400.0, damping: 26.0),
      position.pixels,
      targetPixels,
      velocity * 0.3, // 削弱输入速度，避免弹簧过冲
    );
  }
}
