import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'daily_sign_editor_screen.dart';
import 'daily_sign_detail_screen.dart';
import '../utils/smooth_route.dart';
import '../utils/sign_storage.dart';
import '../utils/favorite_storage.dart';
import '../widgets/responsive_app_bar.dart';
import '../main.dart';

/// 日签帖子数据模型
class DailySignPost {
  final String content;
  final DateTime createdAt;
  final String userName;
  final int likes;
  final int comments;

  DailySignPost({
    required this.content,
    required this.createdAt,
    this.userName = '匿名萨摩',
    this.likes = 0,
    this.comments = 0,
  });

  /// 从存储的 Map 反序列化（createdAt 为 ISO 8601 字符串）
  factory DailySignPost.fromMap(Map<String, dynamic> map) {
    return DailySignPost(
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      userName: (map['userName'] as String?) ?? '匿名萨摩',
      likes: (map['likes'] as int?) ?? 0,
      comments: (map['comments'] as int?) ?? 0,
    );
  }

  /// 序列化为可存储的 Map（createdAt 转 ISO 8601 字符串）
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'userName': userName,
      'likes': likes,
      'comments': comments,
    };
  }
}

/// 6 组柔色渐变背景（网格卡片轮换使用）
const cardGradients = [
  [Color(0xFFFFF0F0), Color(0xFFFFD4D4)], // 浅粉
  [Color(0xFFF3F0FF), Color(0xFFDDD4FF)], // 浅紫
  [Color(0xFFF0F5FF), Color(0xFFD4E4FF)], // 浅蓝
  [Color(0xFFFFF8F0), Color(0xFFFFE8CC)], // 浅橙
  [Color(0xFFF0FFF5), Color(0xFFD4FFE4)], // 浅绿
  [Color(0xFFFFF5FA), Color(0xFFFFD4EC)], // 浅玫红
];

class DailySignSquareScreen extends StatefulWidget {
  final bool alreadySigned;

  const DailySignSquareScreen({super.key, this.alreadySigned = false});

  @override
  State<DailySignSquareScreen> createState() => _DailySignSquareScreenState();
}

