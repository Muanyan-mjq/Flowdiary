/// 日记条目数据模型
class DiaryEntry {
  final String id;
  final String content;       // 日记正文
  final String weather;       // 天气（晴/多云/雨...）
  final String mood;          // 心情（开心/难过/平静...）
  final List<String> events;  // 事件标签
  final int? bgColor;        // 写作页背景色值
  final String? mascotImage; // 创建时的小狗图片路径（锁定不变）
  final List<String> imagePaths; // 日记配图路径列表
  final DateTime createdAt;   // 创建时间
  final DateTime updatedAt;   // 最后修改时间

  DiaryEntry({
    required this.id,
    required this.content,
    required this.weather,
    required this.mood,
    required this.events,
    this.bgColor,
    this.mascotImage,
    this.imagePaths = const [],
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  /// 序列化为 JSON（本地存储，与云端字段名不同）
  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'weather': weather,
    'mood': mood,
    'events': events,
    'bgColor': bgColor,
    'mascotImage': mascotImage,
    'imagePaths': imagePaths,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// 从 JSON 反序列化（兼容旧数据无 updatedAt / imagePaths）
  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
    id: json['id'] as String,
    content: json['content'] as String,
    weather: json['weather'] as String,
    mood: json['mood'] as String,
    events: List<String>.from(json['events'] ?? []),
    bgColor: json['bgColor'] as int?,
    mascotImage: json['mascotImage'] as String?,
    imagePaths: json['imagePaths'] != null
        ? List<String>.from(json['imagePaths'])
        : [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
  );

  /// 转为云端 Supabase 格式（下划线命名）
  Map<String, dynamic> toCloudJson() => {
    'id': id,
    'content': content,
    'weather': weather,
    'mood': mood,
    'events': events,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  /// 从云端 Supabase 格式反序列化
  factory DiaryEntry.fromCloudJson(Map<String, dynamic> json) => DiaryEntry(
    id: json['id'] as String,
    content: json['content'] as String? ?? '',
    weather: json['weather'] as String? ?? '',
    mood: json['mood'] as String? ?? '',
    events: json['events'] is List
        ? List<String>.from(json['events'])
        : [],
    createdAt: _parseTimestamp(json['created_at']),
    updatedAt: _parseTimestamp(json['updated_at']),
  );

  /// 安全解析时间戳（兼容 ISO 字符串和 null）
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
