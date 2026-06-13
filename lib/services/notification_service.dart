import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// 每日写作提醒服务
class NotificationService {
  static const _keyEnabled = 'notification_enabled';
  static const _keyHour = 'notification_hour';
  static const _keyMinute = 'notification_minute';

  static final _plugin = FlutterLocalNotificationsPlugin();

  /// 初始化（需在 main 中调用）
  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final enabled = await isEnabled();
    if (enabled) await schedule();
  }

  static Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyEnabled) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyEnabled, value);
    if (value) {
      await schedule();
    } else {
      await _plugin.cancelAll();
    }
  }

  static Future<({int hour, int minute})> getTime() async {
    final p = await SharedPreferences.getInstance();
    return (hour: p.getInt(_keyHour) ?? 21, minute: p.getInt(_keyMinute) ?? 0);
  }

  static Future<void> setTime(int hour, int minute) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyHour, hour);
    await p.setInt(_keyMinute, minute);
    if (await isEnabled()) {
      await _plugin.cancelAll();
      await schedule();
    }
  }

  /// 安排每日通知
  static Future<void> schedule() async {
    final time = await getTime();
    await _plugin.cancelAll();

    // 计算下一次触发时间
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      0,
      '该写日记啦',
      '今天过得怎么样？花几分钟记录下来吧 ✨',
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder', '每日提醒',
          channelDescription: '每日写作提醒',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
