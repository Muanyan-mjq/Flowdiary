import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart' show DiaryHomePage;
import 'screens/moo_space_tunnel_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/fortune_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/app_lock_screen.dart';
import 'widgets/app_drawer.dart';
import 'utils/user_service.dart';
import 'utils/sign_storage.dart';
import 'utils/stats_storage.dart';
import 'utils/theme_service.dart';
import 'services/moo_location_weather_service.dart';
import 'services/supabase_config.dart';
import 'services/cloud_auth_service.dart';
import 'services/cloud_sync_service.dart';
import 'utils/diary_storage.dart';
import 'utils/focus_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';

/// 后台静默自动同步（不阻塞 UI）
Future<void> _autoSync() async {
  try {
    final diaries = await DiaryStorage.loadAll();
    final tasks = await FocusStorage.loadAll();
    await CloudSyncService.instance.syncAll(localDiaries: diaries, localSigns: [], localFocusTasks: tasks);
  } catch (_) {} // 静默，失败不影响用户体验
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Supabase 云端（离线时静默失败，不影响本地功能）
  try {
    await SupabaseConfig.init();
  } catch (e) {
    debugPrint('[启动] Supabase 初始化失败（可能离线）: $e');
  }

  // 初始化用户数据服务
  await UserService.instance.init();

  // 初始化云端认证（离线时可跳过，只读本地缓存状态）
  try {
    await CloudAuthService.instance.init();
  } catch (e) {
    debugPrint('[启动] 云端认证初始化失败（可能离线）: $e');
  }

  // 记录首次使用日期（app安装当天）
  await StatsStorage.initFirstUseDate();

  // 自动记录今天打开过 app，更新连续打开天数（零点自动+1）
  await SignStorage.init();

  // 初始化天气通知服务
  await MooLocationWeatherService.init();

  // 初始化每日写作提醒
  await NotificationService.init();

  // 如果已绑定云端账号，启动后自动静默同步一次
  if (CloudAuthService.instance.isCloudEnabled) {
    _autoSync();
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SuiXinYeApp());
}

/// 主题颜色提供器（全局共享主题颜色）
class ThemeProvider extends InheritedWidget {
  final Color themeColor;

  const ThemeProvider({
    super.key,
    required this.themeColor,
    required super.child,
  });

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return themeColor != oldWidget.themeColor;
  }
}

class SuiXinYeApp extends StatefulWidget {
  const SuiXinYeApp({super.key});

  @override
  State<SuiXinYeApp> createState() => SuiXinYeAppState();
}

class SuiXinYeAppState extends State<SuiXinYeApp> {
  Color _themeColor = const Color(0xFF87CEEB);

  Color get themeColor => _themeColor;

