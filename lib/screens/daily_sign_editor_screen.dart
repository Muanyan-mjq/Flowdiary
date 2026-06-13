import 'package:flutter/material.dart';
import 'daily_sign_square_screen.dart';
import '../widgets/responsive_app_bar.dart';
import '../utils/user_service.dart';
import '../main.dart';

/// 日签编辑页面
/// 支持文字 + 图片，返回 DailySignPost 给广场页
class DailySignEditorScreen extends StatefulWidget {
  const DailySignEditorScreen({super.key});

  @override
  State<DailySignEditorScreen> createState() => _DailySignEditorScreenState();
}

class _DailySignEditorScreenState extends State<DailySignEditorScreen> {
  Color get _tc => ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
  final TextEditingController _controller = TextEditingController();
  int _charCount = 0;
  final int _maxChars = 200;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 发布日签
  void _publish() {
    if (_controller.text.trim().isEmpty) return;
    final post = DailySignPost(
      content: _controller.text.trim(),
      createdAt: DateTime.now(),
      userName: UserService.instance.nickname,
    );
    Navigator.pop(context, post);
  }

  void _onTextChanged(String text) {
    if (text.length <= _maxChars) {
      setState(() => _charCount = text.length);
    } else {
      _controller.text = text.substring(0, _maxChars);
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _maxChars),
      );
      setState(() => _charCount = _maxChars);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = ResponsiveAppBar.safeTop(context);
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final canPublish = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: appBgColor(context),
      body: Column(
        children: [
          SizedBox(height: safeTop),
          _buildAppBar(canPublish),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: _buildEditorCard(),
            ),
          ),
          _buildBottomBar(bottomSafe),
        ],
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildAppBar(bool canPublish) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios, size: 22, color: Color(0xFF1A1A1A)),
          ),
          const Spacer(),
          const Text(
            '日签',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: canPublish ? _publish : null,
            child: Icon(
              Icons.send,
              size: 24,
              color: canPublish ? _tc : Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  /// 编辑卡片：图片预览区 + 引号输入区
  Widget _buildEditorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildTextSection(),
    );
  }

  /// 引号输入区
  Widget _buildTextSection() {
    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      child: Stack(
        children: [
          // 左上角大引号
          Positioned(
            top: 0,
            left: 4,
            child: Text(
              '"',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w700,
                color: _tc.withValues(alpha: 0.2),
                height: 1,
              ),
            ),
          ),
          // 右下角大引号
          Positioned(
            bottom: 0,
            right: 4,
            child: Text(
              '"',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w700,
                color: _tc.withValues(alpha: 0.2),
                height: 1,
              ),
            ),
          ),
          // 输入区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: TextField(
              controller: _controller,
              onChanged: _onTextChanged,
              maxLines: null,
              maxLength: _maxChars,
              buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '写下一句想留在墙上话...\n可以是诗、书摘、或此刻的心情\n最多$_maxChars字',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[300],
                  height: 1.8,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 18,
                height: 1.6,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 底部栏：图片按钮 + 字数统计
  Widget _buildBottomBar(double bottomSafe) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 12 + bottomSafe),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
      ),
      child: Row(
        children: [
          const Spacer(),
          // 字数统计
          Text(
            '$_charCount/$_maxChars',
            style: TextStyle(
              fontSize: 14,
              color: _charCount > _maxChars * 0.8
                  ? const Color(0xFFFF6B6B)
                  : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
