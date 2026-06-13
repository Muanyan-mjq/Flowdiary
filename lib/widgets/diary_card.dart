import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../utils/weather_service.dart';
import '../screens/diary_wizard_screen.dart';
import '../screens/diary_detail_screen.dart';
import '../utils/letter_service.dart';
import '../utils/smooth_route.dart';
import '../main.dart';

class DiaryCard extends StatefulWidget {
  final int index;
  final bool isDefault;
  final WeatherData? weather;
  final dynamic savedEntry; // DiaryEntry，已保存的日记
  final VoidCallback? onDiarySaved; // 日记保存后回调

  const DiaryCard({
    super.key,
    required this.index,
    this.isDefault = false,
    this.weather,
    this.savedEntry,
    this.onDiarySaved,
  });

  @override
  State<DiaryCard> createState() => _DiaryCardState();
}

class _DiaryCardState extends State<DiaryCard> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  /// 获取当前主题颜色
  Color get _themeColor {
    return ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
  }

  // 文案缓存：防抖 + 定时刷新
  DateTime? _lastTextTime;
  String? _cachedText;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    // 页面保持打开时，每 20 分钟静默刷新文案和图片
    _refreshTimer = Timer.periodic(const Duration(minutes: 20), (_) {
      if (mounted) {
        setState(() {
          _cachedText = null;       // 清除文案缓存
          _cachedImagePath = null;  // 清除图片缓存
        });
      }
    });
  }

  @override
  void dispose() {
    _pressController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// 获取日期天数
  String _getDay() {
    return DateTime.now().day.toString().padLeft(2, '0');
  }

  /// 获取年月
  String _getYearMonth() {
    final now = DateTime.now();
    return '${now.year}年${now.month.toString().padLeft(2, '0')}月';
  }

  // ==================== 动态文案系统 ====================

  /// 图片缓存
  String? _cachedImagePath;
  DateTime? _lastImageTime;

  /// 根据天气 + 时间段返回动态文案（带缓存防抖）
  ///
  /// 变化规则：
  ///   - 每次打开页面：5 分钟内不重复刷新，5 分钟后重新打开会更新
  ///   - 页面保持打开：每 20 分钟自动刷新一次
  String _getDynamicText() {
    final now = DateTime.now();

    // 缓存防抖：5 分钟内返回缓存文案
    if (_cachedText != null && _lastTextTime != null) {
      final elapsed = now.difference(_lastTextTime!).inMinutes;
      if (elapsed < 5) {
        return _cachedText!;
      }
    }

    // 超过 5 分钟或首次，重新生成
    final text = _generateText();
    _cachedText = text;
    _lastTextTime = now;
    return text;
  }

  /// 按时段过滤图片 + 种子取模，保证时段正确且不同日记不同图
  static const _periodImages = {
    '深夜': [
      'assets/images/diary_mascot/时段/深夜/睡觉.jpg',
      'assets/images/diary_mascot/时段/深夜/看星星.jpg',
    ],
    '清晨': [
      'assets/images/diary_mascot/时段/清晨/起床.jpg',
      'assets/images/diary_mascot/时段/清晨/晨跑.jpg',
    ],
    '早上': [
      'assets/images/diary_mascot/时段/早上/吃早餐.jpg',
      'assets/images/diary_mascot/时段/早上/看手机.jpg',
    ],
    '上午': [
      'assets/images/diary_mascot/时段/上午/工作.jpg',
      'assets/images/diary_mascot/时段/上午/学习.jpg',
    ],
    '午间': [
      'assets/images/diary_mascot/时段/中午/吃午饭.jpg',
      'assets/images/diary_mascot/时段/中午/午休.jpg',
    ],
    '午后': [
      'assets/images/diary_mascot/时段/中午/午休.jpg',
      'assets/images/diary_mascot/时段/下午/摸鱼.jpg',
    ],
    '下午': [
      'assets/images/diary_mascot/时段/下午/喝咖啡.jpg',
      'assets/images/diary_mascot/时段/下午/摸鱼.jpg',
    ],
    '傍晚': [
      'assets/images/diary_mascot/时段/傍晚/散步.jpg',
      'assets/images/diary_mascot/时段/傍晚/做饭.jpg',
    ],
    '晚上': [
      'assets/images/diary_mascot/时段/晚上/看电影.jpg',
      'assets/images/diary_mascot/时段/晚上/洗澡.jpg',
    ],
  };
  /// 生成锁定图片：只用日记创建时间的时段图片，不同日记不同图
  String _getImageForTime(DateTime dt, {int extraSeed = 0}) {
    final period = _getTimePeriod(dt.hour);
    // 纯时段图片，不混通用形象图
    final pool = _periodImages[period] ?? _periodImages['早上']!;
    final seed = (dt.year * 100000 + dt.month * 1000 + dt.day * 100 + dt.hour * 60 + dt.minute + extraSeed).abs();
    return pool[seed % pool.length];
  }

  /// 获取动态图片路径（带缓存防抖）
  String _getDynamicImage() {
    final now = DateTime.now();

    // 缓存防抖：5 分钟内返回缓存图片
    if (_cachedImagePath != null && _lastImageTime != null) {
      final elapsed = now.difference(_lastImageTime!).inMinutes;
      if (elapsed < 5) {
        return _cachedImagePath!;
      }
    }

    // 超过 5 分钟或首次，重新生成
    final imagePath = _generateImage();
    _cachedImagePath = imagePath;
    _lastImageTime = now;
    return imagePath;
  }

  /// 实际生成图片路径（根据时间、天气、心情）
  String _generateImage() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final weekday = now.weekday;
    final period = _getTimePeriod(hour);
    final weatherCategory = widget.weather?.category ?? 'sunny';
    final isWeekend = weekday >= 6;

    // 种子：按 5 分钟分桶，同一 5 分钟窗口内图片一致
    final seed = now.year * 100000 + now.month * 1000 + now.day * 100 + hour * 12 + minute ~/ 5;
    final random = Random(seed);

    // 70% 概率显示时段图片，30% 概率显示形象图片
    final roll = random.nextDouble();

    if (roll < 0.7) {
      // 时段图片：根据当前时段选择动作
      return _getTimePeriodImage(period, random);
    } else {
      // 形象图片：根据天气、时间、心情选择
      return _getStyleImage(period, weatherCategory, isWeekend, random);
    }
  }

  /// 获取时段图片路径
  String _getTimePeriodImage(String period, Random random) {
    final periodMap = {
      '深夜': ['睡觉', '看星星'],
      '清晨': ['起床', '晨跑'],
      '早上': ['吃早餐', '看手机'],
      '上午': ['工作', '学习'],
      '午间': ['吃午饭', '午休'],
      '午后': ['午休', '摸鱼'],  // 午后用午休或摸鱼
      '下午': ['喝咖啡', '摸鱼'],
      '傍晚': ['散步', '做饭'],
      '晚上': ['看电影', '洗澡'],
    };

    // 兜底：如果时段没有映射，用早上
    final actions = periodMap[period] ?? ['吃早餐', '看手机'];
    final action = actions[random.nextInt(actions.length)];

    // 午后时段的图片实际在中午或下午文件夹
    String imagePeriod = period;
    if (period == '午后') {
      imagePeriod = action == '午休' ? '中午' : '下午';
    }

    return 'assets/images/diary_mascot/时段/$imagePeriod/$action.jpg';
  }

  /// 获取形象图片路径
  String _getStyleImage(String period, String weather, bool isWeekend, Random random) {
    final list = <String>[];

    // 根据时间选择
    if (period == '深夜' || period == '晚上') {
      list.add('睡觉');
    }
    if (period == '午后' || period == '下午') {
      list.addAll(['看书', '听音乐']);
    }
    if (period == '傍晚' && weather == 'sunny') {
      list.add('拍照');
    }

    // 根据天气选择
    if (weather == 'rain' || weather == 'snow') {
      list.addAll(['听音乐', '看书']);
    }

    // 周末特殊
    if (isWeekend) {
      list.addAll(['购物', '拍照']);
    }

    // 通用形象（兜底）
    list.addAll(['听音乐', '玩偶']);

    final style = list[random.nextInt(list.length)];
    return 'assets/images/diary_mascot/形象/$style/$style.jpg';
  }

  /// 实际生成文案（加权分层抽签）
  /// seed 按 5 分钟分桶，同一 5 分钟窗口内文案一致
  String _generateText() {
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday; // 1=周一, 7=周日
    final month = now.month;
    final day = now.day;
    final minute = now.minute;

    // 种子：按 5 分钟分桶，同一 5 分钟窗口内文案一致
    final seed = now.year * 100000 + now.month * 1000 + now.day * 100 + hour * 12 + minute ~/ 5;
    final random = Random(seed);

    // 获取时段
    final period = _getTimePeriod(hour);
    // 获取天气类别
    final weatherCategory = widget.weather?.category ?? 'sunny';
    // 获取季节
    final season = _getSeason(month);
    // 是否周末
    final isWeekend = weekday >= 6;

    // 分层抽签：节日 → 天气×时段 → 天气/时段通用 → 风格混合 → 诗意/萨摩耶

    // 第一步：15%概率命中节日/特殊日期（深夜时段不显示，凌晨看节日祝福很奇怪）
    if (hour >= 6 && hour < 23) {
      final specialTexts = _specialDateTexts(month, day, weekday);
      if (specialTexts.isNotEmpty && random.nextDouble() < 0.15) {
        return specialTexts[random.nextInt(specialTexts.length)];
      }
    }

    // 第二步：按权重分配剩余85%
    final roll = random.nextDouble();

    // 45% → 天气×时段精准组合（与图片相关）
    if (roll < 0.45) {
      final pool = _weatherTimeTexts(weatherCategory, period);
      if (pool.isNotEmpty) return pool[random.nextInt(pool.length)];
    }

    // 20% → 天气通用 + 时段通用
    if (roll < 0.65) {
      final pool = [
        ..._weatherGeneralTexts(weatherCategory, season, period),
        ..._timeGeneralTexts(period, isWeekend),
      ];
      if (pool.isNotEmpty) return pool[random.nextInt(pool.length)];
    }

    // 20% → 风格混合（治愈/毒舌/搞笑）
    if (roll < 0.85) {
      final pool = _styleTexts(period, weatherCategory, isWeekend);
      if (pool.isNotEmpty) return pool[random.nextInt(pool.length)];
    }

    // 15% → 诗意/文艺 + 萨摩耶特色
    final pool = [
      ..._poeticTexts(season, hour, weatherCategory),
      ..._samoyeTexts(period, weatherCategory),
    ];
    if (pool.isNotEmpty) return pool[random.nextInt(pool.length)];

    // 兜底（理论上不会走到这里）
    return '今天也要记录生活呀';
  }

  /// 获取时段（精准时间划分）
  String _getTimePeriod(int hour) {
    if (hour < 5) return '深夜';
    if (hour < 7) return '清晨';
    if (hour < 9) return '早上';
    if (hour < 11) return '上午';
    if (hour < 13) return '午间';   // 11:00-13:00 午饭时间
    if (hour < 14) return '午后';   // 13:00-14:00 午后过渡
    if (hour < 17) return '下午';   // 14:00-17:00 下午
    if (hour < 19) return '傍晚';
    if (hour < 22) return '晚上';
    return '深夜';
  }

  /// 获取季节
  String _getSeason(int month) {
    if (month >= 3 && month <= 5) return '春天';
    if (month >= 6 && month <= 8) return '夏天';
    if (month >= 9 && month <= 11) return '秋天';
    return '冬天';
  }

  // ==================== 第一优先：天气 + 时段 组合 ====================
  List<String> _weatherTimeTexts(String weather, String period) {
    final list = <String>[];

    // --- 晴天 ---
    if (weather == 'sunny') {
      switch (period) {
        case '深夜':
          list.addAll(['晴朗的夜空，星星在眨眼', '月亮挂在窗外，晚安']);
          break;
        case '清晨':
          list.addAll(['阳光透过窗帘叫你起床了', '晴天的清晨，空气都是甜的']);
          break;
        case '早上':
          list.addAll(['早安，今天是个大晴天', '阳光正好，微风不燥']);
          break;
        case '上午':
          list.addAll(['晴天的上午，适合晒晒心情', '阳光灿烂，效率加倍']);
          break;
        case '中午':
          list.addAll(['大中午的，该吃饭了，别亏待自己', '太阳当空照，午饭不能少']);
          break;
        case '午后':
          list.addAll(['刚吃完饭，晒晒太阳消消食', '午后阳光正好，适合发呆']);
          break;
        case '下午':
          list.addAll(['下午茶时间到，来杯冰美式？', '晴天下午，效率翻倍']);
          break;
        case '傍晚':
          list.addAll(['晴天的夕阳一定很美，抬头看看', '傍晚的晚霞，是天空的情书']);
          break;
        case '晚上':
          list.addAll(['晴天的夜晚，星星特别多', '晴天的晚上，心情也不错']);
          break;
      }
    }

    // --- 多云/阴天 ---
    if (weather == 'cloudy') {
      switch (period) {
        case '深夜':
          list.addAll(['云层厚厚的，月亮躲起来了', '阴天的夜晚，格外安静']);
          break;
        case '清晨':
          list.addAll(['多云的早晨，不用防晒，偷着乐', '阴天适合赖床五分钟']);
          break;
        case '早上':
          list.addAll(['多云转晴？还是多云转雨？随它吧', '阴天也挡不住好心情']);
          break;
        case '上午':
          list.addAll(['阴天最适合宅着了', '多云的上午，光线刚刚好']);
          break;
        case '中午':
          list.addAll(['阴天中午，不用撑伞去吃饭了', '多云天，吃饭去，不晒']);
          break;
        case '午后':
          list.addAll(['刚吃饱，阴天正好午休', '多云午后，困意袭来']);
          break;
        case '下午':
          list.addAll(['阴天下午，困意加倍', '多云的下午，适合发呆']);
          break;
        case '傍晚':
          list.addAll(['阴天的傍晚，路灯提前亮了', '天阴阴的，快下雨了吧']);
          break;
        case '晚上':
          list.addAll(['阴天晚上，适合窝在家里', '多云的夜晚，月亮在捉迷藏']);
          break;
      }
    }

    // --- 雨天 ---
    if (weather == 'rain') {
      switch (period) {
        case '深夜':
          list.addAll(['雨声是最好的催眠曲', '听雨入眠，晚安', '窗外淅淅沥沥，被窝暖暖的']);
          break;
        case '清晨':
          list.addAll(['下雨了，多睡五分钟吧', '雨天的清晨，被窝格外诱人', '听雨声起床，也是一种浪漫']);
          break;
        case '早上':
          list.addAll(['下雨天，别忘了带伞', '雨天出门，鞋子要选对', '雨天路滑，慢慢走']);
          break;
        case '上午':
          list.addAll(['下雨天最适合看书了', '雨天上午，咖啡加倍', '听着雨声工作，效率居然不错']);
          break;
        case '中午':
          list.addAll(['下雨天，点个外卖吧', '雨天中午，热汤最治愈', '下雨了，别淋着去吃饭']);
          break;
        case '午后':
          list.addAll(['雨天午后，听雨声发会儿呆', '刚吃完饭，雨声正好当BGM']);
          break;
        case '下午':
          list.addAll(['雨天下午，困意满分', '下雨天适合发呆和写日记', '雨声滴滴答答，时间慢慢走']);
          break;
        case '傍晚':
          list.addAll(['下雨的傍晚，窗外很安静', '雨天傍晚，路灯映在水洼里', '雨天的傍晚，空气湿湿的']);
          break;
        case '晚上':
          list.addAll(['雨夜，适合听歌写日记', '下雨天晚上，早点回家', '雨天晚上，世界好安静']);
          break;
      }
    }

    // --- 雪天 ---
    if (weather == 'snow') {
      switch (period) {
        case '深夜':
          list.addAll(['雪花飘飘，世界安静了', '雪夜，万籁俱寂']);
          break;
        case '清晨':
          list.addAll(['醒来发现下雪了！快看窗外', '雪天的清晨，世界白茫茫的']);
          break;
        case '早上':
          list.addAll(['下雪了！记得穿厚点', '雪天路滑，小心走路']);
          break;
        case '上午':
          list.addAll(['雪天适合喝热可可', '看着雪花发呆，也是一种享受']);
          break;
        case '中午':
          list.addAll(['雪天中午，来碗热汤面', '下雪了，吃顿好的暖暖身子']);
          break;
        case '午后':
          list.addAll(['雪天午后，喝杯热可可暖暖', '刚吃完饭，看雪花飘']);
          break;
        case '下午':
          list.addAll(['雪天下午，堆雪人去？', '雪花还在飘，世界像童话']);
          break;
        case '傍晚':
          list.addAll(['雪后的傍晚，路灯照在雪地上好美', '下雪天的傍晚，回家的路也变美了']);
          break;
        case '晚上':
          list.addAll(['雪夜，适合窝在被窝里', '下雪的夜晚，格外想家']);
          break;
      }
    }

    // --- 雾天 ---
    if (weather == 'fog') {
      switch (period) {
        case '深夜':
          list.addAll(['雾蒙蒙的夜晚，路灯像星星', '大雾的深夜，世界朦胧了']);
          break;
        case '清晨':
          list.addAll(['大雾天，能见度好低', '雾天清晨，像在云里']);
          break;
        case '早上':
          list.addAll(['大雾天，出门小心', '雾蒙蒙的早上，像仙境']);
          break;
        case '上午':
          list.addAll(['雾还没散，像在做梦', '大雾天适合宅家']);
          break;
        case '中午':
          list.addAll(['雾散了没？该吃饭了', '大雾中午，外卖小哥辛苦了']);
          break;
        case '午后':
          list.addAll(['雾天午后，像在仙境里', '刚吃完饭，雾还没散']);
          break;
        case '下午':
          list.addAll(['雾天下午，困意更浓', '雾蒙蒙的下午，适合午睡']);
          break;
        case '傍晚':
          list.addAll(['雾天傍晚，路灯提前亮了', '大雾的傍晚，回家要小心']);
          break;
        case '晚上':
          list.addAll(['雾夜，路灯像萤火虫', '大雾晚上，早点回家']);
          break;
      }
    }

    // --- 高温 ---
    if (weather == 'hot') {
      switch (period) {
        case '深夜':
          list.addAll(['热到睡不着，开空调了吗', '热到深夜，翻来覆去']);
          break;
        case '清晨':
          list.addAll(['一大早就热起来了', '趁早上凉快，多做点事']);
          break;
        case '早上':
          list.addAll(['今天好热，记得防晒', '早起就热得不行了']);
          break;
        case '上午':
          list.addAll(['热到不想动，但还是要努力', '高温预警，注意防暑']);
          break;
        case '中午':
          list.addAll(['这么热，必须来杯冰的', '热到吃饭都没胃口', '中午别出门，会化的']);
          break;
        case '午后':
          list.addAll(['热到午后只想躺着', '刚吃完饭，热到不想动']);
          break;
        case '下午':
          list.addAll(['热到下午茶只想吃冰', '高温下午，空调续命']);
          break;
        case '傍晚':
          list.addAll(['傍晚终于凉快点了', '热了一天，傍晚的风好珍贵']);
          break;
        case '晚上':
          list.addAll(['晚上还是好热，西瓜吃起来', '热到晚上只想躺着']);
          break;
      }
    }

    // --- 低温 ---
    if (weather == 'cold') {
      switch (period) {
        case '深夜':
          list.addAll(['冷到不想出被窝', '这么冷的天，被窝就是天堂']);
          break;
        case '清晨':
          list.addAll(['好冷，再赖五分钟', '冷到不想起床的一天']);
          break;
        case '早上':
          list.addAll(['天冷了，多穿点再出门', '冷到手都不想伸出来']);
          break;
        case '上午':
          list.addAll(['冷到只想喝热的', '冷到手都僵了']);
          break;
        case '中午':
          list.addAll(['冷天中午，来碗热汤', '这么冷，吃点热乎的']);
          break;
        case '午后':
          list.addAll(['冷天午后，喝杯热茶暖暖', '刚吃完饭，缩着不想动']);
          break;
        case '下午':
          list.addAll(['冷到下午只想缩着', '低温下午，热茶续命']);
          break;
        case '傍晚':
          list.addAll(['天黑得早，冷到不想出门', '冷天傍晚，回家最幸福']);
          break;
        case '晚上':
          list.addAll(['冷天晚上，喝杯热的暖暖', '这么冷，早点洗个热水澡']);
          break;
      }
    }

    return list;
  }

  // ==================== 第二优先：天气通用 ====================
  List<String> _weatherGeneralTexts(String weather, String season, String period) {
    final list = <String>[];

    switch (weather) {
      case 'sunny':
        // 根据时间段显示不同的晴天文案
        if (period == '深夜' || period == '晚上') {
          list.addAll([
            '晴天的夜晚，星星特别多',
            '晴朗的夜空，月亮好圆',
            '晴天晚上，心情也不错',
            '夜空晴朗，适合许愿',
          ]);
        } else {
          list.addAll([
            '阳光正好，心情也跟着好起来了',
            '晴天出门走走吧',
            '今天天气真好，适合记录生活',
            '阳光是最好的滤镜',
          ]);
        }
        break;
      case 'cloudy':
        list.addAll([
          '多云的天气，心情刚刚好',
          '阴天也不错，不用防晒',
          '云层厚厚的，像棉花糖',
          '阴天适合安静地写点东西',
        ]);
        break;
      case 'rain':
        list.addAll([
          '下雨了，世界变得好安静',
          '雨天适合发呆和写日记',
          '雨声滴滴答答，像在讲故事',
          '雨天的空气好好闻',
          '下雨天，适合想念一个人',
        ]);
        break;
      case 'snow':
        list.addAll([
          '下雪了！世界变成了童话',
          '雪花飘飘，好浪漫',
          '雪天适合喝热可可、堆雪人',
          '踩在雪地上，嘎吱嘎吱的',
        ]);
        break;
      case 'fog':
        list.addAll([
          '雾蒙蒙的，像在仙境里',
          '大雾天，世界朦胧了',
          '雾里看花，别有风味',
          '雾天适合宅在家里',
        ]);
        break;
      case 'hot':
        list.addAll([
          '热到融化，只想待在空调房',
          '西瓜空调WiFi，夏天三件套',
          '这么热，冰激凌必须安排',
          '热到什么都不想做',
        ]);
        break;
      case 'cold':
        list.addAll([
          '天冷了，记得加衣服',
          '冷到不想动，但还是要记录生活',
          '冬天的阳光好珍贵',
          '冷天适合吃火锅',
        ]);
        break;
    }

    return list;
  }

  // ==================== 第三优先：时段通用 ====================
  List<String> _timeGeneralTexts(String period, bool isWeekend) {
    final now = DateTime.now();
    final hour = now.hour;
    final list = <String>[];

    switch (period) {
      case '深夜':
        if (hour >= 23) {
          // 23点-0点：准备睡觉
          list.addAll([
            '夜深了，该睡觉了',
            '星星都睡了，你也该休息了',
            '明天又是新的一天，晚安',
          ]);
        } else if (hour >= 22) {
          // 22-23点：准备睡觉
          list.addAll([
            '快11点了，还没睡呀',
            '今天也差不多了，休息吧',
            '晚上好，该收收心了',
          ]);
        } else {
          // 0点-5点：已经很晚了
          list.addAll([
            '这么晚了，赶紧睡吧',
            '熬夜对皮肤不好哦',
            '都这个点了，快睡吧',
          ]);
        }
        break;
      case '清晨':
        list.addAll([
          '早起的鸟儿有虫吃',
          '新的一天，新的开始',
          '今天也要元气满满',
        ]);
        break;
      case '早上':
        list.addAll([
          '早安，今天也要加油鸭',
          '新的一天开始了',
          '早安，记得微笑',
        ]);
        break;
      case '上午':
        list.addAll([
          '上午好，效率最高的时候',
          '上午的时间最宝贵',
          '趁精力充沛，做重要的事',
        ]);
        break;
      case '中午':
        list.addAll([
          '中午好，该吃饭了',
          '午饭时间到',
          '吃饱了才有力气干活',
        ]);
        break;
      case '午后':
        list.addAll([
          '午后好，刚吃完饭歇会儿',
          '午后时光，适合发呆',
          '午后困意来袭，喝杯水提提神',
        ]);
        break;
      case '下午':
        list.addAll([
          '下午好，继续加油',
          '下午茶时间',
          '下午是最适合创作的时间',
        ]);
        break;
      case '傍晚':
        list.addAll([
          '傍晚了，今天的晚霞一定很美',
          '忙了一天，傍晚歇歇吧',
          '傍晚好，记录今天的心情吧',
        ]);
        break;
      case '晚上':
        if (hour >= 22) {
          // 22-23点：快睡觉了
          list.addAll([
            '快11点了，准备休息吧',
            '今天辛苦了，早点睡',
            '晚上好，收拾收拾准备睡觉',
          ]);
        } else {
          // 19-22点：正常晚上
          list.addAll([
            '晚上好，今天辛苦了',
            '晚上是属于自己的时间',
            '晚上好，做点喜欢的事',
          ]);
        }
        break;
    }

    if (isWeekend) {
      list.addAll([
        '周末愉快，好好休息',
        '周末就是要睡到自然醒',
        '周末时光最珍贵',
      ]);
    }

    return list;
  }

  // ==================== 第四优先：风格混合（55%治愈 25%毒舌 20%搞笑）====================
  List<String> _styleTexts(String period, String weather, bool isWeekend) {
    final now = DateTime.now();
    final hour = now.hour;
    final list = <String>[];

    // --- 治愈系 55% ---
    list.addAll([
      '今天也要开心呀',
      '慢慢来，比较快',
      '每一天都值得被记录',
      '不开心也没关系，明天又是新的一天',
      '平凡的日子也闪闪发光',
      '世界偶尔也挺好的',
      '今天也要好好爱自己',
      '今天也辛苦啦，给自己一个拥抱吧',
      '笑一个呗，反正不花钱',
      '你比自己想象的更勇敢',
      '今天的你，也很可爱',
      '日子平淡，但有光',
      '不管怎样，你已经很棒了',
      '把心情照顾好，比什么都重要',
      '你已经很棒了，真的',
    ]);

    // --- 毒舌系 25% ---
    list.addAll([
      '又在摸鱼了吧，我都知道',
      '今天的运动量：从床到冰箱',
      '别看了，说的就是你，该写日记啦',
      '又一天过去了，今天做了什么呢',
      '你今天的效率，连蜗牛都笑了',
      '眼睛累了就歇会儿呗',
      '昨天的计划嘛...就让它随风去吧',
    ]);

    // 饭点相关毒舌：只在11-13点（午饭）、17-19点（晚饭）出现
    if ((hour >= 11 && hour < 13) || (hour >= 17 && hour < 19)) {
      list.add('又不吃饭，胃在骂你了');
    }

    // 晚睡相关毒舌：只在22点后出现
    if (hour >= 22 || hour < 5) {
      list.addAll([
        '这么晚还不睡，明天起得来？',
        '说好的早睡呢？又食言了',
      ]);
    }

    // --- 搞笑系 20% ---
    list.addAll([
      '今天也是元气满满的一天呢（才怪）',
      '人生苦短，及时行乐（主要是吃）',
      '今天的心情：想躺平但钱包不允许',
      '我不是懒，我只是在节约能量',
      '减肥？明天再说吧',
      '今天的目标：活着就行',
      '我的人生信条：能躺着绝不坐着',
    ]);

    // 白天专属搞笑（6-22点）
    if (hour >= 6 && hour < 22) {
      list.add('今天也是假装很忙的一天');
    }

    return list;
  }

  // ==================== 第五优先：诗意/文艺 ====================
  List<String> _poeticTexts(String season, int hour, String weather) {
    final list = <String>[
      '人间烟火气，最抚凡人心',
      '风很温柔，花很好看',
      '眼睛亮亮的，就很好',
      '世界很大，幸福很小',
      '走了好远，还好没丢',
      '慢慢走，沿途有风景',
      '今天的风，好像在说些什么',
      '抬头看看天，心情会好一点',
      '被子里有安全感，文字里有温柔',
      '小事堆起来，就是生活',
    ];

    // 季节诗句
    switch (season) {
      case '春天':
        list.addAll(['等闲识得东风面，万紫千红总是春', '春风不说话，但吹开了花']);
        break;
      case '夏天':
        list.addAll(['小荷才露尖尖角，早有蜻蜓立上头', '夏天的晚风，是最好的礼物']);
        break;
      case '秋天':
        list.addAll(['空山新雨后，天气晚来秋', '踩落叶的声音，是秋天的BGM']);
        break;
      case '冬天':
        list.addAll(['晚来天欲雪，能饮一杯无', '冬天要靠近温暖的事物']);
        break;
    }

    // 时段诗句
    if (hour >= 5 && hour < 9) {
      list.add('清晨入古寺，初日照高林');
    } else if (hour >= 17 && hour < 20) {
      list.add('夕阳无限好，只是近黄昏');
    } else if (hour >= 23 || hour < 5) {
      list.add('月落乌啼霜满天，江枫渔火对愁眠');
    } else if (hour >= 20 && hour < 23) {
      list.add('海上生明月，天涯共此时');
    }

    // 天气诗句（"空山新雨后"已在秋天季节诗句中，不重复添加）
    if (weather == 'rain') {
      list.add('好雨知时节，当春乃发生');
    }
    if (weather == 'snow') {
      list.addAll(['忽如一夜春风来，千树万树梨花开', '窗含西岭千秋雪，门泊东吴万里船']);
    }

    return list;
  }

  // ==================== 第六优先：萨摩耶特色 ====================
  List<String> _samoyeTexts(String period, String weather) {
    final list = <String>[
      '汪汪！今天也要陪你记录生活呀',
      '小萨摩想跟你说：今天也要微笑',
      '小萨摩在等你写日记呢',
      '汪！主人今天开心吗？',
      '小萨摩提醒你：该写日记啦',
      '记录生活的每一刻，小萨摩都陪着你',
      '小萨摩在想你呢',
      '萨摩耶的微笑，治愈一切',
      '慢慢来，不着急，小萨摩一直在',
    ];

    // 天气相关
    if (weather == 'rain') {
      list.addAll(['汪！下雨了，主人带伞了吗', '小萨摩不喜欢下雨，毛会湿湿的']);
    }
    if (weather == 'snow') {
      list.addAll(['汪汪！下雪了！小萨摩去踩雪', '雪地里的萨摩耶，分不清哪个是雪哪个是狗']);
    }
    if (weather == 'hot') {
      list.addAll(['热到萨摩耶都吐舌头了', '汪...好热...小萨摩要化了']);
    }
    if (weather == 'cold') {
      list.addAll(['冷到萨摩耶都不想动了', '汪！主人多穿点，小萨摩有毛不怕冷']);
    }

    // 时段相关
    final hour = DateTime.now().hour;
    if (hour >= 23 || hour < 5) {
      list.addAll(['汪...小萨摩困了，主人也早点睡吧', '晚安呀，小萨摩明天还在']);
    } else if (period == '晚上') {
      list.addAll(['小萨摩在陪主人呢', '晚上好呀，今天过得怎么样']);
    }
    if (period == '清晨' || period == '早上') {
      list.addAll(['汪汪！早安！小萨摩起床啦', '新的一天，小萨摩陪你一起冲']);
    }

    return list;
  }

  // ==================== 第七优先：节日/特殊日期 ====================
  List<String> _specialDateTexts(int month, int day, int weekday) {
    final list = <String>[];
    if (month == 1 && day == 1) list.add('新年快乐');
    if (month == 2 && day == 14) list.add('情人节快乐');
    if (month == 3 && day == 8) list.add('女神节快乐');
    if (month == 5 && day == 1) list.add('劳动节快乐，好好休息');
    if (month == 5 && day == 20) list.add('520，我爱你');
    if (month == 6 && day == 1) list.add('儿童节快乐，保持童心');
    if (month == 9 && day == 10) list.add('教师节快乐');
    if (month == 10 && day == 1) list.add('国庆节快乐');
    if (month == 12 && day == 25) list.add('圣诞节快乐');

    if (day == 1) list.add('新的一个月，新的开始');
    if (day == 15) list.add('月中了，这个月过得怎么样？');
    if (day >= 28) list.add('月底了，这个月过得充实吗？');

    if (weekday == 1) list.add('周一，新的一周开始了');
    if (weekday == 3) list.add('周三，一周过半了');
    if (weekday == 5) list.add('周五啦，明天就是周末了');

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.614; // 占屏幕61.4%（原58.5%增加5%）

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: widget.savedEntry != null
                ? _buildSavedEntryCard()
                : widget.isDefault
                    ? _buildDefaultCard()
                    : _buildNormalCard(),
          ),
        ),
      ),
    );
  }

  /// 默认日记卡片（有黑色条幅，增加7%）— 点击查看给用户的第一封信
  Widget _buildDefaultCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          SmoothRoute(builder: (_) => DiaryDetailScreen(entry: LetterService.letterEntry, title: '给用户的第一封信')),
        );
      },
      child: Column(
        children: [
          // 萨摩耶图片（占84%）
          Expanded(
            flex: 84,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: _buildDefaultImage(),
            ),
          ),
          // 黑色条幅（占16%，原15%增加7%）
          Expanded(
            flex: 16,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF1A1A1A),
              child: Center(child: _buildDefaultBlackBar()),
            ),
          ),
        ],
      ),
    );
  }

  /// 普通日记卡片（底部按钮 + 形象区域）
  Widget _buildNormalCard() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          // 上部内容区（日期 + 动态文案 + 图片）
          Expanded(child: _buildNormalContent()),
          // 底部：按钮
          const SizedBox(height: 12),
          _buildBottomSection(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  /// 已保存日记卡片：和普通卡片一样，只是左上角显示日期 + 点击跳转详情
  Widget _buildSavedEntryCard() {
    final entry = widget.savedEntry;
    // 用 id 字符串的稳定 hash（跨启动一致），而非 Dart hashCode（可能变化）
    final stableSeed = entry.id.runes.fold(0, (s, r) => s * 31 + r).abs();
    final imagePath = _getImageForTime(entry.createdAt, extraSeed: stableSeed);

    // 提取标题：第一行如果是 # 开头就取标题，否则取第一行
    String title, body;
    final firstLine = entry.content.split('\n').first.trim();
    if (firstLine.startsWith('# ')) {
      title = firstLine.substring(2);
      body = entry.content.split('\n').skip(1).join('\n').trim();
    } else if (firstLine.startsWith('## ')) {
      title = firstLine.substring(3);
      body = entry.content.split('\n').skip(1).join('\n').trim();
    } else {
      title = firstLine;
      body = entry.content.split('\n').skip(1).join('\n').trim();
    }
    if (title.length > 20) title = '${title.substring(0, 20)}...';
    final preview = body.length > 40 ? '${body.substring(0, 40)}...' : body;

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日期
                  Text('${entry.createdAt.month}月${entry.createdAt.day}日  '
                       '${entry.createdAt.hour.toString().padLeft(2,'0')}:${entry.createdAt.minute.toString().padLeft(2,'0')}',
                       style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
                  const SizedBox(height: 8),
                  // 标题
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(preview, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF888888)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const Spacer(flex: 1),
                  // 小狗图片
                  Expanded(
                    flex: 9,
                    child: Center(
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          1, 0, 0, 0, 8, 0, 1, 0, 0, 8, 0, 0, 1, 0, 8, 0, 0, 0, 1, 0,
                        ]),
                        child: Image.asset(imagePath, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(Icons.pets, size: 40, color: Colors.grey[300])),
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSavedBottomSection(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }


  Widget _buildSavedBottomSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            SmoothRoute(builder: (_) => DiaryDetailScreen(entry: widget.savedEntry)),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF1A1A1A).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Text('查看', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    );
  }

  /// 底部区域：左侧形象 + 居中按钮
  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // 居中胶囊按钮（高级感）
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                SmoothRoute(builder: (context) => const DiaryWizardScreen()),
              ).then((_) => widget.onDiarySaved?.call());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 16, color: Colors.white.withValues(alpha: 0.9)),
                  const SizedBox(width: 8),
                  const Text(
                    '记录我的今天',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 默认日记：萨摩耶递信图片（缩小10%，白色背景）
  Widget _buildDefaultImage() {
    return Container(
      color: Colors.white,
      child: Center(
        child: SizedBox(
          width: 305,  // 277放大10%
          height: 349, // 317放大10%
          child: Image.asset(
            'assets/images/samoye/samoye_letter.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('图片加载失败: $error', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 默认日记：黑色区域文字
  Widget _buildDefaultBlackBar() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '感谢相遇',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '—',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '一份萨摩小耶的来信',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// 普通日记：内容区域（新笔记）
  Widget _buildNormalContent() {
    final imagePath = _getDynamicImage();
    debugPrint('[图片] 普通卡片加载路径: $imagePath');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期行
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _getDay(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: _themeColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  _getYearMonth(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('—', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          const SizedBox(height: 8),
          // 动态文案（根据时间、天气、季节等变化）
          Text(
            _getDynamicText(),
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF333333),
            ),
          ),
          // 动态图片（ColorFilter 美白背景，剩余空间自适应，不溢出）
          const Spacer(flex: 1),
          Expanded(
            flex: 9,
            child: Center(
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  // RGB 各通道 +8，将近白色背景(~248)推向纯白(255)
                  // 比 +12 更保守，保护浅色角色细节
                  1, 0, 0, 0, 8,
                  0, 1, 0, 0, 8,
                  0, 0, 1, 0, 8,
                  0, 0, 0, 1, 0,
                ]),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('[图片] 普通卡片加载失败: $error, 路径: $imagePath');
                    return Icon(Icons.pets, size: 40, color: Colors.grey[300]);
                  },
                ),
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

}
