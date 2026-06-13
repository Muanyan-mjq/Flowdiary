import 'package:flutter/material.dart';
import '../main.dart';

/// 云朵风格卡片 — 圆润感，选中色跟随主题
class CloudCard extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback? onTap;

  const CloudCard({
    super.key,
    required this.child,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.3) : const Color(0xFFE8E8E8),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Center(child: child),
      ),
    );
  }
}
