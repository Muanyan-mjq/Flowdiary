import 'package:flutter/material.dart';
import '../widgets/responsive_app_bar.dart';
import '../utils/user_service.dart';
import '../main.dart';
import '../utils/smooth_route.dart';

/// 伪装页面（假日记）
/// 输入伪装密码后进入，显示预设的普通内容
/// 模拟真实 app 的主页布局，让窥屏者以为这就是真实内容
class DecoyScreen extends StatefulWidget {
  const DecoyScreen({super.key});

  @override
  State<DecoyScreen> createState() => _DecoyScreenState();
}

class _DecoyScreenState extends State<DecoyScreen> {
  Color get _tc => ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
  int _currentIndex = 0;

  // 假日记日期跟随今天动态生成（最近5天）
  List<Map<String, dynamic>> get _fakeDiaries {
    final now = DateTime.now();
    final weathers = ['☀️ 晴', '⛅ 多云', '🌧️ 小雨', '☀️ 晴', '⛅ 多云'];
    final moods = ['😊 开心', '😌 平静', '😐 一般', '😊 开心', '😌 平静'];
    final contents = [
      '今天天气真好，去图书馆学习了一下午。复习了数据结构的二叉树部分，感觉理解更深了。晚上和同学一起吃了食堂新开的窗口，味道还不错。',
      '上午上了高数课，讲的是定积分的应用。下午在宿舍看了一会儿书，是关于人工智能的历史。傍晚去操场跑了两圈，出了一身汗，很舒服。',
      '今天下雨了，没出门。在宿舍整理了笔记，把上周的内容复习了一遍。中午点的外卖，是学校附近那家黄焖鸡，味道还可以。',
      '周末和朋友去了公园散步，拍了一些花的照片。回来的路上买了杯奶茶，是新出的杨枝甘露口味。晚上看了一部电影，是宫崎骏的《千与千寻》。',
      '今天是周五，上午有英语课。下午去实验室做了实验，是关于电路的。晚上和室友一起打了会儿游戏，放松了一下。',
    ];
    return List.generate(5, (i) {
      final d = now.subtract(Duration(days: i));
      return {
        'date': '${d.year}年${d.month}月${d.day}日',
        'weather': weathers[i],
        'mood': moods[i],
        'content': contents[i],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor(context),
      body: Column(
        children: [
          // 顶部导航栏
          ResponsiveAppBar(
            backgroundColor: appBgColor(context),
            titleAlignment: CrossAxisAlignment.center,
            left: IconButton(
              icon: const Icon(Icons.menu, size: 26, color: Color(0xFF1A1A1A)),
              onPressed: () {
                _showExitDialog();
              },
            ),
            center: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '日记本',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey[600]),
              ],
            ),
            right: IconButton(
              icon: Icon(Icons.edit_outlined, size: 24, color: Colors.grey[600]),
              onPressed: () {},
            ),
          ),
          // 日记列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: _fakeDiaries.length,
              itemBuilder: (context, index) {
                return _buildDiaryCard(_fakeDiaries[index]);
              },
            ),
          ),
        ],
      ),
      // 底部导航栏
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildDiaryCard(Map<String, dynamic> diary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期行
          Row(
            children: [
              Text(
                diary['date'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Text(
                diary['weather'],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                diary['mood'],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 内容
          Text(
            diary['content'],
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.book_outlined, Icons.book, '日记'),
              _buildNavItem(1, Icons.explore_outlined, Icons.explore, '发现'),
              _buildNavItem(2, Icons.chat_bubble_outline, Icons.chat_bubble, '社区'),
              _buildNavItem(3, Icons.auto_awesome_outlined, Icons.auto_awesome, '心情'),
              _buildNavItem(4, Icons.person_outline, Icons.person, '我的'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    final themeColor = _tc;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        // 除"日记"标签（index=0）外，点击其他标签都提示退出伪装
        if (index != 0) {
          _showExitDialog();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                color: themeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Icon(
          isSelected ? activeIcon : icon,
          size: 26,
          color: isSelected ? themeColor : const Color(0xFFCDD5DB),
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出伪装模式'),
        content: const Text('确定要退出伪装模式，回到真实日记吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // 清除假日记模式
              await UserService.instance.clearDecoyMode();
              // 返回真实主页
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  SmoothRoute(builder: (_) => const MainScreen()),
                );
              }
            },
            child: Text(
              '确定',
              style: TextStyle(color: _tc),
            ),
          ),
        ],
      ),
    );
  }
}
