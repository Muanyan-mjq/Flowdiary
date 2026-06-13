import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/responsive_app_bar.dart';

/// 星座数据模型
class ZodiacData {
  final String name;
  final String symbol;
  final String dateRange;
  final String element;       // 火/土/风/水
  final String rulingPlanet;  // 守护星
  final String polarity;      // 阳性/阴性
  final List<String> traits;  // 性格关键词
  final String strength;
  final String weakness;
  final String luckyColor;
  final int luckyNumber;
  final List<String> compatible; // 合拍星座
  final String description;

  const ZodiacData({
    required this.name, required this.symbol, required this.dateRange,
    required this.element, required this.rulingPlanet, required this.polarity,
    required this.traits, required this.strength, required this.weakness,
    required this.luckyColor, required this.luckyNumber,
    required this.compatible, required this.description,
  });
}

/// 12 星座真实数据
const _zodiacDataList = [
  ZodiacData(name: '白羊座', symbol: '♈', dateRange: '3月21日 - 4月19日',
    element: '火', rulingPlanet: '火星', polarity: '阳性',
    traits: ['勇敢', '热情', '冲动', '直率', '领导力'],
    strength: '行动力强，敢为人先，是天生的开拓者和领导者',
    weakness: '容易冲动急躁，缺乏耐心，有时过于自我中心',
    luckyColor: '红色', luckyNumber: 9,
    compatible: ['狮子座', '射手座', '双子座'],
    description: '白羊座是十二星座的第一个，象征着新生与开始。受火星守护，充满了原始的生命力和竞争意识。你天生不喜欢拐弯抹角，直接坦率是你的标签。'),
  ZodiacData(name: '金牛座', symbol: '♉', dateRange: '4月20日 - 5月20日',
    element: '土', rulingPlanet: '金星', polarity: '阴性',
    traits: ['稳重', '务实', '坚韧', '享受', '忠诚'],
    strength: '踏实可靠，对美和品质有天然的鉴赏力，是最靠谱的朋友',
    weakness: '固执已见，改变缓慢，有时过于物质主义',
    luckyColor: '绿色', luckyNumber: 6,
    compatible: ['处女座', '摩羯座', '巨蟹座'],
    description: '金牛座由金星守护，热爱生活中的美好事物——美食、音乐、艺术。你做事不急不躁，一步一个脚印，是大器晚成的代表。'),
  ZodiacData(name: '双子座', symbol: '♊', dateRange: '5月21日 - 6月21日',
    element: '风', rulingPlanet: '水星', polarity: '阳性',
    traits: ['机智', '好奇', '灵活', '善变', '沟通力'],
    strength: '头脑灵活，学习能力极强，是信息和社交的中心节点',
    weakness: '注意力容易分散，三分钟热度，有时表里不一',
    luckyColor: '黄色', luckyNumber: 5,
    compatible: ['天秤座', '水瓶座', '狮子座'],
    description: '双子座由水星守护，掌管沟通与思维。你的大脑永远在高速运转，对世界充满好奇心。一个身体里住着两个灵魂，这是你的独特魅力。'),
  ZodiacData(name: '巨蟹座', symbol: '♋', dateRange: '6月22日 - 7月22日',
    element: '水', rulingPlanet: '月亮', polarity: '阴性',
    traits: ['温柔', '敏感', '顾家', '保护欲', '念旧'],
    strength: '情感细腻，直觉敏锐，是团队中最温暖的情感支柱',
    weakness: '情绪波动大，容易过度保护自己，偶尔会钻牛角尖',
    luckyColor: '银白色', luckyNumber: 2,
    compatible: ['天蝎座', '双鱼座', '金牛座'],
    description: '巨蟹座是唯一由月亮守护的星座，情感如同潮汐般起伏。家庭对你来说是宇宙的中心，你的温柔细腻让身边的人都感到被呵护。'),
  ZodiacData(name: '狮子座', symbol: '♌', dateRange: '7月23日 - 8月22日',
    element: '火', rulingPlanet: '太阳', polarity: '阳性',
    traits: ['自信', '慷慨', '热情', '创造力', '尊严'],
    strength: '天生自带光芒，感染力极强，能点燃周围所有人的热情',
    weakness: '需要关注和认可，自尊心过强，偶尔显得爱面子',
    luckyColor: '金色', luckyNumber: 1,
    compatible: ['白羊座', '射手座', '天秤座'],
    description: '狮子座由太阳守护，是十二星座中唯一的王者。你的存在就是舞台的中心，用热情和慷慨照亮他人。但这不意味着你不需要被理解和关爱。'),
  ZodiacData(name: '处女座', symbol: '♍', dateRange: '8月23日 - 9月22日',
    element: '土', rulingPlanet: '水星', polarity: '阴性',
    traits: ['细致', '理性', '勤奋', '完美主义', '服务精神'],
    strength: '追求卓越，注重细节，是团队中最可靠的品质把控者',
    weakness: '容易陷入完美主义陷阱，对自己和他人要求过高',
    luckyColor: '灰色', luckyNumber: 5,
    compatible: ['金牛座', '摩羯座', '天蝎座'],
    description: '处女座由水星守护，但与双子不同，你的水星能量体现在深度分析上。你追求完美，但请记住：不完美也是一种完美。'),
  ZodiacData(name: '天秤座', symbol: '♎', dateRange: '9月23日 - 10月23日',
    element: '风', rulingPlanet: '金星', polarity: '阳性',
    traits: ['优雅', '公正', '社交', '审美', '平衡'],
    strength: '天生外交家，善于平衡各方利益，对美和和谐有极致追求',
    weakness: '选择困难，常常为了和谐而压抑自己的想法',
    luckyColor: '粉色', luckyNumber: 7,
    compatible: ['双子座', '水瓶座', '狮子座'],
    description: '天秤座由金星守护，是美的化身。你追求公平与和谐，总能在复杂的人际关系中找到平衡点。做选择对你来说是最难的，因为你看得到每个选项的价值。'),
  ZodiacData(name: '天蝎座', symbol: '♏', dateRange: '10月24日 - 11月22日',
    element: '水', rulingPlanet: '冥王星', polarity: '阴性',
    traits: ['深沉', '坚韧', '洞察力', '忠诚', '极致'],
    strength: '意志力惊人，看透事物本质的能力无人能及，是最深情的守护者',
    weakness: '防备心重，控制欲强，容易走向极端的爱或恨',
    luckyColor: '深红色', luckyNumber: 8,
    compatible: ['巨蟹座', '双鱼座', '处女座'],
    description: '天蝎座由冥王星守护，掌管着重生与蜕变。你的感情浓烈而深沉，一旦认定就绝不放手。这种极致的能量，用在对的方向上无坚不摧。'),
  ZodiacData(name: '射手座', symbol: '♐', dateRange: '11月23日 - 12月21日',
    element: '火', rulingPlanet: '木星', polarity: '阳性',
    traits: ['乐观', '自由', '探索', '幽默', '哲学'],
    strength: '视野宏大，乐观向上，是团队中带来希望和方向的人',
    weakness: '不喜欢约束和细节，说话太直偶尔会让人受不了',
    luckyColor: '紫色', luckyNumber: 3,
    compatible: ['白羊座', '狮子座', '双子座'],
    description: '射手座由木星守护，是十二星座中的探索者。你的心里装着一个远方，自由的灵魂不愿被任何牢笼束缚。乐观是你的超能力，但别忘了脚踏实地。'),
  ZodiacData(name: '摩羯座', symbol: '♑', dateRange: '12月22日 - 1月19日',
    element: '土', rulingPlanet: '土星', polarity: '阴性',
    traits: ['自律', '坚韧', '务实', '责任感', '远见'],
    strength: '最强大的执行力和耐力，是所有星座中最能成大事的人',
    weakness: '过于严肃沉闷，不擅长表达感情，容易压抑自己',
    luckyColor: '棕色', luckyNumber: 4,
    compatible: ['金牛座', '处女座', '双鱼座'],
    description: '摩羯座由土星守护，是时间的信徒。你相信积累的力量，不怕走得慢，只怕停下来。成功的果实终会属于坚持到最后的人。'),
  ZodiacData(name: '水瓶座', symbol: '♒', dateRange: '1月20日 - 2月18日',
    element: '风', rulingPlanet: '天王星', polarity: '阳性',
    traits: ['独立', '创新', '理性', '博爱', '反传统'],
    strength: '超前思维，不被常规束缚，是人类进步的推动者',
    weakness: '有时过于疏离，难以被理解，偶尔显得冷漠无情',
    luckyColor: '蓝色', luckyNumber: 11,
    compatible: ['双子座', '天秤座', '白羊座'],
    description: '水瓶座由天王星守护，是十二星座中的革新者。你的思维在同龄人之中常常超前一步，看似冷静的外表下有改变世界的热情。'),
  ZodiacData(name: '双鱼座', symbol: '♓', dateRange: '2月19日 - 3月20日',
    element: '水', rulingPlanet: '海王星', polarity: '阴性',
    traits: ['浪漫', '善良', '直觉', '艺术', '共情力'],
    strength: '情感丰富，共情能力极强，是十二星座中最温柔的治愈者',
    weakness: '容易逃避现实，边界感模糊，有时太容易被影响',
    luckyColor: '海蓝色', luckyNumber: 12,
    compatible: ['巨蟹座', '天蝎座', '摩羯座'],
    description: '双鱼座由海王星守护，是十二星座的最后一个，融合了所有星座的特质。你是天生的艺术家和梦想家，你的善良温柔是这个世界最需要的东西。'),
];

