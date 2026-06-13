import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../main.dart';
import '../utils/smooth_route.dart';

/// 登录/注册成功后的过渡动画页面
/// 播放 Lottie 成功动画，播放完毕后自动进入主页
class LoginSuccessOverlay extends StatefulWidget {
  final String nickname;
  final bool isRegister;

  const LoginSuccessOverlay({
    super.key,
    required this.nickname,
    this.isRegister = false,
  });

  @override
  State<LoginSuccessOverlay> createState() => _LoginSuccessOverlayState();
}

class _LoginSuccessOverlayState extends State<LoginSuccessOverlay> with SingleTickerProviderStateMixin {
  Color get _tc => ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);

  late final AnimationController _lottieController;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_isTransitioning) {
        _isTransitioning = true;
        _goToMain();
      }
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  void _goToMain() {
    Navigator.pushAndRemoveUntil(
      context,
      SmoothRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.32,
            child: Lottie.asset(
              'assets/lottie/success_check.json',
              controller: _lottieController,
              fit: BoxFit.contain,
              onLoaded: (composition) {
                _lottieController.duration = composition.duration;
                _lottieController.forward();
              },
              errorBuilder: (_, __, ___) => Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _tc.withValues(alpha: 0.15)),
                child: Icon(Icons.check_circle, size: 60, color: _tc)),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            widget.isRegister ? '注册成功！' : '欢迎回来！',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 12),
          Text(widget.nickname, style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          const SizedBox(height: 48),
          // 跳过按钮（动画播放中可手动跳过）
          GestureDetector(
            onTap: _goToMain,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_tc, _tc.withValues(alpha: 0.8)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _tc.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Text('进入随心耶', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}
