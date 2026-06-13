import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/user_service.dart';
import '../utils/sign_storage.dart';
import '../utils/draft_storage.dart';
import '../services/cloud_auth_service.dart';
import '../screens/personal_space_screen.dart';
import '../screens/monthly_view_screen.dart';
import '../screens/search_screen.dart';
import '../screens/sync_screen.dart';
import '../main.dart';
import '../screens/list_view_screen.dart';
import '../screens/drafts_screen.dart';
import '../screens/favorites_screen.dart';
import '../utils/smooth_route.dart';
import 'responsive_app_bar.dart';

/// Moo 日记风格配色
const _textDark = Color(0xFF222222);
const _textBody = Color(0xFF1A1A1A);
const _textLight = Color(0xFF999999);
const _bgCard = Color(0xFFF7F8FA);

/// 随心耶侧边栏抽屉
class AppDrawer extends StatefulWidget {
  /// 从子页面返回时的回调（用于重新打开侧边栏）
  final VoidCallback? onNavigate;

  /// 关闭侧边栏的回调（自定义 overlay 模式下替代 Navigator.pop）
  final VoidCallback? closeDrawer;

  const AppDrawer({super.key, this.onNavigate, this.closeDrawer});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Color get _tc => ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
  int _streakDays = 0;
  bool _hasDrafts = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final data = await SignStorage.loadData();
    final unseen = await DraftStorage.hasUnseen();
    if (mounted) setState(() { _streakDays = data.consecutiveDays; _hasDrafts = unseen; });
  }

  /// 构建头像：自定义图片 > 默认图 > 图标兜底
  Widget _buildAvatar() {
    final path = UserService.instance.avatarPath;
    if (path.isNotEmpty) {
      try {
        if (File(path).existsSync()) {
          return Image.file(File(path), fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultAvatar());
        }
      } catch (_) {}
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Image.asset('assets/images/samoye/default_avatar.png', fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 28, color: Color(0xFFCCCCCC)));
  }

  /// 根据时间返回问候语
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return '夜深了';
    if (hour < 7) return '清晨好';
    if (hour < 9) return '早上好';
    if (hour < 12) return '上午好';
    if (hour < 14) return '中午好';
    if (hour < 17) return '下午好';
    if (hour < 19) return '傍晚好';
    if (hour < 22) return '晚上好';
    return '夜深了';
  }

  /// 格式化日期
  String _getDate() {
    final now = DateTime.now();
    return '${now.year}年${now.month.toString().padLeft(2, '0')}月${now.day.toString().padLeft(2, '0')}日';
  }

  @override
  Widget build(BuildContext context) {
    // 屏幕宽度的 75%
    final drawerWidth = MediaQuery.of(context).size.width * 0.75;
    // 顶部安全距离：屏幕高度的 4%，与 ResponsiveAppBar 保持一致
    final safeTop = MediaQuery.sizeOf(context).height * 0.04;

    return GestureDetector(
      // 左滑关闭侧边栏
      onHorizontalDragEnd: (details) {
        // 检测左滑手势（速度为负表示向左滑动）
        if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
          widget.closeDrawer?.call();
        }
      },
      child: SizedBox(
        width: drawerWidth,
        child: Drawer(
          backgroundColor: appBgColor(context),
          elevation: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部安全距离
              SizedBox(height: safeTop),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildUserCard(),
              const SizedBox(height: 32),
              _buildMenuList(),
              const Spacer(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  /// 用户信息卡片（头像 + 昵称 + 打卡天数），点击进入个人空间
  Widget _buildUserCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // 先关闭侧边栏，再跳转，避免遮挡动画
          widget.closeDrawer?.call();
          Navigator.of(context, rootNavigator: true).push(
            SmoothRoute(builder: (_) => const PersonalSpaceScreen()),
          ).then((_) {
            // 返回时重新打开侧边栏
            if (widget.onNavigate != null) {
              widget.onNavigate!();
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // 左侧头像：用户自定义 > 默认图 > 图标兜底
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: _buildAvatar(),
                ),
              ),
              const SizedBox(width: 14),
              // 右侧：昵称 + 打卡天数
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      UserService.instance.nickname,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, size: 16, color: Colors.orange[400]),
                        const SizedBox(width: 4),
                        Text(
                          '已记录 $_streakDays 天',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部头部区域
  /// 顶部间距比主页面标题稍低，营造主次分明的层次感
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '随心耶',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getDate()} ${_getGreeting()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 22, color: _textLight),
            onPressed: () {
              widget.closeDrawer?.call();
              _showSearchDialog(context);
            },
          ),
        ],
      ),
    );
  }

  /// 核心菜单项列表
  Widget _buildMenuList() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.calendar_month_outlined,
          label: '月度视图',
          onTap: () {
            widget.closeDrawer?.call();
            Navigator.of(context, rootNavigator: true).push(
              SmoothRoute(builder: (_) => const MonthlyViewScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.list_alt_outlined,
          label: '列表视图',
          onTap: () {
            widget.closeDrawer?.call();
            Navigator.of(context, rootNavigator: true).push(
              SmoothRoute(builder: (_) => const ListViewScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.favorite_border_rounded,
          label: '我的收藏',
          onTap: () {
            widget.closeDrawer?.call();
            Navigator.of(context, rootNavigator: true).push(
              SmoothRoute(builder: (_) => const FavoritesScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.insert_drive_file_outlined,
          label: '我的草稿',
          showDot: _hasDrafts,
          onTap: () async {
            await DraftStorage.markSeen();
            setState(() => _hasDrafts = false); // 立即消除红点
            widget.closeDrawer?.call();
            if (mounted) {
              Navigator.of(context, rootNavigator: true).push(
                SmoothRoute(builder: (_) => const DraftsScreen()),
              ).then((_) async {
                // 返回后重新检查（处理在草稿箱里又产生新草稿的情况）
                final unseen = await DraftStorage.hasUnseen();
                if (mounted) setState(() => _hasDrafts = unseen);
              });
            }
          },
        ),
        _buildMenuItem(
          icon: Icons.cloud_outlined,
          label: '云端备份',
          trailing: _cloudStatusBadge(),
          onTap: () {
            widget.closeDrawer?.call();
            Navigator.of(context, rootNavigator: true).push(
              SmoothRoute(builder: (_) => const SyncScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget? _cloudStatusBadge() {
    final enabled = CloudAuthService.instance.isCloudEnabled;
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF4CAF50) : Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }

  /// 单个菜单项
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    bool showDot = false,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.grey[500]),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: _textBody,
              ),
            ),
            if (showDot) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            if (trailing != null) ...[
              const Spacer(),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  /// 底部版本信息
  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Text(
        'v1.0.0',
        style: TextStyle(
          fontSize: 11,
          color: _textLight,
        ),
      ),
    );
  }

  /// 搜索弹窗
  void _showSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final searchController = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                const SizedBox(height: 16),
                const Text('搜索日记', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark)),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '输入关键词搜索...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: _textLight),
                    filled: true,
                    fillColor: appBgColor(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final keyword = searchController.text.trim();
                      if (keyword.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('请输入搜索关键词')));
                        return;
                      }
                      Navigator.pop(ctx);
                      // 关闭抽屉 → 打开搜索页
                      widget.closeDrawer?.call();
                      Navigator.of(context, rootNavigator: true).push(
                        SmoothRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tc,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('搜索', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
