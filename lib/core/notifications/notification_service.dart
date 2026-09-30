
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // =========================================================
  // INITIALIZE
  // =========================================================

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    // Teachly is using Egypt time.
    tz.setLocalLocation(
      tz.getLocation('Africa/Cairo'),
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse:
          _onNotificationTapped,
    );

    final AndroidFlutterLocalNotificationsPlugin?
        androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  // =========================================================
  // NOTIFICATION TAP
  // =========================================================

  void _onNotificationTapped(
    NotificationResponse response,
  ) {
    // Navigation can be added later.
  }

  // =========================================================
  // NORMAL REMINDER
  // =========================================================

  Future<void> scheduleReminder({
    required int notificationId,
    required String title,
    String? description,
    required DateTime dateTime,
  }) async {
    await initialize();

    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.from(
      dateTime,
      tz.local,
    );

    if (scheduledDate.isBefore(
      tz.TZDateTime.now(tz.local),
    )) {
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'teachly_reminders',
      'Teachly Reminders',
      channelDescription:
          'Notifications for Teachly reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id: notificationId,
      title: title,
      body: description,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle,
      payload: notificationId.toString(),
    );
  }

  // =========================================================
  // AUTOMATIC CLASS NOTIFICATION
  // =========================================================

  Future<void> scheduleClassNotification({
    required int notificationId,
    required String subject,
    required String day,
    required String startTime,
  }) async {
    await initialize();

    final DateTime? parsedTime =
        _parseTime(startTime);

    if (parsedTime == null) {
      print(
        'Teachly ERROR: Could not parse class time: $startTime',
      );
      return;
    }

    final int? weekday =
        _getWeekday(day);

    if (weekday == null) {
      print(
        'Teachly ERROR: Could not parse class day: $day',
      );
      return;
    }

    final tz.TZDateTime now =
        tz.TZDateTime.now(tz.local);

    // Find next occurrence of the class.
    tz.TZDateTime classDate =
        _nextOccurrence(
      now: now,
      weekday: weekday,
      hour: parsedTime.hour,
      minute: parsedTime.minute,
    );

    // Five minutes before the class.
    tz.TZDateTime notificationDate =
        classDate.subtract(
      const Duration(minutes: 5),
    );

    // If the notification time has already passed,
    // schedule next week's class.
    if (!notificationDate.isAfter(now)) {
      classDate = classDate.add(
        const Duration(days: 7),
      );

      notificationDate =
          classDate.subtract(
        const Duration(minutes: 5),
      );
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'teachly_classes',
      'Teachly Classes',
      channelDescription:
          'Automatic notifications before Teachly classes',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id: notificationId,
      title: 'Upcoming Class',
      body: '$subject starts in 5 minutes',
      scheduledDate: notificationDate,
      notificationDetails: notificationDetails,
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.dayOfWeekAndTime,
      payload: 'class_$notificationId',
    );

    print(
      '==========================================',
    );
    print(
      'Teachly CLASS NOTIFICATION SCHEDULED',
    );
    print(
      'Subject: $subject',
    );
    print(
      'Day: $day',
    );
    print(
      'Class time: $startTime',
    );
    print(
      'Notification time: $notificationDate',
    );
    print(
      'Timezone: ${tz.local.name}',
    );
    print(
      '==========================================',
    );
  }

  // =========================================================
  // NEXT WEEKLY OCCURRENCE
  // =========================================================

  tz.TZDateTime _nextOccurrence({
    required tz.TZDateTime now,
    required int weekday,
    required int hour,
    required int minute,
  }) {
    tz.TZDateTime date = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    int daysUntil =
        (weekday - date.weekday) % 7;

    date = date.add(
      Duration(days: daysUntil),
    );

    if (!date.isAfter(now)) {
      date = date.add(
        const Duration(days: 7),
      );
    }

    return date;
  }

  // =========================================================
  // PARSE TIME
  // =========================================================

  DateTime? _parseTime(String value) {
    try {
      final parts =
          value.trim().split(' ');

      if (parts.isEmpty) {
        return null;
      }

      final timeParts =
          parts[0].split(':');

      if (timeParts.length != 2) {
        return null;
      }

      int hour =
          int.parse(timeParts[0]);

      final int minute =
          int.parse(timeParts[1]);

      if (parts.length > 1) {
        final String period =
            parts[1].toUpperCase();

        if (period == 'PM' && hour != 12) {
          hour += 12;
        }

        if (period == 'AM' && hour == 12) {
          hour = 0;
        }
      }

      return DateTime(
        2000,
        1,
        1,
        hour,
        minute,
      );
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // DAY → WEEKDAY
  // =========================================================

  int? _getWeekday(String day) {
    switch (day.trim().toLowerCase()) {
      case 'monday':
        return DateTime.monday;

      case 'tuesday':
        return DateTime.tuesday;

      case 'wednesday':
        return DateTime.wednesday;

      case 'thursday':
        return DateTime.thursday;

      case 'friday':
        return DateTime.friday;

      case 'saturday':
        return DateTime.saturday;

      case 'sunday':
        return DateTime.sunday;

      default:
        return null;
    }
  }

  // =========================================================
  // CANCEL ONE NOTIFICATION
  // =========================================================

  Future<void> cancelReminder(
    int notificationId,
  ) async {
    await initialize();

    await _notifications.cancel(
      id: notificationId,
    );
  }

  // =========================================================
  // CANCEL ALL
  // =========================================================

  Future<void> cancelAllReminders() async {
    await initialize();

    await _notifications.cancelAll();
  }
  Future<void> cancelAllNotifications() async {
  await initialize();
  await _notifications.cancelAll();
}
}

