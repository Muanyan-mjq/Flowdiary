import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/responsive_app_bar.dart';
import '../models/diary_entry.dart';
import '../models/focus_task.dart';
import '../utils/diary_storage.dart';
import '../utils/draft_storage.dart';
import '../utils/stats_storage.dart';
import '../utils/backup_storage.dart';
import '../utils/focus_storage.dart';
import '../services/cloud_auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../main.dart';

/// 云端同步页面
/// 功能：
///   1. 云端账号绑定/解绑
///   2. 一键同步（上传 + 下载合并）
///   3. 同步状态查看
///   4. 本地备份（保留原有功能）
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _isLoading = false;
  bool _showLocalBackup = false; // 展开本地备份区域

  // 云端状态
  bool _cloudEnabled = false;
  String _cloudEmail = '';

  // 本地统计
  int _diaryCount = 0;
  int _draftCount = 0;
  int _totalWords = 0;
  int _focusTaskCount = 0;
  List<BackupSlot> _slots = [];

  // 同步状态
  String? _lastSyncDiaries;
  String? _lastSyncFocus;
  bool _isSyncing = false;

  Color get _themeColor =>
      ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);

  @override
  void initState() {
    super.initState();
    _cloudEnabled = CloudAuthService.instance.isCloudEnabled;
    _cloudEmail = CloudAuthService.instance.cloudEmail;
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final diaries = await DiaryStorage.loadAll();
    final drafts = await DraftStorage.loadAll();
    final stats = await StatsStorage.loadData();
    final focusTasks = await FocusStorage.loadAll();
    final slots = await BackupStorage.loadAllSlots();

    final diarySync = await CloudSyncService.instance.getLastSyncDiaries();
    final focusSync = await CloudSyncService.instance.getLastSyncFocus();

    if (mounted) {
      setState(() {
        _diaryCount = diaries.length;
        _draftCount = drafts.length;
        _totalWords = stats.totalWords;
        _focusTaskCount = focusTasks.length;
        _slots = slots;
        _lastSyncDiaries = diarySync != null ? _formatSyncTime(diarySync) : null;
        _lastSyncFocus = focusSync != null ? _formatSyncTime(focusSync) : null;
      });
    }
  }

  // ═══════════════ 云端账号 ═══════════════

  /// 绑定云端账号弹窗
  void _showBindDialog() {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool isLogin = false; // 默认注册模式
    String? errorMsg;
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 拖拽条
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isLogin ? '登录云端账号' : '绑定云端账号',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '绑定后数据可同步到云端，换设备也能恢复',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 20),
                    // 邮箱
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: '输入邮箱', hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true, fillColor: appBgColor(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 密码
                    TextField(
                      controller: passwordCtrl, obscureText: true,
                      decoration: InputDecoration(
                        hintText: '设置密码（至少6位）', hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true, fillColor: appBgColor(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    if (errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(errorMsg!, style: const TextStyle(fontSize: 12, color: Color(0xFFE57373))),
                      ),
                    const SizedBox(height: 24),
                    // 按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting ? null : () async {
                          final email = emailCtrl.text.trim();
                          final password = passwordCtrl.text.trim();

                          if (email.isEmpty || !email.contains('@')) {
                            setSheet(() => errorMsg = '请输入有效邮箱');
                            return;
                          }
                          if (password.length < 6) {
                            setSheet(() => errorMsg = '密码至少6位');
                            return;
                          }

                          setSheet(() { submitting = true; errorMsg = null; });

                          final result = isLogin
                              ? await CloudAuthService.instance.signIn(email: email, password: password)
                              : await CloudAuthService.instance.signUp(email: email, password: password);

                          if (result.isSuccess) {
                            if (ctx.mounted) Navigator.pop(ctx);
                            setState(() {
                              _cloudEnabled = true;
                              _cloudEmail = email;
                            });
                            // 首次绑定后自动同步一次
                            _syncAll();
                          } else {
                            setSheet(() {
                              submitting = false;
                              errorMsg = result.message;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _themeColor, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: submitting
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(isLogin ? '登录并绑定' : '注册并绑定', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 切换模式
                    Center(
                      child: GestureDetector(
                        onTap: () => setSheet(() { isLogin = !isLogin; errorMsg = null; }),
                        child: Text(
                          isLogin ? '没有账号？注册新账号' : '已有账号？直接登录',
                          style: TextStyle(fontSize: 13, color: _themeColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 确认解绑
  Future<void> _confirmUnbind() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('解绑云端账号'),
        content: const Text('解绑后：\n\n• 云端数据不会删除\n• 本地日记不受影响\n• 可随时重新绑定恢复同步'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定解绑', style: TextStyle(color: Color(0xFFFF3B30))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CloudAuthService.instance.unbind();
      setState(() {
        _cloudEnabled = false;
        _cloudEmail = '';
        _lastSyncDiaries = null;
        _lastSyncFocus = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已解绑云端账号')));
      }
    }
  }

  // ═══════════════ 同步操作 ═══════════════

  Future<void> _syncAll() async {
    if (!_cloudEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先绑定云端账号')));
      return;
    }

    setState(() => _isSyncing = true);

    final diaries = await DiaryStorage.loadAll();
    final focusTasks = await FocusStorage.loadAll();
    // 本地日签暂不接入全量同步（日签广场当前是模拟数据）

    final result = await CloudSyncService.instance.syncAll(
      localDiaries: diaries,
      localSigns: [],
      localFocusTasks: focusTasks,
    );

    if (mounted) {
      setState(() => _isSyncing = false);

      // 如果有云端数据被拉取下来，合并到本地存储
      if (result.cloudDiaryCount > 0) {
        try {
          final cloudDiaries = await CloudSyncService.instance.pullDiaries();
          if (cloudDiaries.isNotEmpty) {
            final localDiaries = await DiaryStorage.loadAll();
            // 以 id 为键合并：云端最新数据覆盖本地
            final map = <String, DiaryEntry>{};
            for (final d in localDiaries) { map[d.id] = d; }
            for (final d in cloudDiaries) { map[d.id] = d; }
            final merged = map.values.toList();
            merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            await DiaryStorage.replaceAll(merged);
          }
        } catch (_) {}
      }
      if (result.cloudFocusCount > 0) {
        try {
          final cloudTasks = await CloudSyncService.instance.pullFocusTasks();
          if (cloudTasks.isNotEmpty) {
            final localTasks = await FocusStorage.loadAll();
            final map = <String, FocusTask>{};
            for (final t in localTasks) { map[t.id] = t; }
            for (final t in cloudTasks) { map[t.id] = t; }
            await FocusStorage.replaceAll(cloudTasks);
          }
        } catch (_) {}
      }
      await _loadStatus();

      String msg;
      if (result.allSuccess) {
        final parts = <String>[];
        if (result.diaryResult.uploaded > 0) parts.add('日记 ${result.diaryResult.uploaded}');
        if (result.focusResult.uploaded > 0) parts.add('专注 ${result.focusResult.uploaded}');
        msg = parts.isNotEmpty ? '同步完成：${parts.join("，")}' : '数据已是最新';
      } else {
        msg = '部分数据同步失败，请重试';
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String _formatSyncTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  // ═══════════════ 本地备份（保留原有功能） ═══════════════

  Future<void> _createLocalBackup() async {
    setState(() => _isLoading = true);
    try {
      final diaries = await DiaryStorage.loadAll();
      final drafts = await DraftStorage.loadAll();
      final stats = await StatsStorage.loadData();

      final exportData = {
        'appName': '随心耶', 'version': '1.0.0',
        'exportTime': DateTime.now().toIso8601String(),
        'diaries': diaries.map((d) => d.toJson()).toList(),
        'drafts': drafts.map((d) => d.toJson()).toList(),
        'stats': {'diaryCount': stats.diaryCount, 'days': stats.days, 'totalWords': stats.totalWords},
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
      final now = DateTime.now();
      final autoName = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      await BackupStorage.createBackup(
        dataJson: jsonStr, diaryCount: diaries.length,
        draftCount: drafts.length, totalWords: stats.totalWords, name: autoName,
      );

      setState(() => _isLoading = false);
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('本地备份成功！${diaries.length}篇日记')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('备份失败: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _restoreFromSlot(BackupSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复数据'),
        content: Text('将恢复到「${slot.name}」的状态：\n\n📔 日记：${slot.diaryCount} 篇\n📝 草稿：${slot.draftCount} 篇\n📅 时间：${slot.formattedTime}\n\n当前数据将被覆盖。建议先备份。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('恢复', style: TextStyle(color: Color(0xFFFF3B30)))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final data = jsonDecode(slot.dataJson) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      if (data['diaries'] != null) {
        await prefs.setString('diaries', jsonEncode(data['diaries']));
      }
      if (data['drafts'] != null) {
        await prefs.setString('drafts', jsonEncode(data['drafts']));
      }
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据恢复成功！')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('恢复失败: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteSlot(BackupSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除备份'),
        content: Text('确定删除「${slot.name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Color(0xFFFF3B30)))),
        ],
      ),
    );
    if (confirmed == true) {
      await BackupStorage.deleteSlot(slot.id);
      await _loadStatus();
    }
  }

  // ═══════════════ Build ═══════════════

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
              '云端同步',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCloudAccountCard(),
                  const SizedBox(height: 16),
                  _buildSyncStatusCard(),
                  const SizedBox(height: 16),
                  _buildDataOverview(),
                  const SizedBox(height: 24),
                  // 本地备份折叠区域
                  _buildLocalBackupToggle(),
                  if (_showLocalBackup) ...[
                    const SizedBox(height: 16),
                    _buildLocalBackupSection(),
                  ],
                  const SizedBox(height: 24),
                  _buildTipCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ 云端账号卡片 ═══
  Widget _buildCloudAccountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _card(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _cloudEnabled ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _cloudEnabled ? Icons.cloud_done : Icons.cloud_off_outlined,
                  size: 26,
                  color: _cloudEnabled ? const Color(0xFF4CAF50) : Colors.grey[400],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cloudEnabled ? '云端已连接' : '未绑定云端',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _cloudEnabled ? _cloudEmail : '绑定后开启多设备同步',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 操作按钮
          if (_cloudEnabled)
            Row(
              children: [
                Expanded(
                  child: _actionBtn('立即同步', Icons.sync_rounded, _syncAll, loading: _isSyncing),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _confirmUnbind,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF3B30),
                      side: const BorderSide(color: Color(0xFFFFCDD2)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('解绑', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            )
          else
            _actionBtn('绑定云端账号', Icons.cloud_outlined, _showBindDialog),
        ],
      ),
    );
  }

  // ═══ 同步状态卡片 ═══
  Widget _buildSyncStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync_rounded, size: 16, color: _themeColor),
              const SizedBox(width: 6),
              Text('同步状态', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 12),
          _syncStatusRow('日记', _lastSyncDiaries),
          _syncStatusRow('专注任务', _lastSyncFocus),
        ],
      ),
    );
  }

  Widget _syncStatusRow(String label, String? lastSync) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
          ),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: lastSync != null ? const Color(0xFF4CAF50) : Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            lastSync ?? '未同步',
            style: TextStyle(fontSize: 13, color: lastSync != null ? Colors.grey[600] : Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ═══ 数据概览 ═══
  Widget _buildDataOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _card(),
      child: Row(
        children: [
          _statItem('$_diaryCount', '日记'),
          const Spacer(),
          _statItem('$_draftCount', '草稿'),
          const Spacer(),
          _statItem(StatsStorage.formatWords(_totalWords), '字数'),
          const Spacer(),
          _statItem('$_focusTaskCount', '专注任务'),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  // ═══ 本地备份折叠开关 ═══
  Widget _buildLocalBackupToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showLocalBackup = !_showLocalBackup),
      child: Row(
        children: [
          Icon(Icons.backup_rounded, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text('本地备份', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[500])),
          const Spacer(),
          Text('${_slots.length} 个槽位', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          const SizedBox(width: 4),
          Icon(
            _showLocalBackup ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 20, color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  // ═══ 本地备份区域 ═══
  Widget _buildLocalBackupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 创建备份按钮
        GestureDetector(
          onTap: _isLoading ? null : _createLocalBackup,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _themeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _themeColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isLoading
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _themeColor))
                    : Icon(Icons.add, size: 18, color: _themeColor),
                const SizedBox(width: 6),
                Text('创建本地备份', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _themeColor)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 备份列表
        if (_slots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _card(),
            child: Center(
              child: Text('暂无本地备份', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
            ),
          )
        else
          ..._slots.map((slot) => _buildSlotCard(slot)),
      ],
    );
  }

  Widget _buildSlotCard(BackupSlot slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_outlined, size: 16, color: Color(0xFFFF9800)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(slot.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)), overflow: TextOverflow.ellipsis),
              ),
              Text('${slot.sizeKB}KB', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _slotTag('${slot.diaryCount}篇日记'),
              const SizedBox(width: 6),
              _slotTag('${slot.draftCount}篇草稿'),
              const SizedBox(width: 6),
              _slotTag(StatsStorage.formatWords(slot.totalWords)),
              const Spacer(),
              Text(slot.formattedTime, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _slotAction('恢复', Icons.restore, () => _restoreFromSlot(slot)),
              const SizedBox(width: 16),
              _slotAction('删除', Icons.delete_outline, () => _deleteSlot(slot), isDestructive: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slotTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    );
  }

  Widget _slotAction(String label, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? const Color(0xFFFF3B30) : _themeColor;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  // ═══ 提示卡片 ═══
  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: _themeColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '云端同步使用说明\n\n'
              '• 云端同步基于 Supabase（开源 MIT 协议）\n'
              '• 日记数据保存在云端，换设备时登录即可恢复\n'
              '• 离线时日记正常保存本地，联网后自动同步\n'
              '• 本地备份与云端同步互补：云端用于多设备同步，本地备份用于快速恢复\n'
              '• 云端数据存储在你的 Supabase 项目中，完全由你掌控',
              style: TextStyle(fontSize: 12, color: _themeColor.withValues(alpha: 0.8), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ 工具方法 ═══

  BoxDecoration _card() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap, {bool loading = false}) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _themeColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: _themeColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
        ),
      ),
    );
  }
}
