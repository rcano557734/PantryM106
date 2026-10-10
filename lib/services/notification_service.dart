import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int _reminderId = 1001;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      // Fallback for devices where the native timezone isn't available.
      tz.setLocalLocation(tz.getLocation('Asia/Manila'));
    }

    const androidSettings = AndroidInitializationSettings(
      'ic_stat_pantrymatch',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(initializationSettings);

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final granted = await android?.requestNotificationsPermission();

    // Some Android versions don't need a runtime permission.
    return granted ?? true;
  }

  Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await initialize();

    final permissionGranted = await requestPermission();

    if (!permissionGranted) {
      return false;
    }

    final now = tz.TZDateTime.now(tz.local);

    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If today's time has passed, schedule the next occurrence tomorrow.
    if (!scheduledTime.isAfter(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notifications.cancel(_reminderId);

    await _notifications.zonedSchedule(
      _reminderId,
      'Time to plan your next meal!',
      'Open PantryMatch and discover what you can cook with your ingredients.',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminders',
          'Meal reminders',
          channelDescription:
              'Daily reminders to find recipes using pantry ingredients.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    return true;
  }

  Future<void> cancelDailyReminder() async {
    await initialize();
    await _notifications.cancel(_reminderId);
  }
}
