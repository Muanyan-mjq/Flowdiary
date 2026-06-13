/// 高可用天气定位通知服务：GPS 定位 → 获取天气 → 治愈系通知
library moo_location_weather_service;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// ============================================================
// 1. 核心数据模型
// ============================================================

/// 天气类型枚举
enum MooWeatherType {
  sunny,   // 晴天
  cloudy,  // 多云
  rainy,   // 下雨
  snowy,   // 下雪
  windy,   // 大风
  unknown, // 未知
}

/// 天气数据模型
class MooWeatherData {
  final String cityName;           // 城市/区县名
  final int temp;                  // 当前温度
  final MooWeatherType weatherType; // 天气类型枚举
  final String weatherDescription; // 原始天气描述
  final DateTime updateTime;       // 更新时间

  const MooWeatherData({
    required this.cityName,
    required this.temp,
    required this.weatherType,
    required this.weatherDescription,
    required this.updateTime,
  });

  /// 从 JSON 解析（wttr.in format=j1 格式）
  ///
  /// wttr.in 返回格式：
  /// {
  ///   "current_condition": [{"temp_C": "25", "weatherCode": "113",
  ///     "weatherDesc": [{"value": "Sunny"}]}],
  ///   "nearest_area": [{"areaName": [{"value": "Wuhan"}]}]
  /// }
  factory MooWeatherData.fromJson(Map<String, dynamic> json) {
    // 城市名：从 nearest_area 提取
    String cityName = '未知';
    try {
      final areas = json['nearest_area'] as List?;
      if (areas != null && areas.isNotEmpty) {
        final area = areas[0] as Map<String, dynamic>;
        final names = area['areaName'] as List?;
        if (names != null && names.isNotEmpty) {
          cityName = (names[0] as Map<String, dynamic>)['value']?.toString() ?? '未知';
        }
      }
    } catch (_) {
      cityName = '未知';
    }

    // 温度：从 current_condition 提取
    int temp = 25;
    String desc = '晴';
    int weatherCode = 113;
    try {
      final conditions = json['current_condition'] as List?;
      if (conditions != null && conditions.isNotEmpty) {
        final cc = conditions[0] as Map<String, dynamic>;
        final tempC = cc['temp_C'];
        temp = (tempC is String) ? int.tryParse(tempC) ?? 25 : ((tempC as num).round());
        weatherCode = int.tryParse(cc['weatherCode']?.toString() ?? '113') ?? 113;
        final descs = cc['weatherDesc'] as List?;
        if (descs != null && descs.isNotEmpty) {
          desc = (descs[0] as Map<String, dynamic>)['value']?.toString() ?? '晴';
        }
      }
    } catch (_) {
      temp = 25;
      desc = '晴';
    }

    // 映射天气类型（wttr.in weatherCode）
    final type = _mapWttrWeatherType(weatherCode, desc);

    return MooWeatherData(
      cityName: cityName,
      temp: temp,
      weatherType: type,
      weatherDescription: desc,
      updateTime: DateTime.now(),
    );
  }

  /// 根据 wttr.in weatherCode 映射天气类型
  ///
  /// wttr.in 天气代码范围：
  /// - 113: 晴
  /// - 116,119,122: 多云/阴
  /// - 14x,248,260: 雾/霾
  /// - 176,2xx(不含200): 雨/毛毛雨
  /// - 200,386,389,392,395: 雷暴
  /// - 179,3xx: 雪/冰雹/冻雨
  static MooWeatherType _mapWttrWeatherType(int code, String desc) {
    final lower = desc.toLowerCase();

    // 晴天
    if (code == 113) return MooWeatherType.sunny;

    // 多云 / 阴
    if (code == 116 || code == 119 || code == 122) return MooWeatherType.cloudy;

    // 雾 / 霾
    if ((code >= 143 && code < 150) || code == 248 || code == 260) {
      return MooWeatherType.cloudy;
    }

    // 雷暴
    if (code == 200 || (code >= 386 && code <= 395)) return MooWeatherType.rainy;

    // 雨 / 毛毛雨
    if ((code >= 176 && code < 180) || (code >= 263 && code < 300)) {
      return MooWeatherType.rainy;
    }
    // 中雨/大雨
    if (code >= 302 && code < 360) return MooWeatherType.rainy;

    // 雪 / 冰雹 / 冻雨
    if ((code >= 179 && code <= 185) || (code >= 227 && code <= 230)) {
      return MooWeatherType.snowy;
    }
    if (code >= 317 && code <= 377) return MooWeatherType.snowy;

    // 兜底：按文字描述判断
    if (lower.contains('雨') || lower.contains('rain') || lower.contains('drizzle')) {
      return MooWeatherType.rainy;
    }
    if (lower.contains('雪') || lower.contains('snow')) return MooWeatherType.snowy;
    if (lower.contains('风') || lower.contains('wind')) return MooWeatherType.windy;
    if (lower.contains('云') || lower.contains('阴') || lower.contains('cloud') || lower.contains('overcast')) {
      return MooWeatherType.cloudy;
    }
    if (lower.contains('晴') || lower.contains('clear') || lower.contains('sunny')) {
      return MooWeatherType.sunny;
    }

    return MooWeatherType.unknown;
  }