class _DailySignSquareScreenState extends State<DailySignSquareScreen>
    with WidgetsBindingObserver {
  int _consecutiveDays = 0;
  late bool _isSignedToday;
  DateTime? _lastSignDate;

  // 用户发布的日签
  final List<DailySignPost> _myPosts = [];
  // 已收藏的日签标识（content+userName hash）
  Set<String> _favSigns = {};

  /// 签到按钮缩放动画
  double _signButtonScale = 1.0;

  Color get _themeColor {
    return ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isSignedToday = widget.alreadySigned;
    _refreshRecommendPosts();
    _loadSignData();
    _loadFavs();
  }

  Future<void> _loadFavs() async {
    final signs = await FavoriteStorage.getFavoriteSigns();
    if (mounted) setState(() { _favSigns = signs.map((s) => '${s['content']}_${s['userName']}').toSet(); });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSignData();
    }
  }

  Future<void> _loadSignData() async {
    final data = await SignStorage.loadData();
    debugPrint('[签到] 加载数据: isSignedToday=${data.isSignedToday}, consecutiveDays=${data.consecutiveDays}');
    // 加载用户已发布的日签帖子
    final savedPosts = await SignStorage.loadMyPosts();
    if (mounted) {
      setState(() {
        _isSignedToday = data.isSignedToday;
        _consecutiveDays = data.consecutiveDays;
        _lastSignDate = data.lastSignDate;
        _myPosts.clear();
        _myPosts.addAll(savedPosts.map((m) => DailySignPost.fromMap(m)));
      });
    }
  }

  // ==================== 推荐内容（每日轮换） ====================

  /// 语料池（24 条，每次随机抽 6 条）
  static const List<Map<String, dynamic>> _postPool = [
    {'content': '书店是这世界上\n最好的避风港', 'userName': '先锋读者', 'likes': 52},
    {'content': '大地上的异乡者\n都在书里找到了故乡', 'userName': '十字路口', 'likes': 48},
    {'content': '我来到这个世界\n为了看看太阳和蓝色的地平线', 'userName': '北岛', 'likes': 67},
    {'content': '吹灭读书灯\n一身都是月', 'userName': '桂苓', 'likes': 55},
    {'content': '要有最朴素的生活\n与最遥远的梦想', 'userName': '七堇年', 'likes': 89},
    {'content': '凌晨四点醒来\n发现海棠花未眠', 'userName': '川端康成', 'likes': 73},
    {'content': '活在这珍贵的人间\n太阳强烈\n水波温柔', 'userName': '海子', 'likes': 58},
    {'content': '从前的日色变得慢\n一生只够爱一个人', 'userName': '木心', 'likes': 112},
    {'content': '如果有来生\n要做一棵树\n站成永恒', 'userName': '三毛', 'likes': 86},
    {'content': '每想你一次\n天上飘落一粒沙\n从此形成撒哈拉', 'userName': '三毛', 'likes': 77},
    {'content': '爱自己是终身浪漫的开始', 'userName': '王尔德', 'likes': 105},
    {'content': '我们都在阴沟里\n但仍有人仰望星空', 'userName': '王尔德', 'likes': 91},
    {'content': '那时我们有梦\n关于文学关于爱情\n关于穿越世界的旅行', 'userName': '北岛', 'likes': 68},
    {'content': '只要想起一生中后悔的事\n梅花便落满了南山', 'userName': '张枣', 'likes': 55},
    {'content': '草在结它的种子\n风在摇它的叶子\n我们站着不说话\n就十分美好', 'userName': '顾城', 'likes': 81},
    {'content': '黑夜给了我黑色的眼睛\n我却用它寻找光明', 'userName': '顾城', 'likes': 96},
    {'content': '万物皆有裂痕\n那是光照进来的地方', 'userName': '科恩', 'likes': 123},
    {'content': '种一棵树最好的时间\n是十年前\n其次是现在', 'userName': '非洲谚语', 'likes': 39},
    {'content': '山是温柔\n雾是温柔\n心是一切温柔的起点', 'userName': '林清玄', 'likes': 57},
    {'content': '一个人需要隐藏多少秘密\n才能巧妙地度过一生', 'userName': '仓央嘉措', 'likes': 72},
    {'content': '我不知道将去何方\n但我已在路上', 'userName': '宫崎骏', 'likes': 88},
    {'content': '生命可以随心所欲\n但不能随波逐流', 'userName': '宫崎骏', 'likes': 65},
    {'content': '有些路只能一个人走', 'userName': '龙应台', 'likes': 49},
    {'content': '醉后不知天在水\n满船清梦压星河', 'userName': '唐温如', 'likes': 78},
    {'content': '何时杖尔看南雪\n我与梅花两白头', 'userName': '查辛香', 'likes': 59},
    {'content': '人间有味是清欢', 'userName': '苏轼', 'likes': 82},
    {'content': '回首向来萧瑟处\n也无风雨也无晴', 'userName': '苏轼', 'likes': 93},
    {'content': '人生如逆旅\n我亦是行人', 'userName': '苏轼', 'likes': 76},
    {'content': '此心安处是吾乡', 'userName': '苏轼', 'likes': 88},
    {'content': '云想衣裳花想容\n春风拂槛露华浓', 'userName': '李白', 'likes': 71},
    {'content': '仰天大笑出门去\n我辈岂是蓬蒿人', 'userName': '李白', 'likes': 64},
    {'content': '举杯邀明月\n对影成三人', 'userName': '李白', 'likes': 56},
    {'content': '长风破浪会有时\n直挂云帆济沧海', 'userName': '李白', 'likes': 103},
    {'content': '露从今夜白\n月是故乡明', 'userName': '杜甫', 'likes': 47},
    {'content': '正是江南好风景\n落花时节又逢君', 'userName': '杜甫', 'likes': 52},
    {'content': '行到水穷处\n坐看云起时', 'userName': '王维', 'likes': 69},
    {'content': '大漠孤烟直\n长河落日圆', 'userName': '王维', 'likes': 44},
    {'content': '曾经沧海难为水\n除却巫山不是云', 'userName': '元稹', 'likes': 61},
    {'content': '此情可待成追忆\n只是当时已惘然', 'userName': '李商隐', 'likes': 74},
    {'content': '春蚕到死丝方尽\n蜡炬成灰泪始干', 'userName': '李商隐', 'likes': 41},
    {'content': '众里寻他千百度\n蓦然回首\n那人却在灯火阑珊处', 'userName': '辛弃疾', 'likes': 85},
    {'content': '稻花香里说丰年\n听取蛙声一片', 'userName': '辛弃疾', 'likes': 38},
    {'content': '问君能有几多愁\n恰似一江春水向东流', 'userName': '李煜', 'likes': 57},
    {'content': '剪不断理还乱\n是离愁', 'userName': '李煜', 'likes': 33},
    {'content': '昨夜西风凋碧树\n独上高楼望尽天涯路', 'userName': '晏殊', 'likes': 46},
    {'content': '无可奈何花落去\n似曾相识燕归来', 'userName': '晏殊', 'likes': 42},
    {'content': '落霞与孤鹜齐飞\n秋水共长天一色', 'userName': '王勃', 'likes': 79},
    {'content': '海内存知己\n天涯若比邻', 'userName': '王勃', 'likes': 54},
    {'content': '先天下之忧而忧\n后天下之乐而乐', 'userName': '范仲淹', 'likes': 36},
    {'content': '醉翁之意不在酒\n在乎山水之间也', 'userName': '欧阳修', 'likes': 48},
    {'content': '庭院深深深几许\n杨柳堆烟帘幕无重数', 'userName': '欧阳修', 'likes': 31},
    {'content': '人生自是有情痴\n此恨不关风与月', 'userName': '欧阳修', 'likes': 45},
    {'content': '枯藤老树昏鸦\n小桥流水人家\n古道西风瘦马', 'userName': '马致远', 'likes': 63},
    {'content': '满纸荒唐言\n一把辛酸泪', 'userName': '曹雪芹', 'likes': 51},
    {'content': '世事洞明皆学问\n人情练达即文章', 'userName': '曹雪芹', 'likes': 39},
    {'content': '面朝大海\n春暖花开', 'userName': '海子', 'likes': 128},
    {'content': '你来人间一趟\n你要看看太阳', 'userName': '海子', 'likes': 97},
    {'content': '今夜我不关心人类\n我只想你', 'userName': '海子', 'likes': 84},
    {'content': '岁月极美\n在于它必然的流逝', 'userName': '三毛', 'likes': 62},
    {'content': '心若没有栖息的地方\n到哪里都是在流浪', 'userName': '三毛', 'likes': 115},
    {'content': '一个人至少拥有一个梦想\n有一个理由去坚强', 'userName': '三毛', 'likes': 72},
    {'content': '你不愿意种花\n你说你不愿看见它一点点凋落', 'userName': '顾城', 'likes': 53},
    {'content': '我想在大地上画满窗子\n让所有习惯黑暗的眼睛都习惯光明', 'userName': '顾城', 'likes': 67},
    {'content': '一切都明明白白\n但我们仍匆匆错过', 'userName': '顾城', 'likes': 41},
    {'content': '卑鄙是卑鄙者的通行证\n高尚是高尚者的墓志铭', 'userName': '北岛', 'likes': 59},
    {'content': '我和这个世界不熟\n这并非是我安静的原因', 'userName': '北岛', 'likes': 35},
    {'content': '一生或许只是几页\n不断在修改和誊抄着的诗稿', 'userName': '席慕容', 'likes': 47},
    {'content': '所有的悲欢都已化为灰烬\n任世间哪一条路我都不能与你同行', 'userName': '席慕容', 'likes': 43},
    {'content': '每一棵草都会开花\n只是花期不同', 'userName': '佚名', 'likes': 38},
    {'content': '世界以痛吻我\n要我报之以歌', 'userName': '泰戈尔', 'likes': 106},
    {'content': '生如夏花之绚烂\n死如秋叶之静美', 'userName': '泰戈尔', 'likes': 132},
    {'content': '我们把世界看错了\n反说它欺骗我们', 'userName': '泰戈尔', 'likes': 55},
    {'content': '离你越近的地方\n路途越远', 'userName': '泰戈尔', 'likes': 34},
    {'content': '对待生命你不妨大胆一点\n因为我们始终要失去它', 'userName': '尼采', 'likes': 89},
    {'content': '每一个不曾起舞的日子\n都是对生命的辜负', 'userName': '尼采', 'likes': 117},
    {'content': '谁终将声震人间\n必长久深自缄默', 'userName': '尼采', 'likes': 63},
    {'content': '日出未必意味着光明\n太阳也无非是一颗晨星', 'userName': '梭罗', 'likes': 42},
    {'content': '我愿意深深地扎入生活\n吮尽生活的骨髓', 'userName': '梭罗', 'likes': 37},
    {'content': '一个人怎么看待自己\n决定了此人的命运', 'userName': '梭罗', 'likes': 49},
    {'content': '不要着急\n最好的总会在不经意的时候出现', 'userName': '泰戈尔', 'likes': 68},
    {'content': '你的问题主要是读书不多\n而想得太多', 'userName': '杨绛', 'likes': 95},
    {'content': '刚开始是假装坚强\n后来就真的坚强了', 'userName': '杨绛', 'likes': 44},
    {'content': '愿你有好运气\n如果没有\n愿你在不幸中学会慈悲', 'userName': '刘瑜', 'likes': 71},
    {'content': '使人疲惫的不是远方的高山\n而是鞋里的一粒沙子', 'userName': '伏尔泰', 'likes': 56},
    {'content': '真正的光明绝不是没有黑暗的时间\n只是永不被黑暗所掩蔽', 'userName': '罗曼罗兰', 'likes': 62},
    {'content': '所谓无底深渊\n下去也是前程万里', 'userName': '木心', 'likes': 83},
    {'content': '生活的最佳状态是\n冷冷清清的风风火火', 'userName': '木心', 'likes': 58},
    {'content': '我是一个在黑暗中大雪纷飞的人啊', 'userName': '木心', 'likes': 76},
    {'content': '不知原谅什么\n诚觉世事尽可原谅', 'userName': '木心', 'likes': 65},
    {'content': '看清世界荒谬\n是一个智者的基本水准', 'userName': '木心', 'likes': 39},
    {'content': '爱情太短\n而遗忘太长', 'userName': '聂鲁达', 'likes': 47},
    {'content': '当华美的叶片落尽\n生命的脉络才历历可见', 'userName': '聂鲁达', 'likes': 53},
    {'content': '在隆冬\n我终于知道\n我身上有一个不可战胜的夏天', 'userName': '加缪', 'likes': 94},
    {'content': '一切伟大的行动和思想\n都有一个微不足道的开始', 'userName': '加缪', 'likes': 61},
    {'content': '重要的不是治愈\n而是带着病痛活下去', 'userName': '加缪', 'likes': 72},
    {'content': '世上只有一种英雄主义\n就是认清生活的真相后依然热爱它', 'userName': '罗曼罗兰', 'likes': 141},
    {'content': '满地都是六便士\n他却抬头看见了月亮', 'userName': '毛姆', 'likes': 109},
    {'content': '我用尽了全力\n过着平凡的一生', 'userName': '毛姆', 'likes': 87},
    {'content': '为了使灵魂宁静\n一个人每天要做两件他不喜欢的事', 'userName': '毛姆', 'likes': 44},
    {'content': '人的一切痛苦\n本质上都是对自己无能的愤怒', 'userName': '王小波', 'likes': 98},
    {'content': '那一天我二十一岁\n在我一生的黄金时代\n我有好多奢望', 'userName': '王小波', 'likes': 76},
    {'content': '一个人只拥有此生此世是不够的\n他还应该拥有诗意的世界', 'userName': '王小波', 'likes': 82},
    {'content': '活在世上\n无非想要明白些道理\n遇见些有趣的事', 'userName': '王小波', 'likes': 54},
    {'content': '风可以吹起一大张白纸\n却无法吹走一只蝴蝶', 'userName': '冯骥才', 'likes': 41},
  ];

  late List<DailySignPost> _recommendPosts;

  /// 从语料池随机抽取 + 联网获取每日一句
  void _refreshRecommendPosts({bool forceNew = false}) {
    final now = DateTime.now();
    final random = Random(); // 每次随机，退出重进能看到不同推荐

    final indices = List.generate(_postPool.length, (i) => i)..shuffle(random);
    final picked = indices.take(10).toList()..sort();

    _recommendPosts = List.generate(10, (i) {
      final item = _postPool[picked[i]];
      final daysAgo = 9 - i;
      return DailySignPost(
        content: item['content'] as String,
        userName: item['userName'] as String,
        likes: item['likes'] as int,
        createdAt: DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo)),
      );
    });

    // 联网获取每日一言（异步，成功则替换第一条）
    _fetchNetworkQuote().then((quote) {
      if (quote != null && mounted) {
        setState(() {
          _recommendPosts.insert(0, DailySignPost(
            content: quote['content'] as String,
            userName: quote['userName'] as String,
            likes: 999,
            createdAt: now,
          ));
        });
      }
    });
  }

  /// 联网获取每日一句
  Future<Map<String, String>?> _fetchNetworkQuote() async {
    try {
      final resp = await http.get(Uri.parse('https://v1.hitokoto.cn/?c=a&c=b&c=c&c=d')).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return {
          'content': data['hitokoto'] as String,
          'userName': (data['from'] as String?) ?? '一言',
        };
      }
    } catch (_) {}
    return null;
  }

  /// 将当前用户帖子列表持久化到本地存储
  Future<void> _saveMyPosts() async {
    await SignStorage.saveMyPosts(_myPosts.map((p) => p.toMap()).toList());
  }

  /// 下拉刷新回调
  Future<void> _onRefresh() async {
    _refreshRecommendPosts(forceNew: true);
    await _loadSignData();
    // 短暂延迟让用户看到刷新指示器
    await Future.delayed(const Duration(milliseconds: 400));
  }

  int _selectedTab = 0; // 0: 推荐, 1: 我的

  /// 跳转详情页
  void _navigateToDetail(DailySignPost post) {
    Navigator.push(
      context,
      SmoothRoute(
        builder: (_) => DailySignDetailScreen(post: post),
      ),
    );
  }

  // 软木板色系
  static const _corkBase = Color(0xFFC49A6C);
  static const _corkLight = Color(0xFFD9B382);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _corkBase,
      body: Column(
        children: [
          ResponsiveAppBar(
            backgroundColor: _corkBase,
            titleAlignment: CrossAxisAlignment.center,
            left: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 22, color: Colors.white),
              onPressed: () => Navigator.pop(context, _isSignedToday),
            ),
            center: const Text(
              '日签墙',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            right: GestureDetector(
              onTap: () async {
                final result = await Navigator.push<DailySignPost>(
                  context,
                  SmoothRoute(builder: (_) => const DailySignEditorScreen()),
                );
                if (result != null) {
                  setState(() => _myPosts.insert(0, result));
                  _saveMyPosts(); // 持久化到本地
                  _selectedTab = 1; // 发布后切换到"我的"
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.add, size: 22, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Colors.white,
              onRefresh: _onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                // 焦点卡片
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildFocusCard(),
                  ),
                ),
                // 签到区域
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildSignInSection(),
                  ),
                ),
                // Tab 切换
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildTabBar(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                // 网格
                _selectedTab == 0 ? _buildRecommendGridSliver() : _buildMyGridSliver(),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 焦点卡片
  // ═══════════════════════════════════════════════════════

  Widget _buildFocusCard() {
    final hasPost = _myPosts.isNotEmpty;
    final post = hasPost ? _myPosts.first : null;

    return GestureDetector(
      onTap: hasPost ? () => _navigateToDetail(post!) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 360,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEF0), // 便签纸色
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            hasPost ? _buildFocusCardContent(post!) : _buildFocusCardEmpty(),
            // 图钉
            Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: Center(child: _buildPin()),
            ),
          ],
        ),
      ),
    );
  }

  /// 焦点卡片 — 有内容
  Widget _buildFocusCardContent(DailySignPost post) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 20, left: 16,
          child: Text('"',
            style: TextStyle(fontSize: 96, fontWeight: FontWeight.w700,
              color: const Color(0xFFD4A574).withValues(alpha: 0.25), height: 0.6)),
        ),
        Positioned(
          bottom: 20, left: 20, right: 20,
          child: _buildFocusText(post, isDark: false),
        ),
      ],
    );
  }

  /// 焦点卡片文字内容
  Widget _buildFocusText(DailySignPost post, {required bool isDark}) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey[600];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 日期行
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              post.createdAt.day.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w200,
                color: isDark ? Colors.white : _themeColor,
                height: 1,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _getMonthYear(post.createdAt),
                style: TextStyle(fontSize: 13, color: subColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // 内容
        Text(
          post.content,
          style: TextStyle(
            fontSize: 17,
            height: 1.6,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        // 底部信息
        Row(
          children: [
            _buildUserAvatar(post.userName, isDark: isDark),
            const SizedBox(width: 8),
            Text(post.userName, style: TextStyle(fontSize: 13, color: subColor)),
            const Spacer(),
            _buildActionIcon(Icons.favorite_border, '${post.likes}', subColor!),
            const SizedBox(width: 16),
            _buildActionIcon(Icons.chat_bubble_outline, '${post.comments}', subColor),
          ],
        ),
      ],
    );
  }

  /// 用户头像（取昵称首字）
  Widget _buildUserAvatar(String name, {bool isDark = false}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? Colors.white.withValues(alpha: 0.2)
            : const Color(0xFFF0F0F0),
      ),
      child: Center(
        child: Text(
          name.characters.first,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF999999),
          ),
        ),
      ),
    );
  }

  /// 操作图标
  Widget _buildActionIcon(IconData icon, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(count, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  /// 渐变色背景（基于用户名 hash 选择）
  Widget _buildGradientBg(DailySignPost post) {
    final index = post.userName.hashCode.abs() % cardGradients.length;
    final colors = cardGradients[index];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }

  /// 焦点卡片 — 空白
  Widget _buildFocusCardEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 48, color: const Color(0xFFC0B0A0)),
          const SizedBox(height: 12),
          Text('还没有日签', style: TextStyle(fontSize: 16, color: const Color(0xFF8B7355).withValues(alpha: 0.6))),
          const SizedBox(height: 6),
          Text(
            '点击右上角 + 贴一张便签',
            style: TextStyle(fontSize: 13, color: const Color(0xFF8B7355).withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 签到打卡
  // ═══════════════════════════════════════════════════════

  Widget _buildSignInSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF0), // 便签纸色
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 图钉
          Positioned(top: -4, left: 0, right: 0, child: Center(child: _buildPin())),
          Column(
        children: [
          // 进度条（4段 + 填充动画）
          Row(
            children: [
              _buildProgressSegment('签到1天', _consecutiveDays >= 1),
              const SizedBox(width: 4),
              _buildProgressSegment('连签2天', _consecutiveDays >= 2),
              const SizedBox(width: 4),
              _buildProgressSegment('连签3天', _consecutiveDays >= 3),
              const SizedBox(width: 4),
              _buildProgressSegment('连签7天', _consecutiveDays >= 7),
            ],
          ),
          const SizedBox(height: 16),
          // 签到按钮（带缩放反馈）
          GestureDetector(
            onTap: _isSignedToday
                ? null
                : () {
                    _doSign();
                    // 缩放动画反馈
                    setState(() => _signButtonScale = 0.95);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) setState(() => _signButtonScale = 1.0);
                    });
                  },
            child: AnimatedScale(
              scale: _signButtonScale,
              duration: const Duration(milliseconds: 100),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isSignedToday ? const Color(0xFFE0E0E0) : _themeColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: _isSignedToday
                      ? null
                      : [
                          BoxShadow(
                            color: _themeColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    _isSignedToday ? '今日已签，明天再来' : '立即签到',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isSignedToday ? Colors.grey[600] : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _consecutiveDays > 0 ? '已连续签到 $_consecutiveDays 天' : '',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
          ),
        ],
      ),
    );
  }

  /// 执行签到
  Future<void> _doSign() async {
    debugPrint('[签到] 按钮被点击');
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    int newConsecutive;
    if (_lastSignDate != null) {
      final lastDate = DateTime(_lastSignDate!.year, _lastSignDate!.month, _lastSignDate!.day);
      final diff = todayDate.difference(lastDate).inDays;
      if (diff == 1) {
        final manualData = await SignStorage.loadData();
        newConsecutive = manualData.consecutiveDays + 1;
      } else if (diff > 1) {
        newConsecutive = 1;
      } else {
        return;
      }
    } else {
      newConsecutive = 1;
    }

    debugPrint('[签到] 保存签到: consecutiveDays=$newConsecutive');
    await SignStorage.saveSign(newConsecutive);
    await _loadSignData();
  }

  /// 进度条分段（AnimatedContainer 实现从左到右填充过渡）
  Widget _buildProgressSegment(String label, bool isActive) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? _themeColor : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? _themeColor : Colors.grey[400],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Tab 切换
  // ═══════════════════════════════════════════════════════

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab(0, '推荐'),
          const SizedBox(width: 24),
          _buildTab(1, '我的'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 网格：推荐
  // ═══════════════════════════════════════════════════════

  Widget _buildRecommendGridSliver() {
    final posts = _recommendPosts;
    final left = <DailySignPost>[], right = <DailySignPost>[];
    for (int i = 0; i < posts.length; i++) {
      (i.isEven ? left : right).add(posts[i]);
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: List.generate(left.length, (i) =>
            Padding(padding: const EdgeInsets.only(bottom: 20), child: _buildLiteraryCard(left[i], i * 2))))),
          const SizedBox(width: 16),
          Expanded(child: Column(children: List.generate(right.length, (i) =>
            Padding(padding: const EdgeInsets.only(bottom: 20), child: _buildLiteraryCard(right[i], i * 2 + 1))))),
        ]),
      ),
    );
  }

  Widget _buildLiteraryCard(DailySignPost post, int index) {
    final rotation = _stickyRotation(index);
    final paperColor = _paperColors[index % _paperColors.length];
    final faved = _favSigns.contains('${post.content}_${post.userName}');

    return Transform.rotate(angle: rotation, child: GestureDetector(onTap: () => _navigateToDetail(post), child: Container(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
      decoration: BoxDecoration(color: paperColor, borderRadius: BorderRadius.circular(5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(2, 2))]),
      child: Stack(clipBehavior: Clip.none, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(post.content, style: const TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF4A3728))),
          const SizedBox(height: 10),
          Row(children: [
            Text(post.userName, style: const TextStyle(fontSize: 11, color: Color(0xFFA09080))),
            const Spacer(),
            GestureDetector(onTap: () => _toggleFav(post), child: Icon(faved ? Icons.star : Icons.star_outline, size: 15, color: faved ? const Color(0xFFFFB800) : const Color(0xFFCCCCCC))),
          ]),
        ]),
        Positioned(top: -2, left: 0, right: 0, child: Center(child: _buildPin())),
      ]),
    )));
  }

  void _toggleFav(DailySignPost post) async {
    final key = '${post.content}_${post.userName}';
    final f = _favSigns.contains(key);
    await FavoriteStorage.toggleSign(post.content, post.userName, post.likes, post.comments, post.createdAt);
    setState(() { if (f) _favSigns.remove(key); else _favSigns.add(key); });
  }

  /// 我的日签
  Widget _buildMyGridSliver() {
    if (_myPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(children: [
            Icon(Icons.sticky_note_2_outlined, size: 48, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('还没有发布过日签', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5))),
          ]),
        ),
      );
    }

    final posts = _myPosts;
    final left = <DailySignPost>[], right = <DailySignPost>[];
    for (int i = 0; i < posts.length; i++) {
      (i.isEven ? left : right).add(posts[i]);
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: List.generate(left.length, (i) =>
            Padding(padding: const EdgeInsets.only(bottom: 20), child: _buildLiteraryCard(left[i], i * 2))))),
          const SizedBox(width: 16),
          Expanded(child: Column(children: List.generate(right.length, (i) =>
            Padding(padding: const EdgeInsets.only(bottom: 20), child: _buildLiteraryCard(right[i], i * 2 + 1))))),
        ]),
      ),
    );
  }

  /// 便签卡片（旋转 + 图钉 + 纸质感）
  Widget _buildStickyNote(DailySignPost post, int index) {
    final rotation = _stickyRotation(index);
    final paperColor = _paperColors[index % _paperColors.length];

    return Transform.rotate(
      angle: rotation,
      child: Container(
        decoration: BoxDecoration(
          color: paperColor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 便签内容
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 22, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文字内容
                  Expanded(
                    child: Text(
                      post.content,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF4A3728),
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 底部信息
                  Row(
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(fontSize: 10, color: Color(0xFFA09080)),
                      ),
                      const Spacer(),
                      Text(
                        '${post.likes}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFFC0B0A0)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.favorite, size: 10, color: Color(0xFFD4A0A0)),
                    ],
                  ),
                ],
              ),
            ),
            // 图钉（顶部居中）
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: Center(child: _buildPin()),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 工具方法
  // ═══════════════════════════════════════════════════════

  String _getMonthYear(DateTime date) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[date.month - 1]}.${date.year}';
  }

  // ═══════════════════════════════════════════════════════
  // 便签墙工具方法
  // ═══════════════════════════════════════════════════════

  /// 根据 index 生成固定的微旋转角度（±3°），同 index 始终同角度
  double _stickyRotation(int index) {
    final hash = index.hashCode.abs();
    // -3° ~ +3°，避开 0°（太端正不像便签）
    final deg = (hash % 7) - 3; // -3, -2, -1, 0, 1, 2, 3
    return deg * 0.0174533; // 转弧度
  }

  /// 图钉装饰
  Widget _buildPin() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF8B5E3C),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 3,
            offset: const Offset(1, 2),
          ),
        ],
      ),
    );
  }

  /// 便签纸颜色池（柔和暖色系）
  static const _paperColors = [
    Color(0xFFFFFEF0), // 鹅黄
    Color(0xFFFFF8EC), // 米白
    Color(0xFFFFF3E0), // 暖橙白
    Color(0xFFFDF8F0), // 奶白
    Color(0xFFFFFAF0), // 象牙
    Color(0xFFFFF5EE), // 贝壳白
  ];
}
