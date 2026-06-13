import 'dart:convert';
import 'dart:math';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户数据服务
/// 敏感数据使用 FlutterSecureStorage（iOS Keychain / Android Keystore）
/// 非敏感数据使用 SharedPreferences
class UserService {
  // FlutterSecureStorage 实例
  static const _secureStorage = FlutterSecureStorage();

  // SecureStorage 键（敏感数据）
  static const _keyNickname = 'user_nickname';
  static const _keyAvatarPath = 'user_avatar_path';
  static const _keyUserId = 'user_id';
  static const _keyIsLoggedIn = 'user_is_logged_in';
  static const _keyIsGuest = 'user_is_guest';
  static const _keyUsersDb = 'users_db';
  static const _keyLoginAttempts = 'user_login_attempts';
  static const _keyLastFailTime = 'user_last_fail_time';
  static const _keyIsInDecoyMode = 'user_is_in_decoy_mode';

  // SharedPreferences 键（非敏感数据）
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _prefAvatarPath = 'avatar_path'; // 头像路径双存一份到 SharedPreferences 防止丢失

  // 登录锁定配置
  static const _maxAttempts = 5;
  static const _lockoutMinutes = 15;

  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();
  UserService._();

  String _nickname = '';
  String _avatarPath = '';
  String _userId = '';
  bool _isLoggedIn = false;
  bool _isGuest = false;
  bool _isInDecoyMode = false;
  int _loginAttempts = 0;
  DateTime? _lastFailTime;

  String get nickname => _nickname;
  String get avatarPath => _avatarPath;
  String get userId => _userId;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  bool get isInDecoyMode => _isInDecoyMode;

  /// 初始化：从本地存储加载数据
  Future<void> init() async {
    // 读取敏感数据
    _isLoggedIn = (await _secureStorage.read(key: _keyIsLoggedIn)) == 'true';
    _isGuest = (await _secureStorage.read(key: _keyIsGuest)) == 'true';
    _isInDecoyMode = (await _secureStorage.read(key: _keyIsInDecoyMode)) == 'true';
    _nickname = await _secureStorage.read(key: _keyNickname) ?? '';
    _avatarPath = await _secureStorage.read(key: _keyAvatarPath) ?? '';
    // 双存兜底：如果 secure storage 读不到，从 SharedPreferences 读取
    if (_avatarPath.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _avatarPath = prefs.getString(_prefAvatarPath) ?? '';
    }
    _userId = await _secureStorage.read(key: _keyUserId) ?? '';

    // 读取登录失败记录
    final attemptsStr = await _secureStorage.read(key: _keyLoginAttempts);
    _loginAttempts = attemptsStr != null ? int.tryParse(attemptsStr) ?? 0 : 0;
    final lastFailStr = await _secureStorage.read(key: _keyLastFailTime);
    _lastFailTime = lastFailStr != null ? DateTime.tryParse(lastFailStr) : null;

    // 尝试从旧 SharedPreferences 迁移数据
    await _migrateFromSharedPreferences();

    debugPrint('[用户服务] 初始化完成: isLoggedIn=$_isLoggedIn, nickname=$_nickname, decoyMode=$_isInDecoyMode');
  }

  /// 从旧 SharedPreferences 迁移数据到 SecureStorage
  Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final oldDb = prefs.getString('users_db');

