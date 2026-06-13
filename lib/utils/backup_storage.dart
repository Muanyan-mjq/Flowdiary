import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 备份槽位数据模型
class BackupSlot {
  final String id;
  final String name;
  final DateTime createdAt;
  final int diaryCount;
  final int draftCount;
  final int totalWords;
  final String dataJson; // 完整的备份 JSON

  BackupSlot({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.diaryCount,
    required this.draftCount,
    required this.totalWords,
    required this.dataJson,
  });

  /// 备份大小（估算 KB）
  int get sizeKB => (dataJson.length / 1024).ceil();

  /// 格式化时间
  String get formattedTime {
    return '${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} '
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// 序列化为元数据（不含 dataJson，用于列表展示）
  Map<String, dynamic> toMetaJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'diaryCount': diaryCount,
    'draftCount': draftCount,
    'totalWords': totalWords,
  };

  /// 从元数据 + dataJson 重建
  factory BackupSlot.fromMetaAndData(Map<String, dynamic> meta, String dataJson) {
    return BackupSlot(
      id: meta['id'] as String,
      name: meta['name'] as String? ?? '',
      createdAt: DateTime.parse(meta['createdAt'] as String),
      diaryCount: meta['diaryCount'] as int? ?? 0,
      draftCount: meta['draftCount'] as int? ?? 0,
      totalWords: meta['totalWords'] as int? ?? 0,
      dataJson: dataJson,
    );
  }
}

/// 多槽位备份存储服务
class BackupStorage {
  static const String _keyMetaList = 'backup_meta_list';
  static const String _keyDataPrefix = 'backup_data_';
  static const int _maxSlots = 5; // 最多 5 个备份槽位

  /// 创建备份
  static Future<BackupSlot?> createBackup({
    required String dataJson,
    required int diaryCount,
    required int draftCount,
    required int totalWords,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 读取现有元数据列表
    final metaList = await _loadMetaList();

    // 如果已达上限，删除最旧的
    if (metaList.length >= _maxSlots) {
      final oldest = metaList.removeAt(0);
      await prefs.remove(_keyDataPrefix + oldest['id']);
    }

    // 创建新槽位
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final slotName = name ?? '备份 ${metaList.length + 1}';

    final meta = {
      'id': id,
      'name': slotName,
      'createdAt': now.toIso8601String(),
      'diaryCount': diaryCount,
      'draftCount': draftCount,
      'totalWords': totalWords,
    };

    // 保存数据（单独 key，避免 SharedPreferences 大小限制）
    await prefs.setString(_keyDataPrefix + id, dataJson);

    // 更新元数据列表
    metaList.add(meta);
    await prefs.setString(_keyMetaList, jsonEncode(metaList));

    return BackupSlot.fromMetaAndData(meta, dataJson);
  }

  /// 获取所有备份槽位（按时间倒序，不含 dataJson）
  static Future<List<BackupSlot>> loadAllSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final metaList = await _loadMetaList();

    final slots = <BackupSlot>[];
    for (final meta in metaList.reversed) {
      final id = meta['id'] as String;
      final dataJson = prefs.getString(_keyDataPrefix + id);
      if (dataJson != null) {
        slots.add(BackupSlot.fromMetaAndData(meta, dataJson));
      }
    }
    return slots;
  }

  /// 加载单个备份槽位的完整数据
  static Future<BackupSlot?> loadSlot(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final metaList = await _loadMetaList();

    for (final meta in metaList) {
      if (meta['id'] == id) {
        final dataJson = prefs.getString(_keyDataPrefix + id);
        if (dataJson != null) {
          return BackupSlot.fromMetaAndData(meta, dataJson);
        }
      }
    }
    return null;
  }

  /// 删除备份槽位
  static Future<void> deleteSlot(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final metaList = await _loadMetaList();

    metaList.removeWhere((m) => m['id'] == id);
    await prefs.setString(_keyMetaList, jsonEncode(metaList));
    await prefs.remove(_keyDataPrefix + id);
  }

  /// 重命名备份槽位
  static Future<void> renameSlot(String id, String newName) async {
    final metaList = await _loadMetaList();
    for (final meta in metaList) {
      if (meta['id'] == id) {
        meta['name'] = newName;
        break;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMetaList, jsonEncode(metaList));
  }

  /// 获取备份数量
  static Future<int> getSlotCount() async {
    final metaList = await _loadMetaList();
    return metaList.length;
  }

  /// 加载元数据列表
  static Future<List<Map<String, dynamic>>> _loadMetaList() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyMetaList);
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }
}
