import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 全局背景色
Color appBgColor(BuildContext context) => const Color(0xFFF7F8FA);

Color appCardColor(BuildContext context) => Colors.white;

Color appTextColor(BuildContext context) => const Color(0xFF1A1A1A);

/// 响应式顶部导航栏（双重安全距离适配版）
///
/// 适配目标：所有安卓机型 + iPhone
/// - 挖孔屏、刘海屏、灵动岛、无挖孔普通屏幕
///
/// 核心原理：
/// - 安全距离 = max(系统 SafeArea, 屏幕高度 × 4%)
/// - 4% 保底覆盖部分安卓厂商 padding 上报不准的问题
/// - 系统 SafeArea 保证 iPhone 灵动岛等大挖孔精确适配
/// - 使用 Stack 布局确保标题屏幕居中
class ResponsiveAppBar extends StatelessWidget {
  /// 左侧组件（返回按钮等），可选
  final Widget? left;

  /// 居中组件（标题等），必填
  final Widget center;

  /// 右侧组件（操作按钮等），可选
  final Widget? right;

  /// 背景色，不传则自动适配亮/暗模式
  final Color? backgroundColor;

  /// 水平内边距（左右按钮的 padding）
  final double horizontalPadding;

  /// 状态栏图标亮度，不传则根据 backgroundColor 自动推断
  final Brightness? statusBarIconBrightness;

  /// 标题对齐方式
  final CrossAxisAlignment titleAlignment;

  const ResponsiveAppBar({
    super.key,
    this.left,
    required this.center,
    this.right,
    this.backgroundColor,
    this.horizontalPadding = 16,
    this.statusBarIconBrightness,
    this.titleAlignment = CrossAxisAlignment.center,
  });

  /// 获取顶部安全距离（全局统一入口）
  /// 取 max(系统 SafeArea, 屏幕高度 × 4%)
  /// 4% 保底覆盖部分安卓厂商 padding 上报不准的问题
  static double safeTop(BuildContext context) {
    final mq = MediaQuery.of(context);
    final percent4 = mq.size.height * 0.04;
    return mq.padding.top > percent4 ? mq.padding.top : percent4;
  }

  /// 根据屏幕高度返回导航栏内容高度
  static double barHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return screenHeight < 700 ? 48 : 56;
  }

  /// 自动推断状态栏图标亮度
  Brightness _resolvedIconBrightness(BuildContext context) {
    if (statusBarIconBrightness != null) return statusBarIconBrightness!;
    final bg = backgroundColor;
    if (bg != null) return bg.computeLuminance() > 0.5 ? Brightness.dark : Brightness.light;
    return Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final iconBrightness = _resolvedIconBrightness(context);

    final safeLeft = mq.padding.left;
    final safeRight = mq.padding.right;
    final safeTopPadding = safeTop(context);
    final contentHeight = barHeight(context);
    final totalHPadding = horizontalPadding + (safeLeft > safeRight ? safeLeft : safeRight);

    final bg = backgroundColor ?? appBgColor(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness:
            iconBrightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
      child: Container(
        color: bg,
        padding: EdgeInsets.only(top: safeTopPadding),
        child: SizedBox(
          height: contentHeight,
          child: Stack(
            children: [
              // 标题 — 始终屏幕居中，不受左右按钮宽度影响
              Positioned.fill(
                child: Center(
                  child: MediaQuery(
                    data: mq.copyWith(
                      textScaler: TextScaler.linear(
                          mq.textScaler.scale(1.0).clamp(1.0, 1.3)),
                    ),
                    child: DefaultTextStyle(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(),
                      child: center,
                    ),
                  ),
                ),
              ),
              // 左侧按钮
              if (left != null)
                Positioned(
                  left: totalHPadding,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      child: Center(child: left),
                    ),
                  ),
                ),
              // 右侧按钮
              if (right != null)
                Positioned(
                  right: totalHPadding,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      child: Center(child: right),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
