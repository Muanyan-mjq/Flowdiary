/// 日记输入状态模型
/// 记录用户在四个步骤中选择的天气、心情、事件标签和自由写作内容
class DiaryInputState {
  /// 选中的天气（如：晴、多云、雨 等）
  String? weather;

  /// 选中的心情（如：开心、难过、平静 等）
  String? mood;

  /// 选中的事件标签（支持多选，如：健身、追剧 等）
  Set<String> selectedEvents = {};

  /// 自由写作内容（步骤四的用户手写文字）
  String? writeContent;

  /// 写作页背景色值
  int? bgColor;

  /// 日记配图路径列表
  List<String> imagePaths = [];

  /// 清空所有选择
  void reset() {
    weather = null;
    mood = null;
    selectedEvents.clear();
    writeContent = null;
    imagePaths.clear();
  }

  /// 是否所有步骤都已完成
  bool get isComplete =>
      weather != null &&
      mood != null &&
      selectedEvents.isNotEmpty &&
      writeContent != null &&
      writeContent!.trim().isNotEmpty;

  @override
  String toString() {
    return 'DiaryInputState(weather: $weather, mood: $mood, events: $selectedEvents, contentLen: ${writeContent?.length ?? 0})';
  }
}
