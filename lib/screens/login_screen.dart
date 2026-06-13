import 'package:flutter/material.dart';
import '../utils/user_service.dart';
import '../main.dart';
import '../widgets/responsive_app_bar.dart';
import 'login_success_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  Color get _tc => ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nicknameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isLoginMode = true;
  String? _errorMessage;
  bool _isSubmitting = false; // 提交中（登录/注册请求进行中）

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nicknameFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  /// 提交登录/注册
  Future<void> _submit() async {
    final nickname = _nicknameController.text.trim();
    final password = _passwordController.text;

    // 1. 本地校验（所有场景都能即时反馈）
    if (nickname.length < 2 || nickname.length > 12) {
      setState(() => _errorMessage = '昵称长度2-12位');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = '请输入密码');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = '密码至少6位');
      return;
    }
    if (!_isLoginMode && password != _confirmController.text) {
      setState(() => _errorMessage = '两次密码不一致');
      return;
    }

    // 2. 开始提交，显示 loading
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    // 3. 真正执行登录/注册
    bool ok = false;
    String? errorMsg;

    if (_isLoginMode) {
      final result = await UserService.instance.login(nickname, password);
      switch (result) {
        case 'success':
        case 'decoy':
          ok = true;
          break;
        case 'locked':
          final info = await UserService.instance.getLoginFailInfo();
          final sec = info.lockoutRemainingSeconds;
          final min = sec ~/ 60;
          final s = sec % 60;
          errorMsg = '账号已锁定，${min > 0 ? "${min}分" : ""}${s}秒后重试';
          break;
        case 'failed':
          errorMsg = '密码错误';
          break;
        case 'not_found':
          errorMsg = '用户不存在';
          break;
        default:
          errorMsg = '登录失败，请重试';
      }
    } else {
      ok = await UserService.instance.register(nickname, password);
      if (!ok) errorMsg = '昵称已存在，换一个试试';
    }

    if (!mounted) return;

    // 4. 失败 → 显示错误；成功 → 显示成功动画
    if (!ok) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = errorMsg;
      });
    } else {
      // 成功：直接进入过渡动画页（此时登录已完成，不再做任何验证）
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => LoginSuccessOverlay(
            nickname: nickname,
            isRegister: !_isLoginMode,
          ),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ),
        (_) => false,
      );
    }
  }

  /// 切换登录/注册模式
  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
    });
  }

  /// 游客模式
  Future<void> _enterAsGuest() async {
    await UserService.instance.enterAsGuest();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(children: [
        SizedBox(height: ResponsiveAppBar.safeTop(context)),
        Expanded(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(children: [
                  SizedBox(height: screenH * 0.12),
                  const Text('随心耶', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50), letterSpacing: 3)),
                  const SizedBox(height: 6),
                  Text('记录每一个温柔的日子', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  SizedBox(height: screenH * 0.06),

                  // 昵称
                  _buildField(
                    controller: _nicknameController, focusNode: _nicknameFocus,
                    hintText: '昵称', icon: Icons.person_outline_rounded,
                    nextFocus: _passwordFocus,
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 16),

                  // 密码
                  _buildField(
                    controller: _passwordController, focusNode: _passwordFocus,
                    hintText: '密码', icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    onSubmitted: _isLoginMode ? (_) => _submit() : null,
                    enabled: !_isSubmitting,
                  ),

                  // 注册时的确认密码
                  if (!_isLoginMode) ...[
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _confirmController, focusNode: _confirmFocus,
                      hintText: '确认密码', icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      onSubmitted: (_) => _submit(),
                      enabled: !_isSubmitting,
                    ),
                  ],

                  // 错误信息（即时显示，不等待任何动画）
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18, color: Color(0xFFE57373)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(_errorMessage!, style: const TextStyle(fontSize: 14, color: Color(0xFFD32F2F))),
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: screenH * 0.06),

                  // 提交按钮（loading 时显示转圈）
                  _buildSubmitButton(),
                  const SizedBox(height: 20),

                  // 切换登录/注册
                  GestureDetector(
                    onTap: _isSubmitting ? null : _toggleMode,
                    child: Text(
                      _isLoginMode ? '没有账号？去注册' : '已有账号？去登录',
                      style: TextStyle(fontSize: 14, color: _isSubmitting ? Colors.grey[400] : _tc),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 游客模式
                  GestureDetector(
                    onTap: _isSubmitting ? null : _enterAsGuest,
                    child: Text('游客模式', style: TextStyle(fontSize: 13, color: _isSubmitting ? Colors.grey[300] : Colors.grey[400])),
                  ),

                  SizedBox(height: screenH * 0.08),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    FocusNode? nextFocus,
    ValueChanged<String>? onSubmitted,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword,
        enabled: enabled,
        textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
        onSubmitted: onSubmitted ?? (nextFocus != null ? (_) => nextFocus.requestFocus() : null),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, size: 22, color: const Color(0xFFBDBDBD)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _submit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _isSubmitting
              ? const LinearGradient(colors: [Color(0xFFBDBDBD), Color(0xFFE0E0E0)])
              : LinearGradient(colors: [_tc, _tc.withValues(alpha: 0.8)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isSubmitting
              ? null
              : [BoxShadow(color: _tc.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: _isSubmitting
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  _isLoginMode ? '登 录' : '注 册',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 4),
                ),
        ),
      ),
    );
  }
}
