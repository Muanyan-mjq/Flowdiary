import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_entry.dart';
import '../models/focus_task.dart';
import 'cloud_auth_service.dart';

/// 云端数据同步服务
/// 支持日记、日签、专注任务的云端双向同步
class CloudSyncService {
  static CloudSyncService? _instance;
  static CloudSyncService get instance => _instance ??= CloudSyncService._();
  CloudSyncService._();

  SupabaseClient get _client => Supabase.instance.client;

  // 上次同步时间戳的存储 key
  static const _keyLastSyncDiaries = 'cloud_last_sync_diaries';
  static const _keyLastSyncSigns = 'cloud_last_sync_signs';
  static const _keyLastSyncFocus = 'cloud_last_sync_focus';

  /// 是否可以同步（已绑定云端账号 + 已登录）
  bool get canSync {
    return CloudAuthService.instance.isCloudEnabled &&
        _client.auth.currentSession != null;
  }

  // ═══════════════════════════════════════════════════
  // 日记同步
  // ═══════════════════════════════════════════════════

  /// 上传本地日记到云端
  Future<SyncResult> pushDiaries(List<DiaryEntry> localDiaries) async {
    if (!canSync) return SyncResult.failure('未绑定云端账号');
    final userId = CloudAuthService.instance.currentUserId;
    if (userId == null) return SyncResult.failure('云端未登录');

    int uploaded = 0;
    int failed = 0;

    for (final entry in localDiaries) {
      try {
        final exists = await _client
            .from('diaries')
            .select('updated_at')
            .eq('id', entry.id)
            .maybeSingle();

        final data = entry.toCloudJson();
        data['user_id'] = userId;

        if (exists != null) {
          // 云端已有，比较时间戳，新的覆盖旧的
          final cloudTime = DateTime.parse(exists['updated_at'] as String);
          if (entry.updatedAt.isAfter(cloudTime)) {
            await _client.from('diaries').update(data).eq('id', entry.id);
            uploaded++;
          }
        } else {
          // 云端没有，直接插入
          await _client.from('diaries').insert(data);
          uploaded++;
        }
      } catch (e) {
        debugPrint('[云同步] 上传日记失败: ${entry.id} $e');
        failed++;
      }
    }

    debugPrint('[云同步] 日记上传完成: $uploaded 条成功, $failed 条失败');
    return SyncResult.success(uploaded, failed);
  }

  /// 从云端拉取日记（增量：只拉取 lastSync 之后更新的）
  Future<List<DiaryEntry>> pullDiaries() async {
    if (!canSync) return [];

    try {
      final lastSync = await _getLastSyncTime(_keyLastSyncDiaries);

      List<dynamic> rows;
      if (lastSync != null) {
        rows = await _client
            .from('diaries')
            .select()
            .gte('updated_at', lastSync.toIso8601String())
            .order('updated_at', ascending: false);
      } else {
        // 首次同步，拉取全部
        rows = await _client
            .from('diaries')
            .select()
            .order('updated_at', ascending: false);
      }

      final entries = rows.map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        return DiaryEntry.fromCloudJson(json);
      }).toList();

