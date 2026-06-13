import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/responsive_app_bar.dart';
import '../utils/smooth_route.dart';
import '../utils/user_service.dart';
import '../utils/biometric_service.dart';
import '../utils/image_utils.dart';
import '../services/notification_service.dart';
import '../main.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _hasDecoyPassword = false;
  String _biometricType = '生物识别';
  bool _autoSave = true;
  int _fontSizeIndex = 1;
  static const _fontSizeLabels = ['小', '标准', '大'];
  bool _notifyEnabled = false;
  int _notifyHour = 21;
  int _notifyMinute = 0;
  String _signature = '';
  String _nickname = '';
  String? _avatarPath;

  Color get _tc => ThemeProvider.of(context)?.themeColor ?? const Color(0xFF87CEEB);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    _nickname = UserService.instance.nickname;
    _avatarPath = UserService.instance.avatarPath;
    if (_avatarPath != null && _avatarPath!.isEmpty) _avatarPath = null;

    final biometricEnabled = await UserService.instance.getBiometricEnabled();
    final hasDecoy = await UserService.instance.hasDecoyPassword();
    final biometricType = await BiometricService.getBiometricTypeDescription();

    final prefs = await SharedPreferences.getInstance();
    final autoSave = prefs.getBool('auto_save') ?? true;
    final fontSizeIndex = prefs.getInt('font_size_index') ?? 1;
    final signature = prefs.getString('user_signature') ?? '';
    final notifyEnabled = await NotificationService.isEnabled();
    final notifyTime = await NotificationService.getTime();

    if (mounted) setState(() {
      _biometricEnabled = biometricEnabled;
      _hasDecoyPassword = hasDecoy;
      _biometricType = biometricType;
      _autoSave = autoSave;
      _fontSizeIndex = fontSizeIndex;
      _signature = signature;
      _notifyEnabled = notifyEnabled;
      _notifyHour = notifyTime.hour;
      _notifyMinute = notifyTime.minute;
    });
  }

  Future<void> _pickAvatar() async {
    final path = await pickAndSaveImage(maxWidth: 512);
    if (path != null && mounted) {
      await UserService.instance.updateAvatar(path);
      setState(() => _avatarPath = path);
    }
  }

  void _showEditNickname() {
    final ctrl = TextEditingController(text: _nickname);
    showDialog(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: '输入新昵称')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () async {
            final n = ctrl.text.trim();
            if (n.isNotEmpty) {
              await UserService.instance.updateNickname(n);
              setState(() => _nickname = n);
            }
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('确定')),
        ],
      ),
    );
  }

  void _showEditSignature() {
    final ctrl = TextEditingController(text: _signature);
    showDialog(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改签名'),
        content: TextField(controller: ctrl, autofocus: true, maxLines: 2, decoration: const InputDecoration(hintText: '写一句话介绍自己')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () async {
            final s = ctrl.text.trim();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_signature', s);
            setState(() => _signature = s);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('确定')),
        ],
      ),
    );
  }

  void _showFontSizePicker() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('字体大小', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ...List.generate(3, (i) => GestureDetector(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('font_size_index', i);
              setState(() => _fontSizeIndex = i);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: i == _fontSizeIndex ? _tc.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Text(_fontSizeLabels[i], style: TextStyle(fontSize: 16 + i * 2, fontWeight: i == _fontSizeIndex ? FontWeight.w600 : FontWeight.normal, color: i == _fontSizeIndex ? _tc : const Color(0xFF1A1A1A))),
                const Spacer(),
                if (i == _fontSizeIndex) Icon(Icons.check, size: 20, color: _tc),
              ]),
            ),
          )),
        ]),
      ),
    );
  }

  Future<void> _showTimePicker() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _notifyHour, minute: _notifyMinute));
    if (picked != null && mounted) {
      await NotificationService.setTime(picked.hour, picked.minute);
      setState(() { _notifyHour = picked.hour; _notifyMinute = picked.minute; });
    }
  }

  Future<void> _onBiometricChanged(bool v) async {
    await UserService.instance.setBiometricEnabled(v);
    setState(() => _biometricEnabled = v);
  }

  void _showDecoyPasswordDialog() {
    final oldPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    showDialog(context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_hasDecoyPassword ? '修改伪装密码' : '设置伪装密码'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_hasDecoyPassword) ...[
            TextField(controller: oldPwdCtrl, obscureText: true, decoration: const InputDecoration(hintText: '当前伪装密码')),
            const SizedBox(height: 12),
          ],
          TextField(controller: newPwdCtrl, obscureText: true, decoration: const InputDecoration(hintText: '新伪装密码')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () async {
            final newPwd = newPwdCtrl.text.trim();
            if (newPwd.length < 4) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码至少4位')));
              return;
            }
            final ok = await UserService.instance.setDecoyPassword(newPwd);
            if (ok) {
              setState(() => _hasDecoyPassword = true);
              if (ctx.mounted) Navigator.pop(ctx);
            } else if (ctx.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码错误')));
            }
          }, child: const Text('确定')),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改密码'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(hintText: '当前密码')),
          const SizedBox(height: 12),
          TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(hintText: '新密码')),
          const SizedBox(height: 12),
          TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(hintText: '确认新密码')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () async {
            if (newCtrl.text != confirmCtrl.text) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('两次密码不一致')));
              return;
            }
            final ok = await UserService.instance.changePassword(oldCtrl.text.trim(), newCtrl.text.trim());
            if (ok) {
              if (ctx.mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码已修改')));
            } else if (ctx.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('当前密码错误')));
            }
          }, child: const Text('确定')),
        ],
      ),
    );
  }

  void _clearCache() async {
    try {
      // 清除临时图片缓存
      final tempDir = Directory.systemTemp;
      if (tempDir.existsSync()) {
        for (final f in tempDir.listSync()) {
          if (f is File && f.path.contains('img_')) {
            try { await f.delete(); } catch (_) {}
          }
        }
      }
      imageCache.clear();
      imageCache.clearLiveImages();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('缓存已清除')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('清除失败'), backgroundColor: Colors.red));
    }
  }

  void _showLogoutConfirm() {
    showDialog(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () async {
            await UserService.instance.logout();
            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) {
              Navigator.pushAndRemoveUntil(context, SmoothRoute(builder: (_) => const LoginScreen()), (_) => false);
            }
          }, child: const Text('退出', style: TextStyle(color: Color(0xFFFF3B30)))),
        ],
      ),
    );
  }

  void _showClearDataConfirm() {
    showDialog(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除数据'),
        content: const Text('将清除所有日记、草稿和设置数据。此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            await UserService.instance.logout();
            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) {
              Navigator.pushAndRemoveUntil(context, SmoothRoute(builder: (_) => const LoginScreen()), (_) => false);
            }
          }, child: const Text('确定清除', style: TextStyle(color: Color(0xFFFF3B30)))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor(context),
      body: Column(children: [
        ResponsiveAppBar(
          backgroundColor: appBgColor(context),
          titleAlignment: CrossAxisAlignment.center,
          left: IconButton(icon: Icon(Icons.arrow_back_ios, size: 18, color: Colors.grey[600]), onPressed: () => Navigator.pop(context)),
          center: const Text('设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
        ),
        Expanded(child: ListView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20), children: [
          // 个人信息
          _buildSection('个人信息', [
            _buildAvatarRow(),
            _buildDivider(),
            _buildTapItem('昵称', _nickname, _showEditNickname),
            _buildDivider(),
            _buildTapItem('签名', _signature.isEmpty ? '未设置' : _signature, _showEditSignature),
          ]),
          const SizedBox(height: 16),
          // 日记设置
          _buildSection('日记设置', [
            _buildSwitchItem('自动保存草稿', '离开写作页时自动保存', _autoSave, (v) async {
              final p = await SharedPreferences.getInstance(); await p.setBool('auto_save', v);
              setState(() => _autoSave = v);
            }),
            _buildDivider(),
            _buildSwitchItem('每日写作提醒', '${_notifyHour.toString().padLeft(2,'0')}:${_notifyMinute.toString().padLeft(2,'0')} 推送通知', _notifyEnabled, (v) async {
              await NotificationService.setEnabled(v);
              setState(() => _notifyEnabled = v);
            }),
            if (_notifyEnabled) _buildTapItem('提醒时间', '${_notifyHour.toString().padLeft(2,'0')}:${_notifyMinute.toString().padLeft(2,'0')}', _showTimePicker),
          ]),
          const SizedBox(height: 16),
          // 安全设置
          _buildSection('安全设置', [
            _buildBiometricItem(),
            _buildDivider(),
            _buildDecoyPasswordItem(),
            _buildDivider(),
            _buildChangePasswordItem(),
          ]),
          const SizedBox(height: 16),
          // 其他
          _buildSection('其他', [
            _buildTapItem('清除缓存', '', _clearCache),
            _buildDivider(),
            _buildClearDataItem(),
          ]),
          const SizedBox(height: 16),
          // 退出登录
          GestureDetector(
            onTap: _showLogoutConfirm,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: appCardColor(context), borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
              child: const Center(child: Text('退出登录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFFF3B30)))),
            ),
          ),
          const SizedBox(height: 32),
        ])),
      ]),
    );
  }

  // ═══ UI 组件 ═══

  Widget _buildAvatarRow() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        const Text('头像', style: TextStyle(fontSize: 16, color: Color(0xFF1A1A1A))),
        const Spacer(),
        Container(
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE0E0E0), width: 2)),
          child: ClipRRect(borderRadius: BorderRadius.circular(24), child: _defaultAvatar()),
        ),
      ]),
    );
  }

  Widget _defaultAvatar() => Image.asset('assets/images/samoye/default_avatar.png',
      width: 48, height: 48, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(Icons.pets, size: 24, color: Colors.grey[400]));

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: appCardColor(context), borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
        ...children,
      ]),
    );
  }

  Widget _buildTapItem(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A))),
          const Spacer(),
          if (value.isNotEmpty) ...[Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[400])), const SizedBox(width: 4)],
          Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
        ]),
      ),
    );
  }

  Widget _buildSwitchItem(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ])),
        Switch(value: value, onChanged: onChanged, activeColor: _tc),
      ]),
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey[200], indent: 20, endIndent: 20);

  Widget _buildBiometricItem() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_biometricType, style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 2),
          Text('使用$_biometricType解锁应用', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ])),
        Switch(value: _biometricEnabled, onChanged: _onBiometricChanged, activeColor: _tc),
      ]),
    );
  }

  Widget _buildDecoyPasswordItem() {
    return GestureDetector(
      onTap: _showDecoyPasswordDialog, behavior: HitTestBehavior.opaque,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          const Text('伪装密码', style: TextStyle(fontSize: 16, color: Color(0xFF1A1A1A))),
          const Spacer(),
          Text(_hasDecoyPassword ? '已设置' : '未设置', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
        ]),
      ),
    );
  }

  Widget _buildChangePasswordItem() {
    return GestureDetector(
      onTap: _showChangePasswordDialog, behavior: HitTestBehavior.opaque,
      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Text('修改密码', style: TextStyle(fontSize: 16, color: Color(0xFF1A1A1A))),
          Spacer(),
          Icon(Icons.chevron_right, size: 20, color: Color(0xFF999999)),
        ]),
      ),
    );
  }

  Widget _buildClearDataItem() {
    return GestureDetector(
      onTap: _showClearDataConfirm, behavior: HitTestBehavior.opaque,
      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Text('清除所有数据', style: TextStyle(fontSize: 16, color: Color(0xFFFF3B30))),
          Spacer(),
          Icon(Icons.chevron_right, size: 20, color: Color(0xFF999999)),
        ]),
      ),
    );
  }
}
