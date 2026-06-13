import 'package:flutter/material.dart';
import '../main.dart';

/// Moo 日记风格底部按钮 — 圆润、轻盈，颜色跟随主题
class BottomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const BottomButton({
    super.key,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
