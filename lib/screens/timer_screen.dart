import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/focus_task.dart';
import '../utils/focus_storage.dart';
import '../widgets/timer_display.dart';
import '../widgets/responsive_app_bar.dart';

class TimerScreen extends StatefulWidget {
  final FocusTask task;
  const TimerScreen({super.key, required this.task});
  @override State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  late FocusTask _task; late TimerStyle _style;
  late int _totalSeconds, _seconds;
  bool _isRunning = false, _isRestMode = false, _mainPressed = false;
  double _timerScale = 1.0; // 计时器大小倍率
  int _restSeconds = 300;
  Timer? _timer;
  final _summaryCtrl = TextEditingController();
  late AnimationController _pulseCtrl;

  @override void initState() {
    super.initState(); _task = widget.task; _style = _task.timerStyle;
    _totalSeconds = _task.durationSeconds; _seconds = _task.mode == FocusMode.stopwatch ? 0 : _totalSeconds;
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }
  @override void dispose() { _timer?.cancel(); _pulseCtrl.dispose(); _summaryCtrl.dispose(); super.dispose(); }

  void _start() { if (_isRunning) return; _isRunning = true; _pulseCtrl.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (!mounted) return;
      setState(() { if (_task.mode == FocusMode.stopwatch) _seconds++; else _seconds--;
        if (_seconds <= 0 && _task.mode != FocusMode.stopwatch) _onComplete(); }); }); }
  void _pause() { _isRunning = false; _timer?.cancel(); _pulseCtrl.stop(); }
  void _reset() { _timer?.cancel(); _pulseCtrl.stop(); _isRunning = false; setState(() => _seconds = _task.mode == FocusMode.stopwatch ? 0 : _totalSeconds); }

  Future<void> _onComplete() async { _timer?.cancel(); _pulseCtrl.stop(); setState(() => _isRunning = false); await FocusStorage.recordCompletion(_task); _enterRest(); }
  void _enterRest() { setState(() { _isRestMode = true; _restSeconds = 300; });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (!mounted) return; setState(() { _restSeconds--; if (_restSeconds <= 0) _onRestDone(); }); }); }
  void _onRestDone() { _timer?.cancel();
    showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('专注完成'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('写点总结吧', style: TextStyle(color: Color(0xFF666666))), const SizedBox(height: 12),
        TextField(controller: _summaryCtrl, maxLines: 3, decoration: InputDecoration(hintText: '今天专注的感觉怎么样...', filled: true, fillColor: const Color(0xFFF5F5F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(14)))]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('跳过')),
        ElevatedButton(onPressed: () async { final s = _summaryCtrl.text.trim(); if (s.isNotEmpty) await FocusStorage.saveSummary(_task.id, s); if (ctx.mounted) Navigator.pop(ctx); if (mounted) { await FocusStorage.recordCompletion(_task); Navigator.pop(context); } },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('保存'))]));
  }

  String _f(int s) => '${(s ~/ 60).toString().padLeft(2,'0')}:${(s % 60).toString().padLeft(2,'0')}';

  @override Widget build(BuildContext context) {
    final safeTop = ResponsiveAppBar.safeTop(context);
    return Scaffold(body: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF0D1117)])),
      child: Column(children: [
        SizedBox(height: safeTop),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Row(children: [
          GestureDetector(onTap: () { if (_isRunning) _pause(); Navigator.pop(context); },
            child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white54))),
          const SizedBox(width: 12),
          Expanded(child: Text(_task.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.6)), overflow: TextOverflow.ellipsis)),
          Text(_task.modeLabel, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.25))),
        ])),
        Expanded(child: _isRestMode ? _buildRest() : _buildFocus()),
      ])));
  }

  Widget _buildFocus() {
    final h = MediaQuery.sizeOf(context).height;
    return Column(children: [
      const Spacer(flex: 2),
      Center(child: AnimatedBuilder(animation: _pulseCtrl, builder: (_, c) => Transform.scale(scale: _isRunning ? 1.0 + _pulseCtrl.value * 0.006 : 1.0, child: c),
        child: TimerDisplay(style: _style, seconds: _seconds, totalSeconds: _totalSeconds, isRunning: _isRunning, size: h * 0.28 * _timerScale))),
      const Spacer(flex: 2),
      _buildControls(),
      const SizedBox(height: 60),
    ]);
  }

  Widget _buildRest() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)), child: Center(child: Icon(Icons.self_improvement, size: 44, color: Colors.white.withValues(alpha: 0.3)))),
    const SizedBox(height: 28), Text('休息一下', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: Colors.white.withValues(alpha: 0.7))),
    const SizedBox(height: 12), Text(_f(_restSeconds), style: TextStyle(fontSize: 52, fontWeight: FontWeight.w200, color: Colors.white.withValues(alpha: 0.5))),
    const SizedBox(height: 28),
    _TextBtn('跳过休息', _onRestDone),
  ]));

  Widget _buildControls() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _RoundBtn(Icons.refresh_rounded, _reset, 56),
      const SizedBox(width: 36),
      _MainBtn(),
      const SizedBox(width: 36),
      _RoundBtn(Icons.tune, () => _showStyles(), 56),
    ]);
  }

  Widget _MainBtn() {
    return GestureDetector(
      onTapDown: (_) { setState(() => _mainPressed = true); HapticFeedback.mediumImpact(); },
      onTapUp: (_) { setState(() => _mainPressed = false); },
      onTapCancel: () => setState(() => _mainPressed = false),
      onTap: _isRunning ? _pause : _start,
      child: AnimatedScale(scale: _mainPressed ? 0.88 : 1.0, duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(duration: const Duration(milliseconds: 150), width: 76, height: 76,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: _isRunning ? Colors.white.withValues(alpha: _mainPressed ? 0.25 : 0.15) : const Color(0xFFFF6B6B).withValues(alpha: _mainPressed ? 1.0 : 0.85),
            boxShadow: [BoxShadow(color: (_isRunning ? Colors.white : const Color(0xFFFF6B6B)).withValues(alpha: _mainPressed ? 0.35 : 0.2), blurRadius: 16, offset: const Offset(0, 4))]),
          child: Center(child: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 36, color: Colors.white)))));
  }

  Widget _RoundBtn(IconData icon, VoidCallback onTap, double size) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
        child: Icon(icon, size: size * 0.42, color: Colors.white.withValues(alpha: 0.5))));
  }

  Widget _TextBtn(String text, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30)), child: Text(text, style: const TextStyle(fontSize: 15, color: Colors.white70))));
  }

  void _showStyles() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Container(padding: const EdgeInsets.fromLTRB(20,12,20,32), decoration: const BoxDecoration(color: Color(0xFF1A1D24), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36,height: 4,decoration: BoxDecoration(color: Colors.grey[700],borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20), const Text('计时器样式', style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600,color: Colors.white)), const SizedBox(height: 20),
          Wrap(spacing: 12,runSpacing: 12,children: List.generate(TimerStyle.values.length,(i) {
            final s = TimerStyle.values[i];
            return GestureDetector(onTap: () { setSt(() => _style = s); setState(() => _style = s); FocusStorage.setGlobalStyle(s); },
              child: Container(width: 64,height: 56,decoration: BoxDecoration(color: _style==s?Colors.white.withValues(alpha: 0.15):Colors.white.withValues(alpha: 0.05),borderRadius: BorderRadius.circular(14),border: _style==s?Border.all(color: Colors.white.withValues(alpha: 0.3)):null),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon([Icons.circle_outlined,Icons.credit_card,Icons.flip,Icons.minimize,Icons.speed][i],size: 20,color: _style==s?Colors.white:Colors.white38),
                  const SizedBox(height: 4), Text(['圆形','卡片','翻页','极简','仪表'][i],style: TextStyle(fontSize: 10,color: _style==s?Colors.white:Colors.white38))])));
          })),
          const SizedBox(height: 20),
          const Text('数字大小', style: TextStyle(fontSize: 14, color: Colors.white54)),
          const SizedBox(height: 8),
          Row(children: [
            const Text('小', style: TextStyle(fontSize: 12, color: Colors.white38)),
            Expanded(child: SliderTheme(data: SliderThemeData(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7), activeTrackColor: Colors.white38, inactiveTrackColor: Colors.white.withValues(alpha: 0.1), thumbColor: Colors.white),
              child: Slider(value: _timerScale, min: 0.7, max: 1.5, divisions: 8, onChanged: (v) { setSt(() => _timerScale = v); setState(() => _timerScale = v); }))),
            const Text('大', style: TextStyle(fontSize: 16, color: Colors.white38)),
          ]),
        ]))));
  }
}
