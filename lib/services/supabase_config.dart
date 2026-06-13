import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 云端配置
class SupabaseConfig {
  // 替换为你的 Supabase 项目 URL
  static const String url = 'https://eztidfeihvjhmtslwdtk.supabase.co';

  // 替换为你的 Supabase anon key（公开密钥，客户端安全使用）
  static const String publishableKey =
      'sb_publishable_6adfmwJbc0xjqOYl3CaDAA_0V9XKCvY';

  /// 初始化 Supabase 客户端
  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
    );
  }
}