/// 星座详情全屏页面
class ZodiacDetailScreen extends StatelessWidget {
  final int zodiacIndex;

  const ZodiacDetailScreen({super.key, required this.zodiacIndex});

  ZodiacData get _data => _zodiacDataList[zodiacIndex];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dailyFortune = _computeDailyFortune(zodiacIndex, now);
    final score = _computeScore(zodiacIndex, now);

    return Scaffold(
      backgroundColor: appBgColor(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 顶部区域（渐变色背景）
            _buildHeader(context, score),
            // 基本信息卡片
            _buildBasicInfo(),
            // 今日运势
            _buildDailyFortune(dailyFortune, score, now),
            // 性格详情
            _buildPersonality(),
            // 合拍星座
            _buildCompatibility(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 顶部：大符号 + 星座名 + 星级 + 渐变背景
  Widget _buildHeader(BuildContext context, int score) {
    final safeTop = ResponsiveAppBar.safeTop(context);
    final gradientColors = _elementGradient(_data.element);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, safeTop + 8, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Column(
        children: [
          // 顶部栏
          SizedBox(
            height: 52,
            child: Stack(
              children: [
                Positioned(
                  left: 0, top: 0, bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: Text('星座详情',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 大符号
          Text(_data.symbol, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 12),
          // 星座名
          Text(_data.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text(_data.dateRange, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 16),
          // 星级
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(5, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  i < score ? Icons.star : Icons.star_border,
                  size: 28,
                  color: i < score ? Colors.amber[300] : Colors.white.withValues(alpha: 0.35),
                ),
              )),
            ],
          ),
          const SizedBox(height: 6),
          Text(_scoreLabel(score), style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  /// 基本信息：元素/守护星/幸运色/幸运数字
  Widget _buildBasicInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('基本信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _infoCell('元素', _data.element, _elementIcon(_data.element))),
              Expanded(child: _infoCell('守护星', _data.rulingPlanet, '🪐')),
              Expanded(child: _infoCell('极性', _data.polarity, _data.polarity == '阳性' ? '☀️' : '🌙')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _infoCell('幸运色', _data.luckyColor, '🎨')),
              Expanded(child: _infoCell('幸运数字', '${_data.luckyNumber}', '🔢')),
              Expanded(child: _infoCell('特质', _data.traits[0], '✨')),
            ],
          ),
        ],
      ),
    );
  }

  /// 今日运势（结合星座元素 + 当日时间计算）
  Widget _buildDailyFortune(Map<String, dynamic> fortune, int score, DateTime now) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('今日运势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              const Spacer(),
              Text('${now.month}月${now.day}日', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
            ],
          ),
          const SizedBox(height: 6),
          Text(fortune['summary'] as String, style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5)),
          const SizedBox(height: 20),
          _fortuneRow('💕', '爱情运势', fortune['love'] as String),
          _fortuneRow('💼', '事业学业', fortune['work'] as String),
          _fortuneRow('🍀', '财运运势', fortune['luck'] as String),
          _fortuneRow('🧘', '健康提醒', fortune['health'] as String),
          _fortuneRow('🌈', '幸运指引', fortune['tip'] as String),
        ],
      ),
    );
  }

  /// 性格详情
  Widget _buildPersonality() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('性格分析', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          Text(_data.description, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.7)),
          const SizedBox(height: 20),
          // 关键词标签
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _data.traits.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _elementColor(_data.element).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _elementColor(_data.element))),
            )).toList(),
          ),
          const SizedBox(height: 20),
          _traitRow('优势', _data.strength, true),
          const SizedBox(height: 12),
          _traitRow('短板', _data.weakness, false),
        ],
      ),
    );
  }

  /// 合拍星座
  Widget _buildCompatibility() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('合拍星座', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          Text('${_data.name}与以下星座最能产生共鸣', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 16),
          Row(
            children: _data.compatible.map((name) {
              final compatData = _zodiacDataList.firstWhere((z) => z.name == name);
              return Expanded(
                child: Column(
                  children: [
                    Text(compatData.symbol, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 4),
                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                    Text(compatData.element, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════ 运势计算 ═══════════════

  /// 根据星座元素 + 日期计算今日运势（全日结果一致）
  Map<String, dynamic> _computeDailyFortune(int zodiacIndex, DateTime now) {
    final data = _zodiacDataList[zodiacIndex];
    // 种子：年月日 + 星座索引，全天相同
    final seed = now.year * 100000 + now.month * 1000 + now.day * 100 + zodiacIndex;
    final rng = Random(seed);

    final season = _currentSeason(now.month);
    final dayOfWeek = now.weekday; // 1=Mon, 7=Sun

    // 元素与季节的匹配度影响运势基调
    final harmony = _elementSeasonHarmony(data.element, season);

    // 各维度运势文案池（每个维度按星座元素有不同偏向）
    final lovePool = _lovePool(data.element, harmony, dayOfWeek, rng);
    final workPool = _workPool(data.element, harmony, dayOfWeek, rng);
    final luckPool = _luckPool(data.element, harmony, rng);
    final healthPool = _healthPool(data.element, season, rng);
    final tipPool = _tipPool(data.element, data, rng);

    // 运势基调文案
    final summaryMap = {
      '火': {true: '🔥 今天的你能量满满，行动力在巅峰状态，想到就去做吧', false: '🔥 今天火气有点大，控制一下节奏，别冲太猛'},
      '土': {true: '🌿 稳扎稳打的一天，按计划推进会很有收获', false: '🌿 今天可能觉得推进缓慢，但慢就是快，别焦虑'},
      '风': {true: '💨 思维活跃的一天，想法和灵感源源不断', false: '💨 今天脑子有点乱，先把一件事情做完再说'},
      '水': {true: '💧 情感丰沛的一天，直觉会给你正确的指引', false: '💧 今天情绪起伏较大，给自己一点独处的空间'},
    };

    return {
      'summary': summaryMap[data.element]?[harmony] ?? '今天也是值得记录的一天',
      'love': lovePool[rng.nextInt(lovePool.length)],
      'work': workPool[rng.nextInt(workPool.length)],
      'luck': luckPool[rng.nextInt(luckPool.length)],
      'health': healthPool[rng.nextInt(healthPool.length)],
      'tip': tipPool[rng.nextInt(tipPool.length)],
    };
  }

  /// 计算星级（2~5，每日变化：元素×季节 + 每日守护星 + 每日随机因子）
  int _computeScore(int zodiacIndex, DateTime now) {
    final data = _zodiacDataList[zodiacIndex];
    final season = _currentSeason(now.month);
    final harmony = _elementSeasonHarmony(data.element, season);

    int base = harmony ? 3 : 2;

    const dayRuler = {1: '水', 2: '火', 3: '风', 4: '火', 5: '土', 6: '土', 7: '火'};
    if (dayRuler[now.weekday] == data.element) base++;

    // 每日波动 -2~+2，保证每天不一样
    final dayVariance = ((now.year * 397 + now.month * 31 + now.day) * 7 + zodiacIndex * 13) % 5 - 2;

    return (base + dayVariance).clamp(2, 5);
  }

  /// 元素与季节匹配
  bool _elementSeasonHarmony(String element, String season) {
    const harmonyMap = {
      '火': ['春', '夏'],
      '土': ['夏', '秋'],
      '风': ['春', '秋'],
      '水': ['秋', '冬'],
    };
    return harmonyMap[element]?.contains(season) ?? true;
  }

  String _currentSeason(int month) {
    if (month >= 3 && month <= 5) return '春';
    if (month >= 6 && month <= 8) return '夏';
    if (month >= 9 && month <= 11) return '秋';
    return '冬';
  }

  // ═══════════════ 各维度文案池（按元素区分） ═══════════════

  List<String> _lovePool(String element, bool harmony, int dow, Random rng) {
    final firePool = [
      '主动出击！你的热情是今天最大的吸引力，别藏着',
      '坦率表达喜欢，对方会被你的真诚打动',
      '关系中的新鲜感很重要，一起尝试没做过的事吧',
      '今天魅力值拉满，走到哪都有人回头看你',
      '自信就是最好的恋爱滤镜，保持你的本色',
    ];
    final earthPool = [
      '用实际行动表达爱比甜言蜜语更适合你',
      '今天适合和喜欢的人一起享受美食或散步',
      '慢热的感情最持久，不必羡慕别人的节奏',
      '给对方一点实实在在的关心，比什么都强',
      '稳定感是你给伴侣最好的礼物，继续保持',
    ];
    final airPool = [
      '有趣的灵魂万里挑一，今天用你的机智幽默打动对方',
      '沟通是感情的润滑剂，把心里话说出来',
      '社交场合可能遇到有趣的人，保持开放的心态',
      '不要过度分析感情，有时候感觉比逻辑更重要',
      '约朋友喝杯咖啡聊聊天，意外收获在等你',
    ];
    final waterPool = [
      '直觉告诉你的事情，大多数时候是对的',
      '情感的深度比广度重要，珍惜那个懂你的人',
      '今天很容易被感动，一部电影一首歌都能触动你',
      '给彼此一些温柔的空间，沉默也是一种交流',
      '你的细腻和敏感是天赋，不是负担',
    ];

    // 周末爱情运额外加成
    if (dow >= 6) {
      return [..._poolForElement(element, firePool, earthPool, airPool, waterPool),
        '周末约会运极佳，别宅在家了', '今天适合一次浪漫的约会'];
    }

    return _poolForElement(element, firePool, earthPool, airPool, waterPool);
  }

  List<String> _workPool(String element, bool harmony, int dow, Random rng) {
    final firePool = [
      '冲劲十足的一天，适合攻克最难的任务',
      '主动承担责任会带来意想不到的回报',
      '注意合作时的语气，不是所有人都跟你一样快节奏',
      '今天适合开启新项目，你的执行力无人能敌',
      '别只顾着往前冲，回头检查一下细节',
    ];
    final earthPool = [
      '按计划推进，今天适合处理需要耐心的事情',
      '你的靠谱是最大的职业竞争力，继续保持',
      '今天适合做长期规划，列出下个月的目标',
      '小的进步也是进步，不要否定自己的节奏',
      '团队中你的角色不可替代，稳住就是胜利',
    ];
    final airPool = [
      '今天创意满分，头脑风暴会是你的主场',
      '多和同事交流碰撞，好的想法来自对话',
      '信息收集能力今天特别强，善用这个优势',
      '同时进行的事情有点多，排个优先级吧',
      '你的想法值得被更多人听到，大胆说出来',
    ];
    final waterPool = [
      '用你的共情能力去理解同事，团队关系会更好',
      '直觉告诉你哪个方向是对的，跟着走',
      '创造一个舒适的工作环境，效率会更高',
      '今天适合做创意类或需要审美判断的工作',
      '别人的压力不要都往自己身上揽，保护好边界',
    ];

    if (!harmony) {
      final extra = ['今天节奏可能有点不顺，但坚持下来就是胜利', '遇到阻力时想想：这是帮你筛选不重要的东西'];
      final pool = _poolForElement(element, firePool, earthPool, airPool, waterPool);
      return [...pool, ...extra];
    }

    return _poolForElement(element, firePool, earthPool, airPool, waterPool);
  }

  List<String> _luckPool(String element, bool harmony, Random rng) {
    final common = [
      '偏财运一般，但正财稳定，适合做好手头的事',
      '今天不适合冲动消费，想清楚再下单',
      '财运平稳，小额的储蓄计划会有长期回报',
      '可能会有意外小惊喜，比如捡到钱或者收到礼物',
    ];

    final firePool = [...common,
      '果敢的投资决策在今天容易获得好结果',
      '消费欲望有点强，先冷静三小时再做决定',
    ];
    final earthPool = [...common,
      '稳健理财是你最大的财运，别碰不懂的东西',
      '今天适合整理账目，会发现一些不必要的开支',
    ];
    final airPool = [...common,
      '信息就是财富，今天听到的消息值得多想想',
      '社交带来的机会比单纯省钱更有价值',
    ];
    final waterPool = [...common,
      '直觉告诉你哪个方向有财，相信第六感',
      '帮助别人就是帮助自己，善意的付出会有回报',
    ];

    return _poolForElement(element, firePool, earthPool, airPool, waterPool);
  }

  List<String> _healthPool(String element, String season, Random rng) {
    final basePool = [
      '多喝水，少熬夜，身体是革命的本钱',
      '今天适合做一些舒缓的运动，散步或瑜伽',
      '适当放空大脑，比一直运转效率更高',
    ];

    final seasonPool = {
      '春': ['春季养肝，少吃油腻多吃绿色蔬菜', '花粉过敏的注意防护，出门带口罩'],
      '夏': ['夏季心火旺，少喝冰的，温水更解渴', '空调房待久了要起来活动一下'],
      '秋': ['秋季润肺，多吃白色食物如梨和银耳', '秋燥注意保湿，多喝温水少喝咖啡'],
      '冬': ['冬季养肾，注意脚部保暖别光脚踩地板', '天冷也要适当运动，促进血液循环'],
    };

    return [...basePool, ...(seasonPool[season] ?? []), '别总盯着屏幕，每半小时远眺一下'];
  }

  List<String> _tipPool(String element, ZodiacData data, Random rng) {
    return [
      '幸运颜色是${data.luckyColor}，今天可以穿搭中加入这个色系',
      '幸运数字是${data.luckyNumber}，可能会在意想不到的地方出现',
      '今天适合和${data.compatible.first}的朋友聊聊天',
      '早上${7 + rng.nextInt(5)}点到${8 + rng.nextInt(4)}点之间运气最好',
      '今天适合听一首没听过的新歌，会有惊喜',
      '对你来说，今天的关键词是：${data.traits[rng.nextInt(data.traits.length)]}',
      '抬头看看天空，今天的云会给你答案',
      '写下一句想对自己说的话，这就是今天的护身符',
    ];
  }

  List<String> _poolForElement(String e, List<String> fire, List<String> earth, List<String> air, List<String> water) {
    switch (e) {
      case '火': return fire;
      case '土': return earth;
      case '风': return air;
      case '水': return water;
      default: return fire;
    }
  }

  // ═══════════════ UI 组件 ═══════════════

  Widget _infoCell(String label, String value, String icon) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
      ],
    );
  }

  Widget _fortuneRow(String icon, String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
          ),
          Expanded(
            child: Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _traitRow(String label, String content, bool isPositive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isPositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: isPositive ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.6)),
        ),
      ],
    );
  }

  BoxDecoration _card() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2)),
      ],
    );
  }

  String _scoreLabel(int score) {
    switch (score) {
      case 5: return '运势极佳 ✨';
      case 4: return '运势不错 👍';
      case 3: return '运势平稳 🌤️';
      case 2: return '运势稍弱 💪';
      default: return '';
    }
  }

  Color _elementColor(String element) {
    switch (element) {
      case '火': return const Color(0xFFFF6B6B);
      case '土': return const Color(0xFF8B7355);
      case '风': return const Color(0xFF87CEEB);
      case '水': return const Color(0xFF6495ED);
      default: return const Color(0xFF999999);
    }
  }

  String _elementIcon(String element) {
    switch (element) {
      case '火': return '🔥';
      case '土': return '🌍';
      case '风': return '💨';
      case '水': return '💧';
      default: return '✨';
    }
  }

  List<Color> _elementGradient(String element) {
    switch (element) {
      case '火': return [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)];
      case '土': return [const Color(0xFF8B7355), const Color(0xFFA0522D)];
      case '风': return [const Color(0xFF87CEEB), const Color(0xFF5B8DEF)];
      case '水': return [const Color(0xFF6495ED), const Color(0xFF7B68EE)];
      default: return [const Color(0xFF999999), const Color(0xFF666666)];
    }
  }
}
