import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'about_screen.dart';
import 'feedback_screen.dart';
import 'theme_screen.dart';
import '../widgets/responsive_app_bar.dart';
import 'personal_space_screen.dart';
import 'daily_sign_square_screen.dart';
import 'mood_calendar_screen.dart';
import 'drafts_screen.dart';
import 'sync_screen.dart';
import 'favorites_screen.dart';
import '../utils/sign_storage.dart';
import '../utils/stats_storage.dart';
import '../utils/user_service.dart';
import '../utils/image_utils.dart';
import '../main.dart';
import '../utils/smooth_route.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String nickname;
  late String userId;
  String bio = ''; // 同步初始化，异步加载后再覆盖
  late bool _isGuest;

  /// 获取当前主题颜色
  Color get _themeColor {
    return ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
  }

  bool _isSigned = false;
  int _diaryCount = 0;
  int _days = 0;
  int _totalWords = 0;
  int _consecutiveDays = 0;

  @override
  void initState() {
    super.initState();
    _isGuest = UserService.instance.isGuest;
    nickname = UserService.instance.nickname;
    userId = _isGuest ? '---' : UserService.instance.userId;

    // 从 SharedPreferences 加载签名
    _loadBio();
    // 加载状态
    _loadSignStatus();
    _loadStats();
    _loadConsecutiveDays();
  }

  /// 加载签名
  Future<void> _loadBio() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('user_signature');
    if (mounted) {
      setState(() => bio = saved ?? '用萨摩耶的方式，记录每一天 🐾');
    }
  }

  /// 编辑昵称
  void _editNickname() {
    if (_isGuest) return;
    final controller = TextEditingController(text: nickname);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('修改昵称', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '输入新昵称', hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true, fillColor: appBgColor(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('昵称不能为空')));
                        return;
                      }
                      await UserService.instance.updateNickname(name);
                      setState(() => nickname = name);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('昵称已更新')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _themeColor, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('保存', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 编辑签名
  void _editBio() {
    final controller = TextEditingController(text: bio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('修改签名', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 50,
                  decoration: InputDecoration(
                    hintText: '写一句个性签名', hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true, fillColor: appBgColor(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final sig = controller.text.trim();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('user_signature', sig);
                      setState(() => bio = sig);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('签名已更新')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _themeColor, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('保存', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadSignStatus() async {
    final data = await SignStorage.loadData();
    if (mounted) setState(() => _isSigned = data.isSignedToday);
  }

  Future<void> _loadStats() async {
    final data = await StatsStorage.loadData();
    if (mounted) {
      setState(() {
        _diaryCount = data.diaryCount;
        _days = data.days;
        _totalWords = data.totalWords;
      });
    }
  }

  Future<void> _loadConsecutiveDays() async {
    final data = await SignStorage.loadData();
    if (mounted) setState(() => _consecutiveDays = data.consecutiveDays);
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: userId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID 已复制'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = ResponsiveAppBar.safeTop(context);

    return Scaffold(
      backgroundColor: appBgColor(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, safeTop + 16, 24, 24),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 8),
            // 签名栏
            if (bio.isNotEmpty) ...[
              GestureDetector(
                onTap: _editBio,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    bio,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            _buildStats(),
            const SizedBox(height: 24),
            _buildMenuSection(),
            const SizedBox(height: 24),
            _buildLogoutButton(),
            const SizedBox(height: 16),
            Text('Version 1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            IconButton(
              icon: Icon(Icons.settings_outlined, size: 26, color: Colors.grey[700]),
              onPressed: () {
                Navigator.push(context, SmoothRoute(builder: (_) => const SettingsScreen()))
                  .then((_) { _loadBio(); setState(() { nickname = UserService.instance.nickname; }); });
              },
            ),
          ],
        ),
        SizedBox(
          height: 85,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 头像（点击查看大图）
              Positioned(
                left: 0,
                top: -4,
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(32),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(80),
                            child: _buildAvatarImage(isLarge: true),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 65, height: 65,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(32.5),
                      border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32.5),
                      child: _buildAvatarImage(),
                    ),
                  ),
                ),
              ),
              // 昵称 + 个人空间 + ID
              Positioned(
                left: 81, top: 0, right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _editNickname,
                            child: Text(
                              nickname,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              SmoothRoute(
                                builder: (_) => const PersonalSpaceScreen(),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Text('个人空间', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                              Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('ID: $userId', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _copyId,
                          child: Icon(Icons.copy, size: 14, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 始终显示默认头像
  Widget _buildAvatarImage({bool isLarge = false}) {
    final size = isLarge ? 300.0 : 65.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(isLarge ? 80 : 32.5),
      child: Image.asset('assets/images/samoye/default_avatar.png',
        width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.pets, size: isLarge ? 100 : 32, color: Colors.grey[400])),
    );
  }

  /// 最终兜底图标
  Widget _fallbackIcon() {
    return const ColoredBox(
      color: Color(0xFFF5F5F5),
      child: Center(child: Icon(Icons.pets, size: 32, color: Color(0xFFCCCCCC))),
    );
  }

  Widget _buildStats() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('$_diaryCount', '日记'),
              Container(width: 1, height: 30, color: const Color(0xFFE5E5E5)),
              _buildStatItem('$_days', '天数'),
              Container(width: 1, height: 30, color: const Color(0xFFE5E5E5)),
              _buildStatItem(StatsStorage.formatWords(_totalWords), '字数'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSquareCard('心情日历', '查看心情记录', () {
                Navigator.push(context, SmoothRoute(builder: (_) => const MoodCalendarScreen()));
              }),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildDailySignCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSquareCard('草稿箱', '未完成的日记', () {
                Navigator.push(context, SmoothRoute(builder: (_) => const DraftsScreen()));
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSquareCard('云端备份', '备份与恢复数据', () {
                Navigator.push(context, SmoothRoute(builder: (_) => const SyncScreen()));
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDailySignCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push<bool>(
          context,
          SmoothRoute(builder: (_) => DailySignSquareScreen(alreadySigned: _isSigned)),
        );
        _loadSignStatus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('日签墙', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                const Spacer(),
                Icon(_isSigned ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: _isSigned ? _themeColor : Colors.grey[300]),
              ],
            ),
            const SizedBox(height: 4),
            Text(_isSigned ? '今日已签到' : '打开收集好句子', style: TextStyle(fontSize: 11, color: _isSigned ? _themeColor : Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareCard(String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.palette_outlined, '主题', '', () {
            Navigator.push(context, SmoothRoute(builder: (_) => ThemeScreen(
              onThemeChanged: (color) {
                SuiXinYeAppState.of(context)?.updateThemeColor(color);
                if (mounted) setState(() {});
              },
            )));
          }, iconColor: _themeColor),
          _buildDivider(),
          _buildMenuItem(Icons.favorite_border_rounded, '我的收藏', '', () {
            Navigator.push(context, SmoothRoute(builder: (_) => const FavoritesScreen()));
          }),
          _buildDivider(),
          _buildMenuItem(Icons.feedback_outlined, '意见反馈', '', () {
            Navigator.push(context, SmoothRoute(builder: (_) => const FeedbackScreen()));
          }),
          _buildDivider(),
          _buildMenuItem(Icons.info_outline, '关于', 'v1.0.0', () {
            Navigator.push(context, SmoothRoute(builder: (_) => const AboutScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, String value, VoidCallback onTap, {Color? iconColor}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor ?? const Color(0xFF1A1A1A)),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
            const Spacer(),
            if (iconColor != null) ...[
              Container(width: 10, height: 10, decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
            ],
            if (value.isNotEmpty)
              Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 22, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Color(0xFFE5E5E5)),
    );
  }

  Widget _buildLogoutButton() {
    final label = _isGuest ? '登录 / 注册' : '退出登录';
    final color = _isGuest ? _themeColor : const Color(0xFFFF3B30);

    return GestureDetector(
      onTap: () {
        if (_isGuest) {
          Navigator.pushAndRemoveUntil(
            context,
            SmoothRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('确认退出'),
              content: const Text('确定要退出随心耶吗？'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await UserService.instance.logout();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        SmoothRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('确定', style: TextStyle(color: Color(0xFFFF3B30))),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color)),
        ),
      ),
    );
  }
}
