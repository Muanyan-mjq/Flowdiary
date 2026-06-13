import 'package:flutter/material.dart';
import '../models/diary_input_state.dart';
import '../models/diary_entry.dart';
import '../steps/weather_step.dart';
import '../steps/mood_step.dart';
import '../steps/event_step.dart';
import '../steps/writing_step.dart';
import '../utils/diary_storage.dart';
import '../utils/draft_storage.dart';
import '../utils/stats_storage.dart';
import '../widgets/responsive_app_bar.dart';

/// 日记向导主页面
/// 新建或编辑日记
class DiaryWizardScreen extends StatefulWidget {
  /// 可选：从草稿恢复的初始数据
  final DiaryInputState? initialState;
  /// 可选：关联的草稿 ID（保存后自动删除草稿）
  final String? draftId;
  /// 可选：编辑已有日记（传入则预填并替换保存）
  final DiaryEntry? editTarget;

  const DiaryWizardScreen({super.key, this.initialState, this.draftId, this.editTarget});

  @override
  State<DiaryWizardScreen> createState() => _DiaryWizardScreenState();
}

class _DiaryWizardScreenState extends State<DiaryWizardScreen> {
  late final DiaryInputState _diaryState;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();

    if (widget.initialState != null) {
      _diaryState = widget.initialState!;
    } else if (widget.editTarget != null) {
      // 编辑模式：预填已有日记的全部内容
      final e = widget.editTarget!;
      _diaryState = DiaryInputState()
        ..weather = e.weather
        ..mood = e.mood
        ..selectedEvents = Set<String>.from(e.events)
        ..writeContent = e.content
        ..bgColor = e.bgColor;
      _currentStep = 0;
    } else {
      _diaryState = DiaryInputState();
    }
  }

  /// 切换到下一步
  void _goToNextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _saveDiary();
    }
  }

  /// 切换到上一步
  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  /// 构建当前步骤（用 Key 让 AnimatedSwitcher 识别切换）
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return WeatherStep(
          key: const ValueKey('weather'),
          selectedWeather: _diaryState.weather,
          onWeatherSelected: (weather) {
            setState(() => _diaryState.weather = weather);
          },
          onSkip: () {
            // 全部跳过 → 直接跳到写作步骤
            setState(() {
              _diaryState.weather = '';
              _diaryState.mood = '';
              _diaryState.selectedEvents.clear();
              _currentStep = 3;
            });
          },
          onConfirm: () => _goToNextStep(),
        );
      case 1:
        return MoodStep(
          key: const ValueKey('mood'),
          selectedMood: _diaryState.mood,
          onMoodSelected: (mood) {
            setState(() => _diaryState.mood = mood);
          },
          onBack: () => _goToPreviousStep(),
          onConfirm: () => _goToNextStep(),
        );
      case 2:
        return EventStep(
          key: const ValueKey('event'),
          currentMood: _diaryState.mood,
          selectedEvents: _diaryState.selectedEvents,
          onEventToggled: (event) {
            setState(() {
              if (_diaryState.selectedEvents.contains(event)) {
                _diaryState.selectedEvents.remove(event);
              } else {
                _diaryState.selectedEvents.add(event);
              }
            });
          },
          onBack: () => _goToPreviousStep(),
          onConfirm: () => _goToNextStep(),
        );
      case 3:
        return WritingStep(
          key: const ValueKey('writing'),
          initialText: _diaryState.writeContent,
          initialBgColor: _diaryState.bgColor ?? widget.editTarget?.bgColor,
          initialImagePaths: _diaryState.imagePaths,
          onWriteText: (text) { _diaryState.writeContent = text; },
          onBgColorChanged: (c) { _diaryState.bgColor = c; },
          onImagePathsChanged: (paths) { _diaryState.imagePaths = paths; },
          onBack: () => _goToPreviousStep(),
          onSave: () => _saveDiary(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// 保存日记
  Future<void> _saveDiary() async {
    if (_diaryState.isComplete) {
      // 使用用户手写的实际内容
      final content = _diaryState.writeContent?.trim() ?? '';
      final wordCount = content.length;

      // 编辑模式下复用原 ID 和创建时间
      final id = widget.editTarget?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final createdAt = widget.editTarget?.createdAt ?? DateTime.now();
      final entry = DiaryEntry(
        id: id,
        content: content,
        weather: _diaryState.weather ?? '',
        mood: _diaryState.mood ?? '',
        events: _diaryState.selectedEvents.toList(),
        bgColor: _diaryState.bgColor,
        imagePaths: List<String>.from(_diaryState.imagePaths),
        createdAt: createdAt,
      );

      // 保存日记内容
      await DiaryStorage.save(entry);

      // 更新统计数据（总篇数 + 字数 + 按月统计）
      await StatsStorage.addDiary(wordCount > 0 ? wordCount : 1);

      // 如果是从草稿来的，保存后删除草稿
      if (widget.draftId != null) {
        await DraftStorage.delete(widget.draftId!);
      }

      debugPrint('[日记保存] 天气=${_diaryState.weather} 心情=${_diaryState.mood} 事件=${_diaryState.selectedEvents} 内容长度=$wordCount');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日记已保存！')),
        );
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请完成所有步骤后再保存')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = ResponsiveAppBar.safeTop(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    // 天气、心情、事件步骤全屏沉浸，不显示顶栏
    final isFullScreen = _currentStep <= 2;

    // PopScope 拦截系统返回键/手势，自动保存草稿再退出
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return; // 已经是第二次调用
        await _saveAsDraft();
        if (mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          if (!isFullScreen) SizedBox(height: safeTop),
          if (!isFullScreen)
            SizedBox(
              height: 56,
              child: Stack(
                children: [
                  const Center(
                    child: Text('日记',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                  ),
                  Positioned(
                    left: 16, top: 0, bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF666666)),
                        onPressed: () async {
                          // 任意步骤点返回都自动保存草稿再退出
                          await _saveAsDraft();
                          if (mounted) Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16, top: 0, bottom: 0,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(4, (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _currentStep ? 16 : 6, height: 6,
                          decoration: BoxDecoration(
                            color: i == _currentStep ? const Color(0xFF4ACBD4) : Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildCurrentStep()),
          SizedBox(height: isFullScreen ? safeBottom : 0),
        ],
      ),
    )); // 关闭 Scaffold 和 PopScope
  }

  /// 保存为草稿（离开向导时自动调用）
  Future<void> _saveAsDraft() async {
    // 如果没有任何选择，不保存
    if (_diaryState.weather == null &&
        _diaryState.mood == null &&
        _diaryState.selectedEvents.isEmpty &&
        (_diaryState.writeContent == null || _diaryState.writeContent!.trim().isEmpty)) {
      return;
    }

    // 优先使用手写内容，fallback 用拼接字符串
    final content = _diaryState.writeContent?.trim().isNotEmpty == true
        ? _diaryState.writeContent!.trim()
        : '${_diaryState.weather ?? ''} ${_diaryState.mood ?? ''} ${_diaryState.selectedEvents.join(' ')}';
    final draft = DraftEntry(
      id: widget.draftId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      weather: _diaryState.weather ?? '',
      mood: _diaryState.mood ?? '',
      events: _diaryState.selectedEvents.toList(),
      updatedAt: DateTime.now(),
      wordCount: content.trim().length,
    );
    await DraftStorage.save(draft);
  }
}
