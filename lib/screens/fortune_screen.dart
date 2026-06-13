import 'package:flutter/material.dart';
import 'dart:math';
import 'zodiac_detail_screen.dart';
import '../utils/smooth_route.dart';
import '../widgets/responsive_app_bar.dart';
import '../main.dart';

class FortuneScreen extends StatefulWidget {
  const FortuneScreen({super.key});

  @override
  State<FortuneScreen> createState() => _FortuneScreenState();
}

class _FortuneScreenState extends State<FortuneScreen> {
  Color get _tc => ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
  int _selectedTab = 0; // 0: 塔罗, 1: 星座, 2: 八字
  int? _drawnCardIndex;

  // 简单的淡入切换（弃用 3D 翻牌，避免 GPU shader 编译掉帧）
  bool _showFront = false;

  // 缓存牌面 Widget（同一张牌全天不变，避免重复构建）
  Widget? _cachedCardFront;
  Widget? _cachedCardBack;

  // 八字
  Map<String, String>? _baziResult;

  // 完整 78 张塔罗牌
  static const _tarotCards = [
    // ═══ 大阿尔卡纳 22 张 ═══
    {'name': '愚者', 'emoji': '🃏', 'meaning': '新的开始，冒险精神，相信未知的旅程'},
    {'name': '魔术师', 'emoji': '🎩', 'meaning': '创造力，意志力，你有能力将想法变为现实'},
    {'name': '女祭司', 'emoji': '🌙', 'meaning': '直觉，智慧，静下心来听听内心的声音'},
    {'name': '皇后', 'emoji': '👑', 'meaning': '丰盛，滋养，享受生活的美好与温柔'},
    {'name': '皇帝', 'emoji': '🏰', 'meaning': '权威，秩序，用坚定的意志掌控局面'},
    {'name': '教皇', 'emoji': '📿', 'meaning': '信仰，传统，寻求智慧的引导与内心的真理'},
    {'name': '恋人', 'emoji': '💕', 'meaning': '爱情，选择，倾听内心做出重要决定'},
    {'name': '战车', 'emoji': '🏎️', 'meaning': '胜利，决心，克服一切障碍勇往直前'},
    {'name': '力量', 'emoji': '🦁', 'meaning': '勇气，耐心，温柔比强硬更有力量'},
    {'name': '隐者', 'emoji': '🏮', 'meaning': '内省，独处，在安静中找到真正的答案'},
    {'name': '命运之轮', 'emoji': '🎡', 'meaning': '转变，机遇，命运正在转动，好运即将到来'},
    {'name': '正义', 'emoji': '⚖️', 'meaning': '公平，真相，种什么因得什么果'},
    {'name': '倒吊人', 'emoji': '🙃', 'meaning': '换个角度看世界，暂时的等待是一种修行'},
    {'name': '死神', 'emoji': '💀', 'meaning': '结束与新生，放下旧的才能迎来新的'},
    {'name': '节制', 'emoji': '🌊', 'meaning': '平衡，调和，凡事适可而止刚刚好'},
    {'name': '恶魔', 'emoji': '😈', 'meaning': '欲望，束缚，看清什么在困住你'},
    {'name': '高塔', 'emoji': '🗼', 'meaning': '剧变，觉醒，崩塌之后才能重建'},
    {'name': '星星', 'emoji': '⭐', 'meaning': '希望，灵感，相信未来会更好'},
    {'name': '月亮', 'emoji': '🌙', 'meaning': '潜意识，幻象，别被表象迷惑了双眼'},
    {'name': '太阳', 'emoji': '☀️', 'meaning': '快乐，成功，今天是属于你的好日子'},
    {'name': '审判', 'emoji': '📯', 'meaning': '觉醒，召唤，是时候回应内心的使命了'},
    {'name': '世界', 'emoji': '🌍', 'meaning': '完成，圆满，一个周期即将完美收官'},
    // ═══ 权杖 14 张 ═══
    {'name': '权杖Ace', 'emoji': '🪄', 'meaning': '新的创意火花，行动的开始，充满能量与激情'},
    {'name': '权杖二', 'emoji': '🪄', 'meaning': '规划未来，掌控全局，做出重要抉择的时刻'},
    {'name': '权杖三', 'emoji': '🪄', 'meaning': '远见卓识，扩展视野，等待成果的到来'},
    {'name': '权杖四', 'emoji': '🪄', 'meaning': '庆祝与和谐，安稳的阶段，享受生活的果实'},
    {'name': '权杖五', 'emoji': '🪄', 'meaning': '竞争与冲突，不同意见的碰撞，良性竞争'},
    {'name': '权杖六', 'emoji': '🪄', 'meaning': '胜利与认可，努力得到回报，自信前行'},
    {'name': '权杖七', 'emoji': '🪄', 'meaning': '坚守立场，面对挑战不退缩，你比想象中强大'},
    {'name': '权杖八', 'emoji': '🪄', 'meaning': '快速进展，事情加速推进，时机成熟了'},
    {'name': '权杖九', 'emoji': '🪄', 'meaning': '最后的坚持，已经走了这么远，再撑一下'},
    {'name': '权杖十', 'emoji': '🪄', 'meaning': '负担过重，学会放下和委托，别一个人扛'},
    {'name': '权杖侍从', 'emoji': '🪄', 'meaning': '好奇心驱使的探索，新消息即将到来'},
    {'name': '权杖骑士', 'emoji': '🪄', 'meaning': '行动派，热情冲刺，但别忘了看路'},
    {'name': '权杖皇后', 'emoji': '🪄', 'meaning': '自信与温暖，用阳光般的魅力感染他人'},
    {'name': '权杖国王', 'emoji': '🪄', 'meaning': '领导力与远见，掌控你的人生方向'},
    // ═══ 圣杯 14 张 ═══
    {'name': '圣杯Ace', 'emoji': '🍷', 'meaning': '新感情的萌芽，爱的可能，情感的丰盈'},
    {'name': '圣杯二', 'emoji': '🍷', 'meaning': '灵魂伴侣的相遇，深度连接，互相理解'},
    {'name': '圣杯三', 'emoji': '🍷', 'meaning': '欢庆与友谊，分享快乐，社交的好时光'},
    {'name': '圣杯四', 'emoji': '🍷', 'meaning': '对现状的不满，忽略了身边的机会，换个视角'},
    {'name': '圣杯五', 'emoji': '🍷', 'meaning': '失落与遗憾，但仍有两杯没倒，希望还在'},
    {'name': '圣杯六', 'emoji': '🍷', 'meaning': '美好回忆，纯真时光，旧友重逢的喜悦'},
    {'name': '圣杯七', 'emoji': '🍷', 'meaning': '选择太多让人迷茫，分清幻想与现实'},
    {'name': '圣杯八', 'emoji': '🍷', 'meaning': '离开舒适区，追寻更高的精神目标'},
    {'name': '圣杯九', 'emoji': '🍷', 'meaning': '愿望成真，内心的满足，你值得拥有'},
    {'name': '圣杯十', 'emoji': '🍷', 'meaning': '圆满的家庭与情感，幸福就在身边'},
    {'name': '圣杯侍从', 'emoji': '🍷', 'meaning': '敏感而富有想象力，倾听内心的声音'},
    {'name': '圣杯骑士', 'emoji': '🍷', 'meaning': '浪漫的追求者，跟随心的方向前进'},
    {'name': '圣杯皇后', 'emoji': '🍷', 'meaning': '慈爱与直觉，用温柔的力量治愈一切'},
    {'name': '圣杯国王', 'emoji': '🍷', 'meaning': '情感成熟与包容，做情绪的主人'},
    // ═══ 宝剑 14 张 ═══
    {'name': '宝剑Ace', 'emoji': '⚔️', 'meaning': '清晰的思维，真理的突破，新的想法诞生'},
    {'name': '宝剑二', 'emoji': '⚔️', 'meaning': '两难选择，内心的僵局，需要更多信息'},
    {'name': '宝剑三', 'emoji': '⚔️', 'meaning': '心碎与悲伤，接受痛苦才能治愈'},
    {'name': '宝剑四', 'emoji': '⚔️', 'meaning': '休息与恢复，暂停不是放弃，是积蓄力量'},
    {'name': '宝剑五', 'emoji': '⚔️', 'meaning': '冲突与失败，赢了一时输了关系，反思'},
    {'name': '宝剑六', 'emoji': '⚔️', 'meaning': '渡过低谷，缓慢离开困境，未来会更好'},
    {'name': '宝剑七', 'emoji': '⚔️', 'meaning': '策略与机敏，用智慧解决问题，灵活应变'},
    {'name': '宝剑八', 'emoji': '⚔️', 'meaning': '自我设限，你比想象中自由，解开束缚'},
    {'name': '宝剑九', 'emoji': '⚔️', 'meaning': '焦虑与噩梦，心里的担忧可能比现实更可怕'},
    {'name': '宝剑十', 'emoji': '⚔️', 'meaning': '终结与重生，跌到谷底后只能往上走了'},
    {'name': '宝剑侍从', 'emoji': '⚔️', 'meaning': '求知若渴，理性观察，保持好奇心'},
    {'name': '宝剑骑士', 'emoji': '⚔️', 'meaning': '果断行动，思维敏捷，选定目标就冲刺'},
    {'name': '宝剑皇后', 'emoji': '⚔️', 'meaning': '智慧与独立，用逻辑和理性看清真相'},
    {'name': '宝剑国王', 'emoji': '⚔️', 'meaning': '权威的判断力，理性决策，做自己的法官'},
    // ═══ 星币 14 张 ═══
    {'name': '星币Ace', 'emoji': '⭐', 'meaning': '新的财富机会，踏实的开始，物质上的好消息'},
    {'name': '星币二', 'emoji': '⭐', 'meaning': '平衡多件事，灵活应对生活中的变化'},
    {'name': '星币三', 'emoji': '⭐', 'meaning': '团队合作，精益求精，技能在积累中提升'},
    {'name': '星币四', 'emoji': '⭐', 'meaning': '守财与稳固，安全感重要但别太封闭自己'},
    {'name': '星币五', 'emoji': '⭐', 'meaning': '暂时的匮乏，不只是钱还有关怀，寻求帮助'},
    {'name': '星币六', 'emoji': '⭐', 'meaning': '慷慨与分享，给予和接受的平衡'},
    {'name': '星币七', 'emoji': '⭐', 'meaning': '耐心等待收获，评估之前的努力是否值得'},
    {'name': '星币八', 'emoji': '⭐', 'meaning': '专注与精进，日复一日的练习终会开花'},
    {'name': '星币九', 'emoji': '⭐', 'meaning': '独立与享受，你靠自己赢得了美好的生活'},
    {'name': '星币十', 'emoji': '⭐', 'meaning': '家族的传承，稳固的根基，长久的富足'},
    {'name': '星币侍从', 'emoji': '⭐', 'meaning': '学习实用技能，踏实起步，一步一脚印'},
    {'name': '星币骑士', 'emoji': '⭐', 'meaning': '稳重可靠，按计划推进，慢就是快'},
    {'name': '星币皇后', 'emoji': '⭐', 'meaning': '丰盛与滋养，用实际的关怀温暖身边的人'},
    {'name': '星币国王', 'emoji': '⭐', 'meaning': '财富的掌控者，稳健经营，做物质的主人'},
  ];

