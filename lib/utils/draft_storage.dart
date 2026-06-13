import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 草稿数据模型
class DraftEntry {
  final String id;
  final String content;       // 日记正文预览（前50字）
  final String weather;       // 天气
  final String mood;          // 心情
  final List<String> events;  // 事件标签
  final DateTime updatedAt;   // 最后修改时间
  final int wordCount;        // 字数

  DraftEntry({
    required this.id,
    required this.content,
    required this.weather,
    required this.mood,
    required this.events,
    required this.updatedAt,
    required this.wordCount,
  });

  /// 序列化为 JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'weather': weather,
    'mood': mood,
    'events': events,
    'updatedAt': updatedAt.toIso8601String(),
    'wordCount': wordCount,
  };

  /// 从 JSON 反序列化
  factory DraftEntry.fromJson(Map<String, dynamic> json) => DraftEntry(
    id: json['id'] as String,
    content: json['content'] as String? ?? '',
    weather: json['weather'] as String? ?? '',
    mood: json['mood'] as String? ?? '',
    events: List<String>.from(json['events'] ?? []),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    wordCount: json['wordCount'] as int? ?? 0,
  );

  /// 格式化的更新时间（今天显示时间，其他显示日期）
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24 && updatedAt.day == now.day) {
      return '${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${updatedAt.month.toString().padLeft(2, '0')}-${updatedAt.day.toString().padLeft(2, '0')}';
  }
}

/// 草稿持久化存储服务
class DraftStorage {
  static const String _keyDrafts = 'drafts';

  /// 保存草稿
  static Future<void> save(DraftEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadAll();

    // 如果已存在同 ID 草稿，先删除旧的
    list.removeWhere((e) => e.id == entry.id);
    // 新草稿插入开头
    list.insert(0, entry);

    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_keyDrafts, jsonEncode(jsonList));
  }

  /// 读取所有草稿（按更新时间倒序）
  static Future<List<DraftEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyDrafts);
    if (str == null) return [];
    try {
      final jsonList = jsonDecode(str) as List;
      return jsonList
          .map((e) => DraftEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 获取草稿数量
  static Future<int> getCount() async {
    final list = await loadAll();
    return list.length;
  }

  static const _keyLastSeen = 'draft_last_seen';

  /// 是否有未查看的草稿（红点逻辑）
  static Future<bool> hasUnseen() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString(_keyLastSeen);
    if (lastSeen == null) {
      // 从未查看过草稿 → 只要有草稿就显示
      final list = await loadAll();
      return list.isNotEmpty;
    }
    final seenTime = DateTime.parse(lastSeen);
    final list = await loadAll();
    // 有草稿更新于上次查看之后 → 显示红点
    return list.any((d) => d.updatedAt.isAfter(seenTime));
  }

  /// 标记草稿已查看（消除红点）
  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSeen, DateTime.now().toIso8601String());
  }

  /// 删除一篇草稿
  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadAll();
    list.removeWhere((e) => e.id == id);
    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_keyDrafts, jsonEncode(jsonList));
  }

  /// 更新草稿内容
  static Future<void> update(String id, {
    String? content,
    String? weather,
    String? mood,
    List<String>? events,
    int? wordCount,
  }) async {
    final list = await loadAll();
    final index = list.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final old = list[index];
    final updated = DraftEntry(
      id: old.id,
      content: content ?? old.content,
      weather: weather ?? old.weather,
      mood: mood ?? old.mood,
      events: events ?? old.events,
      updatedAt: DateTime.now(),
      wordCount: wordCount ?? old.wordCount,
    );
    list[index] = updated;

    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_keyDrafts, jsonEncode(jsonList));
  }
}
