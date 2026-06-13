import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'daily_sign_square_screen.dart';
import 'daily_sign_share_screen.dart';
import '../main.dart';
import '../utils/favorite_storage.dart';
import '../utils/smooth_route.dart';
import '../widgets/responsive_app_bar.dart';

/// 日签详情页
/// 全屏展示单条日签：大图/渐变背景 + 完整文字 + 用户信息 + 操作栏
class DailySignDetailScreen extends StatefulWidget {
  final DailySignPost post;

  const DailySignDetailScreen({super.key, required this.post});

  @override
  State<DailySignDetailScreen> createState() => _DailySignDetailScreenState();
}

class _DailySignDetailScreenState extends State<DailySignDetailScreen> {
  late int _likes;
  late bool _isLiked;
  late int _comments;
  bool _isFaved = false;

  Color get _themeColor {
    return ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
  }

  List<Color> get _gradientColors {
    final index = widget.post.userName.hashCode.abs() % cardGradients.length;
    return cardGradients[index];
  }

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likes;
    _comments = widget.post.comments;
    _isLiked = false;
    // 加载收藏状态
    FavoriteStorage.isSignFavored(widget.post.content, widget.post.userName).then((v) { if (mounted) setState(() => _isFaved = v); });
  }

  void _toggleFav() async {
    final v = await FavoriteStorage.toggleSign(widget.post.content, widget.post.userName, _likes, _comments, widget.post.createdAt);
    if (mounted) setState(() => _isFaved = v);
  }

  /// 点赞/取消
  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likes += _isLiked ? 1 : -1;
    });
  }

  /// 复制文字
  void _copyContent() {
    Clipboard.setData(ClipboardData(text: widget.post.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
    );
  }

  String _getFullDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  String _getMonthYear(DateTime date) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[date.month - 1]}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = ResponsiveAppBar.safeTop(context);
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: appBgColor(context),
      body: Column(
        children: [
          // 顶部安全距离 + 自定义导航栏
          SizedBox(height: safeTop),
          _buildAppBar(),
          // 可滚动内容
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // 图片/渐变区域
                  _buildHeroSection(),
                  // 文字内容
                  _buildContentSection(),
                  // 操作栏
                  _buildActionBar(),
                  // 分隔线
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Divider(height: 32, color: Color(0xFFEEEEEE)),
                  ),
                  // 评论区（占位）
                  _buildCommentPlaceholder(),
                  SizedBox(height: bottomSafe + 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildAppBar() {
    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          // 居中标题
          const Center(
            child: Text(
              '日签',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
            ),
          ),
          // 左侧返回
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF1A1A1A)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          // 右侧更多菜单
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 22, color: Color(0xFF666666)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'copy') _copyContent();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'copy', child: Row(
                    children: [
                      Icon(Icons.copy, size: 18, color: Color(0xFF666666)),
                      SizedBox(width: 10),
                      Text('复制文字', style: TextStyle(fontSize: 14)),
                    ],
                  )),
                  const PopupMenuItem(value: 'report', child: Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 18, color: Color(0xFF666666)),
                      SizedBox(width: 10),
                      Text('举报', style: TextStyle(fontSize: 14)),
                    ],
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 图片/渐变区域
  Widget _buildHeroSection() {
    return _buildGradientHero();
  }

  /// 图片模式（已废弃）
  Widget _buildImageHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      height: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildGradientHero(),
            // 底部渐变遮罩 + 日期
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 150,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.post.createdAt.day.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w200,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _getMonthYear(widget.post.createdAt),
                          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
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
    );
  }

  /// 渐变模式（无图片时）
  Widget _buildGradientHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 大引号装饰
          Positioned(
            top: 16,
            left: 20,
            child: Text(
              '"',
              style: TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.25),
                height: 0.6,
              ),
            ),
          ),
          // 日期 + 内容
          Positioned(
            bottom: 28,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.post.createdAt.day.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w200,
                        color: _themeColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _getMonthYear(widget.post.createdAt),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.post.content,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.6,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 完整文字内容
  Widget _buildContentSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 引导文字
          Text(
            '今天想对自己说：',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
          const SizedBox(height: 12),
          // 完整内容
          Text(
            widget.post.content,
            style: const TextStyle(
              fontSize: 18,
              height: 1.8,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          // 用户信息行
          Row(
            children: [
              // 用户头像
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF0F0F0),
                ),
                child: Center(
                  child: Text(
                    widget.post.userName.characters.first,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.userName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                  ),
                  Text(
                    _getFullDate(widget.post.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 操作栏
  Widget _buildActionBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 点赞
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: '$_likes',
            color: _isLiked ? const Color(0xFFFF4757) : const Color(0xFF666666),
            onTap: _toggleLike,
          ),
          // 评论
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: '$_comments',
            color: const Color(0xFF666666),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('评论功能开发中...'), duration: Duration(seconds: 1)),
              );
            },
          ),
          // 收藏日签
          _buildActionButton(
            icon: _isFaved ? Icons.star : Icons.star_outline,
            label: _isFaved ? '已收藏' : '收藏',
            color: _isFaved ? const Color(0xFFFFB800) : const Color(0xFF666666),
            onTap: _toggleFav,
          ),
          // 分享卡片
          _buildActionButton(
            icon: Icons.share_outlined,
            label: '分享',
            color: const Color(0xFF666666),
            onTap: () => Navigator.push(context, SmoothRoute(builder: (_) => DailySignShareScreen(post: widget.post))),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }

  /// 评论占位区
  Widget _buildCommentPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline, size: 36, color: Colors.grey[250]),
            const SizedBox(height: 10),
            Text(
              '暂无评论',
              style: TextStyle(fontSize: 14, color: Colors.grey[350]),
            ),
            const SizedBox(height: 4),
            Text(
              '来做第一个评论的人吧',
              style: TextStyle(fontSize: 12, color: Colors.grey[300]),
            ),
          ],
        ),
      ),
    );
  }
}