      await _updateLastSyncTime(_keyLastSyncDiaries);
      debugPrint('[云同步] 拉取日记: ${entries.length} 条');
      return entries;
    } catch (e) {
      debugPrint('[云同步] 拉取日记失败: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════
  // 日签同步
  // ═══════════════════════════════════════════════════

  /// 上传日签（content + imageUrl 等简单字段）
  Future<SyncResult> pushDailySigns(List<Map<String, dynamic>> signs) async {
    if (!canSync) return SyncResult.failure('未绑定云端账号');
    final userId = CloudAuthService.instance.currentUserId;
    if (userId == null) return SyncResult.failure('云端未登录');

    int uploaded = 0;
    for (final sign in signs) {
      try {
        sign['user_id'] = userId;
        await _client.from('daily_signs').upsert(sign);
        uploaded++;
      } catch (e) {
        debugPrint('[云同步] 上传日签失败: $e');
      }
    }
    return SyncResult.success(uploaded, 0);
  }

  /// 拉取日签
  Future<List<Map<String, dynamic>>> pullDailySigns() async {
    if (!canSync) return [];
    try {
      final rows = await _client
          .from('daily_signs')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      await _updateLastSyncTime(_keyLastSyncSigns);
      return rows.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    } catch (e) {
      debugPrint('[云同步] 拉取日签失败: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════
  // 专注任务同步
  // ═══════════════════════════════════════════════════

  /// 上传专注任务
  Future<SyncResult> pushFocusTasks(List<FocusTask> tasks) async {
    if (!canSync) return SyncResult.failure('未绑定云端账号');
    final userId = CloudAuthService.instance.currentUserId;
    if (userId == null) return SyncResult.failure('云端未登录');

    int uploaded = 0;
    for (final task in tasks) {
      try {
        final data = task.toJson();
        data['user_id'] = userId;
        await _client.from('focus_tasks').upsert(data);
        uploaded++;
      } catch (e) {
        debugPrint('[云同步] 上传专注任务失败: $e');
      }
    }
    return SyncResult.success(uploaded, 0);
  }

  /// 拉取专注任务
  Future<List<FocusTask>> pullFocusTasks() async {
    if (!canSync) return [];
    try {
      final rows = await _client
          .from('focus_tasks')
          .select()
          .order('sort_order', ascending: true);
      await _updateLastSyncTime(_keyLastSyncFocus);
      return rows
          .map((r) => FocusTask.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      debugPrint('[云同步] 拉取专注任务失败: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════
  // 反馈同步
  // ═══════════════════════════════════════════════════

  /// 从云端拉取反馈
  Future<List<Map<String, dynamic>>> pullFeedbacks() async {
    if (!canSync) return [];
    try {
      final rows = await _client
          .from('feedbacks')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      return rows.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    } catch (e) {
      debugPrint('[云同步] 拉取反馈失败: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════
  // 一键全量同步
  // ═══════════════════════════════════════════════════

  /// 全量同步：先拉取云端数据合并到本地，再上传本地数据
  /// 返回各类型的同步结果
  Future<FullSyncResult> syncAll({
    required List<DiaryEntry> localDiaries,
    required List<Map<String, dynamic>> localSigns,
    required List<FocusTask> localFocusTasks,
  }) async {
    if (!canSync) return FullSyncResult.empty('请先绑定云端账号');

    // 1. 拉取云端数据
    final cloudDiaries = await pullDiaries();
    final cloudSigns = await pullDailySigns();
    final cloudFocusTasks = await pullFocusTasks();

    // 2. 合并日记：以 updatedAt 为准，新的覆盖旧的
    final mergedDiaries = _mergeDiaries(localDiaries, cloudDiaries);

    // 3. 上传本地数据到云端
    final diaryResult = await pushDiaries(mergedDiaries);
    final signResult = await pushDailySigns(localSigns);
    final focusResult = await pushFocusTasks(localFocusTasks);

    return FullSyncResult(
      diaryResult: diaryResult,
      signResult: signResult,
      focusResult: focusResult,
      cloudDiaryCount: cloudDiaries.length,
      cloudSignCount: cloudSigns.length,
      cloudFocusCount: cloudFocusTasks.length,
    );
  }

  /// 合并日记：以 id 为键，updatedAt 最新者胜出
  List<DiaryEntry> _mergeDiaries(
    List<DiaryEntry> local,
    List<DiaryEntry> cloud,
  ) {
    final map = <String, DiaryEntry>{};

    // 先放入本地数据
    for (final entry in local) {
      map[entry.id] = entry;
    }

    // 云端数据：如果本地没有，或者云端更新，则覆盖
    for (final entry in cloud) {
      final existing = map[entry.id];
      if (existing == null || entry.updatedAt.isAfter(existing.updatedAt)) {
        map[entry.id] = entry;
      }
    }

    return map.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ═══════════════════════════════════════════════════
  // 时间戳管理
  // ═══════════════════════════════════════════════════

  Future<DateTime?> _getLastSyncTime(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(key);
    return iso != null ? DateTime.tryParse(iso) : null;
  }

  Future<void> _updateLastSyncTime(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, DateTime.now().toIso8601String());
  }

  /// 获取某类型的上次同步时间（供 UI 显示）
  Future<DateTime?> getLastSyncDiaries() => _getLastSyncTime(_keyLastSyncDiaries);
  Future<DateTime?> getLastSyncSigns() => _getLastSyncTime(_keyLastSyncSigns);
  Future<DateTime?> getLastSyncFocus() => _getLastSyncTime(_keyLastSyncFocus);
}

/// 单类型同步结果
class SyncResult {
  final bool isSuccess;
  final int uploaded;
  final int failed;
  final String? errorMessage;

  const SyncResult._(this.isSuccess, this.uploaded, this.failed, this.errorMessage);
  factory SyncResult.success(int uploaded, int failed) =>
      SyncResult._(true, uploaded, failed, null);
  factory SyncResult.failure(String msg) =>
      SyncResult._(false, 0, 0, msg);
}

/// 全量同步结果
class FullSyncResult {
  final SyncResult diaryResult;
  final SyncResult signResult;
  final SyncResult focusResult;
  final int cloudDiaryCount;
  final int cloudSignCount;
  final int cloudFocusCount;

  const FullSyncResult({
    required this.diaryResult,
    required this.signResult,
    required this.focusResult,
    required this.cloudDiaryCount,
    required this.cloudSignCount,
    required this.cloudFocusCount,
  });

  factory FullSyncResult.empty(String msg) => FullSyncResult(
        diaryResult: SyncResult.failure(msg),
        signResult: SyncResult.failure(msg),
        focusResult: SyncResult.failure(msg),
        cloudDiaryCount: 0,
        cloudSignCount: 0,
        cloudFocusCount: 0,
      );

  /// 同步是否全部成功
  bool get allSuccess =>
      diaryResult.isSuccess && signResult.isSuccess && focusResult.isSuccess;
}
