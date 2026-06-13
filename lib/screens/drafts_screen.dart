import 'package:flutter/material.dart';
import '../widgets/responsive_app_bar.dart';
import '../widgets/staggered_entrance.dart';
import '../models/diary_input_state.dart';
import '../utils/draft_storage.dart';
import '../main.dart';
import '../utils/smooth_route.dart';
import 'diary_wizard_screen.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  List<DraftEntry> _drafts = [];
  bool _isLoading = true;

  /// 获取当前主题颜色
  Color get _themeColor {
    return ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);
  }

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  /// 加载草稿列表
  Future<void> _loadDrafts() async {
    final drafts = await DraftStorage.loadAll();
    if (mounted) {
      setState(() {
        _drafts = drafts;
        _isLoading = false;
      });
    }
  }

  /// 删除草稿（带确认）
  Future<void> _deleteDraft(DraftEntry draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除草稿'),
        content: const Text('确定要删除这篇草稿吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Color(0xFFFF3B30))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DraftStorage.delete(draft.id);
      await _loadDrafts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('草稿已删除')),
        );
      }
    }
  }

  /// 继续编辑草稿（跳转到日记向导，预填数据）
  void _continueEditing(DraftEntry draft) {
    // 构建预填的日记输入状态
    final initialState = DiaryInputState();
    if (draft.weather.isNotEmpty) initialState.weather = draft.weather;
    if (draft.mood.isNotEmpty) initialState.mood = draft.mood;
    if (draft.events.isNotEmpty) initialState.selectedEvents = Set<String>.from(draft.events);
    // 恢复手写内容
    if (draft.content.isNotEmpty) initialState.writeContent = draft.content;

    // 跳转到日记向导，携带草稿 ID 以便保存后自动删除
    Navigator.push(
      context,
      SmoothRoute(
        builder: (_) => DiaryWizardScreen(
          initialState: initialState,
          draftId: draft.id,
        ),
      ),
    ).then((_) {
      // 返回后刷新草稿列表
      _loadDrafts();
    });
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
              icon: Icon(Icons.arrow_back_ios, size: 18, color: Colors.grey[600]),
              onPressed: () => Navigator.pop(context),
            ),
            center: const Text(
              '草稿箱',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF87CEEB)))
                : _drafts.isEmpty
                    ? _buildEmptyState()
                    : _buildDraftList(),
          ),
        ],
      ),
    );
  }

  /// 空状态页面
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '还没有草稿',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '写日记时未完成的内容会自动保存到这里',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  /// 草稿列表
  Widget _buildDraftList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _drafts.length,
      itemBuilder: (context, index) {
        final draft = _drafts[index];
        return StaggeredEntrance(
          index: index,
          child: _buildDraftCard(draft),
        );
      },
    );
  }

  /// 单个草稿卡片
  Widget _buildDraftCard(DraftEntry draft) {
    // 根据天气/心情生成预览标签
    final tags = <String>[];
    if (draft.weather.isNotEmpty) tags.add(draft.weather);
    if (draft.mood.isNotEmpty) tags.add(draft.mood);

    return Dismissible(
      key: Key(draft.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        await _deleteDraft(draft);
        // 返回 false 因为 _deleteDraft 内部已经处理了删除和刷新
        return false;
      },
      child: GestureDetector(
        onTap: () => _continueEditing(draft),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧内容区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 预览文字（前80字）
                    Text(
                      draft.content.isNotEmpty
                          ? (draft.content.length > 80
                              ? '${draft.content.substring(0, 80)}...'
                              : draft.content)
                          : '（无内容）',
                      style: TextStyle(
                        fontSize: 15,
                        color: draft.content.isNotEmpty
                            ? const Color(0xFF1A1A1A)
                            : Colors.grey[400],
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // 标签行：天气 + 心情 + 时间
                    Row(
                      children: [
                        // 天气和心情标签
                        if (tags.isNotEmpty)
                          ...tags.map((tag) => Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _themeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _themeColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )),
                        const Spacer(),
                        // 字数和时间
                        Text(
                          '${draft.wordCount}字 · ${draft.formattedTime}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 右侧继续编辑箭头
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