  /// 兜底默认数据
  factory MooWeatherData.defaultData() {
    return MooWeatherData(
      cityName: '未知',
      temp: 25,
      weatherType: MooWeatherType.sunny,
      weatherDescription: '晴',
      updateTime: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'MooWeatherData(city: $cityName, temp: $temp°C, type: $weatherType, desc: $weatherDescription)';
  }
}

// ============================================================
// 自定义异常
// ============================================================

/// 定位权限异常
class LocationPermissionDeniedException implements Exception {
  final String message;
  LocationPermissionDeniedException(this.message);

  @override
  String toString() => 'LocationPermissionDeniedException: $message';
}

/// 天气网络异常
class WeatherNetworkException implements Exception {
  final String message;
  final int? statusCode;

  WeatherNetworkException(this.message, {this.statusCode});

  @override
  String toString() => 'WeatherNetworkException: $message (status: $statusCode)';
}

// ============================================================
// 2. 高精度融合定位器
// ============================================================

class _PreciseLocationClient {
  /// 获取高精度 GPS 坐标
  ///
  /// 精度：高精度
  /// 超时：5 秒
  ///
  /// 抛出：
  /// - [LocationPermissionDeniedException] 用户永久拒绝权限
  /// - [Exception] 其他定位失败
  static Future<Position> capturePreciseGPS() async {
    // 第一步：检查系统 GPS 是否开启
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationPermissionDeniedException('LOCATION_SERVICE_DISABLED');
    }

    // 第二步：检查 App 定位授权状态
    var permission = await Geolocator.checkPermission();

    // 状态为 denied 时，动态申请
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 状态为 deniedForever 时，抛出自定义异常
    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedException('USER_PERMANENT_DENIED');
    }

    // 状态仍为 denied，抛出异常
    if (permission == LocationPermission.denied) {
      throw LocationPermissionDeniedException('USER_DENIED');
    }

    // 第三步：授权通过，抓取经纬度
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );
  }
}

// ============================================================
// 3. 真实商业天气网络客户端
// ============================================================

class _WeatherApiClient {
  /// 获取天气数据（wttr.in，免费，用 GPS 经纬度查询）
  ///
  /// [lat] 纬度
  /// [lng] 经度
  ///
  /// 抛出 [WeatherNetworkException] 网络请求失败
  static Future<Map<String, dynamic>> fetchGridWeather({
    required double lat,
    required double lng,
  }) async {
    // 用 GPS 经纬度查询，格式：wttr.in/{lat},{lon}?format=j1
    final url = Uri.parse(
      'https://wttr.in/${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)}?format=j1',
    );

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        throw WeatherNetworkException(
          'HTTP 请求失败',
          statusCode: response.statusCode,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json;
    } on WeatherNetworkException {
      rethrow;
    } catch (e) {
      throw WeatherNetworkException('网络请求异常: $e');
    }
  }
}

// ============================================================
// 4. 治愈系通知文本状态机
// ============================================================

class _MooNotificationContent {
  final String title;
  final String body;

  const _MooNotificationContent({required this.title, required this.body});
}

class _MooEmotionEngine {
  /// 根据天气数据生成治愈系通知文案
  ///
  /// 使用匿名兔口吻，符合 Moo 日记治愈风格
  static _MooNotificationContent generate(MooWeatherData data) {
    switch (data.weatherType) {
      // ---- 下雨天 ----
      case MooWeatherType.rainy:
        return const _MooNotificationContent(
          title: '匿名兔听到了窗外的雨声点点...',
          body: '你那里下雨了呀。出门记得带伞，晚上早点回家，'
              '把湿漉漉的心情写进今天的日记本里吧 🌧️',
        );

      // ---- 大晴天 ----
      case MooWeatherType.sunny:
        return const _MooNotificationContent(
          title: '今天的天气，像你的笑容一样明亮',
          body: '抓住这抹温暖的阳光！今天有什么开心的事发生吗？'
              '快来记录下来，别让它溜走啦 ✨',
        );

      // ---- 下雪 / 大风（降温/恶劣天气）----
      case MooWeatherType.snowy:
      case MooWeatherType.windy:
        return const _MooNotificationContent(
          title: '呼~ 匿名兔提醒你多加一件外套',
          body: '气温悄悄下降了呢。倒一杯热水，找个舒服的姿势，'
              '来和我说说今天的小故事吧 ☕',
        );

      // ---- 多云 ----
      case MooWeatherType.cloudy:
        return const _MooNotificationContent(
          title: '今天的云层厚厚的，像棉花糖',
          body: '多云的天气，心情也刚刚好。'
              '有什么想说的吗？匿名兔在这里听你讲 ☁️',
        );

      // ---- 未知 / 默认 ----
      case MooWeatherType.unknown:
        return const _MooNotificationContent(
          title: '下午好，匿名兔在等你的今天',
          body: '不管你身在何处，不论你那里是晴是雨，'
              '今晚都想听听你的呢喃。来写篇日记吧 🌙',
        );
    }
  }
}

