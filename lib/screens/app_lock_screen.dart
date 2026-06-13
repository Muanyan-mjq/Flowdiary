import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/biometric_service.dart';
import '../utils/user_service.dart';
import '../main.dart';
import '../widgets/responsive_app_bar.dart';
import '../utils/smooth_route.dart';
import 'decoy_screen.dart';

/// 应用锁页面
/// 用户打开 app 时显示，验证身份后进入主页
/// 支持生物识别（面容/指纹）和密码输入
/// 输入伪装密码可进入伪装页面
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with SingleTickerProviderStateMixin {
  Color get _tc => ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);

  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _showPasswordInput = false;
  bool _biometricAvailable = false;
  bool _isInDecoyMode = false;
  String? _errorMessage;
  String _biometricType = '生物识别';

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _isInDecoyMode = UserService.instance.isInDecoyMode;
    _initAnimations();
    _checkBiometric();
  }

  void _initAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  Future<void> _checkBiometric() async {
    final canUse = await BiometricService.canUseBiometric();
    final type = await BiometricService.getBiometricTypeDescription();

    if (mounted) {
      setState(() {
        _biometricAvailable = canUse;
        _biometricType = type;
        // 如果在假日记模式，直接显示密码输入
        if (_isInDecoyMode) {
          _showPasswordInput = true;
        }
      });

      // 如果支持生物识别且不在假日记模式，自动触发验证
      if (canUse && !_isInDecoyMode) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _authenticateWithBiometric();
        });
      }
    }
  }

  Future<void> _authenticateWithBiometric() async {
    setState(() => _isLoading = true);

    final authenticated = await BiometricService.authenticate(
      reason: '请验证身份以访问随心耶',
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (authenticated) {
        _navigateToMain();
      }
    }
  }

  Future<void> _authenticateWithPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _errorMessage = '请输入密码');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final userService = UserService.instance;
    final result = await userService.login(userService.nickname, password);

    if (mounted) {
      setState(() => _isLoading = false);

      switch (result) {
        case 'success':
          _navigateToMain();
          break;
        case 'decoy':
          _navigateToDecoy();
          break;
        case 'locked':
          final failInfo = await userService.getLoginFailInfo();
          setState(() {
            _errorMessage = '账号已锁定，请${failInfo.lockoutRemainingSeconds}秒后重试';
          });
          break;
        case 'failed':
          final failInfo = await userService.getLoginFailInfo();
          setState(() {
            if (failInfo.isLocked) {
              _errorMessage = '账号已锁定，请${failInfo.lockoutRemainingSeconds}秒后重试';
            } else {
              _errorMessage = '密码错误，还剩${failInfo.remainingAttempts}次机会';
            }
          });
          break;
        default:
          setState(() => _errorMessage = '验证失败');
      }
    }
  }

  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      SmoothRoute(builder: (_) => const MainScreen()),
    );
  }

  void _navigateToDecoy() {
    Navigator.pushReplacement(
      context,
      SmoothRoute(builder: (_) => const DecoyScreen()),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F4FD),
              Color(0xFFF0F7FF),
              Color(0xFFFDFBF8),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: ResponsiveAppBar.safeTop(context)),
            Expanded(child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.12),

                    // 锁图标
                    _buildLockIcon(),
                    const SizedBox(height: 24),

                    // 标题
                    const Text(
                      '随心耶',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isInDecoyMode ? '输入密码以继续' : '请验证身份以继续',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.06),

                    // 生物识别按钮
                    if (_biometricAvailable && !_showPasswordInput)
                      _buildBiometricButton(),

                    // 密码输入
                    if (_showPasswordInput || !_biometricAvailable)
                      _buildPasswordInput(),

                    // 假日记模式提示
                    if (_isInDecoyMode)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          '输入伪装密码 → 假日记\n输入真实密码 → 真日记',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                            height: 1.5,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // 错误提示
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _errorMessage != null
                          ? Padding(
                              key: ValueKey(_errorMessage),
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFE57373),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : const SizedBox(
                              key: ValueKey('empty'), height: 20),
                    ),

                    const SizedBox(height: 20),

                    // 切换到密码输入
                    if (_biometricAvailable && !_showPasswordInput)
                      _buildSwitchToPassword(),

                    SizedBox(height: screenHeight * 0.1),
                  ],
                ),
              ),
            ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLockIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _tc.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.lock_outline_rounded,
          size: 36,
          color: _tc,
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return Column(
      children: [
        // 生物识别按钮
        GestureDetector(
          onTap: _isLoading ? null : _authenticateWithBiometric,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _tc.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isLoading
                ? Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: _tc,
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      _biometricType == '面容' || _biometricType == '面容 + 指纹'
                          ? Icons.face_rounded
                          : Icons.fingerprint_rounded,
                      size: 48,
                      color: _tc,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '点击使用$_biometricType解锁',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        children: [
          _buildPasswordField(),
          const SizedBox(height: 20),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return AnimatedBuilder(
      animation: _passwordFocus,
      builder: (context, child) {
        final isFocused = _passwordFocus.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isFocused
                ? const Color(0xFFF5FAFF)
                : appBgColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFocused
                  ? _tc.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _authenticateWithPassword(),
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: _isInDecoyMode ? '输入密码以继续' : '输入密码解锁',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: isFocused
                      ? _tc
                      : Colors.grey[400],
                ),
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [_tc, _tc.withValues(alpha: 0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: _tc.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _authenticateWithPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  '解 锁',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSwitchToPassword() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showPasswordInput = true;
          _errorMessage = null;
        });
      },
      child: Text(
        '使用密码解锁',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[500],
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
