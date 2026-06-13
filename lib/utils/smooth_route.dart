import 'package:flutter/material.dart';

/// 丝滑页面路由工具
///
/// 提供统一的页面转场动画：
/// - 滑入：从右侧滑入 + 轻微淡入（easeOutCubic，300ms）
/// - 滑出：反向滑出 + 轻微淡出（自动由 Navigator.pop 触发）
///
/// 用法：
/// ```dart
/// Navigator.push(context, SmoothRoute(builder: (_) => TargetScreen()));
/// ```
class SmoothRoute<T> extends PageRouteBuilder<T> {
  SmoothRoute({
    required Widget Function(BuildContext) builder,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 200),
  }) : super(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // 滑入 + 轻微缩放（scale 0.97 → 1.0，让过渡更有层次）
      final slideTween = Tween<Offset>(
        begin: const Offset(0.08, 0.0),  // 从右侧 8% 处滑入
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      final scaleTween = Tween<double>(
        begin: 0.97,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      final fadeTween = Tween<double>(
        begin: 0.6,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      return SlideTransition(
        position: animation.drive(slideTween),
        child: ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        ),
      );
    },
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 180),
  );
}

/// 丝滑底部弹窗路由（从底部滑入）
class SmoothBottomRoute<T> extends PageRouteBuilder<T> {
  SmoothBottomRoute({
    required Widget Function(BuildContext) builder,
    RouteSettings? settings,
  }) : super(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween<Offset>(
        begin: const Offset(0.0, 0.3),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      return SlideTransition(
        position: animation.drive(slideTween),
        child: FadeTransition(
          opacity: animation.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic))),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
  );
}

/// 点击缩放动画包装器（给可点击元素添加按压反馈）
class TapBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleAmount;

  const TapBounce({
    super.key,
    required this.child,
    this.onTap,
    this.scaleAmount = 0.96,
  });

  @override
  State<TapBounce> createState() => _TapBounceState();
}

class _TapBounceState extends State<TapBounce> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scaleAmount).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
