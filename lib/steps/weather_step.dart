import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/user_service.dart';

// ==================== Moo 日记配色（mood_step 依赖） ====================

class MooColors {
  static const primary = Color(0xFF4ACBD4);
  static const textPrimary = Color(0xFF2C3E50);
  static const textSecondary = Color(0xFF999999);
  static const textBody = Color(0xFF333333);
  static const bgLight = Color(0xFFF5F9FA);
}

// ==================== 天气数据 ====================

class _WeatherItem {
  final String id;
  final String label;
  final IconData icon;
  const _WeatherItem(this.id, this.label, this.icon);
}

const _weatherList = [
  _WeatherItem('sunny', '晴', Icons.wb_sunny),
  _WeatherItem('cloudy', '多云', Icons.cloud),
  _WeatherItem('overcast', '阴', Icons.filter_drama),
  _WeatherItem('rain', '雨', Icons.grain),
  _WeatherItem('snow', '雪', Icons.ac_unit),
  _WeatherItem('fog', '雾', Icons.foggy),
  _WeatherItem('thunder', '雷暴', Icons.thunderstorm),
  _WeatherItem('hail', '冰雹', Icons.severe_cold),
  _WeatherItem('freezing_rain', '冻雨', Icons.water_drop),
  _WeatherItem('dust', '沙尘暴', Icons.blur_on),
  _WeatherItem('typhoon', '台风', Icons.air),
  _WeatherItem('graupel', '霰', Icons.cloud_queue),
];

// ==================== 时间段 ====================

enum _TimePeriod { morning, afternoon, evening }

_TimePeriod _getTimePeriod() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 11) return _TimePeriod.morning;
  if (h >= 11 && h < 17) return _TimePeriod.afternoon;
  return _TimePeriod.evening;
}

// ==================== 文案池 ====================

