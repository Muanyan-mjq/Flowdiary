import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 云端认证服务
/// 在本地 UserService 基础上，提供可选的 Supabase 云端账号绑定
class CloudAuthService {
  static CloudAuthService? _instance;
  static CloudAuthService get instance => _instance ??= CloudAuthService._();
  CloudAuthService._();

  static const _keyCloudEmail = 'cloud_email';
  static const _keyCloudEnabled = 'cloud_enabled';

  SupabaseClient get _client => Supabase.instance.client;

  /// 是否已绑定云端账号
  bool _cloudEnabled = false;
  bool get isCloudEnabled => _cloudEnabled;

  /// 云端邮箱（用于显示）
  String _cloudEmail = '';
  String get cloudEmail => _cloudEmail;

  /// 初始化：检查是否已绑定
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cloudEnabled = prefs.getBool(_keyCloudEnabled) ?? false;
    _cloudEmail = prefs.getString(_keyCloudEmail) ?? '';

    // 如果已绑定但 Supabase session 过期，尝试恢复
    if (_cloudEnabled && _client.auth.currentSession == null) {
      debugPrint('[云端认证] 已绑定但 session 过期，需要重新登录');
    }
  }

  /// 当前 Supabase 用户 ID（未登录返回 null）
  String? get currentUserId => _client.auth.currentUser?.id;

  /// 注册云端账号并绑定到当前本地账号
  Future<CloudAuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _saveCloudBinding(email);
        debugPrint('[云端认证] 注册并绑定成功: $email');
        return CloudAuthResult.success('云端账号注册成功');
      }
      return CloudAuthResult.failure('注册失败，请重试');
    } on AuthException catch (e) {
      debugPrint('[云端认证] 注册失败: ${e.message}');
      return CloudAuthResult.failure(_translateError(e.message));
    } catch (e) {
      debugPrint('[云端认证] 注册异常: $e');
      return CloudAuthResult.failure('网络错误，请稍后重试');
    }
  }

  /// 登录已有云端账号（用于换设备时恢复数据）
  Future<CloudAuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      await _saveCloudBinding(email);
      debugPrint('[云端认证] 登录成功: $email');
      return CloudAuthResult.success('云端账号登录成功');
    } on AuthException catch (e) {
      debugPrint('[云端认证] 登录失败: ${e.message}');
      return CloudAuthResult.failure(_translateError(e.message));
    } catch (e) {
      debugPrint('[云端认证] 登录异常: $e');
      return CloudAuthResult.failure('网络错误，请稍后重试');
    }
  }

  /// 解绑云端账号
  Future<void> unbind() async {
    if (_client.auth.currentSession != null) {
      await _client.auth.signOut();
    }
    _cloudEnabled = false;
    _cloudEmail = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCloudEnabled);
    await prefs.remove(_keyCloudEmail);
    debugPrint('[云端认证] 已解绑');
  }

  /// 保存绑定状态
  Future<void> _saveCloudBinding(String email) async {
    _cloudEnabled = true;
    _cloudEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCloudEnabled, true);
    await prefs.setString(_keyCloudEmail, email);
  }

  /// 翻译 Supabase 错误信息为中文
  String _translateError(String message) {
    if (message.contains('already registered') || message.contains('already exists')) {
      return '该邮箱已被注册';
    }
    if (message.contains('Invalid login credentials')) {
      return '邮箱或密码错误';
    }
    if (message.contains('password') && message.contains('length')) {
      return '密码至少6位';
    }
    return message;
  }
}

/// 云端认证结果
class CloudAuthResult {
  final bool isSuccess;
  final String message;

  const CloudAuthResult._(this.isSuccess, this.message);
  factory CloudAuthResult.success(String msg) => CloudAuthResult._(true, msg);
  factory CloudAuthResult.failure(String msg) => CloudAuthResult._(false, msg);
}