// ============================================================
// 5. 主服务类
// ============================================================

class MooLocationWeatherService {
  // 单例
  static final MooLocationWeatherService _instance = MooLocationWeatherService._();
  factory MooLocationWeatherService() => _instance;
  MooLocationWeatherService._();

  // 通知插件实例
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Android 通知渠道配置
  static const _androidChannel = AndroidNotificationChannel(
    'moo_weather_channel', // 渠道 ID
    '天气提醒',             // 渠道名称
    description: 'Moo 日记天气提醒通知',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// 初始化通知服务（在 App 启动时调用）
  static Future<void> init() async {
    // Android 初始化
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // 创建 Android 通知渠道
    final android = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(_androidChannel);
      // 请求通知权限（Android 13+）
      await android.requestNotificationsPermission();
    }
  }

  // ============================================================
  // 主入口：后台天气检查并通知
  // ============================================================

  /// 统一公共主入口
  ///
  /// 可被 android_alarm_manager_plus 或 workmanager 直接调用
  ///
  /// 功能：
  /// 1. GPS 定位
  /// 2. 获取天气
  /// 3. 推送治愈系通知
  ///
  /// 异常处理：自动降级，永不崩溃
  static Future<void> executeBackgroundWeatherCheckAndNotify() async {
    debugPrint('[MooWeather] 开始执行后台天气检查...');

    try {
      // ---- 第一步：GPS 定位 ----
      Position? position;
      try {
        position = await _PreciseLocationClient.capturePreciseGPS();
        debugPrint('[MooWeather] GPS 定位成功: ${position.latitude}, ${position.longitude}');
      } on LocationPermissionDeniedException catch (e) {
        debugPrint('[MooWeather] 定位权限异常: $e');
        // 权限异常，进入降级流程
        _showFallbackNotification();
        return;
      } catch (e) {
        debugPrint('[MooWeather] GPS 定位失败: $e');
        // GPS 失败，进入降级流程
        _showFallbackNotification();
        return;
      }

      // ---- 第二步：获取天气 ----
      Map<String, dynamic>? weatherJson;
      try {
        weatherJson = await _WeatherApiClient.fetchGridWeather(
          lat: position.latitude,
          lng: position.longitude,
        );
      } on WeatherNetworkException catch (e) {
        debugPrint('[MooWeather] 天气 API 异常: $e');
        // 网络异常，进入降级流程
        _showFallbackNotification();
        return;
      } catch (e) {
        debugPrint('[MooWeather] 获取天气失败: $e');
        _showFallbackNotification();
        return;
      }

      // ---- 第三步：解析天气数据 ----
      MooWeatherData weatherData;
      try {
        weatherData = MooWeatherData.fromJson(weatherJson);
        debugPrint('[MooWeather] 天气数据: $weatherData');
      } catch (e) {
        debugPrint('[MooWeather] 解析天气数据失败: $e');
        _showFallbackNotification();
        return;
      }

      // ---- 第四步：推送治愈系通知 ----
      await _showWeatherNotification(weatherData);

      debugPrint('[MooWeather] 后台天气检查完成 ✓');
    } catch (e) {
      // 最外层兜底：任何未预期的异常都降级处理
      debugPrint('[MooWeather] 未预期异常: $e');
      _showFallbackNotification();
    }
  }

  // ============================================================
  // 通知推送
  // ============================================================

  /// 推送天气相关通知
  static Future<void> _showWeatherNotification(MooWeatherData data) async {
    final content = _MooEmotionEngine.generate(data);
    await _showNotification(
      id: 1,
      title: content.title,
      body: content.body,
    );
  }

  /// 推送兜底通知（降级时使用）
  static void _showFallbackNotification() {
    debugPrint('[MooWeather] 推送兜底通知');
    _showNotification(
      id: 99,
      title: '下午好，匿名兔在等你的今天',
      body: '不管你身在何处，不论你那里是晴是雨，'
          '今晚都想听听你的呢喃。来写篇日记吧 🌙',
    );
  }

  /// 通用通知推送方法
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(id, title, body, details);
      debugPrint('[MooWeather] 通知推送成功: $title');
    } catch (e) {
      debugPrint('[MooWeather] 通知推送失败: $e');
    }
  }
}
