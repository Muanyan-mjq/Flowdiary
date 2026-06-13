import 'dart:math';
import 'package:flutter/material.dart';
import '../models/focus_task.dart';

/// 五种计时器样式统一组件
/// [style] 样式类型  [seconds] 当前秒数  [totalSeconds] 总秒数（正计时传一个大数）  [isRunning] 是否运行中
class TimerDisplay extends StatelessWidget {
  final TimerStyle style;
  final int seconds;
  final int totalSeconds;
  final bool isRunning;
  final double size; // 计时器直径/宽度

  const TimerDisplay({
    super.key,
    required this.style,
    required this.seconds,
    required this.totalSeconds,
    this.isRunning = false,
    this.size = 280,
  });

  String get _timeText {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress => totalSeconds > 0 ? (seconds / totalSeconds).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case TimerStyle.circular: return _CircularTimer(size: size, timeText: _timeText, progress: _progress, isRunning: isRunning);
      case TimerStyle.card: return _CardTimer(size: size, timeText: _timeText, progress: _progress, isRunning: isRunning);
      case TimerStyle.flip: return _FlipTimer(size: size, seconds: seconds, isRunning: isRunning);
      case TimerStyle.minimal: return _MinimalTimer(size: size, timeText: _timeText);
      case TimerStyle.dashboard: return _DashboardTimer(size: size, timeText: _timeText, progress: _progress, isRunning: isRunning);
    }
  }
}

// ═══════════════════ 1. 圆环进度 ═══════════════════
class _CircularTimer extends StatelessWidget {
  final double size; final String timeText; final double progress; final bool isRunning;
  const _CircularTimer({required this.size, required this.timeText, required this.progress, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size,
      child: Stack(alignment: Alignment.center, children: [
        // 背景环
        SizedBox(width: size, height: size,
          child: CircularProgressIndicator(value: 1.0, strokeWidth: 8, backgroundColor: Colors.white.withValues(alpha: 0.2), color: Colors.white.withValues(alpha: 0.15)),
        ),
        // 进度环
        SizedBox(width: size - 8, height: size - 8,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CircularProgressIndicator(value: v, strokeWidth: 8, strokeCap: StrokeCap.round, color: Colors.white, backgroundColor: Colors.transparent),
          ),
        ),
        // 时间文字
        Text(timeText, style: TextStyle(fontSize: size * 0.22, fontWeight: FontWeight.w200, color: Colors.white, fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

// ═══════════════════ 2. 圆角卡片 ═══════════════════
class _CardTimer extends StatelessWidget {
  final double size; final String timeText; final double progress; final bool isRunning;
  const _CardTimer({required this.size, required this.timeText, required this.progress, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(timeText, style: TextStyle(fontSize: size * 0.22, fontWeight: FontWeight.w200, color: Colors.white, fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(height: 16),
        // 底部进度条
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 4, backgroundColor: Colors.white.withValues(alpha: 0.2), color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════ 3. 翻页时钟 ═══════════════════
class _FlipTimer extends StatelessWidget {
  final double size; final int seconds; final bool isRunning;
  const _FlipTimer({required this.size, required this.seconds, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    final m = (seconds ~/ 60);
    final s = seconds % 60;
    return SizedBox(width: size, height: size * 0.5,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _FlipDigit(value: m ~/ 10, size: size * 0.22),
        _FlipDigit(value: m % 10, size: size * 0.22),
        Padding(padding: EdgeInsets.only(top: size * 0.01),
          child: Text(':', style: TextStyle(fontSize: size * 0.2, fontWeight: FontWeight.w300, color: Colors.white.withValues(alpha: 0.7)))),
        _FlipDigit(value: s ~/ 10, size: size * 0.22),
        _FlipDigit(value: s % 10, size: size * 0.22),
      ]),
    );
  }
}

class _FlipDigit extends StatelessWidget {
  final int value; final double size;
  const _FlipDigit({required this.value, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.7, height: size * 1.35, margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Center(child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInBack, switchOutCurve: Curves.easeOutBack,
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
        child: Text('$value', key: ValueKey(value), style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: Colors.white)),
      )),
    );
  }
}

// ═══════════════════ 4. 极简无框 ═══════════════════
class _MinimalTimer extends StatelessWidget {
  final double size; final String timeText;
  const _MinimalTimer({required this.size, required this.timeText});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size,
      child: Text(timeText, textAlign: TextAlign.center,
        style: TextStyle(fontSize: size * 0.28, fontWeight: FontWeight.w100, color: Colors.white, fontFeatures: const [FontFeature.tabularFigures()], letterSpacing: 8)),
    );
  }
}

// ═══════════════════ 5. 仪表盘 ═══════════════════
class _DashboardTimer extends StatelessWidget {
  final double size; final String timeText; final double progress; final bool isRunning;
  const _DashboardTimer({required this.size, required this.timeText, required this.progress, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size * 0.7,
      child: CustomPaint(painter: _DashboardPainter(progress: progress, isRunning: isRunning), size: Size(size, size * 0.7),
        child: Center(
          child: Padding(padding: EdgeInsets.only(top: size * 0.28),
            child: Text(timeText, style: TextStyle(fontSize: size * 0.18, fontWeight: FontWeight.w200, color: Colors.white, fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        ),
      ),
    );
  }
}

class _DashboardPainter extends CustomPainter {
  final double progress; final bool isRunning;
  _DashboardPainter({required this.progress, required this.isRunning});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.42;
    final bgPaint = Paint()..color = Colors.white.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.round;
    final fgPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.round;

    // 背景弧
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), _rad(135), _rad(270), false, bgPaint);
    // 进度弧
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), _rad(135), _rad(270 * progress), false, fgPaint);
  }

  double _rad(double deg) => deg * pi / 180;

  @override
  bool shouldRepaint(_DashboardPainter old) => old.progress != progress;
}