  static SuiXinYeAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<SuiXinYeAppState>();
  }

  void updateThemeColor(Color color) {
    setState(() => _themeColor = color);
  }

  /// 获取页面背景色
  static Color bgColorOf(BuildContext context) => const Color(0xFFF7F8FA);

  /// 获取卡片背景色
  static Color cardColorOf(BuildContext context) => Colors.white;

  /// 获取主文字色
  static Color textColorOf(BuildContext context) => const Color(0xFF1A1A1A);

  /// 获取次文字色
  static Color textSecondaryOf(BuildContext context) => const Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _loadThemeColor();
  }

  Future<void> _loadThemeColor() async {
    final color = await ThemeService.getThemeColor();
    if (color != null) setState(() => _themeColor = color);
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      themeColor: _themeColor,
      child: MaterialApp(
        title: '随心耶',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('en', 'US'),
        ],
        locale: const Locale('zh'),
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
        ),
        themeMode: ThemeMode.light,
        builder: (context, child) => AnimatedTheme(
          data: Theme.of(context),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          child: child!,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// 登录网关：已登录进主页（可能需要应用锁），未登录进登录页
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _needAppLock = false;

  @override
  void initState() {
    super.initState();
    _checkAppLock();
  }

  Future<void> _checkAppLock() async {
    final isLoggedIn = UserService.instance.isLoggedIn;
    final isGuest = UserService.instance.isGuest;
    final isInDecoyMode = UserService.instance.isInDecoyMode;

    if (isLoggedIn && !isGuest) {
      // 已登录且非游客
      // 如果在假日记模式，需要输入密码选择进入哪个模式
      // 如果启用了生物识别锁，也需要验证
      final biometricEnabled = await UserService.instance.getBiometricEnabled();
      if (mounted) {
        setState(() {
          _needAppLock = isInDecoyMode || biometricEnabled;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF87CEEB),
          ),
        ),
      );
    }

    if (!UserService.instance.isLoggedIn) {
      return const LoginScreen();
    }

    if (_needAppLock) {
      return const AppLockScreen();
    }

    return const MainScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // 侧边栏动画控制器
  late final AnimationController _drawerController;
  late final Animation<double> _drawerAnimation;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _drawerAnimation = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  /// 打开侧边栏
  void _openDrawer() {
    _drawerController.forward();
  }

  /// 关闭侧边栏
  void _closeDrawer() {
    _drawerController.reverse();
  }

  /// 构建当前页面（Key 确保 AnimatedSwitcher 识别页面切换）
  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return DiaryHomePage(key: const ValueKey(0), onOpenDrawer: _openDrawer);
      case 1:
        return const MooSpaceTunnelScreen(key: ValueKey(1));
      case 2:
        return const FocusScreen(key: ValueKey(2));
      case 3:
        return const FortuneScreen(key: ValueKey(3));
      case 4:
        return const ProfileScreen(key: ValueKey(4));
      default:
        return DiaryHomePage(key: const ValueKey(0), onOpenDrawer: _openDrawer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 不再使用 Scaffold 的 drawer，改用 Stack 覆盖层
      body: Stack(
        children: [
          // 主内容 + 底部导航栏
          Column(
            children: [
              Expanded(
                // IndexedStack 保持所有 tab 页面存活，切换零延迟
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    DiaryHomePage(key: const ValueKey(0), onOpenDrawer: _openDrawer),
                    const MooSpaceTunnelScreen(key: ValueKey(1)),
                    const FocusScreen(key: ValueKey(2)),
                    const FortuneScreen(key: ValueKey(3)),
                    const ProfileScreen(key: ValueKey(4)),
                  ],
                ),
              ),
              _buildBottomNavBar(),
            ],
          ),
          // 侧边栏覆盖层（遮罩 + 抽屉），覆盖整个屏幕包括底部导航栏
          _buildDrawerOverlay(),
        ],
      ),
    );
  }

  /// 底部导航栏
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.book, '日记'),
              _buildNavItem(1, Icons.explore, '发现'),
              _buildNavItem(2, Icons.chat_bubble, '社区'),
              _buildNavItem(3, Icons.auto_awesome, '心情'),
              _buildNavItem(4, Icons.person, '我的'),
            ],
          ),
        ),
      ),
    );
  }

  /// 侧边栏覆盖层
  Widget _buildDrawerOverlay() {
    return AnimatedBuilder(
      animation: _drawerAnimation,
      builder: (context, child) {
        if (_drawerAnimation.value == 0) {
          return const SizedBox.shrink();
        }
        final screenWidth = MediaQuery.of(context).size.width;
        final drawerWidth = screenWidth * 0.75;

        return GestureDetector(
          onTap: _closeDrawer,
          child: Container(
            color: Colors.black.withValues(alpha: 0.4 * _drawerAnimation.value),
            child: Row(
              children: [
                Transform.translate(
                  offset: Offset(-drawerWidth * (1 - _drawerAnimation.value), 0),
                  child: GestureDetector(
                    onTap: () {},
                    child: SizedBox(
                      width: drawerWidth,
                      child: AppDrawer(
                        closeDrawer: _closeDrawer,
                        onNavigate: () {
                          Future.delayed(const Duration(milliseconds: 400), () {
                            _openDrawer();
                          });
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(child: Container()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final themeColor = ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);

    return _NavButton(
      onTap: () => setState(() => _currentIndex = index),
      builder: (pressed) => AnimatedScale(
        scale: pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 56,
          height: 44,
          decoration: isSelected
              ? BoxDecoration(
                  color: themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Icon(
            icon,
            size: 26,
            color: isSelected ? themeColor : const Color(0xFFB0B8C1),
          ),
        ),
      ),
    );
  }
}

/// 按钮按下反馈包装器：按下缩小至 0.9，松手弹回
class _NavButton extends StatefulWidget {
  final Widget Function(bool pressed) builder;
  final VoidCallback? onTap;

  const _NavButton({required this.builder, this.onTap});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: widget.builder(_pressed),
    );
  }
}