const Map<String, Map<_TimePeriod, List<String>>> _weatherTexts = {
  'sunny': {
    _TimePeriod.morning: ['光比我先醒了', '今天的云都休假去了', '天蓝得不像话'],
    _TimePeriod.afternoon: ['阳光比心情更明媚', '太阳今天格外慷慨', '连影子都比我开心'],
    _TimePeriod.evening: ['星星今晚加班了', '月亮干净得像刚洗过', '夜空清澈，心事也变轻了'],
  },
  'cloudy': {
    _TimePeriod.morning: ['云在开会，讨论要不要下雨', '天空今天穿了好几层', '今天的云很柔软，像没想好的心事'],
    _TimePeriod.afternoon: ['云把太阳藏进袖子里', '云层很厚，阳光在努力挤出来', '天上有好多棉花糖在排队'],
    _TimePeriod.evening: ['云遮住了月亮，但月亮还在', '云在夜里赶路，走得很慢', '云铺满了天，像给夜空盖了被子'],
  },
  'overcast': {
    _TimePeriod.morning: ['天空今天心情不太好', '天阴着，正好偷个懒', '天空在酝酿一个故事'],
    _TimePeriod.afternoon: ['灰色是今天的主色调', '乌云也有温柔的时候', '天空在给自己放个假'],
    _TimePeriod.evening: ['阴天的夜，安静得很认真', '天还阴着，但明天会亮的', '阴天的月亮，在练习隐身术'],
  },
  'rain': {
    _TimePeriod.morning: ['雨是天空写给大地的信', '每滴雨里都藏着一句话', '雨下得很有耐心，不急着停'],
    _TimePeriod.afternoon: ['雨水在玻璃上写诗', '窗外的雨有自己的节奏', '有些事想不清楚，就听听雨'],
    _TimePeriod.evening: ['雨声是最好的睡前故事', '雨在敲窗，说有晚安要转达', '雨一直下，很适合什么都不想'],
  },
  'snow': {
    _TimePeriod.morning: ['雪把世界调成了静音模式', '一觉醒来，世界被格式化了', '雪落下来的时候，时间变慢了'],
    _TimePeriod.afternoon: ['踩在雪上，像踩在云上', '每一片雪都是天空的碎碎念', '雪是冬天写的诗，分行落在枝头'],
    _TimePeriod.evening: ['雪是心事静谧的注解', '雪夜适合把所有话都埋在雪里', '下雪的夜晚，记忆格外清晰'],
  },
  'fog': {
    _TimePeriod.morning: ['今天的城市加了柔光滤镜', '雾是云下来散步了', '雾里的世界，像没加载完的地图'],
    _TimePeriod.afternoon: ['雾把世界藏起来了一半', '能见度很低，但心情可以很透亮', '雾还没散，像在做一场白日梦'],
    _TimePeriod.evening: ['雾里的路灯，像泡在水里的糖', '雾夜适合迷路，也适合想清楚', '雾把夜晚变成了一个谜'],
  },
  'thunder': {
    _TimePeriod.morning: ['不知道哪位大师在渡劫', '打雷是云和云在吵架', '天空在发脾气，但哄不好的那种'],
    _TimePeriod.afternoon: ['天空在练习打鼓', '闪电在给天空拍X光片', '雷暴来得快去得也快，像脾气'],
    _TimePeriod.evening: ['雷声是天空的睡前咆哮', '雷雨夜，适合胡思乱想', '打雷的时候，离窗户远一点'],
  },
  'hail': {
    _TimePeriod.morning: ['天空在往下扔冰块，不收钱的那种', '噼里啪啦，天在发脾气砸东西', '天空在筛豆子，筛得有点猛'],
    _TimePeriod.afternoon: ['冰雹是云吐的籽', '今天的雨带了些硬货', '冰雹砸在窗上，像在敲门'],
    _TimePeriod.evening: ['下冰雹的夜，屋里就是全世界', '天在发泄，砸完了就好了', '雹停了，夜晚恢复了它的呼吸'],
  },
  'freezing_rain': {
    _TimePeriod.morning: ['雨落下来就成了冰，像时间被冻住了', '今天的雨有一颗冰封的心', '冻雨把世界裹了一层透明的壳'],
    _TimePeriod.afternoon: ['雨滴挂在枝头，变成了水晶', '冻雨是冬天写给春天的信', '每一滴雨都在半空被定格'],
    _TimePeriod.evening: ['冻雨夜，世界像被施了魔法', '路灯下的冻雨，闪着钻石的光', '冻雨停了，留下一个透明的世界'],
  },
  'dust': {
    _TimePeriod.morning: ['今天的世界开了怀旧滤镜', '天黄了，但故事还在继续', '风在搬运远方的土，不知道寄给谁'],
    _TimePeriod.afternoon: ['沙尘在给城市做旧', '天空说今天想换个颜色', '黄沙漫天，但好心情不能被吹走'],
    _TimePeriod.evening: ['沙尘过去了，明天会蓝的', '风沙走后，留了一层薄薄的遗憾', '黄了一天的天，终于闭上了眼睛'],
  },
  'typhoon': {
    _TimePeriod.morning: ['台风过境，今天适合宅着', '风雨交加，世界在咆哮', '台风天，躲在家里就是胜利'],
    _TimePeriod.afternoon: ['台风把城市按下了暂停键', '风大到什么计划都可以取消', '风在外面巡逻，屋里很安全'],
    _TimePeriod.evening: ['台风夜，风在窗外讲了一整夜', '台风走了，世界恢复了它的呼吸', '大风吹过，留下一个干净的夜晚'],
  },
  'graupel': {
    _TimePeriod.morning: ['天上在下白色的小珍珠', '霰是雪的前奏，打着节拍', '小冰粒敲在窗上，像在数数'],
    _TimePeriod.afternoon: ['霰落在地上，像撒了一地白糖', '白色的小颗粒，是天空的碎碎冰', '霰是冬天的逗号，雪才是句号'],
    _TimePeriod.evening: ['霰停了，也许雪要来了', '小冰粒的声音，像远处有人在敲门', '霰落了一地，安静的夜晚开始了'],
  },
};

