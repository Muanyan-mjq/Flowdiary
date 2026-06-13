import 'package:flutter/material.dart';
import '../models/monthly_card_model.dart';
import '../utils/cover_storage.dart';
import 'responsive_app_bar.dart';

/// 月份卡片：封面图铺满 + 左上角月份 + 底部进度条 + 右上角菜单
class MonthlyCardItem extends StatelessWidget {
  final MonthlyCardModel model;
  final int year; // 所属年份（封面按年+月存储）
  final VoidCallback? onTap;
  /// 封面图变化回调（传入年份、月份号和新的图片路径）
  final void Function(int year, int month, String assetPath)? onCoverChanged;

  const MonthlyCardItem({
    super.key,
    required this.model,
    required this.year,
    this.onTap,
    this.onCoverChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildCoverImage(),
            _buildTopLabel(),
            _buildMoreButton(context),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── 封面图 ──────────────────────────────────────────

  Widget _buildCoverImage() {
    if (model.assetPath != null) {
      return Image.asset(
        model.assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final hsl = HSLColor.fromColor(model.themeColor);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor(),
            hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor(),
          ],
        ),
      ),
    );
  }

  // ── 左上角月份标签 ──────────────────────────────────

  Widget _buildTopLabel() {
    return Positioned(
      top: 28,
      left: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${model.monthNumber}',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            model.monthName.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ── 右上角三个点按钮 ────────────────────────────────

  Widget _buildMoreButton(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: GestureDetector(
        onTap: () => _showCoverSheet(context),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.more_horiz,
            color: Colors.white,
            size: 26,
            shadows: [Shadow(blurRadius: 4, color: Colors.black38)],
          ),
        ),
      ),
    );
  }

  // ── 底部封面选择弹窗 ────────────────────────────────

  void _showCoverSheet(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = screenHeight * 0.55;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: sheetHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _CoverPickerSheet(
          monthNumber: model.monthNumber,
          scrollController: ScrollController(),
          onImageSelected: (imagePath) {
            Navigator.pop(context);
            CoverStorage.saveCover(year, model.monthNumber, imagePath);
            onCoverChanged?.call(year, model.monthNumber, imagePath);
          },
          onResetDefault: () {
            Navigator.pop(context);
            CoverStorage.resetCover(year, model.monthNumber);
            onCoverChanged?.call(year, model.monthNumber,
              'assets/images/monthly/${model.monthNumber.toString().padLeft(2, '0')}.jpg');
          },
        ),
      ),
    );
  }

  // ── 底部进度条（亮色处理）──────────────────────────

  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
        child: Row(
          children: [
            Expanded(child: _buildProgressBar()),
            const SizedBox(width: 14),
            Text(
              '${model.currentProgress}/${model.totalDays}天',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 进度条 ─────────────────────────────────────────

  Widget _buildProgressBar() {
    final accent = _accentColor;

    return Container(
      height: 5,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: model.progress,
        child: Container(
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Color get _accentColor {
    final hsl = HSLColor.fromColor(model.themeColor);
    return hsl
        .withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.2).clamp(0.0, 1.0))
        .toColor();
  }
}

// ═══════════════════════════════════════════════════════
// 底部封面选择弹窗（占屏幕 30%）
// ═══════════════════════════════════════════════════════

class _CoverPickerSheet extends StatefulWidget {
  final int monthNumber;
  final ScrollController scrollController;
  final ValueChanged<String>? onImageSelected;
  final VoidCallback? onResetDefault;

  const _CoverPickerSheet({
    required this.monthNumber,
    required this.scrollController,
    this.onImageSelected,
    this.onResetDefault,
  });

  @override
  State<_CoverPickerSheet> createState() => _CoverPickerSheetState();
}

class _CoverPickerSheetState extends State<_CoverPickerSheet> {
  int _selectedCategory = 0;
  String? _selectedImage; // 当前选中的图片路径

  // 图片素材库 — 全量资产
  static const _monthlyCovers = <String>[
    'assets/images/monthly/01.jpg',
    'assets/images/monthly/02.jpg',
    'assets/images/monthly/03.jpg',
    'assets/images/monthly/04.jpg',
    'assets/images/monthly/05.jpg',
    'assets/images/monthly/06.jpg',
    'assets/images/monthly/07.jpg',
    'assets/images/monthly/08.jpg',
    'assets/images/monthly/09.jpg',
    'assets/images/monthly/10.jpg',
    'assets/images/monthly/11.jpg',
    'assets/images/monthly/12.jpg',
  ];

  static const _samoyeDaily = <String>[
    'assets/images/diary_mascot/时段/深夜/睡觉.jpg',
    'assets/images/diary_mascot/时段/深夜/看星星.jpg',
    'assets/images/diary_mascot/时段/清晨/起床.jpg',
    'assets/images/diary_mascot/时段/清晨/晨跑.jpg',
    'assets/images/diary_mascot/时段/早上/吃早餐.jpg',
    'assets/images/diary_mascot/时段/早上/看手机.jpg',
    'assets/images/diary_mascot/时段/上午/工作.jpg',
    'assets/images/diary_mascot/时段/上午/学习.jpg',
    'assets/images/diary_mascot/时段/中午/吃午饭.jpg',
    'assets/images/diary_mascot/时段/中午/午休.jpg',
    'assets/images/diary_mascot/时段/下午/喝咖啡.jpg',
    'assets/images/diary_mascot/时段/下午/摸鱼.jpg',
    'assets/images/diary_mascot/时段/傍晚/散步.jpg',
    'assets/images/diary_mascot/时段/傍晚/做饭.jpg',
    'assets/images/diary_mascot/时段/晚上/洗澡.jpg',
    'assets/images/diary_mascot/时段/晚上/看电影.jpg',
  ];

  static const _samoyeStyle = <String>[
    'assets/images/diary_mascot/形象/听音乐/听音乐.jpg',
    'assets/images/diary_mascot/形象/看书/看书.jpg',
    'assets/images/diary_mascot/形象/拍照/拍照.jpg',
    'assets/images/diary_mascot/形象/玩偶/玩偶.jpg',
    'assets/images/diary_mascot/形象/睡觉/睡觉.jpg',
    'assets/images/diary_mascot/形象/购物/购物.jpg',
  ];

  // 分类定义（名称 + 图片列表，空列表的分类不显示）
  static const _categories = <_Category>[
    _Category('全部', [
      ..._monthlyCovers, ..._samoyeDaily, ..._samoyeStyle,
    ]),
    _Category('月份封面', _monthlyCovers),
    _Category('萨摩耶·日常', _samoyeDaily),
    _Category('萨摩耶·形象', _samoyeStyle),
  ];

  List<String> get _currentImages => _categories[_selectedCategory].images;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: CustomScrollView(
        controller: widget.scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 固定头部
          SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖拽指示条
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 8),
                  child: Container(
                    width: 32, height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _buildCameraRow(context),
                Divider(height: 1, color: Colors.grey[200]),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '从素材库中选择封面',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                ),
                _buildCategoryTabs(),
              ],
            ),
          ),
          // 选中预览 + 确认按钮（有选中时显示）
          if (_selectedImage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(_selectedImage!, width: 48, height: 48, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('已选中', style: TextStyle(fontSize: 13, color: Color(0xFF666666)))),
                    ElevatedButton(
                      onPressed: () => widget.onImageSelected?.call(_selectedImage!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90D9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('设为封面', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          // 图片网格
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: _buildImageGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: appBgColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_outlined, size: 20, color: Color(0xFF666666)),
                SizedBox(width: 8),
                Text('从本地相机选择', style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onResetDefault,
            child: const Text('恢复默认', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4A90D9))),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (_, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1A1A1A) : appBgColor(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${cat.name} (${cat.images.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : const Color(0xFF999999),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageGrid() {
    final images = _currentImages;
    if (images.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('暂无图片', style: TextStyle(color: Color(0xFF999999)))),
      );
    }
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      delegate: SliverChildBuilderDelegate(
        (_, index) => _buildImageItem(images[index]),
        childCount: images.length,
      ),
    );
  }

  /// 单个图片项（支持选中状态）
  Widget _buildImageItem(String path) {
    final isSelected = _selectedImage == path;
    return GestureDetector(
      onTap: () => setState(() => _selectedImage = isSelected ? null : path),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: const Color(0xFF4A90D9), width: 3)
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF0F0F0),
                  child: const Icon(Icons.image_outlined, color: Colors.grey, size: 24),
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                right: 4, bottom: 4,
                child: Container(
                  width: 22, height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A90D9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 封面分类数据
class _Category {
  final String name;
  final List<String> images;
  const _Category(this.name, this.images);
}
