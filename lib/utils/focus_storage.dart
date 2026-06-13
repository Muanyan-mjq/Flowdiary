import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/focus_task.dart';
import '../services/cloud_sync_service.dart';

/// 专注任务持久化存储
class FocusStorage {
  static const _keyTasks = 'focus_tasks';
  static const _keyGlobalStyle = 'focus_global_timer_style';
  static const _keyTodayDate = 'focus_today_date';

  /// 加载所有任务
  static Future<List<FocusTask>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyTasks);
    if (str == null) return [];

    // 检查日期，跨天重置 completedToday
    await _resetDailyIfNeeded(prefs);

    final jsonList = jsonDecode(str) as List;
    final tasks = jsonList
        .map((e) => FocusTask.fromJson(e as Map<String, dynamic>))
        .toList();
    tasks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return tasks;
  }

  /// 保存所有任务
  static Future<void> saveAll(List<FocusTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tasks.map((t) => t.toJson()).toList();
    await prefs.setString(_keyTasks, jsonEncode(jsonList));
    // 后台静默同步到云端
    _syncToCloud();
  }

  static Future<void> _syncToCloud() async {
    try { final t = await loadAll(); await CloudSyncService.instance.pushFocusTasks(t); } catch (_) {}
  }

  /// 添加任务
  static Future<void> add(FocusTask task) async {
    final tasks = await loadAll();
    // 新任务 sortOrder 设为 0（最前）
    task.sortOrder = 0;
    // 其他任务 sortOrder +1
    for (final t in tasks) { t.sortOrder++; }
    tasks.insert(0, task);
    await saveAll(tasks);
  }

  /// 更新任务
  static Future<void> update(FocusTask task) async {
    final tasks = await loadAll();
    final i = tasks.indexWhere((t) => t.id == task.id);
    if (i != -1) { tasks[i] = task; await saveAll(tasks); }
  }

  /// 删除任务
  static Future<void> delete(String id) async {
    final tasks = await loadAll();
    tasks.removeWhere((t) => t.id == id);
    await saveAll(tasks);
  }

  /// 排序（拖拽后）
  static Future<void> reorder(int oldIndex, int newIndex) async {
    final tasks = await loadAll();
    if (oldIndex < newIndex) newIndex--;
    final item = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, item);
    for (int i = 0; i < tasks.length; i++) { tasks[i].sortOrder = i; }
    await saveAll(tasks);
  }

  /// 记录一次完成
  static Future<void> recordCompletion(FocusTask task) async {
    await _resetDailyIfNeeded(await SharedPreferences.getInstance());
    final tasks = await loadAll();
    final i = tasks.indexWhere((t) => t.id == task.id);
    if (i != -1) {
      tasks[i].completedToday++;
      tasks[i].totalCompletions++;
      tasks[i].lastCompleted = DateTime.now();
      await saveAll(tasks);
    }
  }

  /// 保存休息时的总结
  static Future<void> saveSummary(String taskId, String summary) async {
    final prefs = await SharedPreferences.getInstance();
    final date = DateTime.now();
    final key = 'focus_summary_${taskId}_${date.year}_${date.month}_${date.day}';
    await prefs.setString(key, summary);
  }

  /// 获取今日总结
  static Future<String?> getTodaySummary(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final date = DateTime.now();
    final key = 'focus_summary_${taskId}_${date.year}_${date.month}_${date.day}';
    return prefs.getString(key);
  }

  /// 全局计时器样式
  static Future<TimerStyle> getGlobalStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_keyGlobalStyle);
    return TimerStyle.values[v ?? 0];
  }

  static Future<void> setGlobalStyle(TimerStyle s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGlobalStyle, s.index);
  }

  /// 跨天重置
  static Future<void> _resetDailyIfNeeded(SharedPreferences prefs) async {
    final now = DateTime.now();
    final today = '${now.year}_${now.month}_${now.day}';
    final saved = prefs.getString(_keyTodayDate);
    if (saved != today) {
      // 重置所有任务的 completedToday
      final str = prefs.getString(_keyTasks);
      if (str != null) {
        final list = (jsonDecode(str) as List)
            .map((e) => FocusTask.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final t in list) {
          t.completedToday = 0;
          t.lastCompleted = null;
        }
        await prefs.setString(_keyTasks, jsonEncode(list.map((t) => t.toJson()).toList()));
      }
      await prefs.setString(_keyTodayDate, today);
    }
  }

  /// 获取统计数据
  static Future<Map<String, int>> getStatsByTask() async {
    final tasks = await loadAll();
    return {for (final t in tasks) t.name: t.totalCompletions};
  }

  /// 今日总专注次数
  static Future<int> getTodayTotal() async {
    final tasks = await loadAll();
    int sum = 0;
    for (final t in tasks) { sum += t.completedToday; }
    return sum;
  }

  /// 今日总专注时长（分钟）
  static Future<int> getTodayMinutes() async {
    final tasks = await loadAll();
    int sum = 0;
    for (final t in tasks) { sum += t.completedToday * t.durationMinutes; }
    return sum;
  }

  /// 替换全部任务（用于从云端恢复/合并）
  static Future<void> replaceAll(List<FocusTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    // 保留每天的 today 日期不变
    await prefs.setString(_keyTasks, jsonEncode(tasks.map((t) => t.toJson()).toList()));
  }
}
