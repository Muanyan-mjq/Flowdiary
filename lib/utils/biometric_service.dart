import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

/// 生物识别服务
/// 封装面容/指纹识别功能
class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// 检查设备是否支持生物识别
  static Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('[生物识别] 检查设备支持失败: $e');
      return false;
    }
  }

  /// 检查是否有注册的生物识别（指纹/面容）
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('[生物识别] 检查生物识别失败: $e');
      return false;
    }
  }

  /// 获取可用的生物识别类型
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('[生物识别] 获取可用类型失败: $e');
      return [];
    }
  }

  /// 检查是否支持面容识别
  static Future<bool> hasFaceId() async {
    final types = await getAvailableBiometrics();
    return types.contains(BiometricType.face);
  }

  /// 检查是否支持指纹识别
  static Future<bool> hasFingerprint() async {
    final types = await getAvailableBiometrics();
    return types.contains(BiometricType.fingerprint) ||
           types.contains(BiometricType.strong);
  }

  /// 获取生物识别类型描述
  static Future<String> getBiometricTypeDescription() async {
    final types = await getAvailableBiometrics();
    if (types.isEmpty) return '无';

    final hasFace = types.contains(BiometricType.face);
    final hasFingerprint = types.contains(BiometricType.fingerprint) ||
                           types.contains(BiometricType.strong);

    if (hasFace && hasFingerprint) return '面容 + 指纹';
    if (hasFace) return '面容';
    if (hasFingerprint) return '指纹';
    return '生物识别';
  }

  /// 执行生物识别验证
  /// 返回 true 表示验证成功
  static Future<bool> authenticate({
    String reason = '请验证身份以继续',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // 允许设备密码作为备选
        ),
      );
      return isAuthenticated;
    } catch (e) {
      debugPrint('[生物识别] 验证失败: $e');
      return false;
    }
  }

  /// 检查是否可以使用生物识别（设备支持 + 有注册的生物识别）
  static Future<bool> canUseBiometric() async {
    final isSupported = await isDeviceSupported();
    final canCheck = await canCheckBiometrics();
    return isSupported && canCheck;
  }
}
