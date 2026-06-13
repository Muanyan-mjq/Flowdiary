import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../widgets/responsive_app_bar.dart';
import '../utils/theme_service.dart';

class ThemeScreen extends StatefulWidget {
  /// 主题颜色改变回调
  final ValueChanged<Color>? onThemeChanged;

  const ThemeScreen({super.key, this.onThemeChanged});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  /// 预设颜色列表
  static const _presets = <Map<String, dynamic>>[
    {'name': '冰川蓝', 'color': Color(0xFF87CEEB)},
    {'name': '樱花粉', 'color': Color(0xFFFFB7C5)},
    {'name': '蜜瓜橙', 'color': Color(0xFFFFAA7A)},
    {'name': '珊瑚红', 'color': Color(0xFFFF6B6B)},
    {'name': '柠檬黄', 'color': Color(0xFFFFD700)},
    {'name': '琥珀橙', 'color': Color(0xFFFFB347)},
    {'name': '薄荷绿', 'color': Color(0xFF98D8C8)},
    {'name': '天青色', 'color': Color(0xFF4ECDC4)},
    {'name': '松石绿', 'color': Color(0xFF20B2AA)},
    {'name': '鸢尾蓝', 'color': Color(0xFF5B7FFF)},
    {'name': '薰衣草紫', 'color': Color(0xFFB8A9C9)},
    {'name': '深空灰', 'color': Color(0xFF4A4A4A)},
  ];

  int _selectedPresetIndex = 0;
  Color? _customColor; // null = 使用预设，非 null = 使用自定义

  /// 当前生效的主题颜色
  Color get _activeColor => _customColor ?? (_presets[_selectedPresetIndex]['color'] as Color);

  /// 是否是自定义颜色
  bool get _isCustom => _customColor != null;

  @override
  void initState() {
    super.initState();
    _loadSavedTheme();
  }

  /// 加载已保存的主题
  Future<void> _loadSavedTheme() async {
    final saved = await ThemeService.getThemeColor();
    if (saved == null) {
      // 首次使用，默认选中冰川蓝
      setState(() => _selectedPresetIndex = 0);
      return;
    }

    // 检查是否匹配预设
    final matchIdx = _presets.indexWhere(
      (p) => (p['color'] as Color).toARGB32() == saved.toARGB32(),
    );

    if (matchIdx != -1) {
      setState(() {
        _selectedPresetIndex = matchIdx;
        _customColor = null;
      });
    } else {
      // 自定义颜色
      setState(() {
        _selectedPresetIndex = 0; // 兜底选中第一个
        _customColor = saved;
      });
    }
  }

  /// 选中预设颜色 — 即选即应用
  Future<void> _selectPreset(int index) async {
    setState(() {
      _selectedPresetIndex = index;
      _customColor = null;
    });
    await ThemeService.saveThemeColor(_activeColor);
    widget.onThemeChanged?.call(_activeColor);
  }