// ==================== WeatherStep ====================

class WeatherStep extends StatefulWidget {
  final String? selectedWeather;
  final Function(String) onWeatherSelected;
  final VoidCallback? onSkip;
  final VoidCallback? onConfirm; // 点击确认按钮

  const WeatherStep({
    super.key,
    this.selectedWeather,
    required this.onWeatherSelected,
    this.onSkip,
    this.onConfirm,
  });

  @override
  State<WeatherStep> createState() => _WeatherStepState();
}

class _WeatherStepState extends State<WeatherStep>
    with TickerProviderStateMixin {
  String? _selectedId;
  String? _responseText;

  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  late AnimationController _entranceController;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;

  late PageController _weatherPageController;
  int _currentWeatherPage = 0;
  String? _pressedId;

  List<List<_WeatherItem>> get _weatherPages => [
        _weatherList.sublist(0, 6),
        _weatherList.sublist(6, 12),
      ];

  String get _nickname =>
      UserService.instance.nickname.isNotEmpty
          ? UserService.instance.nickname
          : '小萨摩';

  @override
  void initState() {
    super.initState();
    _weatherPageController = PageController();

    _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn = CurvedAnimation(
      parent: _fadeController, curve: Curves.easeOutCubic);

    _entranceController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.7, curve: Curves.easeOut));
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController, curve: Curves.easeOutCubic));

    _entranceController.forward();

    if (widget.selectedWeather != null && widget.selectedWeather!.isNotEmpty) {
      final item = _weatherList.cast<_WeatherItem?>().firstWhere(
            (w) => w?.label == widget.selectedWeather,
            orElse: () => null);
      if (item != null) {
        _selectedId = item.id;
        _responseText = _generateText(item.id);
        _fadeController.value = 1.0;
        _entranceController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _entranceController.dispose();
    _weatherPageController.dispose();
    super.dispose();
  }

  String _generateText(String weatherId) {
    final period = _getTimePeriod();
    final texts = _weatherTexts[weatherId]?[period] ?? [];
    if (texts.isEmpty) return '今天也要好好记录生活呀';
    final now = DateTime.now();
    final random = Random(now.hour * 60 + now.minute);
    return texts[random.nextInt(texts.length)];
  }

  String _buttonText(_WeatherItem item) => '是${item.label}天啊';

  IconData _selectedIcon() {
    if (_selectedId == null) return Icons.wb_sunny;
    return _weatherList.firstWhere((w) => w.id == _selectedId).icon;
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 5) return '夜深了';
    if (h < 7) return '清晨好';
    if (h < 9) return '早上好';
    if (h < 12) return '上午好';
    if (h < 14) return '中午好';
    if (h < 17) return '下午好';
    if (h < 19) return '傍晚好';
    if (h < 22) return '晚上好';
    return '夜深了';
  }

  void _onWeatherTap(_WeatherItem item) {
    setState(() {
      _selectedId = item.id;
      _responseText = _generateText(item.id);
    });
    widget.onWeatherSelected(item.label);
    _fadeController.forward(from: 0);
  }

  void _onSkip() => widget.onSkip?.call();

  // ═══════════════════════════════════════════ Build ═══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeArea = screenHeight * 0.04; // 4% 安全距离
    final gridWidth = screenWidth * 0.82;

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // ── 全部跳过（顶部 4% 安全距离）──
          SizedBox(height: safeArea + 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFFAAAAAA)),
              ),
              GestureDetector(
                onTap: _onSkip,
                behavior: HitTestBehavior.opaque,
                child: const Text('全部跳过',
                    style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 52),
        // ── 左侧天气图标 + 右侧三行文字 ──
        AnimatedBuilder(
          animation: _entranceController,
          builder: (context, child) => Opacity(
            opacity: _entranceFade.value,
            child: Transform.translate(
              offset: Offset(0, _entranceSlide.value.dy * MediaQuery.sizeOf(context).height * 0.25),
              child: child,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：天气图标（自然占据左侧空白）
                if (_selectedId != null)
                  AnimatedBuilder(
                    animation: _fadeIn,
                    builder: (context, child) => Opacity(
                      opacity: _fadeIn.value,
                      child: Transform.translate(
                        offset: Offset(-20 * (1 - _fadeIn.value), 0),
                        child: Transform.rotate(
                          angle: -0.2 * (1 - _fadeIn.value),
                          child: Transform.scale(
                            scale: 0.4 + 0.6 * _fadeIn.value,
                            child: child,
                          ),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, top: 2, right: 16),
                      child: Icon(
                        _selectedIcon(),
                        size: 68,
                        color: const Color(0xFFBBBBBB),
                      ),
                    ),
                  ),
                const Spacer(),
                // 右侧：三行文字（全部右对齐）
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 第一行：问候语
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _getGreeting(),
                            style: TextStyle(fontSize: 17, fontStyle: FontStyle.italic,
                                color: const Color(0xFF1A1A1A)),
                          ),
                          const TextSpan(text: '  '),
                          TextSpan(
                            text: _nickname,
                            style: TextStyle(fontSize: 17, fontStyle: FontStyle.italic,
                                color: const Color(0xFF1A1A1A)),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 第二行：副标题
                    const Text(
                      '不知道你那里天气怎么样？',
                      style: TextStyle(fontSize: 17, fontStyle: FontStyle.italic, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 4),
                    // 第三行：动态文案
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _responseText != null
                          ? AnimatedBuilder(
                              animation: _fadeIn,
                              builder: (context, child) => Opacity(
                                opacity: _fadeIn.value,
                                child: Transform.translate(
                                  offset: Offset(0, 6 * (1 - _fadeIn.value)),
                                  child: child,
                                ),
                              ),
                              child: Text(
                                '"$_responseText"',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF999999), height: 1.6),
                              ),
                            )
                          : const SizedBox(height: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── 天气图标：3×2 翻页（无文字标签，纯图标）──
        Center(
          child: SizedBox(
            width: gridWidth,
            height: 280,
            child: PageView.builder(
              controller: _weatherPageController,
              itemCount: _weatherPages.length,
              pageSnapping: true,
              onPageChanged: (p) => setState(() => _currentWeatherPage = p),
              itemBuilder: (_, pageIndex) =>
                  _buildWeatherGrid(_weatherPages[pageIndex]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── 翻页指示 ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_weatherPages.length, (i) {
            final active = i == _currentWeatherPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1A1A1A) : const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        // ── 确认按钮（黑白风格）──
        Center(
          child: GestureDetector(
            onTap: _selectedId != null ? widget.onConfirm : null,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
              decoration: BoxDecoration(
                color: _selectedId != null ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _selectedId != null
                    ? _buttonText(_weatherList.firstWhere((w) => w.id == _selectedId))
                    : '选好啦',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _selectedId != null ? Colors.white : const Color(0xFFBBBBBB),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════ Sub-widgets ═══════════════════════════════════════════

  Widget _buildWeatherGrid(List<_WeatherItem> items) {
    final top = items.sublist(0, 3);
    final bot = items.sublist(3, 6);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: top.map((item) => _buildWeatherButton(item, _selectedId == item.id)).toList(),
        ),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: bot.map((item) => _buildWeatherButton(item, _selectedId == item.id)).toList(),
        ),
      ],
    );
  }

  Widget _buildWeatherButton(_WeatherItem item, bool isSelected) {
    final pressed = _pressedId == item.id;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedId = item.id),
      onTapUp: (_) => setState(() => _pressedId = null),
      onTapCancel: () => setState(() => _pressedId = null),
      onTap: () => _onWeatherTap(item),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            item.icon,
            size: 38,
            color: isSelected ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}
