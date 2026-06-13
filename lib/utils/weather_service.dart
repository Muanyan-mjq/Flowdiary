import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// 天气服务
/// 优先 GPS 定位，失败则用 ip-api.com 定位（比 wttr.in 准）
class WeatherService {
  /// 获取当前天气
  static Future<WeatherData> getWeather() async {
    try {
      double? lat;
      double? lon;
      String city = '';

      // 第一步：尝试 GPS 定位
      final position = await _getCurrentPosition();
      if (position != null) {
        lat = position.latitude;
        lon = position.longitude;
        debugPrint('[天气] GPS 位置: $lat, $lon');
      } else {
        // 第二步：GPS 失败，用 ip-api.com 定位
        final ipLocation = await _getIPLocation();
        if (ipLocation != null) {
          lat = ipLocation['lat'];
          lon = ipLocation['lon'];
          city = ipLocation['city'] ?? '';
          debugPrint('[天气] IP 定位: $city ($lat, $lon)');
        }
      }

      // 第三步：用经纬度查天气
      String url;
      if (lat != null && lon != null) {
        url = 'https://wttr.in/$lat,$lon?format=j1';
      } else {
        url = 'https://wttr.in/?format=j1';
        debugPrint('[天气] 使用默认位置');
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final current = json['current_condition'][0];
        final temp = int.tryParse(current['temp_C']?.toString() ?? '25') ?? 25;
        final desc = current['weatherDesc'][0]['value'] ?? 'Sunny';
        final humidity = int.tryParse(current['humidity']?.toString() ?? '50') ?? 50;
        final windDir = current['winddir16Point'] ?? '';

        // 从天气接口获取位置名（如果 IP 定位没拿到）
        if (city.isEmpty) {
          final area = json['nearest_area'][0];
          city = area['areaName'][0]['value'] ?? '';
        }

        return WeatherData(
          description: desc,
          temperature: temp,
          iconCode: _mapDescToCode(desc),
          windDir: windDir,
          humidity: humidity,
          city: city,
        );
      }

      debugPrint('[天气] API 返回异常: ${response.statusCode}');
      return WeatherData.defaultData();
    } catch (e) {
      debugPrint('[天气] 获取天气失败: $e');
      return WeatherData.defaultData();
    }
  }

  /// 通过 ip-api.com 获取 IP 位置（免费，无需 key，对中国用户准）
  static Future<Map<String, dynamic>?> _getIPLocation() async {
    try {
      final response = await http.get(
        Uri.parse('https://ip-api.com/json/?lang=zh-CN&fields=status,lat,lon,city,regionName'),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          return {
            'lat': (json['lat'] as num).toDouble(),
            'lon': (json['lon'] as num).toDouble(),
            'city': json['city'] ?? '',
            'region': json['regionName'] ?? '',
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('[定位] IP 定位失败: $e');
      return null;
    }
  }

  /// 获取 GPS 位置
  static Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('[定位] GPS 失败: $e');
      return null;
    }
  }

  /// 根据天气描述映射图标代码
  static String _mapDescToCode(String desc) {
    final lower = desc.toLowerCase();
    if (lower.contains('sunny') || lower.contains('clear')) return '100';
    if (lower.contains('cloudy') || lower.contains('overcast')) return '103';
    if (lower.contains('rain') || lower.contains('drizzle') || lower.contains('shower')) return '300';
    if (lower.contains('snow') || lower.contains('sleet')) return '400';
    if (lower.contains('fog') || lower.contains('mist') || lower.contains('haze')) return '500';
    if (lower.contains('thunder')) return '302';
    return '100';
  }
}

/// 天气数据封装
class WeatherData {
  final String description;
  final int temperature;
  final String iconCode;
  final String windDir;
  final int humidity;
  final String city;
  /// 是否为离线默认数据（未获取到真实天气）
  final bool isOffline;

  const WeatherData({
    required this.description,
    required this.temperature,
    required this.iconCode,
    this.windDir = '',
    this.humidity = 50,
    this.city = '',
    this.isOffline = false,
  });

  factory WeatherData.defaultData() {
    return const WeatherData(
      description: 'Sunny',
      temperature: 25,
      iconCode: '100',
      isOffline: true,
    );
  }

  String get category {
    final code = int.tryParse(iconCode) ?? 100;
    if (temperature >= 35) return 'hot';
    if (temperature <= 5) return 'cold';
    if (code >= 100 && code <= 102) return 'sunny';
    if (code == 103 || code == 104) return 'cloudy';
    if (code >= 300 && code <= 399) return 'rain';
    if (code >= 400 && code <= 499) return 'snow';
    if (code >= 500 && code <= 599) return 'fog';
    return 'sunny';
  }

  String get categoryChinese {
    switch (category) {
      case 'sunny': return '晴天';
      case 'cloudy': return '多云';
      case 'rain': return '雨天';
      case 'snow': return '雪天';
      case 'fog': return '雾天';
      case 'hot': return '高温';
      case 'cold': return '低温';
      default: return '晴天';
    }
  }
}