  /// 打开调色盘
  void _showColorPicker() {
    Color pickerColor = _activeColor;
    final entryColor = pickerColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final screenHeight = MediaQuery.of(context).size.height;
        return Container(
          height: screenHeight * 0.60,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                children: [
                  // 拖拽条
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    width: 36, height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 标题栏 + 常用颜色同行
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setModalState(() => pickerColor = entryColor),
                          child: Text('还原', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        ),
                        const Spacer(),
                        const Text('自定义颜色',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                        ),
                        const Spacer(),
                        Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: pickerColor,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: pickerColor.withValues(alpha: 0.3), blurRadius: 6)],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 常用颜色 — 单行横向滚动
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        Colors.red, Colors.deepOrange, Colors.orange, Colors.amber, Colors.yellow,
                        Colors.lightGreen, Colors.green, Colors.teal, Colors.cyan,
                        Colors.lightBlue, Colors.blue, Colors.indigo, Colors.deepPurple, Colors.purple,
                        Colors.pink, Colors.brown, Colors.grey, Colors.blueGrey,
                      ].map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildQuickColor(c, pickerColor, () => setModalState(() => pickerColor = c)),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 调色盘
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (c) => setModalState(() => pickerColor = c),
                        enableAlpha: false,
                        displayThumbColor: true,
                        paletteType: PaletteType.hsvWithHue,
                        labelTypes: const [],
                        portraitOnly: true,
                      ),
                    ),
                  ),
                  // 按钮
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('取消', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              _customColor = pickerColor;
                              Navigator.pop(ctx);
                              await ThemeService.saveThemeColor(pickerColor);
                              widget.onThemeChanged?.call(pickerColor);
                              if (mounted) setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: pickerColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('选择此颜色', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// 快选颜色按钮
  Widget _buildQuickColor(Color color, Color current, VoidCallback onTap) {
    final isSame = color.toARGB32() == current.toARGB32();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSame ? Border.all(color: Colors.black, width: 2.5) : null,
        ),
        child: isSame ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
      ),
    );
  }


  /// 恢复默认主题 — 立即应用
  Future<void> _resetToDefault() async {
    setState(() {
      _selectedPresetIndex = 0;
      _customColor = null;
    });
    await ThemeService.saveThemeColor(_activeColor);
    widget.onThemeChanged?.call(_activeColor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor(context),
      body: Column(
        children: [
          ResponsiveAppBar(
            backgroundColor: appBgColor(context),
            titleAlignment: CrossAxisAlignment.center,
            left: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 22, color: Color(0xFF1A1A1A)),
              onPressed: () => Navigator.pop(context),
            ),
            center: const Text(
              '主题设置',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 实时预览 ──
                  _buildPreview(),
                  const SizedBox(height: 28),
                  // ── 预设颜色 ──
                  const Text(
                    '选择主题色',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 6),
                  Text('主题色将应用于按钮、图标等元素', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 20),
                  // 预设颜色网格
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: _presets.length + (_isCustom ? 1 : 0),
                    itemBuilder: (context, index) {
                      // 如果当前是自定义颜色，在末尾追加自定义卡片
                      final isCustomCard = _isCustom && index == _presets.length;

                      if (isCustomCard) {
                        return _buildColorCard(
                          color: _customColor!,
                          name: '自定义',
                          isSelected: true,
                          onTap: _showColorPicker,
                        );
                      }

                      final preset = _presets[index];
                      final color = preset['color'] as Color;
                      final name = preset['name'] as String;
                      final isSelected = !_isCustom && _selectedPresetIndex == index;

                      return _buildColorCard(
                        color: color,
                        name: name,
                        isSelected: isSelected,
                        onTap: () => _selectPreset(index),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  // 调色盘入口
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showColorPicker,
                      icon: Icon(Icons.palette_outlined, size: 18, color: Colors.grey[700]),
                      label: Text('调色盘', style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 恢复默认（低调文字链）
                  Center(
                    child: GestureDetector(
                      onTap: _resetToDefault,
                      child: Text(
                        '恢复默认',
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
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

  /// 颜色卡片
  Widget _buildColorCard({
    required Color color,
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: color, width: 2.5)
              : Border.all(color: Colors.transparent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 实时预览区域
  Widget _buildPreview() {
    return Container(
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
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: _activeColor),
              const SizedBox(width: 6),
              Text(
                '预览效果',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 模拟导航栏图标
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPreviewIcon(Icons.book, '日记'),
              _buildPreviewIcon(Icons.explore, '发现'),
              _buildPreviewIcon(Icons.chat_bubble_outline, '社区'),
              _buildPreviewIcon(Icons.auto_awesome, '心情'),
              _buildPreviewIcon(Icons.person_outline, '我的'),
            ],
          ),
          const SizedBox(height: 16),
          // 模拟按钮
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _activeColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('按钮预览', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          // 模拟进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: 0.6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_activeColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: _activeColor),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }
}