    if (oldDb != null && oldDb.isNotEmpty) {
      debugPrint('[用户服务] 发现旧数据，开始迁移...');
      // 迁移用户数据库
      await _secureStorage.write(key: _keyUsersDb, value: oldDb);
      await prefs.remove('users_db');

      // 迁移登录状态
      final oldLoggedIn = prefs.getBool('user_is_logged_in');
      if (oldLoggedIn != null) {
        await _secureStorage.write(key: _keyIsLoggedIn, value: oldLoggedIn.toString());
        await prefs.remove('user_is_logged_in');
      }
      final oldGuest = prefs.getBool('user_is_guest');
      if (oldGuest != null) {
        await _secureStorage.write(key: _keyIsGuest, value: oldGuest.toString());
        await prefs.remove('user_is_guest');
      }
      final oldNickname = prefs.getString('user_nickname');
      if (oldNickname != null) {
        await _secureStorage.write(key: _keyNickname, value: oldNickname);
        await prefs.remove('user_nickname');
      }
      final oldUserId = prefs.getString('user_id');
      if (oldUserId != null) {
        await _secureStorage.write(key: _keyUserId, value: oldUserId);
        await prefs.remove('user_id');
      }

      debugPrint('[用户服务] 数据迁移完成');
    }
  }

  /// 生成唯一ID（8位数字）
  String _generateUserId() {
    final random = Random();
    return List.generate(8, (_) => random.nextInt(10).toString()).join();
  }

  /// 生成默认昵称：某不知名阿耶 + 两位随机数字
  String generateDefaultNickname() {
    final random = Random();
    final num = random.nextInt(100);
    return '某不知名阿耶${num.toString().padLeft(2, '0')}';
  }

  /// 生成随机 salt
  String _generateSalt() {
    return BCrypt.gensalt();
  }

  /// 使用 bcrypt 哈希密码（自带 salt）
  String _hashPassword(String password) {
    return BCrypt.hashpw(password, _generateSalt());
  }

  /// 验证密码
  bool _verifyPassword(String password, String hash) {
    try {
      return BCrypt.checkpw(password, hash);
    } catch (e) {
      debugPrint('[用户服务] 密码验证错误: $e');
      return false;
    }
  }

  /// 获取用户数据库
  Future<Map<String, dynamic>> _getUsersDb() async {
    final dbStr = await _secureStorage.read(key: _keyUsersDb);
    if (dbStr == null || dbStr.isEmpty) {
      return {};
    }
    try {
      return jsonDecode(dbStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[用户服务] 数据库解析失败: $e');
      return {};
    }
  }

  /// 保存用户数据库
  Future<void> _saveUsersDb(Map<String, dynamic> db) async {
    await _secureStorage.write(key: _keyUsersDb, value: jsonEncode(db));
  }

  /// 检查是否被锁定
  /// 返回 null 表示未锁定，否则返回剩余秒数
  Future<int?> _checkLockout() async {
    if (_loginAttempts < _maxAttempts || _lastFailTime == null) {
      return null;
    }

    final now = DateTime.now();
    final diff = now.difference(_lastFailTime!).inMinutes;

    if (diff >= _lockoutMinutes) {
      // 锁定时间已过，重置
      _loginAttempts = 0;
      _lastFailTime = null;
      await _secureStorage.write(key: _keyLoginAttempts, value: '0');
      await _secureStorage.delete(key: _keyLastFailTime);
      return null;
    }

    // 返回剩余锁定秒数
    return (_lockoutMinutes - diff) * 60 - now.difference(_lastFailTime!).inSeconds % 60;
  }

  /// 记录登录失败
  Future<void> _recordFailAttempt() async {
    _loginAttempts++;
    _lastFailTime = DateTime.now();
    await _secureStorage.write(key: _keyLoginAttempts, value: _loginAttempts.toString());
    await _secureStorage.write(key: _keyLastFailTime, value: _lastFailTime!.toIso8601String());
  }

  /// 重置登录失败记录
  Future<void> _resetFailAttempts() async {
    _loginAttempts = 0;
    _lastFailTime = null;
    await _secureStorage.write(key: _keyLoginAttempts, value: '0');
    await _secureStorage.delete(key: _keyLastFailTime);
  }

  /// 注册新用户
  Future<bool> register(String nickname, String password, {String? decoyPassword}) async {
    try {
      debugPrint('[注册] 开始注册: nickname=$nickname');

      final db = await _getUsersDb();
      debugPrint('[注册] 当前用户数: ${db.length}');

      // 检查昵称是否已存在
      if (db.containsKey(nickname)) {
        debugPrint('[注册] 昵称已存在');
        return false;
      }

      // 生成用户ID
      String userId;
      do {
        userId = _generateUserId();
      } while (db.values.any((u) => u['userId'] == userId));
      debugPrint('[注册] 生成用户ID: $userId');

      // 构建用户数据（密码已加盐）
      final userData = <String, dynamic>{
        'userId': userId,
        'password': _hashPassword(password),
        'createdAt': DateTime.now().toIso8601String(),
      };

      // 如果设置了伪装密码
      if (decoyPassword != null && decoyPassword.isNotEmpty) {
        userData['decoyPassword'] = _hashPassword(decoyPassword);
      }

      // 保存新用户
      db[nickname] = userData;
      await _saveUsersDb(db);
      debugPrint('[注册] 保存用户数据成功');

      // 自动登录
      await _saveLoginState(nickname, userId);
      debugPrint('[注册] 自动登录成功');

      return true;
    } catch (e) {
      debugPrint('[注册] 发生错误: $e');
      return false;
    }
  }

  /// 登录
  /// 返回值：
  ///   'success' - 登录成功
  ///   'decoy' - 伪装密码登录成功
  ///   'locked' - 账号已锁定
  ///   'failed' - 密码错误
  ///   'not_found' - 用户不存在
  Future<String> login(String nickname, String password) async {
    try {
      debugPrint('[登录] 开始登录: nickname=$nickname');

      // 检查是否被锁定
      final lockoutRemaining = await _checkLockout();
      if (lockoutRemaining != null) {
        debugPrint('[登录] 账号已锁定，剩余 $lockoutRemaining 秒');
        return 'locked';
      }

      final db = await _getUsersDb();

      if (!db.containsKey(nickname)) {
        debugPrint('[登录] 用户不存在');
        return 'not_found';
      }

      final user = db[nickname] as Map<String, dynamic>;

      // 检查是否是伪装密码
      if (user.containsKey('decoyPassword')) {
        if (_verifyPassword(password, user['decoyPassword'])) {
          debugPrint('[登录] 伪装密码登录成功');
          await _resetFailAttempts();
          await _saveLoginState(nickname, user['userId'] as String);
          await setDecoyMode(); // 设置为假日记模式
          return 'decoy';
        }
      }

      // 检查真实密码
      if (_verifyPassword(password, user['password'])) {
        debugPrint('[登录] 登录成功');
        await _resetFailAttempts();
        await _saveLoginState(nickname, user['userId'] as String);
        await clearDecoyMode(); // 清除假日记模式
        return 'success';
      }

      // 密码错误
      debugPrint('[登录] 密码错误');
      await _recordFailAttempt();
      return 'failed';
    } catch (e) {
      debugPrint('[登录] 发生错误: $e');
      return 'failed';
    }
  }

  /// 获取登录失败信息
  Future<LoginFailInfo> getLoginFailInfo() async {
    final lockoutRemaining = await _checkLockout();
    return LoginFailInfo(
      attempts: _loginAttempts,
      maxAttempts: _maxAttempts,
      isLocked: lockoutRemaining != null,
      lockoutRemainingSeconds: lockoutRemaining ?? 0,
    );
  }

  /// 游客模式进入
  Future<void> enterAsGuest() async {
    _nickname = generateDefaultNickname();
    _userId = '';
    _isLoggedIn = true;
    _isGuest = true;

    await _secureStorage.write(key: _keyIsLoggedIn, value: 'true');
    await _secureStorage.write(key: _keyIsGuest, value: 'true');
    await _secureStorage.write(key: _keyNickname, value: _nickname);
    await _secureStorage.delete(key: _keyUserId);
  }

  /// 保存登录状态
  Future<void> _saveLoginState(String nickname, String userId) async {
    _nickname = nickname;
    _userId = userId;
    _isLoggedIn = true;
    _isGuest = false;

    await _secureStorage.write(key: _keyNickname, value: nickname);
    await _secureStorage.write(key: _keyUserId, value: userId);
    await _secureStorage.write(key: _keyIsLoggedIn, value: 'true');
    await _secureStorage.write(key: _keyIsGuest, value: 'false');
  }

  /// 退出登录
  Future<void> logout() async {
    debugPrint('[退出登录] 开始退出登录');

    _nickname = '';
    _userId = '';
    _isLoggedIn = false;
    _isGuest = false;
    _isInDecoyMode = false;

    await _secureStorage.delete(key: _keyIsLoggedIn);
    await _secureStorage.delete(key: _keyIsGuest);
    await _secureStorage.delete(key: _keyNickname);
    await _secureStorage.delete(key: _keyUserId);
    await _secureStorage.delete(key: _keyIsInDecoyMode);

    debugPrint('[退出登录] 退出登录完成');
  }

  /// 清除所有用户数据（调试用）
  Future<void> clearAllData() async {
    _nickname = '';
    _userId = '';
    _isLoggedIn = false;
    _isGuest = false;
    _isInDecoyMode = false;

    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('[用户服务] 已清除所有数据');
  }

  /// 更新昵称（同步更新登录数据库）
  Future<void> updateNickname(String name) async {
    if (_isGuest) return;
    final oldName = _nickname;
    if (oldName == name) return;
    _nickname = name;
    await _secureStorage.write(key: _keyNickname, value: name);

    // 同步更新用户数据库中的 key
    try {
      final db = await _getUsersDb();
      if (db.containsKey(oldName) && !db.containsKey(name)) {
        final userData = Map<String, dynamic>.from(db[oldName] as Map);
        db[name] = userData;
        db.remove(oldName);
        await _saveUsersDb(db);
      }
    } catch (_) {}
  }

  /// 更新头像路径（双存：secure storage + SharedPreferences，防止部分安卓机丢失数据）
  Future<void> updateAvatar(String path) async {
    _avatarPath = path;
    await _secureStorage.write(key: _keyAvatarPath, value: path);
    // 双存到 SharedPreferences 兜底
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefAvatarPath, path);
  }

  /// 设置伪装密码
  Future<bool> setDecoyPassword(String decoyPassword) async {
    if (_isGuest) return false;

    try {
      final db = await _getUsersDb();
      if (!db.containsKey(_nickname)) return false;

      final user = db[_nickname] as Map<String, dynamic>;
      user['decoyPassword'] = _hashPassword(decoyPassword);
      db[_nickname] = user;
      await _saveUsersDb(db);

      debugPrint('[用户服务] 伪装密码设置成功');
      return true;
    } catch (e) {
      debugPrint('[用户服务] 设置伪装密码失败: $e');
      return false;
    }
  }

  /// 移除伪装密码
  Future<bool> removeDecoyPassword() async {
    if (_isGuest) return false;

    try {
      final db = await _getUsersDb();
      if (!db.containsKey(_nickname)) return false;

      final user = db[_nickname] as Map<String, dynamic>;
      user.remove('decoyPassword');
      db[_nickname] = user;
      await _saveUsersDb(db);

      debugPrint('[用户服务] 伪装密码已移除');
      return true;
    } catch (e) {
      debugPrint('[用户服务] 移除伪装密码失败: $e');
      return false;
    }
  }

  /// 检查是否设置了伪装密码
  Future<bool> hasDecoyPassword() async {
    if (_isGuest) return false;

    try {
      final db = await _getUsersDb();
      if (!db.containsKey(_nickname)) return false;

      final user = db[_nickname] as Map<String, dynamic>;
      return user.containsKey('decoyPassword');
    } catch (e) {
      return false;
    }
  }

  /// 修改密码
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_isGuest) return false;

    try {
      final db = await _getUsersDb();
      if (!db.containsKey(_nickname)) return false;

      final user = db[_nickname] as Map<String, dynamic>;

      // 验证旧密码
      if (!_verifyPassword(oldPassword, user['password'])) {
        return false;
      }

      // 更新密码
      user['password'] = _hashPassword(newPassword);
      db[_nickname] = user;
      await _saveUsersDb(db);

      debugPrint('[用户服务] 密码修改成功');
      return true;
    } catch (e) {
      debugPrint('[用户服务] 修改密码失败: $e');
      return false;
    }
  }

  /// 获取生物识别开关状态
  Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  /// 设置生物识别开关状态
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  /// 设置为假日记模式
  Future<void> setDecoyMode() async {
    _isInDecoyMode = true;
    await _secureStorage.write(key: _keyIsInDecoyMode, value: 'true');
    debugPrint('[用户服务] 已切换到假日记模式');
  }

  /// 清除假日记模式（回到真实日记）
  Future<void> clearDecoyMode() async {
    _isInDecoyMode = false;
    await _secureStorage.write(key: _keyIsInDecoyMode, value: 'false');
    debugPrint('[用户服务] 已切换到真实日记模式');
  }

  /// 检查是否有伪装密码
  /// 用于判断是否需要显示密码输入页面
  Future<bool> needPasswordToEnter() async {
    if (!_isLoggedIn || _isGuest) return false;
    // 如果在假日记模式，或者启用了生物识别锁，都需要验证
    if (_isInDecoyMode) return true;
    final biometricEnabled = await getBiometricEnabled();
    return biometricEnabled;
  }
}

/// 登录失败信息
class LoginFailInfo {
  final int attempts;
  final int maxAttempts;
  final bool isLocked;
  final int lockoutRemainingSeconds;

  const LoginFailInfo({
    required this.attempts,
    required this.maxAttempts,
    required this.isLocked,
    required this.lockoutRemainingSeconds,
  });

  /// 剩余尝试次数
  int get remainingAttempts => maxAttempts - attempts;
}
