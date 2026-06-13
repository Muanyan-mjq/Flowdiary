import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cloud_auth_service.dart';

/// 反馈类型
enum FeedbackType {
  feature,   // 功能建议
  bug,       // 问题反馈
  other,     // 其他
}

/// 反馈数据模型
class FeedbackEntry {
  final String id;
  final FeedbackType type;
  final String description;
  final String contact;
  final DateTime createdAt;
  final FeedbackStatus status;

  FeedbackEntry({
    required this.id,
    required this.type,
    required this.description,
    required this.contact,
    required this.createdAt,
    this.status = FeedbackStatus.pending,
  });

  /// 类型文字
  String get typeLabel {
    switch (type) {
      case FeedbackType.feature:
        return '功能建议';
      case FeedbackType.bug:
        return '问题反馈';
      case FeedbackType.other:
        return '其他';
    }
  }

  /// 状态文字
  String get statusLabel {
    switch (status) {
      case FeedbackStatus.pending:
        return '处理中';
      case FeedbackStatus.reviewed:
        return '已查看';
      case FeedbackStatus.resolved:
        return '已解决';
    }
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'description': description,
    'contact': contact,
    'createdAt': createdAt.toIso8601String(),
    'status': status.index,
  };

  /// 从 JSON 反序列化
  factory FeedbackEntry.fromJson(Map<String, dynamic> json) => FeedbackEntry(
    id: json['id'] as String,
    type: FeedbackType.values[json['type'] as int? ?? 0],
    description: json['description'] as String? ?? '',
    contact: json['contact'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    status: FeedbackStatus.values[json['status'] as int? ?? 0],
  );
}

/// 反馈状态
enum FeedbackStatus {
  pending,    // 处理中
  reviewed,   // 已查看
  resolved,   // 已解决
}

/// 反馈持久化存储服务
class FeedbackStorage {
  static const String _keyFeedbacks = 'feedbacks';

  /// 保存反馈（本地 + 云端）
  static Future<void> save(FeedbackEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadAll();
    list.insert(0, entry); // 新反馈插入开头
    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_keyFeedbacks, jsonEncode(jsonList));

    // 后台异步上传到云端（静默失败不影响本地保存）
    _syncToCloud(entry);
  }

  /// 后台同步单条反馈到云端
  static Future<void> _syncToCloud(FeedbackEntry entry) async {
    try {
      if (!CloudAuthService.instance.isCloudEnabled) return;
      final userId = CloudAuthService.instance.currentUserId;
      if (userId == null) return;

      await Supabase.instance.client.from('feedbacks').upsert({
        'id': entry.id,
        'user_id': userId,
        'type': entry.typeLabel,
        'description': entry.description,
        'contact': entry.contact,
        'status': entry.statusLabel,
        'created_at': entry.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // 静默失败，本地已保存成功
    }
  }

  /// 读取所有反馈（按时间倒序）
  static Future<List<FeedbackEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyFeedbacks);
    if (str == null) return [];
    try {
      final jsonList = jsonDecode(str) as List;
      return jsonList
          .map((e) => FeedbackEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 更新反馈状态
  static Future<void> updateStatus(String id, FeedbackStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadAll();
    final index = list.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final old = list[index];
    list[index] = FeedbackEntry(
      id: old.id,
      type: old.type,
      description: old.description,
      contact: old.contact,
      createdAt: old.createdAt,
      status: status,
    );

    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_keyFeedbacks, jsonEncode(jsonList));
  }
}