  @override
  void initState() {
    super.initState();
    // 预构建牌背，确保首次渲染时 GPU shader 已编译
    _cachedCardBack = _buildCardBack();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 点击牌背 → 翻到牌面；点击牌面 → 翻回牌背（可多次翻转）
  void _toggleCard() {
    if (_showFront) {
      // 翻回牌背
      setState(() => _showFront = false);
      return;
    }

    final now = DateTime.now();
    // 按年月洗牌，确保每月牌序不同
    final shuffleSeed = now.year * 100 + now.month;
    final shuffled = List.generate(_tarotCards.length, (i) => i)
      ..shuffle(Random(shuffleSeed));
    final dayOfYear = int.parse('${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}')
        .remainder(1000);
    final index = shuffled[(dayOfYear + now.month * 7) % _tarotCards.length];

    // 预构建牌面
    final prebuiltFront = _buildCardFrontForIndex(index);

    setState(() {
      _drawnCardIndex = index;
      _cachedCardFront = prebuiltFront;
      _showFront = true;
    });
  }

  /// 计算星座今日星级（确保每天每个星座都不同）
  int _getZodiacDailyScore(int index) {
    final element = _zodiacElements[index];
    final now = DateTime.now();
    final month = now.month;

    String season;
    if (month >= 3 && month <= 5) season = '春';
    else if (month >= 6 && month <= 8) season = '夏';
    else if (month >= 9 && month <= 11) season = '秋';
    else season = '冬';

    const harmonyMap = {'火': ['春', '夏'], '土': ['夏', '秋'], '风': ['春', '秋'], '水': ['秋', '冬']};
    final harmony = harmonyMap[element]?.contains(season) ?? true;
    int base = harmony ? 3 : 2;

    const dayRuler = {1: '水', 2: '火', 3: '风', 4: '火', 5: '土', 6: '土', 7: '火'};
    if (dayRuler[now.weekday] == element) base++;

    // 每日波动：-2 到 +2，基于日期+星座，确保每天变化
    final dayVariance = ((now.year * 397 + now.month * 31 + now.day) * 7 + index * 13) % 5 - 2;

    return (base + dayVariance).clamp(2, 5);
  }

  // 12星座对应元素（和 zodiac_detail_screen 一致）
  static const _zodiacElements = ['火', '土', '风', '水', '火', '土', '风', '水', '火', '土', '风', '水'];

  // 预建星级图标（避免每次 build 重建 List.generate）
  static const _starFull = Icon(Icons.star, size: 12, color: Color(0xFFFFB347));
  static const _starEmpty = Icon(Icons.star_border, size: 12, color: Color(0xFFE8E8E8));
  static const _starFull14 = Icon(Icons.star, size: 14, color: Color(0xFFFFB347));
  static const _starEmpty14 = Icon(Icons.star_border, size: 14, color: Color(0xFFE0E0E0));

  /// 点击星座卡片 → 跳转全屏详情页
  void _showZodiacDetail(int index) {
    Navigator.push(
      context,
      SmoothRoute(builder: (_) => ZodiacDetailScreen(zodiacIndex: index)),
    );
  }

  /// 打开八字日期选择器（四滚轮：年/月/日/时辰）
  void _showBaziDatePicker() {
    final now = DateTime.now();
    final selYear = ValueNotifier(2000);
    final selMonth = ValueNotifier(6);
    final selDay = ValueNotifier(15);
    final selHour = ValueNotifier(6);
    final yearCtrl = FixedExtentScrollController(initialItem: 2000 - 1940);
    final monthCtrl = FixedExtentScrollController(initialItem: 5);
    final dayCtrl = FixedExtentScrollController(initialItem: 14);
    final hourCtrl = FixedExtentScrollController(initialItem: 6);
    const hourNames = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    const hourRanges = ['23-1', '1-3', '3-5', '5-7', '7-9', '9-11', '11-13', '13-15', '15-17', '17-19', '19-21', '21-23'];

    int daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

    // 控制滚轮淡入 + 预热滚动
    final wheelOpacity = ValueNotifier<double>(0.0);
    bool warmedUp = false;

    void _warmupWheels() {
      if (warmedUp) return;
      warmedUp = true;
      // 微滚动预热：强制 ListWheelScrollView 渲染圆柱面，编译所有 shader
      for (final ctrl in [yearCtrl, monthCtrl, dayCtrl, hourCtrl]) {
        final cur = ctrl.selectedItem;
        ctrl.jumpToItem(cur + 1);
        Future.delayed(const Duration(milliseconds: 30), () {
          ctrl.jumpToItem(cur);
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          wheelOpacity.value = 1.0;
          // 淡入后再预热滚动渲染管线
          Future.delayed(const Duration(milliseconds: 200), _warmupWheels);
        });

        return Container(
            height: MediaQuery.of(context).size.height * 0.48,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Color(0xFF999999), fontSize: 15))),
                      ListenableBuilder(
                        listenable: Listenable.merge([selYear, selMonth, selDay, selHour]),
                        builder: (_, __) => Column(
                          children: [
                            const Text('出生日期 & 时辰', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                            Text('${selYear.value}年${selMonth.value}月${selDay.value}日 ${hourNames[selHour.value]}时', style: TextStyle(fontSize: 12, color: _tc)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final birthday = DateTime(selYear.value, selMonth.value, selDay.value);
                          final hour = selHour.value;
                          Navigator.pop(ctx);
                          // 等滚轮收起动画完成后再计算和显示结果
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() => _baziResult = _calculateBazi(birthday, hour));
                          });
                        },
                        child: Text('确定', style: TextStyle(color: _tc, fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  // 滚轮淡入：初始透明避免与弹窗入场动画竞争 GPU
                  child: ValueListenableBuilder<double>(
                    valueListenable: wheelOpacity,
                    builder: (_, opacity, child) => AnimatedOpacity(
                      opacity: opacity,
                      duration: const Duration(milliseconds: 150),
                      child: child,
                    ),
                    child: Row(
                      children: [
                        _wheel('年', now.year - 1940 + 1, yearCtrl, (i) {
                          selYear.value = 1940 + i;
                          final maxDay = daysInMonth(selYear.value, selMonth.value);
                          if (selDay.value > maxDay) { selDay.value = maxDay; dayCtrl.jumpToItem(maxDay - 1); }
                        }, (i) => '${1940 + i}'),
                        _wheel('月', 12, monthCtrl, (i) {
                          selMonth.value = i + 1;
                          final maxDay = daysInMonth(selYear.value, selMonth.value);
                          if (selDay.value > maxDay) { selDay.value = maxDay; dayCtrl.jumpToItem(maxDay - 1); }
                        }, (i) => '${i + 1}月'),
                        _wheel('日', daysInMonth(selYear.value, selMonth.value), dayCtrl,
                          (i) => selDay.value = i + 1, (i) => '${i + 1}日'),
                        _wheel('时', 12, hourCtrl,
                          (i) => selHour.value = i, (i) => '${hourNames[i]} ${hourRanges[i]}', labelWidth: 28),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
      },
    );
  }

  /// 单个滚轮
  Widget _wheel(String label, int count, FixedExtentScrollController ctrl, void Function(int) onChanged, String Function(int) display, {double labelWidth = 20}) {
    return Expanded(
      child: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(width: labelWidth, child: Center(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))))),
          Expanded(
            child: RepaintBoundary(
              child: ListWheelScrollView.useDelegate(
                controller: ctrl,
                itemExtent: 48, diameterRatio: 2.0,
                useMagnifier: true, magnification: 1.2,
                overAndUnderCenterOpacity: 0.35,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: count,
                  builder: (context, i) => Center(child: Text(display(i), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 计算八字命盘（节气定月 + 时辰柱 + 十神 + 纳音）
  Map<String, String> _calculateBazi(DateTime birthday, int hourIndex) {
    const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    const branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    const zodiacAnimals = ['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪'];
    const elements = ['木', '木', '火', '火', '土', '土', '金', '金', '水', '水'];
    const branchElements = ['水', '土', '木', '木', '土', '火', '火', '土', '金', '金', '土', '水'];
    const nayin = [
      '海中金', '炉中火', '大林木', '路旁土', '剑锋金', '山头火',
      '涧下水', '城头土', '白蜡金', '杨柳木', '泉中水', '屋上土',
      '霹雳火', '松柏木', '流年水', '砂石金', '山下火', '平地木',
      '壁上土', '金箔金', '覆灯火', '天河水', '大驿土', '钗钏金',
      '桑柘木', '柘榴木', '大海水', '石榴木', '大海水', '海中金',
    ];
    // 节气近似日期（month, day），定义12个月建的起点
    const solarTerms = [
      [2, 4],  // 立春 → 寅月
      [3, 6],  // 惊蛰 → 卯月
      [4, 5],  // 清明 → 辰月
      [5, 6],  // 立夏 → 巳月
      [6, 6],  // 芒种 → 午月
      [7, 7],  // 小暑 → 未月
      [8, 8],  // 立秋 → 申月
      [9, 8],  // 白露 → 酉月
      [10, 8], // 寒露 → 戌月
      [11, 8], // 立冬 → 亥月
      [12, 7], // 大雪 → 子月
      [1, 6],  // 小寒 → 丑月
    ];

    // 年柱（立春为界：立春前属上一年）
    final lichun = DateTime(birthday.year, 2, 4); // 立春近似在2月4日
    final effectiveYear = birthday.isBefore(lichun) ? birthday.year - 1 : birthday.year;
    final yearStemIdx = (effectiveYear - 4) % 10;
    final yearBranchIdx = (effectiveYear - 4) % 12;
    final nayinIdx = (effectiveYear - 4) % 30;

    // 月柱（按节气）
    int monthBranchIdx = 1; // 默认丑月
    for (int i = 0; i < 12; i++) {
      final term = solarTerms[i];
      final termDate = DateTime(birthday.year, term[0], term[1]);
      if (birthday.isAfter(termDate.subtract(const Duration(days: 1)))) {
        monthBranchIdx = (i + 2) % 12; // 寅月→2
      }
    }
    // 小寒在1月，如果生日在1月1日-1月5日，仍属前一年的丑月
    final xiaoHan = DateTime(birthday.year, 1, 6);
    if (birthday.isBefore(xiaoHan)) monthBranchIdx = 1; // 丑月

    const monthStemBases = [2, 4, 6, 8, 0]; // 五虎遁
    final monthBase = monthStemBases[yearStemIdx % 5];
    final monthStemIdx = (monthBase + (monthBranchIdx - 2 + 12) % 12) % 10;

    // 日柱
    final baseDate = DateTime(2000, 1, 1);
    final daysDiff = birthday.difference(baseDate).inDays;
    final dayStemIdx = daysDiff % 10;
    final dayBranchIdx = daysDiff % 12;

    // 时柱（用户选中的时辰）
    final hourBranchIdx = hourIndex;
    // 时干：五鼠遁 — 甲己日→甲子(0), 乙庚日→丙子(2), 丙辛日→戊子(4), 丁壬日→庚子(6), 戊癸日→壬子(8)
    const timeStemBases = [0, 2, 4, 6, 8];
    final hourStemIdx = (timeStemBases[dayStemIdx % 5] + hourBranchIdx) % 10;

    // 十神
    final pillarIdxs = [yearStemIdx, monthStemIdx, dayStemIdx, hourStemIdx];
    final tenGods = <String>[];
    for (int i = 0; i < 4; i++) {
      tenGods.add(_tenGod(dayStemIdx, pillarIdxs[i]));
    }

    // 五行统计
    final allStems = [yearStemIdx, monthStemIdx, dayStemIdx, hourStemIdx];
    final allBranches = [yearBranchIdx, monthBranchIdx, dayBranchIdx, hourBranchIdx];
    final wuxingCount = {'金': 0, '木': 0, '水': 0, '火': 0, '土': 0};
    for (final s in allStems) wuxingCount[elements[s]] = (wuxingCount[elements[s]] ?? 0) + 1;
    for (final b in allBranches) wuxingCount[branchElements[b]] = (wuxingCount[branchElements[b]] ?? 0) + 1;

    final dayMaster = elements[dayStemIdx];
    final strong = wuxingCount[dayMaster]! >= 3;
    final rizhuStrength = strong ? '日主偏强，意志坚定，有领导力' : '日主中和，思维灵活，善于适应';
    final missing = wuxingCount.entries.where((e) => e.value == 0).map((e) => e.key).toList();

    // 十神简评
    final yearTG = tenGods[0];
    final monthTG = tenGods[1];
    final hourTG = tenGods[3];

    return {
      '生肖': zodiacAnimals[yearBranchIdx],
      '纳音': nayin[nayinIdx],
      '年柱': '${stems[yearStemIdx]}${branches[yearBranchIdx]}',
      '月柱': '${stems[monthStemIdx]}${branches[monthBranchIdx]}',
      '日柱': '${stems[dayStemIdx]}${branches[dayBranchIdx]}',
      '时柱': '${stems[hourStemIdx]}${branches[hourBranchIdx]}',
      '日主五行': dayMaster,
      '日主简评': rizhuStrength,
      '五行缺失': missing.isEmpty ? '五行俱全，命格平衡' : '五行缺${missing.join("、")}',
      '年干支': '${stems[yearStemIdx]}${branches[yearBranchIdx]}年',
      '月干支': '${stems[monthStemIdx]}${branches[monthBranchIdx]}月',
      '日干支': '${stems[dayStemIdx]}${branches[dayBranchIdx]}日',
      '时干支': '${stems[hourStemIdx]}${branches[hourBranchIdx]}时',
      '五行_金': '${wuxingCount['金'] ?? 0}',
      '五行_木': '${wuxingCount['木'] ?? 0}',
      '五行_水': '${wuxingCount['水'] ?? 0}',
      '五行_火': '${wuxingCount['火'] ?? 0}',
      '五行_土': '${wuxingCount['土'] ?? 0}',
      '年十神': yearTG,
      '月十神': monthTG,
      '日十神': '日主',
      '时十神': hourTG,
      '十神简评': '年柱$yearTG，月柱$monthTG，时柱$hourTG。日主${dayMaster}命，${rizhuStrength}。',
    };
  }

  /// 十神计算：以日干为"我"，判断其他天干与我的关系
  String _tenGod(int dayStemIdx, int otherStemIdx) {
    const stemElements = ['木', '木', '火', '火', '土', '土', '金', '金', '水', '水'];
    final dayElem = stemElements[dayStemIdx];
    final otherElem = stemElements[otherStemIdx];
    final dayYin = dayStemIdx % 2; // 0=阳, 1=阴
    final otherYin = otherStemIdx % 2;
    final sameYin = dayYin == otherYin;

    if (dayElem == otherElem) return sameYin ? '比肩' : '劫财';

    // 生克关系
    const generate = {'木': '火', '火': '土', '土': '金', '金': '水', '水': '木'};
    const control = {'木': '土', '土': '水', '水': '火', '火': '金', '金': '木'};

    if (generate[otherElem] == dayElem) return sameYin ? '偏印' : '正印';     // 他生我
    if (generate[dayElem] == otherElem) return sameYin ? '食神' : '伤官';     // 我生他
    if (control[dayElem] == otherElem) return sameYin ? '偏财' : '正财';     // 我克他
    if (control[otherElem] == dayElem) return sameYin ? '七杀' : '正官';     // 他克我

    return '比肩';
  }

  @override
  Widget build(BuildContext context) {
    // 顶部安全距离：屏幕高度的 4%
    final safeTop = ResponsiveAppBar.safeTop(context);

    return Scaffold(
      backgroundColor: appBgColor(context),
      body: Padding(
        padding: EdgeInsets.fromLTRB(24, safeTop + 16, 24, 24),
        child: Column(
          children: [
            // 顶部
            _buildHeader(),
            const SizedBox(height: 20),
            // Tab 切换
            _buildTabBar(),
            const SizedBox(height: 24),
            // 内容
            Expanded(
              child: _selectedTab == 0
                  ? _buildTarotContent()
                  : _selectedTab == 1
                      ? _buildZodiacContent()
                      : _buildBaziContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '运势',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '探索命运的指引',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Row(
      children: [
        _buildTab(0, '🃏', '塔罗牌'),
        const SizedBox(width: 12),
        _buildTab(1, '⭐', '星座'),
        const SizedBox(width: 12),
        _buildTab(2, '📅', '八字'),
      ],
    );
  }

  Widget _buildTab(int index, String icon, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTarotContent() {
    final hasCard = _drawnCardIndex != null;

    return Column(
      children: [
        // ═══ 塔罗牌卡片区 ═══
        // 使用 AnimatedCrossFade 淡入切换：同时持有正反面 widget，GPU 提前编译 shader
        GestureDetector(
          onTap: _toggleCard,
          child: RepaintBoundary(
            child: SizedBox(
              width: double.infinity,
              height: 360,
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 500),
                crossFadeState: _showFront
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: _cachedCardBack!,
                secondChild: _cachedCardFront ?? _cachedCardBack!,
                firstCurve: Curves.easeOut,
                secondCurve: Curves.easeOut,
                sizeCurve: Curves.easeOut,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // ═══ 底部提示 ═══
        if (hasCard)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE082), width: 0.5),
            ),
            child: Row(
              children: [
                const Text('🔮', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '今日指引：${_tarotCards[_drawnCardIndex!]['meaning']}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6D4C41), height: 1.5),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 10),
                Text(
                  '点击塔罗牌，抽取今日指引\n再次点击可翻回牌背',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 牌背（金色花纹 + 神秘感）
  Widget _buildCardBack() {
    return Container(
      width: double.infinity,
      height: 360,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1A0A2E).withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 外层金边方框
          Positioned(
            top: 24, left: 24, right: 24, bottom: 24,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1),
              ),
            ),
          ),
          // 内层菱形
          Transform.rotate(
            angle: 0.785,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.15), width: 1),
              ),
            ),
          ),
          // 中心图案
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 星星装饰
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _starDot(0), const SizedBox(width: 28),
                  _starDot(1), const SizedBox(width: 28),
                  _starDot(2),
                ],
              ),
              const SizedBox(height: 20),
              // 中心大符号
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [const Color(0xFFFFD700).withValues(alpha: 0.4), Colors.transparent],
                  ),
                ),
                child: const Center(
                  child: Text('✦', style: TextStyle(fontSize: 32, color: Color(0xFFFFD700))),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'THE TAROT',
                style: TextStyle(
                  fontSize: 13, letterSpacing: 6,
                  color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          // 四角装饰
          _cornerDeco(true, true),
          _cornerDeco(true, false),
          _cornerDeco(false, true),
          _cornerDeco(false, false),
        ],
      ),
    );
  }

  /// 预构建牌正面（传入卡牌索引，不依赖 _drawnCardIndex）
  Widget _buildCardFrontForIndex(int cardIndex) => _buildCardFrontContent(
    _tarotCards[cardIndex]['name']!,
    _tarotCards[cardIndex]['emoji']!,
    _tarotCards[cardIndex]['meaning']!,
    cardIndex,
  );

  Widget _buildCardFrontContent(String cardName, String cardEmoji, String cardMeaning, int cardNumber) {

    return Container(
      width: double.infinity,
      height: 360,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFEF9), Color(0xFFFFF8E7), Color(0xFFFFF3D6)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFFB8860B).withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8)),
          BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 0)),
        ],
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5), width: 2),
      ),
      child: Stack(
        children: [
          // 内边框
          Positioned(
            top: 16, left: 16, right: 16, bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4A017).withValues(alpha: 0.3), width: 1),
              ),
            ),
          ),
          // 左上：编号
          Positioned(
            top: 28, left: 28,
            child: Text(
              '${_cardLabel(cardNumber)}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFD4A017).withValues(alpha: 0.7)),
            ),
          ),
          // 右上：元素符号
          Positioned(
            top: 28, right: 28,
            child: Text('✦', style: TextStyle(fontSize: 16, color: const Color(0xFFFFD700).withValues(alpha: 0.6))),
          ),
          // 中心内容
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 大符号
                Text(cardEmoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                // 卡牌名
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF3D6), Color(0xFFFFF8E7), Color(0xFFFFF3D6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Text(
                    cardName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF4E342E)),
                  ),
                ),
                const SizedBox(height: 12),
                // 含义
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    cardMeaning.split('，').first,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.brown[300], height: 1.5, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          // 底部日期
          Positioned(
            bottom: 28, left: 0, right: 0,
            child: Center(
              child: Text(
                '${DateTime.now().year}.${DateTime.now().month}.${DateTime.now().day}  ·  今日专属',
                style: TextStyle(fontSize: 11, color: const Color(0xFFD4A017).withValues(alpha: 0.5), letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 角装饰
  Widget _cornerDeco(bool isTop, bool isLeft) {
    return Positioned(
      top: isTop ? 32 : null,
      bottom: isTop ? null : 32,
      left: isLeft ? 32 : null,
      right: isLeft ? null : 32,
      child: Container(
        width: 4, height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// 星星装饰点
  Widget _starDot(int index) {
    return Container(
      width: 6, height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withValues(alpha: 0.3 + index * 0.15),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.4), blurRadius: 6)],
      ),
    );
  }

  /// 大牌用罗马数字，小牌用数字
  static String _cardLabel(int n) {
    if (n < 22) {
      if (n == 0) return '0';
      const ones = ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX'];
      const tens = ['', 'X', 'XX'];
      if (n < 10) return ones[n];
      return tens[n ~/ 10] + ones[n % 10];
    }
    return '${n + 1}';
  }

  /// 计算当前日期属于哪个星座
  int _todayZodiacIndex() {
    final now = DateTime.now();
    final md = now.month * 100 + now.day;
    if (md >= 321 && md <= 419) return 0;  // 白羊
    if (md >= 420 && md <= 520) return 1;  // 金牛
    if (md >= 521 && md <= 621) return 2;  // 双子
    if (md >= 622 && md <= 722) return 3;  // 巨蟹
    if (md >= 723 && md <= 822) return 4;  // 狮子
    if (md >= 823 && md <= 922) return 5;  // 处女
    if (md >= 923 && md <= 1023) return 6; // 天秤
    if (md >= 1024 && md <= 1122) return 7; // 天蝎
    if (md >= 1123 && md <= 1221) return 8; // 射手
    if (md >= 1222 || md <= 119) return 9; // 摩羯(跨年)
    if (md >= 120 && md <= 218) return 10; // 水瓶
    return 11; // 双鱼
  }

  Widget _buildZodiacContent() {
    final zodiacs = [
      {'name': '白羊座', 'symbol': '♈', 'date': '3.21-4.19', 'element': '火'},
      {'name': '金牛座', 'symbol': '♉', 'date': '4.20-5.20', 'element': '土'},
      {'name': '双子座', 'symbol': '♊', 'date': '5.21-6.21', 'element': '风'},
      {'name': '巨蟹座', 'symbol': '♋', 'date': '6.22-7.22', 'element': '水'},
      {'name': '狮子座', 'symbol': '♌', 'date': '7.23-8.22', 'element': '火'},
      {'name': '处女座', 'symbol': '♍', 'date': '8.23-9.22', 'element': '土'},
      {'name': '天秤座', 'symbol': '♎', 'date': '9.23-10.23', 'element': '风'},
      {'name': '天蝎座', 'symbol': '♏', 'date': '10.24-11.22', 'element': '水'},
      {'name': '射手座', 'symbol': '♐', 'date': '11.23-12.21', 'element': '火'},
      {'name': '摩羯座', 'symbol': '♑', 'date': '12.22-1.19', 'element': '土'},
      {'name': '水瓶座', 'symbol': '♒', 'date': '1.20-2.18', 'element': '风'},
      {'name': '双鱼座', 'symbol': '♓', 'date': '2.19-3.20', 'element': '水'},
    ];

    final todayIdx = _todayZodiacIndex();
    final todayScore = _getZodiacDailyScore(todayIdx);

    return Column(
      children: [
        // 当前星座高亮条
        GestureDetector(
          onTap: () => _showZodiacDetail(todayIdx),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF8F9FF), Color(0xFFF0F4FF)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF5B8DEF).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Text(zodiacs[todayIdx]['symbol']!, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(zodiacs[todayIdx]['name']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B8DEF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('当前', style: TextStyle(fontSize: 10, color: Color(0xFF5B8DEF), fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(children: _buildStars(todayScore, 14)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
              ],
            ),
          ),
        ),
        // 12星座网格
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: zodiacs.length,
            itemBuilder: (context, index) {
              final score = _getZodiacDailyScore(index);
              final element = zodiacs[index]['element']!;
              final accentColor = _elementAccent(element);
              final isToday = index == todayIdx;

              return GestureDetector(
                onTap: () => _showZodiacDetail(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isToday ? Border.all(color: accentColor, width: 2) : null,
                    boxShadow: [
                      BoxShadow(
                        color: isToday
                            ? accentColor.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: isToday ? 12 : 6,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 符号
                      Text(zodiacs[index]['symbol']!, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 4),
                      // 星座名
                      Text(zodiacs[index]['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 2),
                      // 元素标签 + 日期
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(element, style: TextStyle(fontSize: 9, color: accentColor, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 4),
                          Text(zodiacs[index]['date']!, style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // 星级
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: _buildStars(score, 12)),
                    ],
                  ),
                ),
              );
              },
            ),
          ),
      ],
    );
  }

  Color _elementAccent(String element) {
    switch (element) {
      case '火': return const Color(0xFFFF6B6B);
      case '土': return const Color(0xFF8B7355);
      case '风': return const Color(0xFF87CEEB);
      case '水': return const Color(0xFF6495ED);
      default: return const Color(0xFF999999);
    }
  }

  /// 缓存的星级图标列表（避免每次 build 时 List.generate）
  static final Map<int, List<Widget>> _starCache12 = {
    for (int s = 0; s <= 5; s++) s: List.generate(5, (i) => i < s ? _starFull : _starEmpty as Widget),
  };
  static final Map<int, List<Widget>> _starCache14 = {
    for (int s = 0; s <= 5; s++) s: List.generate(5, (i) => i < s ? _starFull14 : _starEmpty14 as Widget),
  };

  List<Widget> _buildStars(int score, double size) {
    return (size <= 12 ? _starCache12 : _starCache14)[score.clamp(0, 5)]!;
  }

  Widget _buildBaziContent() {
    if (_baziResult != null) {
      final r = _baziResult!;
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ═══ 概要卡片 ═══
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C1810), Color(0xFF3E2723), Color(0xFF2C1810)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF3E2723).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  Text('🐾', style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 10),
                  Text('生肖${r['生肖']} · ${r['纳音']}命',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFFFF3E0))),
                  const SizedBox(height: 4),
                  Text('日主五行属${r['日主五行']}', style: TextStyle(fontSize: 14, color: const Color(0xFFFFF3E0).withValues(alpha: 0.7))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ═══ 四柱八字 ═══
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _whiteCard(),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.grid_view_rounded, size: 16, color: Color(0xFF8D6E63)),
                      const SizedBox(width: 6),
                      const Text('四柱八字', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _pillar('年柱', r['年柱']!, r['年干支']!, r['年十神']!),
                      _pillar('月柱', r['月柱']!, r['月干支']!, r['月十神']!),
                      _pillar('日柱', r['日柱']!, r['日干支']!, r['日十神']!),
                      _pillar('时柱', r['时柱']!, r['时干支']!, r['时十神']!),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Text('🔮', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(r['十神简评']!, style: const TextStyle(fontSize: 13, color: Color(0xFF4A148C), height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '日柱「${r['日柱']}」代表你自己。${r['日主简评']}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF6D4C41), height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ═══ 五行分析 ═══
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _whiteCard(),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.whatshot, size: 16, color: Color(0xFF8D6E63)),
                      const SizedBox(width: 6),
                      const Text('五行分布', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                      const Spacer(),
                      Text(r['五行缺失']!, style: TextStyle(fontSize: 12, color: const Color(0xFF8D6E63).withValues(alpha: 0.7))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _wuxingBar('金', int.parse(r['五行_金']!), const Color(0xFFFFD700)),
                  _wuxingBar('木', int.parse(r['五行_木']!), const Color(0xFF4CAF50)),
                  _wuxingBar('水', int.parse(r['五行_水']!), const Color(0xFF2196F3)),
                  _wuxingBar('火', int.parse(r['五行_火']!), const Color(0xFFFF5722)),
                  _wuxingBar('土', int.parse(r['五行_土']!), const Color(0xFF795548)),
                  const SizedBox(height: 12),
                  Text(
                    r['日主简评']!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 重新测算
            GestureDetector(
              onTap: _showBaziDatePicker,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text('重新选择日期', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '* 时辰请按实际出生时间选择\n* 此为娱乐参考，非专业命理推算',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    // 未测算 — 日期选择界面
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF3E2723).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(child: Text('📅', style: TextStyle(fontSize: 48))),
          ),
          const SizedBox(height: 24),
          const Text('生辰八字', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text('选择出生日期，查看八字命盘', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('包含四柱八字、五行分布、纳音命理', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _showBaziDatePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3E2723), Color(0xFF2C1810)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF3E2723).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: const Text('开始测算', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  /// 四柱中的一柱（含十神）
  Widget _pillar(String label, String ganZhi, String fullName, String tenGod) {
    final gan = ganZhi[0];
    final zhi = ganZhi[1];
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400], letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(gan, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 2),
          Text(zhi, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF666666))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(tenGod, style: const TextStyle(fontSize: 11, color: Color(0xFF666666), fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  /// 五行进度条
  Widget _wuxingBar(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 20, child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color))),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: count / 8,
                backgroundColor: const Color(0xFFF0F0F0),
                color: color,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 28, child: Text('×$count', style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
        ],
      ),
    );
  }

  BoxDecoration _whiteCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
    );
  }
}
