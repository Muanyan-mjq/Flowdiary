import 'package:flutter/material.dart';
import '../main.dart';

/// 页面指示器 — 圆点颜色跟随主题
class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    final color = ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: currentPage == index ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: currentPage == index ? color : Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
